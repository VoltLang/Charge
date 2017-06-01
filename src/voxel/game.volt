// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.game;

import core.exception;

import io = watt.io;
import watt.io.file;

import charge.ctl;
import charge.sys.resource;
import charge.core;
import charge.gfx;
import charge.game;
import charge.game.scene.background;

import voxel.viewer;
import voxel.svo;
import voxel.loaders;
import gen = voxel.svo.gen;


class Game : GameSceneManagerApp
{
public:
	this(args: string[])
	{
		// First init core.
		opts := new CoreOptions();
		opts.title = "Mixed Voxel Rendering";
		opts.width = 1920;
		opts.height = 1080;
		opts.windowMode = coreWindow.Normal;
		super(opts);


		if (!checkVersion()) {
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
			c.panic("Could not load or generate a level");
		}

		io.writefln("svo: %s (x: %s, y: %s, z: %s)", state.numLevels,
		            state.xShift, state.yShift, state.zShift);
		push(new RayTracer(this, ref state, frames, data));
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
		og: OneGen;

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
		fg: FlatGen;

		// Only one frame.
		frames = new u32[](1);
		frames[0] = fg.genY(ref ib, 11);

		data = ib.getData();
		return true;
	}

	//! Absolute minimum required.
	fn checkVersion() bool
	{
		// Need OpenGL 4.5 now.
		if (!GL_VERSION_4_5) {
			c.panic("Need at least GL 4.5");
		}

		// For texture functions.
		if (!GL_ARB_texture_storage && !GL_VERSION_4_5) {
			c.panic("Need GL_ARB_texture_storage or OpenGL 4.5");
		}

		// For samplers functions.
		if (!GL_ARB_sampler_objects && !GL_VERSION_3_3) {
			c.panic("Need GL_ARB_sampler_objects or OpenGL 3.3");
		}

		// For shaders.
		if (!GL_ARB_ES2_compatibility) {
			c.panic("Need GL_ARB_ES2_compatibility");
		}
		if (!GL_ARB_explicit_attrib_location) {
			c.panic("Need GL_ARB_explicit_attrib_location");
		}

		return true;
	}
}
