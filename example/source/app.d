import std.random;

import std.stdio;
import std.datetime;
import std.typecons;
import std.algorithm;
import std.string;

import des.cl;
import des.cl.helpers;

enum string KERNEL_SOURCES = q{
#define GGI(a) get_global_id(a)
#define GGS(a) get_global_size(a)

kernel void sum( const global float2* a,
                 const global float2* b,
                 global float2* c,
                 const uint size )
{
    for( int i = GGI(0); i < size; i += GGS(0) )
        c[i] = a[i] + b[i];
}
};

struct vec2
{
    float[2] data;
    this( float x, float y ) { data[0] = x; data[1] = y; }

    vec2 opBinary(string op)( ref const(vec2) rhs ) const
    {
        mixin( format( `return vec2( data[0] %1$s rhs.data[0], data[1] %1$s rhs.data[1] );`, op ) );
    }
}

void printInfo( CLPlatform pl )
{
    write( getCLPlatformFullInfoString( pl, "% 9s : %s" ) ~ "\n\n" );
    foreach( i, dev; pl.devices )
    {
        writeln( "  device #", i );
        write( getCLDeviceFullInfoString( dev ) ~ "\n\n" );
    }
}

auto testPlatform( CLPlatform platform, vec2[] a_data, vec2[] b_data, vec2[] c_data )
{
    // create context for all platform devices
    auto ctx = new CLContext( platform );

    // create command queue for first device in list
    // with profiling for measuring execution time
    auto cq = ctx.newEMM!CLCommandQueue( ctx, ctx.devices[0],
            [CLCommandQueue.Properties.PROFILING] );

    // create and build program in context for all devices in context
    auto prog = ctx.buildProgram( KERNEL_SOURCES );

    auto size = a_data.length * vec2.sizeof;

    // aux object
    auto sum = new CLKernelCaller( prog["sum"], cq );

    // work group size
    sum.setWorkGroupSize([ 1024 ]);

    // create buffers, flags describe access from kernel
    auto a = CLMemory.createBuffer( ctx, [ CLMemory.Flag.READ_ONLY ], size );
    auto b = CLMemory.createBuffer( ctx, [ CLMemory.Flag.READ_ONLY ], size );
    auto c = CLMemory.createBuffer( ctx, [ CLMemory.Flag.WRITE_ONLY ], size );

    StopWatch sw;

    sw.start();

    a.write( cq, a_data );
    b.write( cq, b_data );

    sum.setArgs( a, b, c, cast(uint)a_data.length );

    // clEnqueueNDRangeKernel : run kernels
    sum.range();

    c.readTo( cq, c_data );

    sw.stop();

    ctx.destroy();

    return tuple( ( sum.exec_inst.end - sum.exec_inst.queued ) * 1e-9,
                   sw.peek().hnsecs * 1e-7 );
}

void testOCL( vec2[] a, vec2[] b, vec2[] c )
{
    loadCL();

    auto platforms = CLPlatform.getAll();

    foreach( pl; platforms )
    {
        printInfo( pl );
        auto tm = testPlatform( pl, a, b, c );
        writeln( "kernel exec time: ", tm[0] , " sec" );
        writeln( "full exec time: ", tm[1] , " sec" );
    }
}

void testCPU( vec2[] abuf, vec2[] bbuf, vec2[] cbuf )
{
    StopWatch sw;
    sw.start();

    foreach( a, b, ref c; lockstep(abuf,bbuf,cbuf) )
        c = a + b;

    sw.stop();
    writeln( "\ncpu exec time: ", sw.peek().hnsecs * 1e-7, " sec" );
}

void main()
{
    auto count = 16 * 1024 * 1024;

    auto a_data = new vec2[]( count );
    auto b_data = new vec2[]( count );
    auto c_data = new vec2[]( count );

    // fill source data

    foreach( i; 0 .. count )
    {
        a_data[i] = vec2( i, i*2 );
        b_data[i] = vec2( i, i*i );
    }

    testOCL( a_data, b_data, c_data );
    testCPU( a_data, b_data, c_data );

    auto size = count * vec2.sizeof;
    writeln( "\nbuffers size: ", size, " bytes (", size / (1024 * 1024.0f), "MiB)" );
}
