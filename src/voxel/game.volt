// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.game;

import core.exception;
import core.rt.format;

import io = watt.io;

import watt.io.file;

import core = charge.core;
import ctl = charge.ctl;
import gfx = charge.gfx;
import scene = charge.game.scene;

import charge.util.stopwatch;
import charge.gfx.gl;

import gen = voxel.generators;

import voxel.viewer;
import voxel.svo;
import voxel.loaders;


class Game : scene.ManagerApp
{
public:
	this(args: string[])
	{
		// Get the runtime startup.
		rtStart: StopWatch;
		rtStart.fromInit();

		// Time the core startup.
		coreStart: StopWatch;
		coreStart.startAndStop(ref rtStart);

		// First init core.
		opts := new core.Options();
		opts.title = "Mixed Voxel Rendering";
		opts.width = 1920;
		opts.height = 1080;
		opts.windowMode = core.WindowMode.Normal;
		super(opts);

		// We are now starting the game.
		gameStart: StopWatch;
		gameStart.startAndStop(ref coreStart);

		if (!checkVersion()) {
			core.quit();
			return;
		}

		data: void[];
		frames: u32[];

		filename := "res/test.vox";
		if (args.length > 1) {
			filename = args[1];
		}

		// State to give to the renderers.
		state: Create;

		// First try a magica voxel level.
		if (!loadFile(filename, out state, out frames, out data) &&
		    !doGen(filename, out state, out frames, out data)) {
			mCore.panic("Could not load or generate a level");
		}

		d := new Data(ref state, data);
		obj := new Entity(d, frames);

		push(new RayTracer(this, d, obj));

		// Done with game startup, do some debug prinintg.
		// We are now starting the game.
		countStart: StopWatch;
		countStart.startAndStop(ref gameStart);

		count := d.count(obj, 9);

		countStart.stop();

		// Print out svo info.
		io.output.writef("svo: %s (x: %s, y: %s, z: %s) size: ",
			state.numLevels, state.xShift, state.yShift, state.zShift);
		vrt_format_readable_size(io.output.write, data.length);
		io.output.writefln("");
		io.output.writefln("count: %s", count);
		io.output.flush();

		// Do timings
		rtU := rtStart.microseconds;
		coreU := coreStart.microseconds;
		gameU := gameStart.microseconds;
		countU := countStart.microseconds;
		io.output.writefln("rt:%7s.%03sms\ncore:%5s.%03sms\ngame:%5s.%03sms\ncount:%4s.%03sms",
			rtU / 1000, rtU % 1000,
			coreU / 1000, coreU % 1000,
			gameU / 1000, gameU % 1000,
			countU / 1000, countU % 1000);
		io.output.flush();
	}


	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	fn loadFile(filename: string, out c: Create, out frames: u32[], out data: void[]) bool
	{
		if (!isFile(filename)) {
			return false;
		}

		// Load the file.
		fileData := cast(void[])read(filename);

		if (magica.isMagicaFile(fileData)) {
			return loadMagica(fileData, out c, out frames, out data);
		}

		if (chalmers.isChalmersDag(fileData)) {
			return loadChalmers(fileData, out c, out frames, out data);
		}

		return false;
	}

	fn loadMagica(fileData: void[], out c: Create,
	              out frames: u32[], out data: void[]) bool
	{
		// Setup the state.
		c.xShift = XShift;
		c.yShift = YShift;
		c.zShift = ZShift;
		c.numLevels = 11;

		// Reserve the first index.
		ib: InputBuffer;
		ib.setup(1);

		// Create the loader.
		l := new magica.Loader();

		// Load parse the file.
		return l.loadFileFromData(fileData, out frames, out data);
	}

	fn loadChalmers(fileData: void[], out c: Create,
	                out frames: u32[], out data: void[]) bool
	{
		// Reserve the first index.
		ib: InputBuffer;
		ib.setup(1);

		// Create the loader.
		l := new chalmers.Loader();

		// Load parse the file.
		return l.loadFileFromData(fileData, out c, out frames, out data);
	}

	fn doGen(arg: string, out c: Create, out frames: u32[], out data: void[]) bool
	{
		switch (arg) {
		case "--gen-one":
			return genOne(out c, out frames, out data);
		case "--gen-flat", "--gen-flat-y":
			return genFlatY(out c, out frames, out data);
		default:
			return genFlatY(out c, out frames, out data);
		}
	}

	fn genOne(out c: Create, out frames: u32[], out data: void[]) bool
	{
		// Setup the state.
		c.xShift = XShift;
		c.yShift = YShift;
		c.zShift = ZShift;
		c.numLevels = 11;

		// Reserve the first index.
		ib: InputBuffer;
		ib.setup(1);

		// Load parse the file.
		og: gen.OneGen;

		// Only one frame.
		frames = new u32[](1);
		frames[0] = og.gen(ref ib, 11);

		data = ib.getData();
		return true;
	}

	fn genFlatY(out c: Create, out frames: u32[], out data: void[]) bool
	{
		// Setup the state.
		c.xShift = XShift;
		c.yShift = YShift;
		c.zShift = ZShift;
		c.numLevels = 11;

		// Reserve the first index.
		ib: InputBuffer;
		ib.setup(1);

		// Load parse the file.
		fg: gen.FlatGen;

		// Only one frame.
		frames = new u32[](1);
		frames[0] = fg.genYColored(ref ib, c.numLevels);

		data = ib.getData();
		return true;
	}

	//! Absolute minimum required.
	fn checkVersion() bool
	{
		// Error string.
		str: string;

		// Need OpenGL 4.5 now.
		if (!GL_VERSION_4_5) {
			str ~= "Need at least GL 4.5\n";
		}

		// For texture functions.
		if (!GL_ARB_texture_storage && !GL_VERSION_4_5) {
			str ~= "Need GL_ARB_texture_storage or OpenGL 4.5\n";
		}

		// For samplers functions.
		if (!GL_ARB_sampler_objects && !GL_VERSION_3_3) {
			str ~= "Need GL_ARB_sampler_objects or OpenGL 3.3\n";
		}

		// For shaders.
		if (!GL_ARB_ES2_compatibility) {
			str ~= "Need GL_ARB_ES2_compatibility\n";
		}
		if (!GL_ARB_explicit_attrib_location) {
			str ~= "Need GL_ARB_explicit_attrib_location\n";
		}
		if (!GL_ARB_shader_ballot) {
			str ~= "Need GL_ARB_shader_ballot\n";
		}
		if (!GL_ARB_shader_atomic_counter_ops && !GL_AMD_shader_atomic_counter_ops) {
			str ~= "Need GL_ARB_shader_atomic_counter_ops or GL_AMD_shader_atomic_counter_ops\n";
		}

		if (str.length) {
			mCore.panic(str);
		}
		return true;
	}
}
