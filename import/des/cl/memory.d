module des.cl.memory;

import std.traits;

import des.cl.base;
import des.cl.context;
import des.cl.event;
import des.cl.commandqueue;

class CLMemory : CLReference
{
package cl_mem id;

protected:

    this( cl_mem id, Type type, Flag[] flags )
    {
        this.id = id;
        this._type = type;
        this._flags = flags.dup;
    }

public:

    enum Type
    {
        BUFFER,
        IMAGE2D,
        IMAGE3D
    }

    private Type _type;
    @property Type type() const { return _type; }

    enum Flag
    {
        READ_WRITE     = CL_MEM_READ_WRITE,
        WRITE_ONLY     = CL_MEM_WRITE_ONLY,
        READ_ONLY      = CL_MEM_READ_ONLY,
        USE_HOST_PTR   = CL_MEM_USE_HOST_PTR,
        ALLOC_HOST_PTR = CL_MEM_ALLOC_HOST_PTR,
        COPY_HOST_PTR  = CL_MEM_COPY_HOST_PTR
    }

    static pure
    {
        ulong compileFlags( Flag[] flags... )
        { return reduce!((r,f)=>r|=cast(ulong)f)(0UL,flags); }
    }

    private Flag[] _flags;
    @property const(Flag[]) flags() const { return _flags; }

    static CLMemory createBuffer( CLContext context, Flag[] flags, size_t size, void* host_ptr=null )
    {
        int retcode;
        auto id = clCreateBuffer( context.id, compileFlags(flags), size, host_ptr, &retcode );
        checkError( retcode, "clCreateBuffer" );

        return new CLMemory( id, Type.BUFFER, flags );
    }

    void readTo( CLCommandQueue command_queue, void[] buffer, size_t offset=0, bool blocking=true,
            CLEvent[] wait_list=[], CLEvent event=null )
    {
        assert( type == Type.BUFFER ); // TODO: images

        checkCall!(clEnqueueReadBuffer)( command_queue.id, id,
               blocking, offset, 
               buffer.length, buffer.ptr, 
               cast(cl_uint)wait_list.length, 
               amap!(a=>a.id)(wait_list).ptr,
               (event is null ? null : &(event.id)) );
    }

    void[] read( CLCommandQueue command_queue, size_t size, size_t offset=0, bool blocking=true,
            CLEvent[] wait_list=[], CLEvent event=null )
    {
        auto buffer = new void[](size);
        readTo( command_queue, buffer, offset, blocking, wait_list, event );
        return buffer;
    }

    void write( CLCommandQueue command_queue, void[] buffer, size_t offset=0, bool blocking=true,
            CLEvent[] wait_list=[], CLEvent event=null )
    {
        assert( type == Type.BUFFER ); // TODO: images

        checkCall!(clEnqueueWriteBuffer)( command_queue.id, id,
                blocking, offset,
                buffer.length, buffer.ptr,
                cast(cl_uint)wait_list.length,
                amap!(a=>a.id)(wait_list).ptr,
                (event is null ? null : &(event.id)) );
    }

    // TODO: map

    void release() { checkCall!(clReleaseMemObject)(id); }
}
