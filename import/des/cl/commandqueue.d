module des.cl.commandqueue;

import des.cl.base;
import des.cl.device;
import des.cl.context;

class CLCommandQueue : CLResource
{
    cl_command_queue id;

    CLContext context;
    CLDevice device;

    enum Properties
    {
        NONE = 0,
        OUT_OF_ORDER = CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE,
        PROFILING = CL_QUEUE_PROFILING_ENABLE
    }

    this( CLContext ctx, size_t devID, Properties[] prop=[Properties.NONE] )
    in { assert( ctx !is null ); } body
    {
        context = ctx;
        device = context.devices[devID];
        assert( device !is null );
        id = checkCode!clCreateCommandQueue( context.id, device.id, buildFlags(prop) );
        updateProperties();
    }

    void flush() { checkCall!clFlush(id); }
    void finish() { checkCall!clFinish(id); }

    static private enum prop_list = 
    [
        "size_t:properties"
    ];

    mixin( infoProperties( "command_queue", "queue", prop_list ) );

protected:

    override void selfDestroy()
    { checkCall!clReleaseCommandQueue(id); }
}
