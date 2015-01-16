module des.cl.device;

import des.cl.base;
import des.cl.platform;

///
class CLDevice : CLResource
{
protected:
    ///
    CLPlatform platform;
    
    bool is_sub_device;

    ///
    this( cl_device_id id, CLPlatform platform, bool sub_dev=false )
    {
        this.id = id;
        this.platform = platform;
        this.is_sub_device = sub_dev;
        updateInfo();
    }

public:
    ///
    cl_device_id id;

    ///
    enum Type
    {
        CPU         = CL_DEVICE_TYPE_CPU, /// `CL_DEVICE_TYPE_CPU`
        GPU         = CL_DEVICE_TYPE_GPU, /// `CL_DEVICE_TYPE_GPU`
        ACCELERATOR = CL_DEVICE_TYPE_ACCELERATOR, /// `CL_DEVICE_TYPE_ACCELERATOR`
        DEFAULT     = CL_DEVICE_TYPE_DEFAULT /// `CL_DEVICE_TYPE_DEFAULT`
    }

    ///
    static CLDevice[] getAll( CLPlatform platform, Type type=Type.DEFAULT )
    {
        cl_uint nums;

        checkCall!clGetDeviceIDs( platform.id, type, 0, null, &nums );
        auto ids = new cl_device_id[](nums);
        checkCall!clGetDeviceIDs( platform.id, type, nums, ids.ptr, null );
        CLDevice[] buf;
        foreach( id; ids )
            buf ~= new CLDevice( id, platform, false );
        return buf;
    }

    ///
    enum FPConfig
    {
        DENORM           = CL_FP_DENORM,          /// `CL_FP_DENORM`
        INF_NAN          = CL_FP_INF_NAN,         /// `CL_FP_INF_NAN`
        ROUND_TO_NEAREST = CL_FP_ROUND_TO_NEAREST,/// `CL_FP_ROUND_TO_NEAREST`
        ROUND_TO_ZERO    = CL_FP_ROUND_TO_ZERO,   /// `CL_FP_ROUND_TO_ZERO`
        ROUND_TO_INF     = CL_FP_ROUND_TO_INF,    /// `CL_FP_ROUND_TO_INF`
        FMA              = CL_FP_FMA              /// `CL_FP_FMA`
    }

    ///
    enum ExecCapabilities
    {
        KERNEL        = CL_EXEC_KERNEL, /// `CL_EXEC_KERNEL`
        NATIVE_KERNEL = CL_EXEC_NATIVE_KERNEL /// `CL_EXEC_NATIVE_KERNEL`
    }

    ///
    enum MemCacheType
    {
        NONE             = CL_NONE,            /// `CL_NONE`
        READ_ONLY_CACHE  = CL_READ_ONLY_CACHE, ///  CL_READ_ONLY_CACHE`
        READ_WRITE_CACHE = CL_READ_WRITE_CACHE ///  CL_READ_WRITE_CACHE`
    }

    enum LocalMemTYPE
    {
        LOCAL  = CL_LOCAL, /// `CL_LOCAL`
        GLOBAL = CL_GLOBAL /// `CL_GLOBAL`
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
     +  uint:address_bits
     +  uint:bool:available
     +  uint:bool:compiler_available
     +  ulong:double_fp_config // FPConfig
     +  uint:bool:endian_little
     +  uint:bool:error_correction_support
     +  ulong:execution_capabilities
     +  string:extensions
     +  ulong:global_mem_cache_size
     +  uint:MemCacheType:global_mem_cache_type
     +  uint:global_mem_cacheline_size
     +  ulong:global_mem_size
     +  uint:bool:image_support
     +  size_t:image2d_max_height
     +  size_t:image2d_max_width
     +  size_t:image3d_max_depth
     +  size_t:image3d_max_height
     +  size_t:image3d_max_width
     +  ulong:local_mem_size
     +  uint:local_mem_type
     +  uint:max_clock_frequency
     +  uint:max_compute_units
     +  uint:max_constant_args
     +  ulong:max_constant_buffer_size
     +  ulong:max_mem_alloc_size
     +  size_t:max_parameter_size
     +  uint:max_read_image_args
     +  uint:max_samplers
     +  size_t:max_work_group_size
     +  uint:max_work_item_dimensions
     +  size_t[]:max_work_item_sizes
     +  uint:max_write_image_args
     +  uint:mem_base_addr_align
     +  uint:min_data_type_align_size
     +  string:name

     +  uint:preferred_vector_width_char
     +  uint:preferred_vector_width_short
     +  uint:preferred_vector_width_int
     +  uint:preferred_vector_width_long
     +  uint:preferred_vector_width_float
     +  uint:preferred_vector_width_double

     +  string:profile
     +  size_t:profiling_timer_resolution
     +  ulong:queue_properties
     +  ulong:single_fp_config // FPConfig
     +  ulong:Type:type

     +  string:vendor
     +  uint:vendor_id
     +  string:version // _version
     +  string:!driver_version
     + ---
     +/
    static private enum info_list =
    [
        "uint:address_bits",
        "uint:bool:available",
        "uint:bool:compiler_available",
        "ulong:double_fp_config", // FPConfig
        "uint:bool:endian_little",
        "uint:bool:error_correction_support",
        "ulong:execution_capabilities",
        "string:extensions",
        "ulong:global_mem_cache_size",
        "uint:MemCacheType:global_mem_cache_type",
        "uint:global_mem_cacheline_size",
        "ulong:global_mem_size",
        //"ulong:half_fp_config", // FPConfig, WTF? not work
        "uint:bool:image_support",
        "size_t:image2d_max_height",
        "size_t:image2d_max_width",
        "size_t:image3d_max_depth",
        "size_t:image3d_max_height",
        "size_t:image3d_max_width",
        "ulong:local_mem_size",
        "uint:local_mem_type",
        "uint:max_clock_frequency",
        "uint:max_compute_units",
        "uint:max_constant_args",
        "ulong:max_constant_buffer_size",
        "ulong:max_mem_alloc_size",
        "size_t:max_parameter_size",
        "uint:max_read_image_args",
        "uint:max_samplers",
        "size_t:max_work_group_size",
        "uint:max_work_item_dimensions",
        "size_t[]:max_work_item_sizes",
        "uint:max_write_image_args",
        "uint:mem_base_addr_align",
        "uint:min_data_type_align_size",
        "string:name",

        "uint:preferred_vector_width_char",
        "uint:preferred_vector_width_short",
        "uint:preferred_vector_width_int",
        "uint:preferred_vector_width_long",
        "uint:preferred_vector_width_float",
        "uint:preferred_vector_width_double",

        "string:profile",
        "size_t:profiling_timer_resolution",
        "ulong:queue_properties",
        "ulong:single_fp_config", // FPConfig
        "ulong:Type:type",

        "string:vendor",
        "uint:vendor_id",
        "string:version",
        "string:!driver_version"
    ];

    mixin( infoMixin( "device", info_list ) );

protected:

    override void selfDestroy()
    {
        if( is_sub_device )
            checkCall!clRetainDevice( id );
    }
}
