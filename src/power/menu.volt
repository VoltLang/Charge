// Copyright © 2012-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.menu;

import charge.core;
import charge.ctl;
import charge.gfx;
import charge.game;

import tui = charge.game.tui;


class Menu : tui.MenuScene
{
	this(g: GameSceneManagerApp)
	{
		voxels := new tui.Button();
		voxels.str = "Voxels";
		voxels.pressed = pressedVoxels;
		super(g, "Charged Experiments", voxels);

		this.quit.pressed = pressedQuit;
		this.close.pressed = pressedClose;

		setHeader(cast(immutable(u8)[])"Charged Experiments");
	}

	fn pressedClose(button: tui.Button)
	{
		mManager.closeMe(this);
	}

	fn pressedQuit(button: tui.Button)
	{
		chargeQuit();
	}

	fn pressedVoxels(button: tui.Button)
	{
		mManager.closeMe(this);
	}
}
