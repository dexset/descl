module des.cl.glinterop.context;

import des.cl.base;
import des.cl.device;
import des.cl.platform;
import des.cl.context;
import des.cl.commandqueue;

import des.cl.glinterop.memory;

class CLGLContext : CLContext
{
protected:

    static struct AcquireElem
    {
        CLCommandQueue queue;
        CLGLMemory mem;
    }

    AcquireElem[] acquired_list;

public:

    this( CLPlatform pl, size_t[] devIDs ) { super(pl,devIDs); }
    this( CLPlatform pl, CLDevice.Type type ) { super(pl,type); }

    void registerAcquired( CLCommandQueue queue, CLGLMemory mem )
    {
        acquired_list ~= AcquireElem( queue, mem );
    }

    void releaseAllToGL()
    {
        CLCommandQueue[] qs;
        foreach( elem; acquired_list )
        {
            elem.mem.releaseToGL( elem.queue );
            qs ~= elem.queue;
        }

        acquired_list.length = 0;

        foreach( q; qs ) q.finish();
    }

protected:
    override cl_context_properties[] getProperties()
    {
        version(linux)
        {
            import derelict.opengl3.glx;
            return [ CL_GL_CONTEXT_KHR, cast(cl_context_properties)glXGetCurrentContext(),
                    CL_GLX_DISPLAY_KHR, cast(cl_context_properties)glXGetCurrentDisplay() ] ~
                super.getProperties();
        }
        version(Windows)
        {
            // TODO
            static assert(0, "not implemented");
        }
        version(OSX)
        {
            // TODO
            static assert(0, "not implemented");
        }
    }
}
