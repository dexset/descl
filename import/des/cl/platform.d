module des.cl.platform;

import des.cl.base;

import des.cl.device;
import des.cl.context;

///
class CLPlatform : ExternalMemoryManager
{
    mixin EMM;

private:

    ///
    this( cl_platform_id pl_id )
    {
        this.id = pl_id;
        updateInfo();

        devices = registerChildEMM( CLDevice.getAll(this) );
    }

public:

    ///
    CLDevice[] devices;

    ///
    cl_platform_id id;

    ///
    static CLPlatform[] getAll()
    {
        cl_uint nums;
        checkCall!clGetPlatformIDs( 0, null, &nums );
        auto ids = new cl_platform_id[](nums);
        checkCall!clGetPlatformIDs( nums, ids.ptr, &nums );
        CLPlatform[] buf;
        foreach( id; ids )
            buf ~= new CLPlatform(id);
        return buf;
    }

    /++ generate info properties
     +
     + Rules:
     + ---
     +      type:param_name
     +      cl_type:dlang_type:param_name
     + ---
     + List:
     + ---
     +  string:name
     +  string:vendor
     +  string:profile
     +  string:version
     +  string:extensions
     + ---
     +/
    static private enum info_list =
    [
        "string:name",
        "string:vendor",
        "string:profile",
        "string:version",
        "string:extensions"
    ];

    mixin( infoMixin( "platform", info_list ) );
}
