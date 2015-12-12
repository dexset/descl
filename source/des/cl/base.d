/++ base classes, functions, public imports, 

    `static this` load DerelictCL with version 1.1
 +/
module des.cl.base;

public import derelict.opencl.cl;

package
{
    import std.string;
    import std.traits;
    import std.range;
    import std.algorithm;
    import std.array;
    import std.exception;

    import des.arch;
    import des.log;

    import des.cl.util;
    import des.cl.event;
}

///
extern(C)
void loadCL()
{
    if( !DerelictCL.isLoaded ) DerelictCL.load();
    DerelictCL.reload( CLVersion.CL12 );
}

///
class CLException : Exception
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow
    { super( msg, file, line ); }
}

///
class CLCallException : CLException
{
    ///
    string func;
    ///
    string[2][] args;
    ///
    CLError error;

    ///
    this( string func, string[2][] args, CLError error, string file=__FILE__, size_t line=__LINE__ ) @safe pure
    {
        this.func = func;
        this.args = args.dup;
        this.error = error;
        string msg = format( "'%s' fails with error %s", func, error );
        super( msg, file, line );
    }
}

///
class CLResource : ExternalMemoryManager { mixin EMM; }

//
enum CLError
{
    NONE                                      = CL_SUCCESS, ///
    DEVICE_NOT_FOUND                          = CL_DEVICE_NOT_FOUND, ///
    PLATFORM_NOT_FOUND                        = CL_PLATFORM_NOT_FOUND_KHR, ///
    DEVICE_NOT_AVAILABLE                      = CL_DEVICE_NOT_AVAILABLE, ///
    INVALID_PARTITION_COUNT                   = CL_INVALID_PARTITION_COUNT_EXT, ///
    INVALID_PARTITION_NAME                    = CL_INVALID_PARTITION_NAME_EXT, ///
    COMPILER_NOT_AVAILABLE                    = CL_COMPILER_NOT_AVAILABLE, ///
    MEM_OBJECT_ALLOCATION_FAILURE             = CL_MEM_OBJECT_ALLOCATION_FAILURE, ///
    OUT_OF_RESOURCES                          = CL_OUT_OF_RESOURCES, ///
    OUT_OF_HOST_MEMORY                        = CL_OUT_OF_HOST_MEMORY, ///
    PROFILING_INFO_NOT_AVAILABLE              = CL_PROFILING_INFO_NOT_AVAILABLE, ///
    MEM_COPY_OVERLAP                          = CL_MEM_COPY_OVERLAP, ///
    IMAGE_FORMAT_MISMATCH                     = CL_IMAGE_FORMAT_MISMATCH, ///
    IMAGE_FORMAT_NOT_SUPPORTED                = CL_IMAGE_FORMAT_NOT_SUPPORTED, ///
    BUILD_PROGRAM_FAILURE                     = CL_BUILD_PROGRAM_FAILURE, ///
    MAP_FAILURE                               = CL_MAP_FAILURE, ///
    MISALIGNED_SUB_BUFFER_OFFSET              = CL_MISALIGNED_SUB_BUFFER_OFFSET, ///
    EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST = CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST, ///
    COMPILE_PROGRAM_FAILURE                   = CL_COMPILE_PROGRAM_FAILURE, ///
    LINKER_NOT_AVAILABLE                      = CL_LINKER_NOT_AVAILABLE, ///
    LINK_PROGRAM_FAILURE                      = CL_LINK_PROGRAM_FAILURE, ///
    DEVICE_PARTITION_FAILED                   = CL_DEVICE_PARTITION_FAILED, ///
    KERNEL_ARG_INFO_NOT_AVAILABLE             = CL_KERNEL_ARG_INFO_NOT_AVAILABLE, ///
    INVALID_VALUE                             = CL_INVALID_VALUE, ///
    INVALID_DEVICE_TYPE                       = CL_INVALID_DEVICE_TYPE, ///
    INVALID_PLATFORM                          = CL_INVALID_PLATFORM, ///
    INVALID_DEVICE                            = CL_INVALID_DEVICE, ///
    INVALID_CONTEXT                           = CL_INVALID_CONTEXT, ///
    INVALID_QUEUE_PROPERTIES                  = CL_INVALID_QUEUE_PROPERTIES, ///
    INVALID_COMMAND_QUEUE                     = CL_INVALID_COMMAND_QUEUE, ///
    INVALID_HOST_PTR                          = CL_INVALID_HOST_PTR, ///
    INVALID_MEM_OBJECT                        = CL_INVALID_MEM_OBJECT, ///
    INVALID_IMAGE_FORMAT_DESCRIPTOR           = CL_INVALID_IMAGE_FORMAT_DESCRIPTOR, ///
    INVALID_IMAGE_SIZE                        = CL_INVALID_IMAGE_SIZE, ///
    INVALID_SAMPLER                           = CL_INVALID_SAMPLER, ///
    INVALID_BINARY                            = CL_INVALID_BINARY, ///
    INVALID_BUILD_OPTIONS                     = CL_INVALID_BUILD_OPTIONS, ///
    INVALID_PROGRAM                           = CL_INVALID_PROGRAM, ///
    INVALID_PROGRAM_EXECUTABLE                = CL_INVALID_PROGRAM_EXECUTABLE, ///
    INVALID_KERNEL_NAME                       = CL_INVALID_KERNEL_NAME, ///
    INVALID_KERNEL_DEFINITION                 = CL_INVALID_KERNEL_DEFINITION, ///
    INVALID_KERNEL                            = CL_INVALID_KERNEL, ///
    INVALID_ARG_INDEX                         = CL_INVALID_ARG_INDEX, ///
    INVALID_ARG_VALUE                         = CL_INVALID_ARG_VALUE, ///
    INVALID_ARG_SIZE                          = CL_INVALID_ARG_SIZE, ///
    INVALID_KERNEL_ARGS                       = CL_INVALID_KERNEL_ARGS, ///
    INVALID_WORK_DIMENSION                    = CL_INVALID_WORK_DIMENSION, ///
    INVALID_WORK_GROUP_SIZE                   = CL_INVALID_WORK_GROUP_SIZE, ///
    INVALID_WORK_ITEM_SIZE                    = CL_INVALID_WORK_ITEM_SIZE, ///
    INVALID_GLOBAL_OFFSET                     = CL_INVALID_GLOBAL_OFFSET, ///
    INVALID_EVENT_WAIT_LIST                   = CL_INVALID_EVENT_WAIT_LIST, ///
    INVALID_EVENT                             = CL_INVALID_EVENT, ///
    INVALID_OPERATION                         = CL_INVALID_OPERATION, ///
    INVALID_GL_OBJECT                         = CL_INVALID_GL_OBJECT, ///
    INVALID_BUFFER_SIZE                       = CL_INVALID_BUFFER_SIZE, ///
    INVALID_MIP_LEVEL                         = CL_INVALID_MIP_LEVEL, ///
    INVALID_GLOBAL_WORK_SIZE                  = CL_INVALID_GLOBAL_WORK_SIZE, ///
    INVALID_PROPERTY                          = CL_INVALID_PROPERTY, ///
    INVALID_IMAGE_DESCRIPTOR                  = CL_INVALID_IMAGE_DESCRIPTOR, ///
    INVALID_COMPILER_OPTIONS                  = CL_INVALID_COMPILER_OPTIONS, ///
    INVALID_LINKER_OPTIONS                    = CL_INVALID_LINKER_OPTIONS, ///
    INVALID_DEVICE_PARTITION_COUNT            = CL_INVALID_DEVICE_PARTITION_COUNT, ///
}

