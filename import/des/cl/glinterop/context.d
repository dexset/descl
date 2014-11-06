module des.cl.glinterop.context;

import des.cl.base;
import des.cl.device;
import des.cl.platform;
import des.cl.context;

class CLGLContext : CLContext
{
public:

    this( CLPlatform pl ) { super(pl); }

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
