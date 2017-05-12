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
import gen = voxel.svo.gen;
import magica = voxel.loaders.magica;


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

		// First try a magica voxel level.
		if (!loadMagica(filename, out frames, out data) &&
		    !genFlat(out frames, out data)) {
			c.panic("Could not load or generate a level");
		}

		push(new RayTracer(this, frames, data));
	}

	fn loadMagica(filename: string, out frames: u32[], out data: void[]) bool
	{
		if (!isFile(filename)) {
			return false;
		}

		// Load the file.
		fileData := cast(void[])read(filename);

		// Reserve the first index.
		ib: InputBuffer;
		ib.setup(1);

		// Create the loader.
		l := new magica.Loader();

		// Load parse the file.
		if (!l.loadFileFromData(fileData)) {
			return false;
		}

		// Only one frame.
		frames = new u32[](1);
		frames[0] = l.toBuffer(ref ib, 3);

		// Grab the data.
		data = ib.getData();

		return true;
	}

	fn genFlat(out frames: u32[], out data: void[]) bool
	{
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

	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	/// Absolute minimum required.
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
