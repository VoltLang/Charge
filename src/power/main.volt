// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.main;

import core.exception;

import watt.io;

import charge.ctl;
import charge.sys.resource;
import charge.core;
import charge.gfx;
import charge.game;
import charge.game.scene.background;
import charge.math.matrix;

import power.experiments.brute;
import power.experiments.aligntest;
import power.experiments.raytracer;


class Game : GameSceneManagerApp
{
public:
	this(string[] args)
	{
		// First init core.
		auto opts = new CoreOptions();
		opts.title = "Charged Power";
		opts.width = 800;
		opts.height = 600;
		super(opts);

		checkVersion();

		push(new RayTracer(this));
		//push(new Brute(this));
	}


	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	void checkVersion()
	{
		// For texture functions.
		if (!GL_ARB_ES3_compatibility &&
		    !GL_ARB_texture_storage &&
		    !GL_VERSION_4_2) {
			throw new Exception("Need GL_ARB_texture_storage or OpenGL 4.2");
		}

		// For samplers functions.
		if (!GL_ARB_ES3_compatibility &&
		    !GL_ARB_sampler_objects &&
		    !GL_VERSION_3_3) {
			throw new Exception("Need GL_ARB_sampler_objects or OpenGL 3.3");
		}

		// For shaders.
		if (!GL_ARB_ES2_compatibility || !GL_VERSION_4_5) {
			throw new Exception("Need GLSL 4.5");
		}
	}
}
