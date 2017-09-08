// Copyright © 2012-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.menu;

import core = charge.core;
import ctl = charge.ctl;
import gfx = charge.gfx;
import tui = charge.game.tui;

import power.app;


class Menu : tui.MenuScene
{
public:
	app: App;


public:
	this(app: App)
	{
		this.app = app;
		voxelTest := new tui.Button();
		voxelTest.str = "Voxel Test";
		voxelTest.pressed = pressedVoxels;

		alignTest := new tui.Button();
		alignTest.str = "Align Test";
		alignTest.pressed = pressedAlignTest;

		super(app, "Charged Experiments", voxelTest, alignTest);

		this.quit.pressed = pressedQuit;
		this.close.pressed = pressedClose;
	}

	fn pressedClose(button: tui.Button)
	{
		app.closeMe(this);
	}

	fn pressedQuit(button: tui.Button)
	{
		core.quit();
	}

	fn pressedAlignTest(button: tui.Button)
	{
		app.closeMe(this);
		app.showAlignTest();
	}

	fn pressedVoxels(button: tui.Button)
	{
		app.closeMe(this);
		app.showVoxelTest();
	}
}
