module des.cl.kernel;

import std.string;
import std.traits;

import des.cl.base;
import des.cl.event;
import des.cl.memory;
import des.cl.commandqueue;
import des.cl.program;

import des.math.linear;

interface CLMemoryHandler
{
    protected @property CLMemory clmem();
    protected @property void clmem( CLMemory );

    void setAsArgCallback( CLKernel );

    static @property string getCLMemProperty()
    {
        return `
        protected
        {
            CLMemory clmemory;
            @property CLMemory clmem() { return clmemory; }
            @property void clmem( CLMemory m )
            in{ assert( m !is null ); } body
            { clmemory = m; }
        }`;
    }
}

class CLKernel : CLResource
{
public:
    cl_kernel id;

    this( CLProgram program, string name )
    {
        id = checkCode!clCreateKernel( program.id, name.toStringz );
    }

    void setArgs(Args...)( Args args )
    {
        foreach( i, arg; args )
            setArg( i, arg );
    }

    static struct CallParams
    {
        CLCommandQueue queue;
        size_t[] offset, size, loc_size;

        void reset() { offset = []; size = []; loc_size = []; }
    }

    CallParams params;

    void setQueue( CLCommandQueue queue )
    in { assert( queue !is null ); } body
    { params.queue = queue; }

    void setParams( CLCommandQueue queue, size_t[] offset, size_t[] size, size_t[] loc_size=[] )
    in { assert( queue !is null ); } body
    {
        params.queue = queue;
        params.offset = offset.dup;
        params.size = size.dup;
        params.loc_size = loc_size.dup;
    }

    void setSizes( size_t[] size, size_t[] loc_size=[] )
    {
        params.size = size.dup;
        params.loc_size = loc_size.dup;
    }

    void exec( CLEvent[] wait_list=[], CLEvent event=null )
    in
    {
        assert( params.queue !is null );

        auto dm = params.size.length;

        assert( dm >= 1 && dm <= 3 );
        assert( params.offset.length == dm ||
                params.offset.length == 0 );
        assert( params.loc_size.length == dm ||
                params.loc_size.length == 0 );
    }
    body
    {
        uint dim = cast(uint)params.size.length;
        size_t* lws_ptr = params.loc_size.length ? params.loc_size.ptr : null;
        auto gwo = params.offset.length ? params.offset : new size_t[](dim);

        checkCall!clEnqueueNDRangeKernel( params.queue.id,
                this.id, dim,
                gwo.ptr,
                params.size.ptr,
                lws_ptr,
                cast(cl_uint)wait_list.length,
                amap!(a=>a.id)(wait_list).ptr,
                (event is null ? null : &(event.id)) );
    }

    void opCall(Args...)( size_t[] sz, size_t[] lsz,
                          Args args )
    {
        setArgs( args );
        setSizes( sz, lsz );
        exec();
    }

    void opCall(Args...)( size_t[] sz, size_t[] lsz, 
                          CLEvent[] wlist, CLEvent ev,
                          Args args )
    {
        setArgs( args );
        setSizes( sz, lsz );
        exec( wlist, ev );
    }

    void setArg(Arg)( uint index, Arg arg )
    {
        void *value;
        size_t size;

        static if( is( Arg : CLMemory ) )
        {
            auto aid = (cast(CLMemory)arg).id;
            value = &aid;
            size = aid.sizeof;
        }
        else static if( is( Arg : CLMemoryHandler ) )
        {
            auto cmh = cast(CLMemoryHandler)arg;
            cmh.setAsArgCallback( this );
            auto aid = cmh.clmem.id;
            value = &aid;
            size = aid.sizeof;
        }
        else static if( isStaticVector!Arg || isStaticMatrix!Arg )
        {
            value = arg.data.ptr;
            size = arg.data.sizeof;
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

        checkCall!clSetKernelArg( id, index, size, value );

        debug(printkernelargs)
            log_info( "set '%s' arg #%d: %s %s",
                    Arg.stringof, index, size, value );
    }

protected:

    override void selfDestroy() { checkCall!clReleaseKernel(id); }

}
