// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.game;

import core.exception;

import core = charge.core;
import gfx = charge.gfx;
import tui = charge.game.tui;
import scene = charge.game.scene;

import charge.gfx.gl;

import power.app;
import power.menu;
import power.inbuilt;
import power.svoloader;
import power.experiments.brute;
import power.experiments.aligntest;


class Game : App
{
private:
	mArg: string;


public:
	this(args: string[])
	{
		if (args.length > 1) {
			mArg = args[1];
		} else {
			mArg = "res/test.vox";
		}

		// First init core.
		opts := new core.Options();
		opts.title = "Charged Power";
		opts.width = 1920;
		opts.height = 1080;
		opts.windowMode = core.WindowMode.Normal;
		super(opts);

		checkVersion();

		bg := new scene.Background(this);
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
		push(new SvoLoader(this, mArg));
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
