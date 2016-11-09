// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/**
 * Source file for Mouse.
 */
module charge.ctl.mouse;

import lib.sdl2.mouse;

import charge.ctl.device;


class Mouse : Device
{
public:
	u32 state; /**< Mask of button state, 1 == pressed */
	int x;
	int y;

	void delegate(Mouse, int, int) move;
	void delegate(Mouse, int) down;
	void delegate(Mouse, int) up;

public:
	void setRelativeMode(bool value)
	{
		SDL_SetRelativeMouseMode(value);
	}

	bool getRelativeMode()
	{
		return cast(bool)SDL_GetRelativeMouseMode();
	}
}
