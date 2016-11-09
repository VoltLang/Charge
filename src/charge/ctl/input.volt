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
	Mouse[] mouseArray;
	Keyboard[] keyboardArray;
	Joystick[] joystickArray;


private:
	global Input mInstance;


public:
	global Input opCall()
	{
		return mInstance;
	}

	final @property Mouse mouse()
	{
		return mouseArray[0];
	}

	final @property Keyboard keyboard()
	{
		return keyboardArray[0];
	}

	final @property Joystick joystick()
	{
		return joystickArray[0];
	}

	Mouse[] mice()
	{
		return new mouseArray[0 .. $];
	}

	Keyboard[] keyboards()
	{
		return new keyboardArray[0 .. $];
	}

	Joystick[] joysticks()
	{
		return new joystickArray[0 .. $];
	}


protected:
	this()
	{
		mInstance = this;
	}
}
