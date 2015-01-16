module des.cl.helpers;

import des.cl;

/// full info about platform as AA
string[string] getCLPlatformFullInfoAA( CLPlatform pl )
{
    string[string] ret;
    ret["platform"] = pl.name;
    ret["vendor"] = pl.vendor;
    ret["profile"] = pl.profile;
    ret["version"] = pl._version;
    ret["ext"] = pl.extensions;
    return ret;
}

/// full info about platform as string
string getCLPlatformFullInfoString( CLPlatform pl, string fmt="", string sep="\n" )
{
    enum order = [ "platform", "vendor", "profile", "version", "ext", ];
    return formatInfo( getCLPlatformFullInfoAA(pl), order, fmt, sep );
}

/// full info about device as AA
string[string] getCLDeviceFullInfoAA( CLDevice dev )
{
    string[string] ret;
    ret["name"                      ] = format( "%s", dev.name );
    ret["type"                      ] = format( "%s", dev.type );
    ret["available"                 ] = format( "%s", dev.available );
    ret["compiler_available"        ] = format( "%s", dev.compiler_available );
    ret["endian_little"             ] = format( "%s", dev.endian_little );
    ret["profile"                   ] = format( "%s", dev.profile );
    ret["vendor"                    ] = format( "%s", dev.vendor );
    ret["vendor_id"                 ] = format( "%s", dev.vendor_id );
    ret["version"                   ] = format( "%s", dev._version );
    ret["address_bits"              ] = format( "%s", dev.address_bits );
    ret["double_fp_config"          ] = format( "%s", getMaskString!(CLDevice.FPConfig)(dev.double_fp_config) );
    ret["single_fp_config"          ] = format( "%s", getMaskString!(CLDevice.FPConfig)(dev.single_fp_config) );
    ret["error_correction_support"  ] = format( "%s", dev.error_correction_support );
    ret["execution_capabilities"    ] = format( "%s", getMaskString!(CLDevice.ExecCapabilities)(dev.execution_capabilities) );
    ret["extensions"                ] = format( "%s", dev.extensions );
    ret["global_mem_cache_size"     ] = fmtsize( dev.global_mem_cache_size );
    ret["global_mem_cache_type"     ] = format( "%s", getMaskString!(CLDevice.MemCacheType)(dev.global_mem_cache_type) );
    ret["global_mem_cacheline_size" ] = fmtsize( dev.global_mem_cacheline_size );
    ret["global_mem_size"           ] = fmtsize( dev.global_mem_size );
    ret["local_mem_size"            ] = fmtsize( dev.local_mem_size );
    ret["local_mem_type"            ] = format( "%s", getMaskString!(CLDevice.MemCacheType)(dev.local_mem_type) );
    ret["image_support"             ] = format( "%s", dev.image_support );
    ret["image2d_max_height"        ] = format( "%s", dev.image2d_max_height );
    ret["image2d_max_width"         ] = format( "%s", dev.image2d_max_width );
    ret["image3d_max_depth"         ] = format( "%s", dev.image3d_max_depth );
    ret["image3d_max_height"        ] = format( "%s", dev.image3d_max_height );
    ret["image3d_max_width"         ] = format( "%s", dev.image3d_max_width );
    ret["max_clock_frequency"       ] = format( "%s", dev.max_clock_frequency );
    ret["max_compute_units"         ] = format( "%s", dev.max_compute_units );
    ret["max_constant_args"         ] = format( "%s", dev.max_constant_args );
    ret["max_constant_buffer_size"  ] = fmtsize( dev.max_constant_buffer_size );
    ret["max_mem_alloc_size"        ] = fmtsize( dev.max_mem_alloc_size );
    ret["max_parameter_size"        ] = fmtsize( dev.max_parameter_size );
    ret["max_read_image_args"       ] = format( "%s", dev.max_read_image_args );
    ret["max_samplers"              ] = format( "%s", dev.max_samplers );
    ret["max_work_group_size"       ] = format( "%s", dev.max_work_group_size );
    ret["max_work_item_dimensions"  ] = format( "%s", dev.max_work_item_dimensions );
    ret["max_work_item_sizes"       ] = format( "%s", dev.max_work_item_sizes[0 .. dev.max_work_item_dimensions] );
    ret["max_write_image_args"      ] = format( "%s", dev.max_write_image_args );
    ret["mem_base_addr_align"       ] = format( "%s", dev.mem_base_addr_align );
    ret["min_data_type_align_size"  ] = fmtsize( dev.min_data_type_align_size );
    ret["preferred_vector_width_char"] = format( "%s", dev.preferred_vector_width_char );
    ret["preferred_vector_width_short"] = format( "%s", dev.preferred_vector_width_short );
    ret["preferred_vector_width_int"] = format( "%s", dev.preferred_vector_width_int );
    ret["preferred_vector_width_long"] = format( "%s", dev.preferred_vector_width_long );
    ret["preferred_vector_width_float"] = format( "%s", dev.preferred_vector_width_float );
    ret["preferred_vector_width_double"] = format( "%s", dev.preferred_vector_width_double );
    ret["profiling_timer_resolution"] = format( "%s nsec", dev.profiling_timer_resolution );
    ret["queue_properties"          ] = format( "%s", getMaskString!(CLCommandQueue.Properties)(dev.queue_properties) );
    ret["driver_version"            ] = format( "%s", dev.driver_version );

    return ret;
}

