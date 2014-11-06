module des.cl.platform;

import des.cl.base;

class CLPlatform
{

    this( cl_platform_id pl_id )
    {
        this.id = pl_id;
        updateProperties();
    }

public:
    cl_platform_id id;

    static CLPlatform[] getAll()
    {
        cl_uint nums;
        checkCall!(clGetPlatformIDs)( 0, null, &nums );
        auto ids = new cl_platform_id[](nums);
        checkCall!(clGetPlatformIDs)( nums, ids.ptr, &nums );
        CLPlatform[] buf;
        foreach( id; ids )
            buf ~= new CLPlatform(id);
        return buf;
    }

    /+
        type:param_name,
        cl_type:dlang_type:param_name
    +/
    static private enum prop_list =
    [
        "string:name",
        "string:vendor",
        "string:profile",
        "string:version",
        "string:extensions"
    ];

    mixin( infoProperties( "platform", prop_list ) );
}
