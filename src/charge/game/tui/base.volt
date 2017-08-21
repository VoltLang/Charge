// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.game.tui.base;

import charge.game.tui.grid;


/*!
 * Base class for all text-user-interface objects.
 */
abstract class Base
{
public:
	width, height: u32;


public:
	abstract fn put(grid: Grid, x: i32, y: i32);
}
