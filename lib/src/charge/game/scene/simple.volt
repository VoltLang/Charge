// Copyright 2016-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for @ref Simple, helper default implementation.
 */
module charge.game.scene.simple;

import ctl = charge.ctl;
import gfx = charge.gfx;

import charge.game.scene.scene;


/*!
 * Helper that, implements all of the functions on Scene.
 */
abstract class Simple : Scene
{
protected:
	mInput: ctl.Input;


public:
	this(m: Manager, type: Type)
	{
		super(m, type);
		mInput = ctl.Input.opCall();
	}

	override fn close() {}
	override fn logic() {}
	override fn render(gfx.Target, ref gfx.ViewInfo) {}

	fn keyText(ctl.Keyboard, scope const(char)[]) {}
	fn keyDown(ctl.Keyboard, int) {}
	fn keyUp(ctl.Keyboard, int) {}

	fn mouseMove(ctl.Mouse, int, int) {}
	fn mouseDown(ctl.Mouse, int) {}
	fn mouseUp(ctl.Mouse, int) {}

	override fn assumeControl()
	{
		mInput.keyboard.text = keyText;
		mInput.keyboard.down = keyDown;
		mInput.keyboard.up = keyUp;
		mInput.mouse.move = mouseMove;
		mInput.mouse.down = mouseDown;
		mInput.mouse.up = mouseUp;
	}

	override fn dropControl()
	{
		if (mInput.keyboard.text is keyText) {
			mInput.keyboard.text = null;
		}
		if (mInput.keyboard.down is keyDown) {
			mInput.keyboard.down = null;
		}
		if (mInput.keyboard.up is keyUp) {
			mInput.keyboard.up = null;
		}
		if (mInput.mouse.move is mouseMove) {
			mInput.mouse.move = null;
		}
		if (mInput.mouse.down is mouseDown) {
			mInput.mouse.down = null;
		}
		if (mInput.mouse.up is mouseUp) {
			mInput.mouse.up = null;
		}
	}
}
