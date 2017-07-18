/*!
 * OpenHMD - Free and Open Source API and drivers for immersive technology.
 * Copyright (C) 2013 Fredrik Hultin.
 * Copyright (C) 2013 Jakob Bornecrantz.
 * Distributed under the Boost 1.0 licence, see src/charge/license.volt for full text.
 */
module lib.ohmd;


/*!
 * \file openhmd.h
 * Main header for OpenHMD public API.
 **/

/*! Maximum length of a string, including termination, in OpenHMD. */
enum size_t OHMD_STR_SIZE = 256;

/*! Return status codes, used for all functions that can return an error. */
enum ohmd_status {
	OK = 0,
	UNKNOWN_ERROR = -1,
	INVALID_PARAMETER = -2,
	UNSUPPORTED = -3,
	INVALID_OPERATION = -4,

	/*! USER_RESERVED and below can be used for user purposes, such as errors within ohmd wrappers, etc. */
	USER_RESERVED = -16384,
}

/*! A collection of string value information types, used for getting information with ohmd_list_gets(). */
enum ohmd_string_value {
	VENDOR    = 0,
	PRODUCT   = 1,
	PATH      = 2,
}

/*! A collection of string descriptions, used for getting strings with ohmd_gets(). */
enum ohmd_string_description {
	GLSL_DISTORTION_VERT_SRC = 0,
	GLSL_DISTORTION_FRAG_SRC = 1,
}

/*! A collection of float value information types, used for getting and setting information with
    ohmd_device_getf() and ohmd_device_setf(). */
enum ohmd_float_value {
	/*! float[4] (get): Absolute rotation of the device, in space, as a quaternion (x, y, z, w). */
	ROTATION_QUAT                    =  1,

	/*! float[16] (get): A "ready to use" OpenGL style 4x4 matrix with a modelview matrix for the
	    left eye of the HMD. */
	LEFT_EYE_GL_MODELVIEW_MATRIX     =  2,
	/*! float[16] (get): A "ready to use" OpenGL style 4x4 matrix with a modelview matrix for the
	    right eye of the HMD. */
	RIGHT_EYE_GL_MODELVIEW_MATRIX    =  3,

	/*! float[16] (get): A "ready to use" OpenGL style 4x4 matrix with a projection matrix for the
	    left eye of the HMD. */
	LEFT_EYE_GL_PROJECTION_MATRIX    =  4,
	/*! float[16] (get): A "ready to use" OpenGL style 4x4 matrix with a projection matrix for the
	    right eye of the HMD. */
	RIGHT_EYE_GL_PROJECTION_MATRIX   =  5,

	/*! float[3] (get): A 3-D vector representing the absolute position of the device, in space. */
	POSITION_VECTOR                  =  6,

	/*! float[1] (get): Physical width of the device screen in metres. */
	SCREEN_HORIZONTAL_SIZE           =  7,
	/*! float[1] (get): Physical height of the device screen in metres. */
	SCREEN_VERTICAL_SIZE             =  8,

	/*! float[1] (get): Physical separation of the device lenses in metres. */
	LENS_HORIZONTAL_SEPARATION       =  9,
	/*! float[1] (get): Physical vertical position of the lenses in metres. */
	LENS_VERTICAL_POSITION           = 10,

	/*! float[1] (get): Physical field of view for the left eye in degrees. */
	LEFT_EYE_FOV                     = 11,
	/*! float[1] (get): Physical display aspect ratio for the left eye screen. */
	LEFT_EYE_ASPECT_RATIO            = 12,
	/*! float[1] (get): Physical field of view for the left right in degrees. */
	RIGHT_EYE_FOV                    = 13,
	/*! float[1] (get): Physical display aspect ratio for the right eye screen. */
	RIGHT_EYE_ASPECT_RATIO           = 14,

	/*! float[1] (get, set): Physical interpupillary distance of the user in metres. */
	EYE_IPD                          = 15,

	/*! float[1] (get, set): Z-far value for the projection matrix calculations (i.e. drawing distance). */
	PROJECTION_ZFAR                  = 16,
	/*! float[1] (get, set): Z-near value for the projection matrix calculations (i.e. close clipping distance). */
	PROJECTION_ZNEAR                 = 17,

