// Copyright © 2012-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/**
 * Source file for Joystick.
 */
module charge.ctl.joystick;

import lib.sdl.sdl;

import charge.ctl.device;


class Joystick : Device
{
public:
	void delegate(Joystick, int, int) axis;
	void delegate(Joystick, int) down;
	void delegate(Joystick, int) up;

private:
	int id;
	Sint16[32] axisValues;
	SDL_Joystick* stick;

public:
	final bool enable() { return enabled = true; }
	final void disable() { enabled = false; }

	@property final bool enabled(bool status)
	{
		if (status) {
			if (stick is null) {
				stick = SDL_JoystickOpen(id);
			}
		} else {
			if (stick !is null) {
				SDL_JoystickClose(stick);
				stick = null;
			}
		}
		return enabled;
	}

	@property final bool enabled()
	{
		return stick !is null;
	}

package:
	this(int id)
	{
		this.id = id;
	}

	void handleAxis(size_t which, short value)
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
