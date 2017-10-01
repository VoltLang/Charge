// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.game;

import core.exception;

import io = watt.io;

import core = charge.core;
import gfx = charge.gfx;
import tui = charge.game.tui;
import scene = charge.game.scene;

import charge.gfx.gl;

import power.app;
import power.menu;
import power.inbuilt;
import power.experiments.svo;
import power.experiments.aligntest;


class Game : App
{
public:
	this(args: string[])
	{


		// First init core.
		opts := new core.Options();
		opts.title = "Charged Power";
		opts.width = 1920;
		opts.height = 1080;
		opts.windowMode = core.WindowMode.Normal;
		super(opts);

		checkVersion();

		if (GL_EXT_memory_object) {
			io.writefln("GL_EXT_memory_object");
			io.writefln("\tGL_EXT_memory_object_fd %s", GL_EXT_memory_object_fd);
			io.writefln("\tGL_EXT_memory_object_win32 %s", GL_EXT_memory_object_win32);
		}

		bg := new scene.Background(this);
		bg.setTile(makeInbuiltTilePng());
		push(bg);

		if (args.length > 1) {
			push(new SvoLoader(this, args[1]));
		} else {
			showMenu();
		}
	}

	override fn showMenu()
	{
		push(new Menu(this));
	}

	override fn showVoxelTest()
	{
		push(new SvoLoader(this, "res/test.vox"));
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
