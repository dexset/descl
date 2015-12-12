module des.cl.helpers;

import des.cl;

/// full info about platform
string[2][] getCLPlatformFullInfo( CLPlatform pl )
{
    string[2][] ret = [
        ["platform" , pl.name],
        ["vendor"   , pl.vendor],
        ["profile"  , pl.profile],
        ["version"  , pl._version],
        ["ext"      , pl.extensions],
    ];
    return ret;
}

/// full info about platform as string
string getCLPlatformFullInfoString( CLPlatform pl, string fmt="", string sep="\n" )
{ return formatInfo( getCLPlatformFullInfo(pl), fmt, sep ); }

/// full info about device
string[2][] getCLDeviceFullInfo( CLDevice dev )
{
    string[2][] ret = [
        ["type - name"                    , format( "%s - %s", fmtFlags(dev.typeMask,[CLDevice.Type.ALL]), dev.name ) ],
        ["available"                      , format( "dev:%s compiler:%s linker:%s", dev.available, dev.compiler_available, dev.linker_available ) ],
        ["max_compute_units"              , format( "%s", dev.max_compute_units ) ],
        ["max_work_item_dimensions"       , format( "%s", dev.max_work_item_dimensions ) ],
        ["max_work_group_size"            , format( "%s", dev.max_work_group_size ) ],
        ["max_work_item_sizes"            , format( "%s", dev.max_work_item_sizes ) ],
        ["image_support"                  , format( "%s", dev.image_support ) ],
        ["max_read_image_args"            , format( "%s", dev.max_read_image_args ) ],
        ["max_write_image_args"           , format( "%s", dev.max_write_image_args ) ],
        ["max image2d size"               , format( "[%d, %d]", dev.image2d_max_width, dev.image2d_max_height ) ],
        ["max image3d size"               , format( "[%d, %d, %d]", dev.image3d_max_width, dev.image3d_max_height, dev.image3d_max_depth ) ],
        ["image_max_buffer_size"          , format( "%s px", dev.image_max_buffer_size ) ],
        ["image_max_array_size"           , format( "%s", dev.image_max_array_size ) ],
        ["address_bits"                   , format( "%s", dev.address_bits ) ],
        ["max_mem_alloc_size"             , fmtSize( dev.max_mem_alloc_size ) ],
        ["max_clock_frequency"            , format( "%s MHz (%.2e sec)", dev.max_clock_frequency, 1.0f / ( dev.max_clock_frequency * 1e6 ) ) ],
        ["max_parameter_size"             , fmtSize( dev.max_parameter_size ) ],
        ["max_samplers"                   , format( "%s", dev.max_samplers ) ],
        ["mem_base_addr_align"            , format( "%s bits", dev.mem_base_addr_align ) ],
        ["global_mem_cache_type"          , format( "%s", dev.global_mem_cache_type ) ],
        ["global_mem_cacheline_size"      , format( "%s", fmtSize( dev.global_mem_cacheline_size ) ) ],
        ["global_mem_cache_size"          , format( "%s", fmtSize( dev.global_mem_cache_size ) ) ],
        ["global_mem_size"                , format( "%s", fmtSize( dev.global_mem_size ) ) ],
        ["max_constant_buffer_size"       , format( "%s", fmtSize( dev.max_constant_buffer_size ) ) ],
        ["max_constant_args"              , format( "%s", dev.max_constant_args ) ],
        ["local_mem_type"                 , format( "%s", dev.local_mem_type ) ],
        ["local_mem_size"                 , format( "%s", fmtSize( dev.local_mem_size ) ) ],
        ["error_correction_support"       , format( "%s", dev.error_correction_support ) ],
        ["profiling_timer_resolution"     , format( "%s ns", dev.profiling_timer_resolution ) ],
        ["endian_little"                  , format( "%s", dev.endian_little ) ],
        ["preferred vector width"         , format( "char:%s short:%s int:%s long:%s half:%s float:%s double:%s",
                                                    dev.preferred_vector_width_char,
                                                    dev.preferred_vector_width_short,
                                                    dev.preferred_vector_width_int,
                                                    dev.preferred_vector_width_long,
                                                    dev.preferred_vector_width_half,
                                                    dev.preferred_vector_width_float,
                                                    dev.preferred_vector_width_double ) ],
        ["native vector width"            , format( "char:%s short:%s int:%s long:%s half:%s float:%s double:%s",
                                                    dev.native_vector_width_char,
                                                    dev.native_vector_width_short,
                                                    dev.native_vector_width_int,
                                                    dev.native_vector_width_long,
                                                    dev.native_vector_width_half,
                                                    dev.native_vector_width_float,
                                                    dev.native_vector_width_double ) ],
        ["execution_capabilities"         , format( "%s", fmtFlags!(CLDevice.ExecCapabilities)(dev.execution_capabilities) ) ],
        ["queue_properties"               , format( "%s", fmtFlags!(CLCommandQueue.Properties)(dev.queue_properties) ) ],
        ["vendor"                         , format( "%s (id:%s)", dev.vendor, dev.vendor_id ) ],
        ["driver_version"                 , format( "%s", dev.driver_version ) ],
        ["profile"                        , format( "%s", dev.profile ) ],
        ["version"                        , format( "%s", dev._version ) ],
        ["extensions"                     , format( "%s", dev.extensions ) ],
        ["built_in_kernels"               , format( "%s", dev.built_in_kernels ) ],
        ["opencl_c_version"               , format( "%s", dev.opencl_c_version ) ],
        //["platform"                       , format( "%s", dev.platform ) ],
        ["single_fp_config"               , format( "%s", fmtFlags!(CLDevice.FPConfig)(dev.single_fp_config) ) ],
        ["double_fp_config"               , format( "%s", fmtFlags!(CLDevice.FPConfig)(dev.double_fp_config) ) ],
        ["host_unified_memory"            , format( "%s", dev.host_unified_memory ) ],
        ["is root device"                 , format( "%s", !dev.parent_device ) ],
        ["partition_max_sub_devices"      , format( "%s", dev.partition_max_sub_devices ) ],
        ["partition_properties"           , format( "%s", dev.partition_properties ) ],
        ["partition_affinity_domain"      , format( "%s", dev.partition_affinity_domain ) ],
        ["partition_type"                 , format( "%s", dev.partition_type ) ],
        ["reference_count"                , format( "%s", dev.refcount ) ],
        ["preferred_interop_user_sync"    , format( "%s", dev.preferred_interop_user_sync ) ],
        ["printf_buffer_size"             , fmtSize( dev.printf_buffer_size ) ],
    ];

    return ret;
}

/// full info about device as string
string getCLDeviceFullInfoString( CLDevice dev, string fmt="", string sep="\n" )
{ return formatInfo( getCLDeviceFullInfo(dev), fmt, sep ); }

string formatInfo( string[2][] info, string fmt="", string sep="\n" )
{
    string[] ret;

    if( fmt == "" ) fmt = " %30 s : %s";

    foreach( item; info )
        ret ~= format( fmt, item[0], item[1] );

    return ret.join(sep);
}

import std.traits;

string fmtSize( ulong bytes )
{
    string ret = format( "%d bytes", bytes );
    if( bytes < 1024 ) return ret;

    enum sizes = [ "", "Ki", "Mi", "Gi", "Ti", "Pi" ];
    float size = bytes;
    ubyte k;
    do { k++; size /= 1024; } while( size > 1024 );
    return format( "%.2f %s (%s)", size, sizes[k]~"b", ret );
}

string fmtFlags(T)( ulong mask, T[] without=[] )
{ return parseFlags!T(mask,without).map!(a=>format("%s",a)).array.join("|"); }
