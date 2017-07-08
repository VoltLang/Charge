// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module ohmd.hmd;

import lib.ohmd;
static import lib.ohmd.loader;

import watt.library;

import math = charge.math;


/*!
 * Container for OpenHMD library and interfacing code.
 */
class Context
{
public:
	library: Library;
	ctx: ohmd_context*;


public:
	fn close()
	{
		if (ctx !is null) {
			ctx.destroy();
			ctx = null;
		}
		if (library !is null) {
			library.free();
			library = null;
		}
	}

	global fn load() Context
	{
		// The bindings know which library to load.
		library := lib.ohmd.loader.loadLibrary();
		if (library is null) {
			return null;
		}

		// Loading the functions.
		lib.ohmd.loader.loadFunctions(library.symbol);

		// Start OpenHMD.
		ctx := ohmd_ctx_create();
		if (ctx is null) {
			library.free();
			return null;
		}

		return new Context(library, ctx);
	}

	fn update()
	{
		ctx.update();
	}

	fn getDevice() Device
	{
		num := ctx.probe();
		//io.writefln("ohmd: %s device%s", num, num > 1 ? "s" : "");
		foreach (i; 0 .. num) {
			//io.writefln("ohmd device #%s", i);
			//io.writefln("\t%s", .toString(ctx.list_gets(i, ohmd_string_value.VENDOR)));
			//io.writefln("\t%s", .toString(ctx.list_gets(i, ohmd_string_value.PRODUCT)));
			//io.writefln("\t%s", .toString(ctx.list_gets(i, ohmd_string_value.PATH)));
		}

		devNum := 0;
		//io.writefln("ohmd: Opening device %s.", devNum);
		dev := ctx.list_open_device(devNum);
		if (dev is null) {
			return null;
		}

		return new Device(this, dev);
	}


private:
	this(library: Library, ctx: ohmd_context*)
	{
		this.library = library;
		this.ctx = ctx;
	}
}

//! A single HMD device.
class Device
{
public:
	ctx: Context;
	dev: ohmd_device*;


public:
	this(ctx: Context, dev: ohmd_device*)
	{
		this.ctx = ctx;
		this.dev = dev;
	}

	fn close()
	{
		ctx = null;
		if (dev !is null) {
			dev.close();
			dev = null;
		}
	}

	fn getPosAndRot(ref pos: math.Point3f, ref rot: math.Quatf)
	{
		pos = math.Point3f.opCall(0.5f, 1.75f, 0.5f);
		dev.get_rot(ref *cast(f32[4]*)rot.ptr);
	}
}

class NoContext : Context
{
	this()
	{
		super(null, null);
	}

	override fn update() {}
	override fn getDevice() Device
	{
		return new NoDevice();
	}
}

class NoDevice : Device
{
public:
	this()
	{
		super(null, null);
	}

	override fn getPosAndRot(ref pos: math.Point3f, ref rot: math.Quatf)
	{
		pos = math.Point3f.opCall(0.5f, 1.75f, 0.5f);
		rot = math.Quatf.opCall();
	}
}
