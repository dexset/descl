module des.cl.memory;

import std.traits;

import des.cl.base;
import des.cl.context;
import des.cl.event;
import des.cl.commandqueue;

///
class CLMemory : CLResource
{
protected:
    ///
    this( CLContext context, cl_mem mem_id, Type type, Flag[] flags )
    {
        this.id = mem_id;
        this._type = type;
        this._flags = flags.dup;
        this.context = context;
    }

public:
    ///
    cl_mem id;

    ///
    CLContext context;

    ///
    enum Type
    {
        BUFFER,  ///
        IMAGE2D, ///
        IMAGE3D  ///
    }

    private Type _type;
    ///
    Type type() @property const { return _type; }

    ///
    enum Flag
    {
        READ_WRITE     = CL_MEM_READ_WRITE,     /// `CL_MEM_READ_WRITE`
        WRITE_ONLY     = CL_MEM_WRITE_ONLY,     /// `CL_MEM_WRITE_ONLY`
        READ_ONLY      = CL_MEM_READ_ONLY,      /// `CL_MEM_READ_ONLY`
        USE_HOST_PTR   = CL_MEM_USE_HOST_PTR,   /// `CL_MEM_USE_HOST_PTR`
        ALLOC_HOST_PTR = CL_MEM_ALLOC_HOST_PTR, /// `CL_MEM_ALLOC_HOST_PTR`
        COPY_HOST_PTR  = CL_MEM_COPY_HOST_PTR   /// `CL_MEM_COPY_HOST_PTR`
    }

    private Flag[] _flags;
    ///
    const(Flag[]) flags() @property const { return _flags; }

    ///
    static CLMemory createBuffer( CLContext context, Flag[] flags, size_t size, void* host_ptr=null )
    {
        auto id = checkCode!clCreateBuffer( context.id, buildFlags(flags ~ (host_ptr?[Flag.USE_HOST_PTR]:[])), size, host_ptr );

        return new CLMemory( context, id, Type.BUFFER, flags );
    }

    // TODO: Image

    ///
    void readTo( CLCommandQueue command_queue, void[] buffer, size_t offset=0, bool blocking=true,
            CLEvent[] wait_list=[], CLEvent event=null )
    {
        assert( type == Type.BUFFER ); // TODO: images

        checkCall!clEnqueueReadBuffer( command_queue.id, id,
               blocking, offset, 
               buffer.length, buffer.ptr, 
               cast(cl_uint)wait_list.length, 
               amap!(a=>a.id)(wait_list).ptr,
               (event is null ? null : &(event.id)) );
    }

    ///
    void[] read( CLCommandQueue command_queue, size_t size, size_t offset=0, bool blocking=true,
            CLEvent[] wait_list=[], CLEvent event=null )
    {
        auto buffer = new void[](size);
        readTo( command_queue, buffer, offset, blocking, wait_list, event );
        return buffer;
    }

    ///
    void write( CLCommandQueue command_queue, void[] buffer, size_t offset=0, bool blocking=true,
            CLEvent[] wait_list=[], CLEvent event=null )
    {
        assert( type == Type.BUFFER ); // TODO: images

        checkCall!clEnqueueWriteBuffer( command_queue.id, id,
                blocking, offset,
                buffer.length, buffer.ptr,
                cast(cl_uint)wait_list.length,
                amap!(a=>a.id)(wait_list).ptr,
                (event is null ? null : &(event.id)) );
    }

    // TODO: map

protected:
    override void selfDestroy() { checkCall!clRetainMemObject(id); }
}