package
{
    ///
    auto getIDsPtr(T)( T[] list... ) pure
    { return map!(a=>a.id)(list).array.ptr; }

    ///
    auto buildFlags(T=uint)( T[] list... ) pure
    { return reduce!((a,b)=>a|=b)(T(0),list); }

    unittest
    {
        assert( buildFlags( 0b01, 0b10 ) == 0b11 );
        assert( buildFlags() == 0 );
    }

    ///
    auto parseFlags(T)( ulong mask, T[] without=[] )
    {
        T[] ret;
        foreach( v; [EnumMembers!T] )
        {
            if( without.canFind(v) ) continue;
            if( mask & cast(ulong)v )
                ret ~= v;
        }
        return ret;
    }

    unittest
    {
        enum TT
        {
            ONE = 1<<0,
            TWO = 1<<1,
            THR = 1<<2,
            FOU = 1<<3
        }

        auto mask = buildFlags( TT.ONE, TT.THR );
        auto tt = parseFlags!TT( mask );
        assert( tt == [ TT.ONE, TT.THR ] );
    }

    /// check error code and throw exception if it not `CL_SUCCESS`
    void checkError( int code, lazy string fnc, lazy string[2][] args, lazy string file=__FILE__, lazy size_t line=__LINE__ )
    {
        auto err = cast(CLError)code;
        if( err == CLError.NONE ) return;
        throw new CLCallException( fnc, args, err, file, line );
    }

    /++ check OpenCL `fnc` return value
     +  calls `fnc( args )`
     +/
    void checkCall(alias fnc, string file=__FILE__, size_t line=__LINE__, Args...)( Args args )
    { checkError( fnc( args ), (&fnc).stringof[2..$], argsToStringArray(args), file, line ); }

    /++ check OpenCL `fnc` return value
     +  easy wait_list and event passes
     +  see_also: `checkCall`
     +/
    void checkCallWL(alias fnc, string file=__FILE__, size_t line=__LINE__, Args...)( Args args )
    {
        static assert( is( Args[$-1] : CLEvent* ) );
        static assert( is( Args[$-2] : CLEvent[] ) );
        auto wl = args[$-2];
        auto ev = args[$-1];
        checkCall!(fnc,file,line)( args[0..$-2],
                cast(uint)wl.length, cast(cl_event*)wl.ptr, cast(cl_event*)ev );
    }

    /++ check error code after OpenCL `fnc` call
     + calls `fnc( args, &retcode )`
     + Returns:
     + result of `fnc` call
     +/
    auto checkCode(alias fnc, string file=__FILE__, size_t line=__LINE__, Args...)( Args args )
    {
        int retcode;
        debug
        {
            auto id = fnc( args, &retcode );
            checkError( retcode, (&fnc).stringof[2..$], argsToStringArray(args), file, line );
            return id;
        }
        else
        {
            scope(exit) checkError( retcode, (&fnc).stringof[2..$], argsToStringArray(args), file, line );
            return fnc( args, &retcode );
        }
    }

    /++ check error code after OpenCL `fnc` call
     +  easy wait_list and event passes
     +  see_also: `checkCode`
     +/
    auto checkCodeWL(alias fnc, string file=__FILE__, size_t line=__LINE__, Args...)( Args args )
    {
        static assert( is( Args[$-1] : CLEvent* ) );
        static assert( is( Args[$-2] : CLEvent[] ) );
        auto wl = args[$-2];
        auto ev = args[$-1];
        return checkCode!(fnc,file,line)( args[0..$-2],
                cast(uint)wl.length, cast(cl_event*)wl.ptr, cast(cl_event*)ev );
    }

    string[2][] argsToStringArray(Args...)( Args args )
    {
        static if( Args.length > 1 )
            return argsToStringArray( args[0..$/2] ) ~ argsToStringArray( args[$/2..$] );
        else
        {
            enum tname = Args[0].stringof;
            static if( isIntegral!(Args[0]) )
                return [ [ tname, format( "%1$d (0x%1$x)", args[0] ) ] ];
            else
                return [ [ tname, format( "%s", args[0] ) ] ];
        }
    }
}
