// Copyright © 2012-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/**
 * Source file for Joystick.
 */
module charge.ctl.joystick;

import charge.ctl.device;


abstract class Joystick : Device
{
public:
	i32[32] axisValues;

	void delegate(Joystick, i32, i32) axis;
	void delegate(Joystick, i32) down;
	void delegate(Joystick, i32) up;


public:
	final bool enable() { return enabled = true; }
	final void disable() { enabled = false; }

	@property abstract bool enabled(bool status);
	@property abstract bool enabled();


protected:
	void handleAxis(size_t which, i16 value)
	{
		if (which >= axisValues.length) {
			return;
		}
		if (value == axisValues[which]) {
			return;
		}

		axisValues[which] = value;

		if (axis is null) {
			return;
		}
		axis(this, cast(int)which, cast(int)value);
	}
}
