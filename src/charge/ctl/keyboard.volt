// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver 1.0).
/**
 * Source file for Keyboard.
 */
module charge.ctl.keyboard;

import charge.ctl.device;

import lib.sdl.keysym;


class Keyboard : Device
{
public:
	int mod;

public:
	void delegate(Keyboard, int, dchar, scope char[]) down;
	void delegate(Keyboard, int) up;


public:
	final bool ctrl()
	{
		return (mod & KMOD_CTRL) != 0;
	}

	final bool alt()
	{
		return (mod & KMOD_ALT) != 0;
	}

	final bool meta()
	{
		return (mod & KMOD_META) != 0;
	}

	final bool shift()
	{
		return (mod & KMOD_SHIFT) != 0;
	}
}
