// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file containing @ref Core and @ref Options.
 *
 * @ingroup core
 */
module charge.core;

import gfx = charge.gfx;


/*!
 * @defgroup core Core
 * @brief Main thing that holds everything together.
 */

/*!
 * Enum for selecting subsystems.
 *
 * @ingroup core
 */
enum Flag
{
	CTL  = (1 << 0),
	GFX  = (1 << 1),
	SFX  = (1 << 2),
	NET  = (1 << 3),
	PHY  = (1 << 4),
	AUTO = (1 << 5),
}

/*!
 * Enum for selecting window mode.
 *
 * @ingroup core
 */
enum WindowMode
{
	Normal,
	FullscreenDesktop,
	Fullscreen,
}

/*!
 * Get a new core created with the given flags.
 *
 * @ingroup core
 */
@mangledName("chargeStart") fn start(opts: Options) Core;

/*!
 * Signal a quit a condition, this function mearly pushes
 * a quit event on the event queue and then returns.
 *
 * @ingroup core
 */
@mangledName("chargeQuit") fn quit();

/*!
 * Return the current core.
 *
 * @ingroup core
 */
@mangledName("chargeGet") fn get() Core;

/*!
 * These functions are run just after Core is initialize and
 * right before Core is closed.
 *
 * @ingroup core
 */
fn addInitAndCloseRunners(init: fn(), close: fn())
{
	if (init !is null) {
		Core.gInitFuncs ~= init;
	}

	if (close !is null) {
		Core.gCloseFuncs ~= close;
	}
}

/*!
 * Options at initialization.
 *
 * @ingroup core
 */
class Options
{
public:
	width: uint;
	height: uint;
	title: string;
	flags: Flag;
	windowMode: WindowMode;
	openglDebug: bool;


public:
	this()
	{
		this.width = Core.DefaultWidth;
		this.height = Core.DefaultHeight;
		this.flags = Flag.AUTO;
		this.title = Core.DefaultTitle;
		this.windowMode = Core.DefaultWindowMode;
	}
}

/*!
 * Class holding the entire thing together.
 *
 * @ingroup core
 */
abstract class Core
{
public:
	enum DefaultWidth : u32 = 800u;
	enum DefaultHeight : u32 = 600u;
	enum DefaultFullscreen : bool = false;
	enum DefaultFullscreenAutoSize : bool = true;
	enum DefaultTitle : string = "Charge Game Engine";
	enum DefaultForceResizeEnable : bool = false;
	enum DefaultWindowMode : WindowMode = WindowMode.Normal;


public:
	flags: Flag;
	resizeSupported: bool;
	verbosePrinting: bool;


protected:
	global gInitFuncs: fn()[];
	global gCloseFuncs: fn()[];


public:
	/*!
	 * Sets callback functions.
	 * @{
	 */
	abstract fn setUpdateActions(dgt: dg(i64));
	abstract fn setLogic(dgt: dg());
	abstract fn setRender(dgt: dg(gfx.Target, ref gfx.ViewInfo));
	abstract fn setClose(dgt: dg());
	abstract fn setIdle(dgt: dg(i64));
	/*!
	 * @}
	 */

	/*!
	 * Main loop functions, you should expect that this function returns.
	 * Best usage is if you in your main function do this "return c.loop();".
	 */
	abstract fn loop() int;

	/*!
	 * Display a panic message, usually a dialogue box, then
	 * calls exit(-1), so this function does not return.
	 */
	abstract fn panic(message: string);


	/*
	 *
	 * Misc
	 *
	 */


	/*!
	 * Returns text from the clipboard, should any be in it.
	 */
	abstract fn getClipboardText() string;

	abstract fn resize(w: uint, h: uint, mode: WindowMode);
	abstract fn size(out w: uint, out h: uint, out mode: WindowMode);

	abstract fn screenShot();


protected:
	this(flags: Flag)
	{
		this.flags = flags;
	}
}
