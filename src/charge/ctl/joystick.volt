// Copyright © 2012-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/**
 * Source file for Joystick.
 */
module charge.ctl.joystick;

import lib.sdl2.joystick;

import charge.ctl.device;


class Joystick : Device
{
public:
	i32[32] axisValues;

	void delegate(Joystick, i32, i32) axis;
	void delegate(Joystick, i32) down;
	void delegate(Joystick, i32) up;

private:
	size_t mId;
	SDL_Joystick* mStick;


public:
	final bool enable() { return enabled = true; }
	final void disable() { enabled = false; }

	@property final bool enabled(bool status)
	{
		if (status) {
			if (mStick is null) {
				mStick = SDL_JoystickOpen(cast(int)mId);
			}
		} else {
			if (mStick !is null) {
				SDL_JoystickClose(mStick);
				mStick = null;
			}
		}
		return enabled;
	}

	@property final bool enabled()
	{
		return mStick !is null;
	}

protected:
	this(size_t id)
	{
		mId = id;
	}

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
