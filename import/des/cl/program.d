module des.cl.program;

import des.cl.base;
import des.cl.device;
import des.cl.context;
import des.cl.kernel;

import des.util.string;

///
class CLProgram : CLResource
{
protected:

    ///
    this( cl_program p_id, string source )
    {
        this.id = p_id;
        this.source = source;
    }

    ///
    CLDevice[] last_build_devices;
    ///
    string source;

public:
    ///
    cl_program id;

    ///
    CLKernel[string] kernel;

    ///
    static CLProgram createWithSource( CLContext context, string source )
    {
        char[] str = source.dup;
        char* buf = str.ptr;
        auto id = checkCode!clCreateProgramWithSource( context.id, 1,
                     &buf, [source.length].ptr );

        return new CLProgram( id, source );
    }

    ///
    BuildInfo[] build( CLDevice[] devices, CLBuildOption[] options=[] )
    {
        last_build_devices = devices.dup;
        int retcode = clBuildProgram( id,
                cast(uint)devices.length,
                amap!(a=>a.id)(devices).ptr,
                getOptionsStringz( options ),
                null, null /+ callback and userdata for callback +/ );

        if( retcode != CL_SUCCESS )
        {
            log_error( "\n%s", buildInfo() );

            throw new CLException( format( "'%s' return error code %d",
                        "clBuildProgram", retcode) );
        }

        auto kernel_names = parseKernelNames( source );
        kernel.destroy();
        foreach( kn; kernel_names )
            kernel[kn] = newEMM!CLKernel( this, kn );
        log_info( "finded kernels: %(%s, %)", kernel.keys );

        return buildInfo();
    }

    ///
    enum BuildStatus
    {
        NONE        = CL_BUILD_NONE,       /// `CL_BUILD_NONE`
        ERROR       = CL_BUILD_ERROR,      /// `CL_BUILD_ERROR`
        SUCCESS     = CL_BUILD_SUCCESS,    /// `CL_BUILD_SUCCESS`
        IN_PROGRESS = CL_BUILD_IN_PROGRESS /// `CL_BUILD_IN_PROGRESS`
    }

    ///
    static struct BuildInfo
    {
        ///
        CLDevice device;
        ///
        BuildStatus status;
        ///
        string log;

        ///
        string toString() { return format( "%s for %s:\n%s", status, device.name, log ); }
    }

    ///
    BuildInfo[] buildInfo()
    {
        BuildInfo[] ret;
        foreach( dev; last_build_devices )
            ret ~= BuildInfo( dev,
                    buildStatus(dev), 
                    buildLog( dev ) );
        return ret;
    }

protected:

    /++ cl kernel declaration must starts with keyword
        "kernel" or "__kernel__" and must have
        name of kernel at same line +/
    string[] parseKernelNames( string src )
    {
        string[] kn;
        foreach( ln; src.splitLines )
        {
            auto cln = ln.strip;
            if( cln.startsWith("kernel") || cln.startsWith("__kernel__") )
            {
                auto kname = cln.split[2];
                kn ~= kname.endsWith("(") ? kname[0..$-1] : kname;
            }
        }
        return kn;
    }

    override void selfDestroy() { checkCall!clRetainProgram(id); }

    ///
    auto getOptionsStringz( CLBuildOption[] options )
    {
        if( options.length == 0 ) return null;
        auto opt_str = amap!(a=>a.toString)(options).join(" ");
        log_info( opt_str );
        return opt_str.toStringz;
    }

    ///
    BuildStatus buildStatus( CLDevice device )
    {
        cl_build_status val;
        size_t len;
        checkCall!clGetProgramBuildInfo( id, device.id, 
                CL_PROGRAM_BUILD_STATUS, cl_build_status.sizeof, &val, &len );
        return cast(BuildStatus)val;
    }

    ///
    string buildLog( CLDevice device )
    {
        size_t len;
        checkCall!clGetProgramBuildInfo( id, device.id, 
                CL_PROGRAM_BUILD_LOG, 0, null, &len );
        auto val = new char[](len);
        checkCall!clGetProgramBuildInfo( id, device.id, 
                CL_PROGRAM_BUILD_LOG, val.length, val.ptr, &len );
        return val.idup;
    }
}

///
interface CLBuildOption
{
    ///
    string toString();

    static
    {
        ///
        CLBuildOption define( string name, string val=null )
        {
            return new class CLBuildOption
            { 
                override string toString()
                { return format( "-D %s%s", name, (val?"="~val:"") ); }
            };
        }

        ///
        CLBuildOption dir( string d )
        {
            return new class CLBuildOption
            { override string toString() { return format( "-I %s", d ); } };
        }

        ///
        @property CLBuildOption inhibitAllWarningMessages()
        {
            return new class CLBuildOption
            { override string toString() { return "-w"; } };
        }

        ///
        @property CLBuildOption makeAllWarningsIntoErrors()
        {
            return new class CLBuildOption
            { override string toString() { return "-Werror"; } };
        }

        private
        {
            enum string[] simple_cl_options =
            [
                "single-precision-constant",
                "denorms-are-zero",
                "opt-disable",
                "strict-aliasing",
                "mad-enable",
                "no-signed-zeros",
                "unsafe-math-optimizations",
                "finite-math-only",
                "fast-relaxed-math"
            ];

            private string simpleCLOptionsListFunctionsString( in string[] list )
            { return amap!(a=>simpleCLOptionFunctionString(a))(list).join("\n"); }

            string simpleCLOptionFunctionString( string opt )
            {
                return format(`
            static @property CLBuildOption %s()
            {
                return new class CLBuildOption
                { override string toString() { return "-cl-%s"; } };
            }`, toCamelCaseBySep(opt,"-",false), opt );
            }
        }

        mixin( simpleCLOptionsListFunctionsString( simple_cl_options ) );
    }
}
