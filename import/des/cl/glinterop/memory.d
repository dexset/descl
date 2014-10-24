module des.cl.glinterop.memory;

import des.gl.base;
import des.cl.base;
import des.cl.memory;
import des.cl.commandqueue;

import des.cl.glinterop.context;

class CLGLMemory : CLMemory
{
protected:
    this( cl_mem id, Type type, Flag[] flags )
    { super( id, type, flags ); }

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
        int retcode;
        auto id = clCreateFromGLBuffer( context.id, compileFlags(flags), buffer.id, &retcode );
        checkError( retcode, "clCreateFromGLBuffer" );

        return new CLGLMemory( id, Type.BUFFER, flags );
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
        int retcode;
        CLMemory.Type tp;
        cl_mem id;
        ulong cflags = compileFlags(flags);
        if( texture.target == texture.Target.T2D )
        {
            id = clCreateFromGLTexture2D( context.id, cflags, cast(GLenum)texture.target,
                                            0, texture.id, &retcode );
            tp = Type.IMAGE2D;
            checkError( retcode, "clCreateFromGLTexture2D" );
        }
        else if( texture.target == texture.Target.T3D )
        {
            id = clCreateFromGLTexture3D( context.id, cflags, cast(GLenum)texture.target,
                                            0, texture.id, &retcode );
            tp = Type.IMAGE3D;
            checkError( retcode, "clCreateFromGLTexture3D" );
        }
        else throw new CLException( format( "unsupported gl texture type %s", texture.target) );
        return new CLGLMemory( id, tp, flags );
    }

    static auto createFromGLRenderBuffer( CLGLContext context, GLRenderBuffer buffer, Flag[] flags=[Flag.READ_WRITE] )
    in{
        assert( context !is null );
        assert( buffer !is null );
        assert( flags.length > 0 );
        assert( all!(validCLGLMemoryFlag)(flags) );
    }
    body
    {
        int retcode;
        auto id = clCreateFromGLRenderbuffer( context.id, compileFlags(flags), buffer.id, &retcode );
        checkError( retcode, "clCreateFromGLRenderbuffer" );

        return new CLGLMemory( id, Type.IMAGE2D, flags );
    }

    void acquireFromGL( CLCommandQueue command_queue )
    {
        checkCall!(clEnqueueAcquireGLObjects)( command_queue.id, 1u, &id, 
                0, cast(cl_event*)null, cast(cl_event*)null ); // TODO events
    }

    void releaseToGL( CLCommandQueue command_queue )
    {
        checkCall!(clEnqueueReleaseGLObjects)( command_queue.id, 1u, &id, 
                0, cast(cl_event*)null, cast(cl_event*)null ); // TODO events
    }
}
