module des.cl.glsimple;

import std.string;
import std.traits;

import des.gl.base;

import des.cl.base;
import des.cl.platform;
import des.cl.device;
import des.cl.context;
import des.cl.commandqueue;
import des.cl.memory;
import des.cl.program;
import des.cl.event;
import des.cl.glinterop;

import derelict.opengl3.gl3;

public import des.cl.kernel;
public import des.cl.glinterop.memory;

import des.math.linear;

/++ cl kernel declaration must have keyword "kernel" or "__kernel__" and
    name of kernel at one line +/
@property string[] staticLoadCLSource(string name)()
{
    auto src = import( name );
    string[] kernels;
    foreach( ln; src.splitLines )
    {
        auto cln = ln.strip;
        if( cln.startsWith("kernel") || cln.startsWith("__kernel__") )
        {
            auto kname = cln.split[2];
            kernels ~= kname.endsWith("(") ? kname[0..$-1] : kname;
        }
    }
    return src ~ kernels;
}


interface CLMemoryBuffer
{
    protected @property CLGLMemory clmem();
    protected @property void clmem( CLGLMemory );

    static @property string getCLMemProperty()
    {
        return `
            protected
            {
                CLGLMemory clglmemory;
                @property CLGLMemory clmem() { return clglmemory; }
                @property void clmem( CLGLMemory m )
                in{ assert( m !is null ); } body
                { clglmemory = m; }

                final void clInit() { CLGL.initBuffer( this ); }
            }
        `;
    }
}

class SimpleCLKernel
{
private:
    CLKernel kernel;

    this( CLKernel k )
    in{ assert( k !is null ); } body
    { kernel = k; }

public:

    void setArgs(Args...)( Args args )
    {
        foreach( i, arg; args )
            setArg( i, arg );
    }

    void setArg(T)( uint index, T arg )
    {
        static if( is( T : CLMemoryBuffer ) )
            kernel.setArg( index, (cast(CLMemoryBuffer)arg).clmem );
        else static if( isStaticVector!T )
            kernel.setArg( index, arg.data );
        else static if( isStaticMatrix!T )
            kernel.setArg( index, arg.data );
        else kernel.setArg( index, arg );
    }

    void exec( uint dim, size_t[] global_work_offset,
            size_t[] global_work_size, size_t[] local_work_size,
            CLEvent[] wait_list=[], CLEvent event=null )
    {
        kernel.exec( CLGL.singleton.cmdqueue, dim, global_work_offset,
                global_work_size, local_work_size, wait_list, event );
    }
}

final class CLGL
{
private:
    static CLGL clgl;

    CLCommandQueue cmdqueue;
    CLGLContext context;
    CLDevice[] devices;

    CLReference[] clrefs;

    CLMemoryBuffer[] acquire_list;

    this()
    {
        auto platform = CLPlatform.getAll()[0];
        devices = registerCLRef( CLDevice.getAll( platform ) );

        context = registerCLRef( new CLGLContext( platform ) );
        context.initializeFromType( CLDevice.Type.GPU );

        cmdqueue = registerCLRef( new CLCommandQueue( context, devices[0] ) );
    }

    static @property CLGL singleton()
    {
        if( clgl is null ) clgl = new CLGL();
        return clgl;
    }

    void acquireList( CLMemoryBuffer[] list... )
    {
        glFlush();
        glFinish();

        acquire_list = list;
        foreach( obj; list )
            obj.clmem.acquireFromGL( cmdqueue );
    }

    void releaseList()
    {
        foreach( obj; acquire_list )
            obj.clmem.releaseToGL( cmdqueue );
        acquire_list.length = 0;

        cmdqueue.flush();
    }

    void initMemoryBuffer(T)( T mb )
        if( is( T : CLMemoryBuffer ) && is( T : GLBuffer ) )
    {
        (cast(CLMemoryBuffer)mb).clmem = registerCLRef( CLGLMemory.createFromGLBuffer( context,
                                        CLMemory.Flags.READ_WRITE, mb ) );
    }

    SimpleCLKernel[string] buildProgramAndGetKernels( string src, string[] kernels )
    {
        auto program = registerCLRef( CLProgram.createWithSource( context, src ) );

        try program.build( devices, [ CLBuildOption.fastRelaxedMath ] );
        catch( CLException e )
        {
            import std.stdio;
            stderr.writeln( program.buildInfo()[0] );
            throw e;
        }

        SimpleCLKernel[string] ret;

        foreach( k; kernels )
        {
            auto clk = registerCLRef( new CLKernel( program, k ) );
            ret[k] = new SimpleCLKernel( clk );
        }

        return ret;
    }

public static
{

    void acquireFromGL( CLMemoryBuffer[] list... )
    { singleton.acquireList( list ); }

    SimpleCLKernel[string] build( string[] args... )
    in{ assert( args.length > 1 ); } body
    { return singleton.buildProgramAndGetKernels( args[0], args[1..$] ); }

    void releaseToGL() { singleton.releaseList(); }

    void initBuffer(T)( T mb )
        if( is( T : CLMemoryBuffer ) && is( T : GLBuffer ) )
    { singleton.initMemoryBuffer( mb ); }

    void systemDestroy()
    {
        singleton.destroyCLRefs();
        clgl = null;
    }
}

private:

    auto registerCLRef(T)( T[] objs ) if( is( T : CLReference ) )
    {
        foreach( obj; objs )
            clrefs ~= cast(CLReference)obj;
        return objs;
    }

    auto registerCLRef(T)( T obj ) if( is( T : CLReference ) )
    {
        clrefs ~= cast(CLReference)obj;
        return obj;
    }

    void destroyCLRefs()
    {
        foreach( obj; clrefs )
            obj.release();
    }
}
