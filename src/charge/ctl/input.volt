// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/**
 * Source file for main Input processing and interface.
 */
module charge.ctl.input;

import watt.text.utf;

import charge.ctl.device;
import charge.ctl.mouse;
import charge.ctl.keyboard;
import charge.ctl.joystick;


abstract class Input
{
public:
	mouseArray: Mouse[];
	keyboardArray: Keyboard[];
	joystickArray: Joystick[];


private:
	global mInstance: Input;


public:
	global fn opCall() Input
	{
		return mInstance;
	}

	final @property fn mouse() Mouse
	{
		return mouseArray[0];
	}

	final @property fn keyboard() Keyboard
	{
		return keyboardArray[0];
	}

	final @property fn joystick() Joystick
	{
		return joystickArray[0];
	}

	fn mice() Mouse[]
	{
		return new mouseArray[0 .. $];
	}

	fn keyboards() Keyboard[]
	{
		return new keyboardArray[0 .. $];
	}

	fn joysticks() Joystick[]
	{
		return new joystickArray[0 .. $];
	}


protected:
	this()
	{
		mInstance = this;
	}
}
