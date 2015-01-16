module des.cl.event;

import des.cl.base;
import des.cl.context;

///
class CLEvent : CLResource
{
package:
    ///
    this( cl_event ev_id )
    {
        id = ev_id;
        updateInfo();
    }

public:
    ///
    cl_event id;

    ///
    this(){}

    ///
    enum Type
    {
        NDRANGE_KERNEL       = CL_COMMAND_NDRANGE_KERNEL,      /// `CL_COMMAND_NDRANGE_KERNEL`
        TASK                 = CL_COMMAND_TASK,                /// `CL_COMMAND_TASK`
        NATIVE_KERNEL        = CL_COMMAND_NATIVE_KERNEL,       /// `CL_COMMAND_NATIVE_KERNEL`
        READ_BUFFER          = CL_COMMAND_READ_BUFFER,         /// `CL_COMMAND_READ_BUFFER`
        WRITE_BUFFER         = CL_COMMAND_WRITE_BUFFER,        /// `CL_COMMAND_WRITE_BUFFER`
        COPY_BUFFER          = CL_COMMAND_COPY_BUFFER,         /// `CL_COMMAND_COPY_BUFFER`
        READ_IMAGE           = CL_COMMAND_READ_IMAGE,          /// `CL_COMMAND_READ_IMAGE`
        WRITE_IMAGE          = CL_COMMAND_WRITE_IMAGE,         /// `CL_COMMAND_WRITE_IMAGE`
        COPY_IMAGE           = CL_COMMAND_COPY_IMAGE,          /// `CL_COMMAND_COPY_IMAGE`
        COPY_BUFFER_TO_IMAGE = CL_COMMAND_COPY_BUFFER_TO_IMAGE,/// `CL_COMMAND_COPY_BUFFER_TO_IMAGE`
        COPY_IMAGE_TO_BUFFER = CL_COMMAND_COPY_IMAGE_TO_BUFFER,/// `CL_COMMAND_COPY_IMAGE_TO_BUFFER`
        MAP_BUFFER           = CL_COMMAND_MAP_BUFFER,          /// `CL_COMMAND_MAP_BUFFER`
        MAP_IMAGE            = CL_COMMAND_MAP_IMAGE,           /// `CL_COMMAND_MAP_IMAGE`
        UNMAP_MEM_OBJECT     = CL_COMMAND_UNMAP_MEM_OBJECT,    /// `CL_COMMAND_UNMAP_MEM_OBJECT`
        MARKER               = CL_COMMAND_MARKER,              /// `CL_COMMAND_MARKER`
        ACQUIRE_GL_OBJECTS   = CL_COMMAND_ACQUIRE_GL_OBJECTS,  /// `CL_COMMAND_ACQUIRE_GL_OBJECTS`
        RELEASE_GL_OBJECTS   = CL_COMMAND_RELEASE_GL_OBJECTS   /// `CL_COMMAND_RELEASE_GL_OBJECTS`
    }

    ///
    enum Status
    {
        QUEUED    = CL_QUEUED,   /// `CL_QUEUED`
        SUBMITTED = CL_SUBMITTED,/// `CL_SUBMITTED`
        RUNNING   = CL_RUNNING,  /// `CL_RUNNING`
        COMPLETE  = CL_COMPLETE  /// `CL_COMPLETE`
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
     +  cl_command_type:Type:command_type
     +  cl_int:Status:command_execution_status
     + ---
     +/
    static private enum info_list =
    [
        "cl_command_type:Type:command_type",
        "cl_int:Status:command_execution_status"
    ];

    mixin( infoMixin( "event", info_list ) );

    /++ generate profile properties
     +
     + Rules:
     + ---
     +      type:param_name
     +      cl_type:dlang_type:param_name
     + ---
     + List:
     + ---
     +  ulong:queued
     +  ulong:submit
     +  ulong:start
     +  ulong:end
     + ---
     +/
    static private enum prof_list =
    [
        "ulong:queued",
        "ulong:submit",
        "ulong:start",
        "ulong:end"
    ];

    mixin( immediatelyInfoMixin( "event_profiling", "profiling_command", prof_list ) );

    ///
    bool isValid() @property const { return id != null; }

    /// `clRetainEvent`
    void reset() { if( isValid ) checkCall!clRetainEvent(id); }

protected:
    override void selfDestroy() { reset(); }
}

///
class CLUserEvent : CLEvent
{
    ///
    this( CLContext context ) { id = checkCode!clCreateUserEvent( context.id ); }
    ///
    void setStatus( Status stat ) { checkCall!clSetUserEventStatus( id, stat ); }
}
