module des.cl.kernel;

import des.cl.base;
import des.cl.event;
import des.cl.memory;
import des.cl.commandqueue;
import des.cl.program;
import des.cl.device;
import des.cl.context;

///
class CLKernel : CLResource
{
package:
    ///
    cl_kernel id;

public:

    ///
    this( CLProgram program, string nm )
    { id = checkCode!clCreateKernel( program.id, nm.toStringz ); }

    static private enum info_list =
    [
        "string function_name:name",
        "uint num_args",
        "uint reference_count:refcount",    
        "cl_context:CLContext context",
        "cl_program:CLProgram program",
        "string attributes"
    ];

    mixin( infoMixin( "kernel", info_list ) );

protected:

    override void selfDestroy() { checkCall!clReleaseKernel(id); }
}

///
interface CLMemoryHandler
{
    ///
    protected CLMemory clmem() @property;

    ///
    /+ for post exec actions (release GL for example)
     + save queue and add this to list (acquired list for example)
     + before ocl operations process created list
     +/
    void preSetAsKernelArg( CLCommandQueue );

    ///
    mixin template CLMemoryHandlerHelper()
    {
        protected
        {
            CLMemory clmemory;
            CLMemory clmem() @property { return clmemory; }
        }
    }
}

///
class CLKernelCaller
{
protected:
    size_t[] offset = null;
    size_t[] wgsize = [64,1,1];
    size_t[] lgsize = null;

    uint range_dim = 1;

    void setArray( ref size_t[] arr, size_t[] val )
    {
        if( val )
        {
            enforce( val.length >= range_dim );
            arr = val[0..range_dim].dup;
        }
        else arr = null;
    }

public:

    CLKernel kernel;
    CLCommandQueue queue;
    CLEvent exec_inst;

    this( CLKernel kernel, CLCommandQueue queue )
    {
        this.kernel = kernel;
        this.queue = queue;
    }

    ///
    size_t preferedWorkGroupSizeMultiple() @property
    {
        size_t kpwgsm;

        checkCall!clGetKernelWorkGroupInfo(
                kernel.id, queue.device.id,
                CL_KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE,
                size_t.sizeof, &kpwgsm, null );

        return kpwgsm;
    }

    size_t rangeDim() const @property { return range_dim; }
    void set1DRange() { range_dim = 1; }
    void set2DRange() { range_dim = 2; }
    void set3DRange() { range_dim = 3; }

    void setGlobalOffset( size_t[] v ) { setArray( offset, v ); }
    void setWorkGroupSize( size_t[] v ) { setArray( wgsize, v ); }
    void setLocalGroupSize( size_t[] v ) { setArray( lgsize, v ); }

    ///
    void setArgs(Args...)( Args args )
    {
        foreach( i, arg; args )
            setArg( i, arg );
    }

    ///
    void range( CLEvent[] wait_list=[] )
    {
        checkCallWL!clEnqueueNDRangeKernel( queue.id, kernel.id,
                range_dim, offset.ptr, wgsize.ptr, lgsize.ptr,
                wait_list, &exec_inst );
    }

    ///
    void task( CLEvent[] wait_list=[] )
    {
        checkCallWL!clEnqueueTask( queue.id, kernel.id, wait_list, &exec_inst );
    }

protected:

    ///
    void setArg(Arg)( uint index, Arg arg )
    {
        void *value;
        size_t size;

        static if( is( Arg : CLMemory ) )
        {
            auto aid = arg ? (cast(CLMemory)arg).id : null;
            value = &aid;
            size = cl_mem.sizeof;
        }
        else static if( is( Arg : CLMemoryHandler ) )
        {
            auto cmh = cast(CLMemoryHandler)arg;
            cl_mem aid = null;
            if( cmh !is null )
            {
                cmh.preSetAsKernelArg( queue );
                aid = cmh.clmem.id;
            }
            value = &aid;
            size = cl_mem.sizeof;
        }
        else static if( !hasIndirections!Arg )
        {
            value = &arg;
            size = arg.sizeof;
        }
        else
        {
            pragma(msg, "type of ", Arg, " couldn't be set as kernel argument" );
            static assert(0);
        }

        checkCall!clSetKernelArg( kernel.id, index, size, value );

        debug(printkernelargs)
            log_info( "set '%s' arg #%d: %s %s",
                    Arg.stringof, index, size, value );
    }
}
