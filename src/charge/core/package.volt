// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file containing Core and CoreOptions.
 */
module charge.core;


/**
 * Enum for selecting subsystems.
 */
enum coreFlag
{
	CTL  = (1 << 0),
	GFX  = (1 << 1),
	SFX  = (1 << 2),
	NET  = (1 << 3),
	PHY  = (1 << 4),
	AUTO = (1 << 5),
}

enum coreWindow
{
	Normal,
	Borderless,
	FullscreenDesktop,
	Fullscreen,
}

/**
 * Get a new core created with the given flags.
 */
extern(C) fn chargeCore(opts: CoreOptions) Core;

/**
 * Signal a quit a condition, this function mearly pushes
 * a quit event on the event queue and then returns.
 */
extern(C) fn chargeQuit();

/**
 * Options at initialization.
 */
class CoreOptions
{
public:
	width: uint;
	height: uint;
	title: string;
	flags: coreFlag;
	windowMode: coreWindow;
	openglDebug: bool;


public:
	this()
	{
		this.width = Core.defaultWidth;
		this.height = Core.defaultHeight;
		this.flags = coreFlag.AUTO;
		this.title = Core.defaultTitle;
		this.windowMode = Core.defaultWindow;
	}
}

/**
 * Class holding the entire thing together.
 */
abstract class Core
{
public:
	enum uint defaultWidth = 800;
	enum uint defaultHeight = 600;
	enum bool defaultFullscreen = false;
	enum bool defaultFullscreenAutoSize = true;
	enum string defaultTitle = "Charge Game Engine";
	enum bool defaultForceResizeEnable = false;
	enum coreWindow defaultWindow = coreWindow.Normal;

	flags: coreFlag;
	resizeSupported: bool;

protected:
	static initFuncs: fn()[] ;
	static closeFuncs: fn()[] ;


private:
	global instance: Core;

public:
	/**
	 * Return the current core.
	 */
	global fn get() Core { return instance; }

	/**
	 * Sets callback functions.
	 * @{
	 */
	abstract fn setRender(dgt: dg());
	abstract fn setLogic(dgt: dg());
	abstract fn setClose(dgt: dg());
	abstract fn setIdle(dgt: dg(long));
	/**
	 * @}
	 */

	/**
	 * Main loop functions, you should expect that this function returns.
	 * Best usage is if you in your main function do this "return c.loop();".
	 */
	abstract fn loop() int;

	/**
	 * Initialize a subsystem. Only a single subsystem can be initialized
	 * a time. Will throw Exception upon failure.
	 *
	 * XXX: Most Cores are bit picky when it comes which subsystems can be
	 * initialized after a general initialization, generally speaking
	 * SFX and PHY should always work.
	 */
	abstract fn initSubSystem(flags: coreFlag);

	/**
	 * These functions are run just after Core is initialize and
	 * right before Core is closed.
	 */
	global fn addInitAndCloseRunners(init: fn(), close: fn())
	{
		if (init !is null) {
			initFuncs ~= init;
		}

		if (close !is null) {
			closeFuncs ~= close;
		}
	}

	/**
	 * Display a panic message, usually a dialogue box, then
	 * calls exit(-1), so this function does not return.
	 */
	abstract fn panic(message: string);


	/*
	 *
	 * Misc
	 *
	 */


	/**
	 * Returns text from the clipboard, should any be in it.
	 */
	abstract fn getClipboardText() string;

	abstract fn resize(w: uint, h: uint, mode: coreWindow);
	abstract fn size(out w: uint, out h: uint, out mode: coreWindow);

	abstract fn screenShot();


protected:
	this(coreFlag flags)
	{
		this.flags = flags;
		instance = this;
	}
}
