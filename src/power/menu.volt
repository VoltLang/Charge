// Copyright © 2012-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.meun;

import charge.core;
import charge.ctl;
import charge.gfx;
import charge.game;
import charge.game.scene.tuimenu;

import tui = charge.game.tui;


class Menu : TuiWindowScene
{
	this(g: GameSceneManagerApp)
	{
		width := 48u;
		height := 3u + 3u + 1u + 3u;
		super(g, width, height);
		buttonWidth := width - 7u * 2u;
		bottonX := cast(i32)(width / 2 - buttonWidth / 2);
		bottonY := cast(i32)(height - 3u - 3u - 1u);

		setHeader(cast(immutable(u8)[])"Voxel Experiments");

		lastButtonsWidth := 10u;
		lastButtonsSeparation := 2u;
		lastButtonsY := cast(i32)(height - 3u);
		lastButtonsX1 := cast(i32)((width / 2) -
			(lastButtonsWidth * 2 + lastButtonsSeparation) / 2);
		lastButtonsX2 := lastButtonsX1 +
			cast(i32)(lastButtonsWidth + lastButtonsSeparation);

		tui.makeButton(grid, bottonX, bottonY,
			buttonWidth, false, cast(immutable(u8)[])"Voxels");

		tui.makeButton(grid, lastButtonsX1, lastButtonsY,
			lastButtonsWidth, false, cast(immutable(u8)[])"Quit");
		tui.makeButton(grid, lastButtonsX2, lastButtonsY,
			lastButtonsWidth, false, cast(immutable(u8)[])"Close");
	}

	override fn keyDown(CtlKeyboard, keycode: int)
	{
		switch (keycode) {
		case 27:
			mManager.closeMe(this);
			break;
		default:
		}
	}

	override fn mouseMove(m: CtlMouse, i32, i32)
	{
		posX = m.x;
		posY = m.y;
	}

	override fn render(t: GfxTarget)
	{
		width, height: u32;
		getSizeInPixels(out width, out height);

		this.posX = cast(i32)(t.width / 2 - (width / 2));
		this.posY = cast(i32)(t.height / 2 - (height / 2));
		super.render(t);
	}
}
