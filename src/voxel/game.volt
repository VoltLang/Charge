// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.game;

import core.exception;

import watt.io;

import charge.ctl;
import charge.sys.resource;
import charge.core;
import charge.gfx;
import charge.game;
import charge.game.scene.background;

import power.experiments.raytracer;


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

		if (checkVersion()) {
			push(new RayTracer(this));
		}
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
