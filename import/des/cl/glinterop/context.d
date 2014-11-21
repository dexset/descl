module des.cl.glinterop.context;

import des.cl.base;
import des.cl.device;
import des.cl.platform;
import des.cl.context;
import des.cl.event;
import des.cl.commandqueue;

import des.cl.glinterop.memory;

class CLGLContext : CLContext
{
protected:

    CLGLMemory[] acquired_list;

package:

    void registerAcquired( CLGLMemory mem )
    { acquired_list ~= mem; }

    void unregisterAcquired( CLGLMemory mem )
    {
        CLGLMemory[] buf;
        foreach( elem; acquired_list )
            if( elem.id != mem.id ) buf ~= elem;
        acquired_list = buf;
    }

public:

    this( CLPlatform pl, size_t[] devIDs ) { super(pl,devIDs); }
    this( CLPlatform pl, CLDevice.Type type ) { super(pl,type); }

    void releaseAllToGL( CLCommandQueue queue, CLEvent[] wait_list=[], CLEvent event=null )
    {
        checkCall!clEnqueueReleaseGLObjects( queue.id,
                cast(uint)acquired_list.length,
                getIDsPtr(acquired_list),
                cast(uint)wait_list.length,
                getIDsPtr(wait_list),
                event ? &(event.id) : null );

        foreach( elem; acquired_list ) elem.ctxReleaseToGL();
        acquired_list.length = 0;

        queue.finish();
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