	/*! float[6] (get): Device specific distortion value. */
	DISTORTION_K                     = 18,

	/*!
	 * float[10] (set): Perform sensor fusion on values from external sensors.
	 *
	 * Values are: dt (time since last update in seconds) X, Y, Z gyro, X, Y, Z accelerometer and X, Y, Z magnetometer.
	 **/
	EXTERNAL_SENSOR_FUSION           = 19,

	/*! float[4] (get): Universal shader distortion coefficients (PanoTools model <a,b,c,d>. */
	UNIVERSAL_DISTORTION_K           = 20,

	/*! float[3] (get): Universal shader aberration coefficients (post warp scaling <r,g,b>. */
	UNIVERSAL_ABERRATION_K           = 21,

}

/*! A collection of int value information types used for getting information with ohmd_device_geti(). */
enum ohmd_int_value {
	/*! int[1] (get): Physical horizontal resolution of the device screen. */
	SCREEN_HORIZONTAL_RESOLUTION     =  0,
	/*! int[1] (get): Physical vertical resolution of the device screen. */
	SCREEN_VERTICAL_RESOLUTION       =  1,

	/*! int[1] (get): Get number of events waiting in digital input event queue. */
	BUTTON_EVENT_COUNT               =  2,
	/*! int[1] (get): Get if the there was an overflow in the event queue causing events to be dropped. */
	BUTTON_EVENT_OVERFLOW            =  3,
	/*! int[1] (get): Get the number of physical digital input buttons on the device. */
	BUTTON_COUNT                     =  4,
	/*! int[2] (get): Performs an event pop action. Format: [button_index, button_state], where button_state is either OHMD_BUTTON_DOWN or OHMD_BUTTON_UP */
	BUTTON_POP_EVENT                 =  5,
}

/*! A collection of data information types used for setting information with ohmd_set_data(). */
enum ohmd_data_value {
	/*! void* (set): Set void* data for use in the internal drivers. */
	DRIVER_DATA		= 0,
	/*!
	 * ohmd_device_properties* (set):
	 * Set the device properties based on the ohmd_device_properties struct for use in the internal drivers.
	 *
	 * This can be used to fill in information about the device internally, such as Android, or for setting profiles.
	 **/
	DRIVER_PROPERTIES	= 1,
}

enum ohmd_int_settings {
	/*! int[1] (set, default: 1): Set this to 0 to prevent OpenHMD from creating background threads to do automatic device ticking.
	    Call ohmd_update(); must be called frequently, at least 10 times per second, if the background threads are disabled. */
	IDS_AUTOMATIC_UPDATE = 0,
}

/*! Button states for digital input events. */
enum ohmd_button_state {
	/*! Button was pressed. */
	BUTTON_DOWN = 0,
	/*! Button was released. */
	BUTTON_UP   = 1
}

/*! An opaque pointer to a context structure. */
struct ohmd_context
{
	fn destroy()
	{ ohmd_ctx_destroy(&this); }
	fn probe() int
	{ return ohmd_ctx_probe(&this); }
	fn update()
	{ ohmd_ctx_update(&this); }
	fn list_gets(index: int, type: ohmd_string_value) const(char)*
	{ return ohmd_list_gets(&this, index, type); }
	fn list_open_device(index: int) ohmd_device*
	{ return ohmd_list_open_device(&this, index); }
	fn list_open_device_s(index: int, settings: ohmd_device_settings*) ohmd_device*
	{ return ohmd_list_open_device_s(&this, index, settings); }
}

/*! An opaque pointer to a structure representing a device, such as an HMD. */
struct ohmd_device
{
	fn close()
	{ ohmd_close_device(&this); }
	fn get_rot(ref vec: f32[4]) i32
	{ return ohmd_device_getf(&this, ohmd_float_value.ROTATION_QUAT, &vec[0]); }
	fn get_pos(ref vec: f32[3]) i32
	{ return ohmd_device_getf(&this, ohmd_float_value.POSITION_VECTOR, &vec[0]); }
	fn getf(type: ohmd_float_value, _out: float*) i32
	{ return ohmd_device_getf(&this, type, _out); }
	fn setf(type: ohmd_float_value, _in: const(float)*) i32
	{ return ohmd_device_setf(&this, type, _in); }
	fn geti(type: ohmd_float_value, _out: int*) i32
	{ return ohmd_device_geti(&this, type, _out); }
	fn seti(type: ohmd_float_value, _in: const(int)*) i32
	{ return ohmd_device_seti(&this, type, _in); }
}

