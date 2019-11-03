// Copyright 2016-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
module lib.ohmd.loader;

import lib.ohmd;

import watt.library;


fn loadLibrary() Library
{
	return Library.loads([
		"libopenhmd.0.dylib",
		"libopenhmd.dylib",
		"libopenhmd.so.0.0.0",
		"libopenhmd.so.0",
		"libopenhmd.so",
		"OpenHMD.dll"]);
}

fn loadFunctions(l: dg(string) void*)
{
	ohmd_ctx_create = cast(typeof(ohmd_ctx_create))l("ohmd_ctx_create");
	ohmd_ctx_destroy = cast(typeof(ohmd_ctx_destroy))l("ohmd_ctx_destroy");
	ohmd_ctx_get_error = cast(typeof(ohmd_ctx_get_error))l("ohmd_ctx_get_error");
	ohmd_ctx_update = cast(typeof(ohmd_ctx_update))l("ohmd_ctx_update");
	ohmd_ctx_probe = cast(typeof(ohmd_ctx_probe))l("ohmd_ctx_probe");
	ohmd_gets = cast(typeof(ohmd_gets))l("ohmd_gets");
	ohmd_list_gets = cast(typeof(ohmd_list_gets))l("ohmd_list_gets");
	ohmd_list_open_device = cast(typeof(ohmd_list_open_device))l("ohmd_list_open_device");
	ohmd_list_open_device_s = cast(typeof(ohmd_list_open_device_s))l("ohmd_list_open_device_s");
	ohmd_device_settings_seti = cast(typeof(ohmd_device_settings_seti))l("ohmd_device_settings_seti");
	ohmd_device_settings_create = cast(typeof(ohmd_device_settings_create))l("ohmd_device_settings_create");
	ohmd_device_settings_destroy = cast(typeof(ohmd_device_settings_destroy))l("ohmd_device_settings_destroy");
	ohmd_close_device = cast(typeof(ohmd_close_device))l("ohmd_close_device");
	ohmd_device_getf = cast(typeof(ohmd_device_getf))l("ohmd_device_getf");
	ohmd_device_setf = cast(typeof(ohmd_device_setf))l("ohmd_device_setf");
	ohmd_device_geti = cast(typeof(ohmd_device_geti))l("ohmd_device_geti");
	ohmd_device_seti = cast(typeof(ohmd_device_seti))l("ohmd_device_seti");
	ohmd_device_set_data = cast(typeof(ohmd_device_set_data))l("ohmd_device_set_data");
}
