// Copyright © 2012-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.game.tui.messagescene;

import watt.algorithm;

import core = charge.core;
import ctl = charge.ctl;
import gfx = charge.gfx;
import scene = charge.game.scene;

import charge.game.tui.glyphdraw;
import charge.game.tui.menuscene;
import charge.game.tui.windowscene;


class Text
{
public:
	str: string;
	x, y: i32;
	w, h: u32;
}

class MessageScene : WindowScene
{
public:
	ok: Button;
	text: Text;


public:
	this(m: scene.Manager, header: string, str: string)
	{
		text = new Text();
		text.str = str;

		ok = new Button();
		ok.str = "Ok";
		ok.w = MenuScene.LastButtonWidth;
		ok.h = MenuScene.ButtonHeight;
		ok.pressed = pressedOk;

		super(m, 1, 1);

		setHeader(cast(immutable(u8)[])header);

		doLayout();

		drawText(text);
		drawButton(ok);
	}

	override fn keyDown(ctl.Keyboard, keycode: int)
	{
		switch (keycode) {
		case 27:
			if (ok.pressed !is null) {
				ok.pressed(ok);
			} else {
				mManager.closeMe(this);
			}
			break;
		default:
		}
	}

	override fn gridMouseDown(m: ctl.Mouse, x: u32, y: u32, button: i32)
	{
		if (button != 1) {
			return;
		}

		ok.maybeClicked(cast(i32)x, cast(i32)y);
	}

	fn pressedOk(button: Button)
	{
		mManager.closeMe(this);
	}


private:
	fn doLayout()
	{
		makeTextLayout(text.str, out text.w, out text.h);

		w := min(max(text.w, 20),  80);
		h := min(max(text.h,  1), 120);

		// Even out the number of columns.
		w += w & 0x1;
		h += 2;

		text.x = cast(i32)(w / 2 - text.w / 2);
		text.y = 1;

		ok.x = cast(i32)(w / 2 - ok.w / 2);
		ok.y = cast(i32)(h);

		h += 3;

		setSize(w, h);
	}

	fn drawText(text: Text)
	{
		makeText(grid, text.x, text.y, text.str);
	}

	fn drawButton(b: Button)
	{
		makeButton(grid, b.x, b.y, b.w, false, cast(immutable(u8)[])b.str);
	}
}
