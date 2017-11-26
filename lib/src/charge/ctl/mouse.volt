// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/*!
 * Source file for Mouse.
 */
module charge.ctl.mouse;

import charge.ctl.device;


abstract class Mouse : Device
{
public:
	state: u32; /*!< Mask of button state, 1 == pressed */
	x: int;
	y: int;

	move: dg(Mouse, int, int);
	down: dg(Mouse, int);
	up: dg(Mouse, int);

public:
	abstract fn setRelativeMode(value: bool);
	abstract fn getRelativeMode() bool;
}
