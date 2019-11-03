// Copyright 2012-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for Joystick.
 */
module charge.ctl.joystick;

import charge.ctl.device;


abstract class Joystick : Device
{
public:
	axisValues: i32[32];

	axis: dg(Joystick, i32, i32);
	down: dg(Joystick, i32);
	up: dg(Joystick, i32);


public:
	final fn enable() bool { return enabled = true; }
	final fn disable() { enabled = false; }

	@property abstract fn enabled(status: bool) bool;
	@property abstract fn enabled() bool;


protected:
	fn handleAxis(which: size_t, value: i16)
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