/*! An opaque pointer to a structure representing arguments for a device. */
struct ohmd_device_settings {}


extern(C) @loadDynamic:

/*!
 * Create an OpenHMD context.
 *
 * @return a pointer to an allocated ohmd_context on success or NULL if it fails.
 **/
fn ohmd_ctx_create() ohmd_context*;

/*!
 * Destroy an OpenHMD context.
 *
 * ohmd_ctx_destroy de-initializes and de-allocates an OpenHMD context allocated with ohmd_ctx_create.
 * All devices associated with the context are automatically closed.
 *
 * @param ctx The context to destroy.
 **/
fn ohmd_ctx_destroy(ctx: ohmd_context*);

/*!
 * Get the last error as a human readable string.
 *
 * If a function taking a context as an argument (ohmd_context "methods") returns non-successfully,
 * a human readable error message describing what went wrong can be retrieved with this function.
 *
 * @param ctx The context to retrieve the error message from.
 * @return a pointer to the error message.
 **/
fn ohmd_ctx_get_error(ctx: ohmd_context*, const(char)*);

/*!
 * Update a context.
 *
 * Update the values for the devices handled by a context.
 *
 * If background threads are disabled, this performs tasks like pumping events from the device. The exact details 
 * are up to the driver but try to call it quite frequently.
 * Once per frame in a "game loop" should be sufficient.
 * If OpenHMD is handled in a background thread in your program, calling ohmd_ctx_update and then sleeping for 10-20 ms
 * is recommended.
 *
 * @param ctx The context that needs updating.
 **/
fn ohmd_ctx_update(ctx: ohmd_context*);

/*!
 * Probe for devices.
 *
 * Probes for and enumerates supported devices attached to the system.
 *
 * @param ctx A context with no currently open devices.
 * @return the number of devices found on the system.
 **/
fn ohmd_ctx_probe(ctx: ohmd_context*) int;

/*!
 * Get string from openhmd.
 *
 * Gets a string from OpenHMD. This is where non-device specific strings reside.
 * This is where the distortion shader sources can be retrieved.
 *
 * @param type The name of the string to fetch. One of OHMD_GLSL_DISTORTION_FRAG_SRC, and OHMD_GLSL_DISTORTION_FRAG_SRC.
 * @param[out] _out The location to return a const char*
 * @return 0 on success, <0 on failure.
 **/
fn ohmd_gets(type: ohmd_string_description, _out: const(char)**) int;

/*!
 * Get device description from enumeration list index.
 *
 * Gets a human readable device description string from a zero indexed enumeration index
 * between 0 and (max - 1), where max is the number ohmd_ctx_probe returned
 * (i.e. if ohmd_ctx_probe returns 3, valid indices are 0, 1 and 2).
 * The function can return three types of data. The vendor name, the product name and
 * a driver specific path where the device is attached.
 *
 * ohmd_ctx_probe must be called before calling ohmd_list_gets.
 *
 * @param ctx A (probed) context.
 * @param _index An index, between 0 and the value returned from ohmd_ctx_probe.
 * @param type The type of data to fetch. One of OHMD_VENDOR, OHMD_PRODUCT and OHMD_PATH.
 * @return a string with a human readable device name.
 **/
 fn ohmd_list_gets(ctx: ohmd_context*, index: int, type: ohmd_string_value) const(char)*;

/*!
 * Open a device.
 *
 * Opens a device from a zero indexed enumeration index between 0 and (max - 1)
 * where max is the number ohmd_ctx_probe returned (i.e. if ohmd_ctx_probe returns 3,
 * valid indices are 0, 1 and 2).
 *
 * ohmd_ctx_probe must be called before calling ohmd_list_open_device.
 *
 * @param ctx A (probed) context.
 * @param _index An index, between 0 and the value returned from ohmd_ctx_probe.
 * @return a pointer to an ohmd_device, which represents a hardware device, such as an HMD.
 **/
