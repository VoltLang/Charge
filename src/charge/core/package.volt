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

/**
 * Get a new core created with the given flags.
 */
extern(C) Core chargeCore(CoreOptions opts);

/**
 * Signal a quit a condition, this function mearly pushes
 * a quit event on the event queue and then returns.
 */
extern(C) void chargeQuit();

/**
 * Options at initialization.
 */
class CoreOptions
{
public:
	uint width;
	uint height;
	string title;
	coreFlag flags;
	bool windowDecorations;

public:
	this()
	{
		this.width = Core.defaultWidth;
		this.height = Core.defaultHeight;
		this.flags = coreFlag.AUTO;
		this.title = Core.defaultTitle;
		this.windowDecorations = Core.defaultWindowDecorations;
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
	enum bool defaultWindowDecorations = true;

	coreFlag flags;
	bool resizeSupported;

protected:
	static void function()[] initFuncs;
	static void function()[] closeFuncs;


private:
	global Core instance;

public:
	/**
	 * Sets callback functions.
	 * @{
	 */
	abstract void setRender(void delegate() dgt);
	abstract void setLogic(void delegate() dgt);
	abstract void setClose(void delegate() dgt);
	abstract void setIdle(void delegate(long) dgt);
	/**
	 * @}
	 */

	/**
	 * Main loop functions, you should expect that this function returns.
	 * Best usage is if you in your main function do this "return c.loop();".
	 */
	abstract int loop();

	/**
	 * Initialize a subsystem. Only a single subsystem can be initialized
	 * a time. Will throw Exception upon failure.
	 *
	 * XXX: Most Cores are bit picky when it comes which subsystems can be
	 * initialized after a general initialization, generally speaking
	 * SFX and PHY should always work.
	 */
	abstract void initSubSystem(coreFlag flags);

	/**
	 * These functions are run just after Core is initialize and
	 * right before Core is closed.
	 */
	global void addInitAndCloseRunners(void function() init, void function() close)
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
	abstract void panic(string message);


	/*
	 *
	 * Misc
	 *
	 */


	/**
	 * Returns text from the clipboard, should any be in it.
	 */
	abstract string getClipboardText();

	abstract void resize(uint w, uint h);
	abstract void resize(uint w, uint h, bool fullscreen);
	abstract void size(out uint w, out uint h, out bool fullscreen);

	abstract void screenShot();


protected:
	this(coreFlag flags)
	{
		this.flags = flags;
		instance = this;
	}
}