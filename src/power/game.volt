// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.game;

import core.exception;

import charge.gfx;
import charge.core;
import charge.game;

import tui = charge.game.tui;

import power.app;
import power.menu;
import power.inbuilt;
import power.experiments.brute;
import power.experiments.aligntest;
import power.experiments.raytracer;


class Game : App
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

		bg := new GameBackgroundScene(this);
		bg.setTile(makeInbuiltTilePng());
		push(bg);

		showMenu();
	}

	override fn showMenu()
	{
		push(new Menu(this));
	}

	override fn showVoxelTest()
	{
		push(new RayTracer(this));
	}

	override fn showAlignTest()
	{
		push(new AlignTest(this));
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