fn ohmd_list_open_device(ctx: ohmd_context*, index: int) ohmd_device*;

/*!
 * Open a device with additional settings provided.
 *
 * Opens a device from a zero indexed enumeration index between 0 and (max - 1)
 * where max is the number ohmd_ctx_probe returned (i.e. if ohmd_ctx_probe returns 3,
 * valid indices are 0, 1 and 2).
 *
 * ohmd_ctx_probe must be called before calling ohmd_list_open_device.
 *
 * @param ctx A (probed) context.
 * @param _index An index, between 0 and the value returned from ohmd_ctx_probe.
 * @param settings A pointer to a device settings struct.
 * @return a pointer to an ohmd_device, which represents a hardware device, such as an HMD.
 **/
fn ohmd_list_open_device_s(ctx: ohmd_context*, index: int, settings: ohmd_device_settings*) ohmd_device*;

/*!
 * Specify int settings in a device settings struct.
 *
 * @param settings The device settings struct to set values to.
 * @param key The specefic setting you wish to set.
 * @param value A pointer to an int or int array (containing the expected number of elements) with the value(s) you wish to set.
 **/
fn ohmd_device_settings_seti(settings: ohmd_device_settings*, key: ohmd_int_settings, val: const(int)*) ohmd_status;

/*!
 * Create a device settings instance.
 *
 * @param ctx A pointer to a valid ohmd_context.
 * @return a pointer to an allocated ohmd_context on success or NULL if it fails.
 **/
fn ohmd_device_settings_create(ctx: ohmd_context*) ohmd_device_settings*;

/*!
 * Destroy a device settings instance.
 *
 * @param ctx The device settings instance to destroy.
 **/
fn ohmd_device_settings_destroy(settings: ohmd_device_settings*);

/*!
 * Close a device.
 *
 * Closes a device opened by ohmd_list_open_device. Note that ohmd_ctx_destroy automatically closes any open devices
 * associated with the context being destroyed.
 *
 * @param device The open device.
 * @return 0 on success, < 0 on failure.
 **/
fn ohmd_close_device(device: ohmd_device*) int;

/*!
 * Get a floating point value from a device.
 *
 *
 * @param device An open device to retrieve the value from.
 * @param type What type of value to retrieve, see ohmd_float_value section for more information.
 * @param[out] _out A pointer to a float, or float array where the retrieved value should be written.
 * @return 0 on success, < 0 on failure.
 **/
fn ohmd_device_getf(device: ohmd_device*, type: ohmd_float_value, _out: float*) int;

/*!
 * Set a floating point value for a device.
 *
 * @param device An open device to set the value in.
 * @param type What type of value to set, see ohmd_float_value section for more information.
 * @param _in A pointer to a float, or float array where the new value is stored.
 * @return 0 on success, < 0 on failure.
 **/
fn ohmd_device_setf(device: ohmd_device*, type: ohmd_float_value, _in: const(float)*) int;

/*!
 * Get an integer value from a device.
 *
 * @param device An open device to retrieve the value from.
 * @param type What type of value to retrieve, ohmd_int_value section for more information.
 * @param[out] _out A pointer to an integer, or integer array where the retrieved value should be written.
 * @return 0 on success, < 0 on failure.
 **/
fn ohmd_device_geti(device: ohmd_device*, type: ohmd_int_value, _out: int*) int;

/*!
 * Set an integer value for a device.
 *
 * @param device An open device to set the value in.
 * @param type What type of value to set, see ohmd_float_value section for more information.
 * @param _in A pointer to a int, or int array where the new value is stored.
 * @return 0 on success, < 0 on failure.
 **/
fn ohmd_device_seti(device: ohmd_device*, type: ohmd_int_value, _in: const(int)*) int;

/*!
 * Set an void* data value for a device.
 *
 * @param device An open device to set the value in.
 * @param type What type of value to set, see ohmd_float_value section for more information.
 * @param _in A pointer to the void* casted object.
 * @return 0 on success, < 0 on failure.
 **/
fn ohmd_device_set_data(device: ohmd_device*, type: ohmd_data_value, _in: const(void)*) int;
