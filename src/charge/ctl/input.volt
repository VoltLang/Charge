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


class Input
{
private:
	global Input instance;
	Mouse[] mouseArray;
	Keyboard[] keyboardArray;
	Joystick[] joystickArray;

public:
	global Input opCall()
	{
		return instance;
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

private:
	this(size_t numJoysticks)
	{
		instance = this;

		keyboardArray ~= new Keyboard();
		mouseArray ~= new Mouse();

		// Small hack to allow hotplug.
		auto num = numJoysticks;
		if (num < 8) {
			num = 8;
		}

		joystickArray = new Joystick[](num);
		foreach (i; 0 .. num) {
			joystickArray[i] = new Joystick(i);
		}
	}

	~this()
	{
/+
		hotplug.destruct();
		resize.destruct();
		quit.destruct();
+/
	}
}
