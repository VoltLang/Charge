// Copyright 2012-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
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
		voxelScene := new tui.Button();
		voxelScene.str = "Voxel Scene";
		voxelScene.pressed = pressedVoxelScene;
		voxelCmp := new tui.Button();
		voxelCmp.str = "Voxel Test";
		voxelCmp.pressed = pressedVoxelCompare;

		alignTest := new tui.Button();
		alignTest.str = "Align Test";
		alignTest.pressed = pressedAlignTest;

		super(app, "Charged Experiments", voxelScene, voxelCmp, alignTest);

		this.quit.pressed = pressedQuit;
		this.close.pressed = pressedClose;
	}

	fn pressedClose(button: tui.Button)
	{
		app.closeMe(this);
	}

	fn pressedQuit(button: tui.Button)
	{
		core.get().quit(0);
	}

	fn pressedAlignTest(button: tui.Button)
	{
		app.closeMe(this);
		app.showAlignTest();
	}

	fn pressedVoxelScene(button: tui.Button)
	{
		app.closeMe(this);
		app.showVoxelScene();
	}

	fn pressedVoxelCompare(button: tui.Button)
	{
		app.closeMe(this);
		app.showVoxelCompare();
	}
}
