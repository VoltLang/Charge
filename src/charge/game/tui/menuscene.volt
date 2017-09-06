// Copyright © 2012-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.game.tui.menuscene;

import ctl = charge.ctl;
import gfx = charge.gfx;
import game = charge.game;

import charge.core;
import charge.game.tui.glyphdraw;
import charge.game.tui.windowscene;


class Button
{
public:
	pressed: dg(Button);
	str: string;
	x, y: i32;
	w, h: u32;


public:
	fn maybeClicked(x: i32, y: i32) {
		if (x >= this.x &&
		    y >= this.y &&
		    x < this.x + cast(i32)this.w &&
		    y < this.y + cast(i32)this.h &&
		    pressed !is null) {
			pressed(this);
		}
	}
}

class MenuScene : WindowScene
{
public:
	enum TopOffset : u32 = 0u;
	enum TotalWidth : u32 = 48u;

	enum ButtonWidth : u32 = TotalWidth - 7u * 2u;
	enum ButtonHeight : u32 = 3u;
	enum ButtonVerticalSeperation : u32 = 1u;

	enum LastButtonWidth : u32 = 10u;
	enum LastButtonHorizontalSeperation : u32 = 2u;


public:
	buttons: Button[];
	quit: Button;
	close: Button;


public:
	this(g: game.SceneManager, header: string, buttons: scope Button[]...)
	{
		super(g, 1, 1);
		this.quit = new Button();
		this.close = new Button();
		this.quit.str = "Quit";
		this.close.str = "Close";
		this.buttons = new buttons[..];

		setHeader(cast(immutable(u8)[])header);

		doLayout();

		foreach (b; buttons) {
			drawButton(b);
		}

		drawButton(quit);
		drawButton(close);
	}

	override fn keyDown(ctl.Keyboard, keycode: int)
	{
		switch (keycode) {
		case 27:
			mManager.closeMe(this);
			break;
		default:
		}
	}

	override fn gridMouseDown(m: ctl.Mouse, x: u32, y: u32, button: i32)
	{
		if (button != 1) {
			return;
		}

		foreach (b; buttons) {
			b.maybeClicked(cast(i32)x, cast(i32)y);
		}

		quit.maybeClicked(cast(i32)x, cast(i32)y);
		close.maybeClicked(cast(i32)x, cast(i32)y);
	}


private:
	fn doLayout()
	{
		width := TotalWidth; 
		height := TopOffset;
		buttonX := cast(i32)(TotalWidth / 2 - ButtonWidth / 2);
		buttonY := cast(i32)(TopOffset);

		foreach (b; buttons) {
			b.x = buttonX;
			b.y = buttonY;
			b.w = ButtonWidth;
			b.h = ButtonHeight;

			height += ButtonHeight;
			buttonY += cast(i32)(ButtonHeight);
		}

		buttonY += ButtonVerticalSeperation;
		height += ButtonVerticalSeperation;
		height += ButtonHeight;

		setSize(width, height);

		lastButtonsX1 := cast(i32)((TotalWidth / 2) -
			(LastButtonWidth * 2 + LastButtonHorizontalSeperation) / 2);
		lastButtonsX2 := lastButtonsX1 +
			cast(i32)(LastButtonWidth + LastButtonHorizontalSeperation);

		if (quit !is null) {
			quit.x = lastButtonsX1;
			quit.y = buttonY;
			quit.w = LastButtonWidth;
			quit.h = ButtonHeight;
		}

		if (close !is null) {
			close.x = lastButtonsX2;
			close.y = buttonY;
			close.w = LastButtonWidth;
			close.h = ButtonHeight;
		}
	}

	fn drawButton(b: Button)
	{
		makeButton(grid, b.x, b.y, b.w, false, cast(immutable(u8)[])b.str);
	}
}
