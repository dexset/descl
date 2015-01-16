import std.random;

import des.math.linear;

import des.cl;
import des.cl.helpers;

import std.stdio;

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

void printInfo( CLContext ctx )
{
    write( getCLPlatformFullInfoString( ctx.platform, "% 9s : %s" ) ~ "\n\n" );
    foreach( i, dev; ctx.devices )
    {
        writeln( "  device #", i );
        write( getCLDeviceFullInfoString( dev ) ~ "\n\n" );
    }
}

void main()
{
    // create OpenCL context with platform #0 and GPUs
    auto ctx = new CLContext( 0, CLDevice.Type.GPU );

    printInfo( ctx );

    auto cmdqueue = new CLCommandQueue( ctx, 0 );

    auto program = CLProgram.createWithSource( ctx, KERNEL_SOURCES );
    // build program for devices from ctx
    program.build();

    // fill source data

    uint cnt = 400;
    uint size = cast(uint)( vec2.sizeof * cnt );

    auto a_data = new vec2[]( cnt );
    auto b_data = new vec2[]( cnt );

    foreach( i; 0 .. cnt )
    {
        a_data[i] = vec2( i, i*2 );
        b_data[i] = vec2( i, i*i );
    }

    // create buffers

    auto a = CLMemory.createBuffer( ctx, [ CLMemory.Flag.READ_WRITE ], size );
    a.write( cmdqueue, a_data );

    auto b = CLMemory.createBuffer( ctx, [ CLMemory.Flag.READ_WRITE ], size );
    b.write( cmdqueue, b_data );

    auto c = CLMemory.createBuffer( ctx, [ CLMemory.Flag.READ_WRITE ], size );

    // set default command queue
    program.kernel["sum"].setQueue( cmdqueue );

    // call kernel with grid size [128], local grid [32] and args
    program.kernel["sum"]( [128], [32], a, b, c, cnt );

    // read from buffer
    auto c_data = cast(vec2[])( c.read( cmdqueue, size ) );

    writeln( c_data );

    program.destroy();
    cmdqueue.destroy();
    ctx.destroy();
}
