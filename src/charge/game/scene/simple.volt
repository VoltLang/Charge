// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for SimpleScene, helper default implementation.
 */
module charge.game.scene.simple;

import charge.ctl;
import charge.gfx;
import charge.game.scene.scene;


/*!
 * Helper that, implements all of the functions on Scene.
 */
abstract class SimpleScene : Scene
{
protected:
	mInput: CtlInput;


public:
	this(SceneManager sm, Type type)
	{
		super(sm, type);
		mInput = CtlInput.opCall();
	}

	override fn close() {}
	override fn logic() {}
	override fn render(GfxTarget) {}

	fn keyText(CtlKeyboard, scope const(char)[]) {}
	fn keyDown(CtlKeyboard, int) {}
	fn keyUp(CtlKeyboard, int) {}

	fn mouseMove(CtlMouse, int, int) {}
	fn mouseDown(CtlMouse, int) {}
	fn mouseUp(CtlMouse, int) {}

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
