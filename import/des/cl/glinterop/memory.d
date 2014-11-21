module des.cl.glinterop.memory;

import des.gl.base;

import des.cl.base;
import des.cl.memory;
import des.cl.commandqueue;
import des.cl.context;
import des.cl.event;

import des.cl.glinterop.context;

class CLGLMemory : CLMemory
{
protected:
    this( CLContext ctx, cl_mem id, Type type, Flag[] flags )
    { super( ctx, id, type, flags ); }

    static bool validCLGLMemoryFlag( Flag flag )
    {
        final switch( flag )
        {
            case Flag.READ_WRITE:
            case Flag.WRITE_ONLY:
            case Flag.READ_ONLY:
                return true;
            case Flag.USE_HOST_PTR:
            case Flag.ALLOC_HOST_PTR:
            case Flag.COPY_HOST_PTR:
                return false;
        }
    }

    bool acquired = false;

public:

    static auto createFromGLBuffer( CLGLContext context, GLBuffer buffer, Flag[] flags=[Flag.READ_WRITE] )
    in{
        assert( context !is null );
        assert( buffer !is null );
        assert( flags.length > 0 );
        assert( all!(validCLGLMemoryFlag)(flags) );
    }
    body
    {
        auto id = checkCode!clCreateFromGLBuffer( context.id, buildFlags(flags), buffer.id );
        return new CLGLMemory( context, id, Type.BUFFER, flags );
    }

    static auto createFromGLTexture( CLGLContext context, GLTexture texture, Flag[] flags=[Flag.READ_WRITE] )
    in{
        assert( context !is null );
        assert( texture !is null );
        assert( flags.length > 0 );
        assert( all!(validCLGLMemoryFlag)(flags) );
    }
    body
    {
        CLMemory.Type tp;
        cl_mem id;
        ulong cflags = buildFlags(flags);
        if( texture.target == texture.Target.T2D )
        {
            id = checkCode!clCreateFromGLTexture2D( context.id, cflags, cast(GLenum)texture.target,
                                            0, texture.id );
            tp = Type.IMAGE2D;
        }
        else if( texture.target == texture.Target.T3D )
        {
            id = checkCode!clCreateFromGLTexture3D( context.id, cflags, cast(GLenum)texture.target,
                                            0, texture.id );
            tp = Type.IMAGE3D;
        }
        else throw new CLException( format( "unsupported gl texture type %s", texture.target) );
        return new CLGLMemory( context, id, tp, flags );
    }

    static auto createFromGLRenderBuffer( CLGLContext context,
            GLRenderBuffer buffer, Flag[] flags=[Flag.READ_WRITE] )
    in{
        assert( context !is null );
        assert( buffer !is null );
        assert( flags.length > 0 );
        assert( all!(validCLGLMemoryFlag)(flags) );
    }
    body
    {
        auto id = checkCode!clCreateFromGLRenderbuffer( context.id, buildFlags(flags), buffer.id );

        return new CLGLMemory( context, id, Type.IMAGE2D, flags );
    }

    @property bool isAcquired() const { return acquired; }

    void acquireFromGL( CLCommandQueue queue, CLEvent[] wait_list=[], CLEvent event=null )
    in{ assert( queue !is null ); } body
    {
        if( acquired ) return;
        checkCall!clEnqueueAcquireGLObjects( queue.id, 1u, &id, 
                cast(uint)wait_list.length,
                amap!(a=>a.id)(wait_list).ptr,
                event ? &(event.id) : null );
        acquired = true;
        (cast(CLGLContext)context).registerAcquired( this );
    }

    void releaseToGL( CLCommandQueue queue, CLEvent[] wait_list=[], CLEvent event=null )
    {
        if( !acquired ) return;
        checkCall!clEnqueueReleaseGLObjects( queue.id, 1u, &id,
                cast(uint)wait_list.length,
                amap!(a=>a.id)(wait_list).ptr,
                event ? &(event.id) : null );
        acquired = false;
        (cast(CLGLContext)context).unregisterAcquired( this );
    }

    package void ctxReleaseToGL() { acquired = false; }
}
