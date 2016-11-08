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
	bool relativeMode(bool value)
	{
		SDL_SetRelativeMouseMode(value);
		return value;
	}

	bool relativeMode()
	{
		return cast(bool)SDL_GetRelativeMouseMode();
	}

/+
	bool grab(bool status)
	{
		auto mode = status ? SDL_GrabMode.SDL_GRAB_ON : SDL_GrabMode.SDL_GRAB_OFF;
		return SDL_WM_GrabInput(mode) == SDL_GrabMode.SDL_GRAB_ON;
	}

	bool grab()
	{
		auto status = SDL_WM_GrabInput(SDL_GrabMode.SDL_GRAB_QUERY);
		return status == SDL_GrabMode.SDL_GRAB_ON;
	}

	bool show(bool status)
	{
		auto mode = status ? SDL_ENABLE : SDL_DISABLE;
		return SDL_ShowCursor(mode) == SDL_ENABLE;
	}

	bool show()
	{
		return SDL_ShowCursor(SDL_QUERY) == SDL_ENABLE;
	}
+/
}
