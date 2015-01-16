module des.cl.context;

import des.cl.base;
import des.cl.device;
import des.cl.platform;
import des.cl.program;
import des.cl.commandqueue;

import des.util.stdext.string;

extern(C) void pfn_notify( const char* errinfo, const void* private_info, size_t cb, void* user_data )
{
    auto nb = (cast(shared CLContext.NotifyBuffer)user_data);
    nb.push( CLContext.Notify( errinfo.toDString,
                (cast(ubyte*)private_info)[0..cb].idup ) );
}

///
class CLContext : CLResource
{
    ///
    static synchronized class NotifyBuffer
    {
        ///
        Notify[] list;

        ///
        void push( Notify n ) { list ~= n; }

        ///
        Notify[] clearGet()
        {
            Notify[] ret;
            foreach( n; list )
                ret ~= n;
            list.length = 0;
            return ret;
        }
    }

    ///
    shared NotifyBuffer notify_buffer;

public:

    ///
    CLPlatform platform;

    ///
    CLDevice[] devices;

    ///
    static struct Notify
    {
        ///
        string errinfo;
        ///
        immutable(void)[] bininfo;
    }

    ///
    cl_context id;

    ///
    this( CLPlatform pl, size_t[] devIDs )
    {
        platform = pl;
        auto prop = getProperties();
        
        notify_buffer = new shared NotifyBuffer;

        foreach( devID; devIDs )
            devices ~= platform.devices[devID];

        id = checkCode!clCreateContext( prop.ptr,
                                       cast(uint)devices.length,
                                       amap!(a=>a.id)(devices).ptr,
                                       &pfn_notify,
                                       cast(void*)notify_buffer );
    }

    ///
    this( CLPlatform pl, CLDevice.Type type )
    {
        platform = pl;
        auto prop = getProperties();
        
        notify_buffer = new shared NotifyBuffer;

        foreach( dev; platform.devices )
            if( type == dev.type ) devices ~= dev;

        id = checkCode!clCreateContextFromType( prop.ptr, type,
                                       &pfn_notify,
                                       cast(void*)notify_buffer );
    }

    ///
    this( size_t plID, size_t[] devIDs )
    { this( CLPlatform.getAll()[plID], devIDs ); }

    ///
    this( size_t plID, CLDevice.Type type )
    { this( CLPlatform.getAll()[plID], type ); }

    ///
    Notify[] pullNotifies() { return notify_buffer.clearGet(); }

    ///
    CLProgram buildProgram( string src, CLBuildOption[] opt=[] )
    {
         auto prog = registerChildEMM( CLProgram.createWithSource( this, src ) );
         prog.build( devices, opt );
         return prog;
    }

    ///
    CLCommandQueue createQueue( CLCommandQueue.Properties[] prop, size_t devNo=0 )
    in{ assert( devNo < devices.length ); } body
    { return newEMM!CLCommandQueue( this, devNo, prop ); }

protected:

    override void selfDestroy() { checkCall!clRetainContext(id); }

    cl_context_properties[] getProperties()
    {
        return [ CL_CONTEXT_PLATFORM, cast(cl_context_properties)(platform.id), 0 ];
    }
}
