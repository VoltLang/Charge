// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.app;

import core.exception;

import charge.gfx;
import charge.core;
import charge.game;

import power.menu;
import power.experiments.brute;
import power.experiments.aligntest;
import power.experiments.raytracer;


class App : GameSceneManagerApp
{
public:
	this(args: string[])
	{
		// First init core.
		opts := new CoreOptions();
		opts.title = "Charged Power";
		opts.width = 1920;
		opts.height = 1080;
		opts.windowMode = coreWindow.Normal;
		super(opts);

		checkVersion();

		push(new Menu(this));
	}


	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	//! Absolute minimum required.
	fn checkVersion()
	{
		// For texture functions.
		if (!GL_ARB_texture_storage && !GL_VERSION_4_5) {
			throw new Exception("Need GL_ARB_texture_storage or OpenGL 4.5");
		}

		// For samplers functions.
		if (!GL_ARB_sampler_objects && !GL_VERSION_3_3) {
			throw new Exception("Need GL_ARB_sampler_objects or OpenGL 3.3");
		}

		// For shaders.
		if (!GL_ARB_ES2_compatibility) {
			throw new Exception("Need GL_ARB_ES2_compatibility");
		}
		if (!GL_ARB_explicit_attrib_location) {
			throw new Exception("Need GL_ARB_explicit_attrib_location");
		}
	}
}