string fmtsize( size_t bytes )
{
    string ret = format( "%d bytes", bytes );
    if( bytes < 1024 ) return ret;

    enum sizes = [ "", "K", "M", "G", "T", "P" ];
    float size = bytes;
    ubyte k;
    do { k++; size /= 1024; } while( size > 1024 );
    return format( "%.2f %s (%s)", size, sizes[k]~"b", ret );
}

/// full info about device as string
string getCLDeviceFullInfoString( CLDevice dev, string fmt="", string sep="\n" )
{
    enum infos =
    [
    "name", "type", "available", "compiler_available",
    "endian_little", "profile", "vendor", "vendor_id",
    "version", "address_bits", "double_fp_config",
    "single_fp_config", "error_correction_support",
    "execution_capabilities", "extensions",
    "global_mem_cache_size", "global_mem_cache_type",
    "global_mem_cacheline_size", "global_mem_size",
    "local_mem_size", "local_mem_type", "image_support",
    "image2d_max_height", "image2d_max_width",
    "image3d_max_depth", "image3d_max_height",
    "image3d_max_width", "max_clock_frequency",
    "max_compute_units", "max_constant_args",
    "max_constant_buffer_size", "max_mem_alloc_size",
    "max_parameter_size", "max_read_image_args",
    "max_samplers", "max_work_group_size",
    "max_work_item_dimensions", "max_work_item_sizes",
    "max_write_image_args", "mem_base_addr_align",
    "min_data_type_align_size", "preferred_vector_width_char",
    "preferred_vector_width_short", "preferred_vector_width_int",
    "preferred_vector_width_long", "preferred_vector_width_float",
    "preferred_vector_width_double", "profiling_timer_resolution",
    "queue_properties", "driver_version"
    ];

    return formatInfo( getCLDeviceFullInfoAA(dev), infos, fmt, sep );
}

string formatInfo( string[string] aa, string[] order, string fmt="", string sep="\n" )
{
    string[] ret;

    if( fmt == "" ) fmt = " %30 s : %s";

    foreach( n; order )
        ret ~= format( fmt, n, aa[n] );

    return ret.join(sep);
}

import std.traits;

string getMaskString(T)( ulong mask )
{
    string[] ret;
    foreach( v; [EnumMembers!T] )
        if( mask & cast(ulong)v )
            ret ~= format( "%s", v );
    return ret.join(" | ");
}
