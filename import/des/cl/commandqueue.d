module des.cl.commandqueue;

import des.cl.base;
import des.cl.device;
import des.cl.context;

class CLCommandQueue : CLReference
{
    cl_command_queue id;

    enum Properties
    {
        NONE = 0,
        OUT_OF_ORDER_EXEC_MODE_ENABLE = CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE,
        PROFILING_ENABLE = CL_QUEUE_PROFILING_ENABLE
    }

    this( CLContext context, CLDevice device, Properties prop=Properties.NONE )
    {
        int retcode;
        id = clCreateCommandQueue( context.id, device.id,
                prop, &retcode );
        checkError( retcode, "clCreateCommandQueue" );
    }

    void flush() { clFlush(id); }
    void finish() { clFinish(id); }

    // TODO info

    protected override void selfDestroy()
    { checkCall!(clReleaseCommandQueue)(id); }
}
