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

    void setAsKernelArgCallback( CLCommandQueue );

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

    this( CLProgram program, string nm )
    {
        k_name = nm;
        id = checkCode!clCreateKernel( program.id, nm.toStringz );
    }

    private string k_name;
    @property string name() const { return k_name; }

    void setArgs(Args...)( Args args )
    {
        foreach( i, arg; args )
            setArg( i, arg );
    }

    static struct CallParams
    {
        CLCommandQueue queue;
        CLEvent event;
        size_t[] offset, size, loc_size;

        void reset() { offset = []; size = []; loc_size = []; }
    }

    CallParams params;

    void setQueue( CLCommandQueue queue )
    in { assert( queue !is null ); } body
    { params.queue = queue; }

    void setMinParams( CLCommandQueue queue, CLEvent event )
    in { assert( queue !is null ); } body
    {
        params.queue = queue;
        params.event = event;
    }

    void setParams( CLCommandQueue queue, CLEvent event, size_t[] offset,
                    size_t[] size, size_t[] loc_size=[] )
    in { assert( queue !is null ); } body
    {
        params.queue = queue;
        params.event = event;
        params.offset = offset.dup;
        params.size = size.dup;
        params.loc_size = loc_size.dup;
    }

    void setSizes( size_t[] size, size_t[] loc_size=[] )
    {
        params.size = size.dup;
        params.loc_size = loc_size.dup;
    }

    void exec( CLEvent[] wait_list=[] )
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

        if( params.event ) params.event.reset();

        checkCall!clEnqueueNDRangeKernel( params.queue.id,
                this.id, dim,
                gwo.ptr,
                params.size.ptr,
                lws_ptr,
                cast(uint)wait_list.length,
                amap!(a=>a.id)(wait_list).ptr,
                (params.event is null ? null : &(params.event.id)) );
    }

    void opCall(Args...)( size_t[] sz, size_t[] lsz, Args args )
    {
        setArgs( args );
        setSizes( sz, lsz );
        exec();
    }

    void opCall(Args...)( size_t[] sz, size_t[] lsz, CLEvent[] wlist, Args args )
    {
        setArgs( args );
        setSizes( sz, lsz );
        exec( wlist );
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
            cmh.setAsKernelArgCallback( params.queue );
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

    override void selfDestroy()
    { checkCall!clRetainKernel(id); }

}
