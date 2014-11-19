module des.cl.kernel;

import std.string;
import std.traits;

import des.cl.base;
import des.cl.event;
import des.cl.memory;
import des.cl.commandqueue;
import des.cl.program;

class CLKernel : CLReference
{
public:
    cl_kernel id;

    this( CLProgram program, string name )
    {
        int retcode;
        id = clCreateKernel( program.id, name.toStringz, &retcode );
        checkError( retcode, "clCreateKernel" );
    }

    void setArgs(Args...)( Args args )
    {
        foreach( i, arg; args )
            setArg( i, arg );
    }

    void exec( CLCommandQueue command_queue, uint dim, size_t[] global_work_offset,
            size_t[] global_work_size, size_t[] local_work_size,
            CLEvent[] wait_list=[], CLEvent event=null )
    in
    {
        assert( global_work_offset.length == dim );
        assert( global_work_size.length == dim );
        assert( local_work_size.length == dim );
    }
    body
    {
        checkCall!(clEnqueueNDRangeKernel)( command_queue.id,
                this.id, dim,
                global_work_offset.ptr,
                global_work_size.ptr,
                local_work_size.ptr,
                cast(cl_uint)wait_list.length, 
                amap!(a=>a.id)(wait_list).ptr,
                (event is null ? null : &(event.id)) );
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

        checkCall!(clSetKernelArg)( id, index, size, value );
        debug(printkernelargs)
        {
            import std.stdio;
            stderr.writefln( "set '%s' arg #%d: %s %s", 
                    Arg.stringof, index, size, value );
        }
    }

protected:

    override void selfDestroy() { checkCall!(clReleaseKernel)(id); }

}
