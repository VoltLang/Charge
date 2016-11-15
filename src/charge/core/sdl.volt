// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for CoreSDL.
 */
module charge.core.sdl;

import core.exception;
import core.stdc.stdio : printf;
import core.stdc.stdlib : exit;

import watt.conv : toStringz;
import watt.library;
import watt.text.utf;

import charge.core;
import charge.gfx.gfx;
import charge.gfx.target;
import charge.ctl.input;
import charge.ctl.mouse;
import charge.ctl.keyboard;
import charge.ctl.joystick;
import charge.core.common;
import charge.util.properties;

import lib.sdl2;
import lib.gl;
import lib.gl.loader;

version (Emscripten) {
	extern(C) fn emscripten_set_main_loop(fn(), fps: int, infloop: int);
	extern(C) fn emscripten_cancel_main_loop();
}


/*
 *
 * Exported functions.
 *
 */

extern(C) fn chargeCore(opts: CoreOptions) Core
{
	return new CoreSDL(opts);
}

extern(C) fn chargeQuit()
{
	// If SDL haven't been loaded yet.
	version (!StaticSDL) {
		if (SDL_PushEvent is null) {
			return;
		}
	}

	event: SDL_Event;
	event.type = SDL_QUIT;
	SDL_PushEvent(&event);
}

class CoreSDL : CommonCore
{
private:
	opts: CoreOptions;

	input: Input;

	title: string;
	screenshotNum: int;
	fullscreen: bool; //< Should we be fullscreen
	fullscreenAutoSize: bool; //< Only used at start

	noVideo: bool;

	/* surface for window */
	window: SDL_Window*;
	glcontext: SDL_GLContext;

	/* run time libraries */
	glu: Library;
	sdl: Library;

	running: bool;

	/* name of libraries to load */
	version (Windows) {
		enum string[] libSDLname = ["SDL.dll"];
		enum string[] libGLUname = ["glu32.dll"];
	} else version (Linux) {
		enum string[] libSDLname = ["libSDL.so", "libSDL-1.2.so.0"];
		enum string[] libGLUname = ["libGLU.so", "libGLU.so.1"];
	} else version (OSX) {
		enum string[] libSDLname = ["SDL.framework/SDL"];
		enum string[] libGLUname = ["OpenGL.framework/OpenGL"];
	} else version (!StaticSDL) {
		static assert(false);
	}

	enum gfxFlags = coreFlag.GFX | coreFlag.AUTO;

public:
	this(opts: CoreOptions)
	{
		this.opts = opts;
		this.running = true;
		super(opts.flags);

		loadLibraries();

		if (opts.flags & gfxFlags) {
			initGfx();
		} else {
			initNoGfx();
		}

		this.input = new InputSDL(0);

		foreach (initFunc; initFuncs) {
			initFunc();
		}
	}

	fn close()
	{
		if (closeDg !is null) {
			closeDg();
		}

		foreach (closeFunc; closeFuncs) {
			closeFunc();
		}

		saveSettings();

/+
		Pool().clean();
+/

		closeSfx();
		closePhy();

		if (gfxLoaded) {
			closeGfx();
		}
		if (noVideo) {
			closeNoGfx();
		}
	}

	override fn panic(msg: string)
	{
		printf("panic\n".ptr);
		exit(-1);
	}

	override fn getClipboardText() string
	{
		if (gfxLoaded)
			throw new Exception("Gfx not initd!");
		return null;
	}

	override fn screenShot()
	{
		if (gfxLoaded) {
			throw new Exception("Gfx not initd!");
		}
	}

	override fn resize(w: uint, h: uint)
	{
		this.resize(w, h, fullscreen);
	}

	override fn resize(w: uint, h: uint, fullscreen: bool)
	{
		if (!resizeSupported) {
			return;
		}

		if (gfxLoaded) {
			throw new Exception("Gfx not initd!");
		}
	}

	override fn size(out w: uint, out h: uint, out fullscreen: bool)
	{
		if (!gfxLoaded) {
			throw new Exception("Gfx not initd!");
		}

		t := DefaultTarget.opCall();
		w = t.width;
		h = t.height;
		fullscreen = this.fullscreen;
	}


	/*
	 *
	 * Main loop.
	 *
	 */


version (Emscripten) {

	extern(C) global fn loopCb()
	{
		event: SDL_Event;
		quitSet: bool;

		while (SDL_PollEvent(&event)) {
			if (cast(int)event.type == SDL_QUIT) {
				quitSet = true;
				break;
			} else if (cast(int)event.type == SDL_KEYDOWN) {
				quitSet = true;
				break;
			}
		}

		if (quitSet) {
			emscripten_cancel_main_loop();
			(cast(CoreSDL)instance).close();
			return;
		}

		if (instance.renderDg !is null) {
			instance.renderDg();
			SDL_GL_SwapWindow(window);
		}
	}

	override fn loop() int
	{
		emscripten_set_main_loop(loopCb, 0, 0);
		return -1;
	}

} else {

	override fn loop() int
	{
		now: long = SDL_GetTicks();
		step: long = 10;
		where: long = now;
		last: long = now;

		keypress: int = 0;

		changed: bool; //< Tracks if should render
		while (running) {
			now = SDL_GetTicks();

			doInput();

			while (where < now) {
				doInput();
				logicDg();

				where = where + step;
				changed = true;
			}

			if (changed) {
				renderDg();
				SDL_GL_SwapWindow(window);
				changed = true;
			}

			diff := (step + where) - now;
			idleDg(diff);

			// Do the sleep now if there is time left.
			diff = (step + where) - SDL_GetTicks();
			if (diff > 0) {
				SDL_Delay(cast(uint)diff);
			}
		}

		close();

		return 0;
	}

	fn doInput()
	{
		e: SDL_Event;

		SDL_JoystickUpdate();

		while(SDL_PollEvent(&e)) {
			switch (e.type) {
			case SDL_QUIT:
				running = false;
				break;

/*
			case SDL_VIDEORESIZE:
				auto t = DefaultTarget.opCall();
				t.width = cast(uint)e.resize.w;
				t.height = cast(uint)e.resize.h;
				break;
*/

			case SDL_JOYBUTTONDOWN:
				j := input.joystickArray[e.jbutton.which];
				if (j.down is null) {
					break;
				}
				j.down(j, e.jbutton.button);
				break;

			case SDL_JOYBUTTONUP:
				j := input.joystickArray[e.jbutton.which];
				if (j.up is null) {
					break;
				}
				j.up(j, e.jbutton.button);
				break;

			case SDL_JOYAXISMOTION:
				j := input.joystickArray[e.jbutton.which];
				j.handleAxis(e.jaxis.axis, e.jaxis.value);
				break;

			case SDL_KEYDOWN:
				k := input.keyboard;
				//k.mod = e.key.keysym.mod;

				if (k.down is null) {
					break;
				}
				k.down(k, e.key.keysym.sym, 0, null);
				break;

			case SDL_KEYUP:
				k := input.keyboard;
				//k.mod = e.key.keysym.mod;

				if (k.up is null) {
					break;
				}
				k.up(k, e.key.keysym.sym);
				break;

			case SDL_MOUSEMOTION:
				m := input.mouse;
				m.state = e.motion.state;
				m.x = e.motion.x;
				m.y = e.motion.y;

				if (m.move is null) {
					break;
				}
				m.move(m, e.motion.xrel, e.motion.yrel);
				break;

			case SDL_MOUSEBUTTONDOWN:
				m := input.mouse;
				m.state |= cast(u32)(1 << e.button.button);
				m.x = e.button.x;
				m.y = e.button.y;

				if (m.move is null) {
					break;
				}
				m.down(m, e.button.button);
				break;

			case SDL_MOUSEBUTTONUP:
				m := input.mouse;
				m.state = cast(u32)~(1 << e.button.button) & m.state;
				m.x = e.button.x;
				m.y = e.button.y;

				if (m.up is null) {
					break;
				}
				m.up(m, e.button.button);
				break;

			default:
				break;
			}
		}
	}
}

private:
	/*
	 *
	 * Init and close functions
	 *
	 */

	fn loadLibraries()
	{
/*
		version (!StaticSDL) {
			version (OSX) {
/+
				string[] libSDLnames = [privateFrameworksPath ~ "/" ~ libSDLname[0]] ~ libSDLname;
+/
				string[] libSDLnames = libSDLname;
			} else {
				string[] libSDLnames = libSDLname;
			}

			sdl = Library.loads(libSDLnames);
			if (sdl is null) {
				printf("Could not load SDL, crashing bye bye!\n");
			}
			loadSDL(sdl.symbol);
		}
*/
	}


	/*
	 *
	 * Init and close functions for subsystems
	 *
	 */


	fn initNoGfx()
	{
		noVideo = true;
		SDL_Init(SDL_INIT_JOYSTICK);
	}

	fn closeNoGfx()
	{
		if (!noVideo) {
			return;
		}

		SDL_Quit();
		noVideo = false;
	}

	fn initGfx()
	{
		SDL_Init(cast(uint)(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK));

		width := opts.width;
		height := opts.height;
		fullscreen = false;//p.getBool("fullscreen", defaultFullscreen);
		fullscreenAutoSize = true;//p.getBool("fullscreenAutoSize", defaultFullscreenAutoSize);
		windowDecorations := opts.windowDecorations;
		title := opts.title.toStringz();

		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
		SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
		SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

		bits: uint = SDL_WINDOW_OPENGL;
		if (resizeSupported) {
 			bits |= SDL_WINDOW_RESIZABLE;
		}
		if (fullscreen) {
			bits |= SDL_WINDOW_FULLSCREEN;
		}
		if (!windowDecorations) {
			bits |= SDL_WINDOW_BORDERLESS;
		}
		if (fullscreen && fullscreenAutoSize) {
			width = height = 0;
		}

		window = SDL_CreateWindow(title,
			SDL_WINDOWPOS_UNDEFINED,
			SDL_WINDOWPOS_UNDEFINED,
			cast(int)width, cast(int)height, bits);

		glcontext = createCoreGL(4, 5);
		if (glcontext is null) {
			glcontext = createCoreGL(3, 3);
		}
		
		if (glcontext !is null) {
			gladLoadGL(loadFunc);
			gfxLoaded = true;

			printf("%s\n".ptr, glGetString(GL_VENDOR));
			printf("%s\n".ptr, glGetString(GL_VERSION));
			printf("%s\n".ptr, glGetString(GL_RENDERER));
		}

		// Readback size
		w, h: int;
		t := DefaultTarget.opCall();
		SDL_GetWindowSize(window, &w, &h);
		t.width = cast(uint)w;
		t.height = cast(uint)h;

/+
		auto numSticks = SDL_NumJoysticks();
		
		if (numSticks != 0) {
			l.info("Found %s joystick%s", numSticks, numSticks != 1 ? "s" : "");
		} else {
			l.info("No joysticks found");
		}
		for(int i; i < numSticks; i++) {
			l.info("   %s", .toString(SDL_JoystickName(i)));
		}
+/
	}

	fn createCoreGL(major: int, minor: int) SDL_GLContext
	{
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, major);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, minor);
		return SDL_GL_CreateContext(window);
	}

	fn closeGfx()
	{
		if (!gfxLoaded) {
			return;
		}

		DefaultTarget.close();

		SDL_Quit();
		gfxLoaded = false;
	}

	fn loadFunc(c: string) void*
	{
		return SDL_GL_GetProcAddress(toStringz(c));
	}
}


class InputSDL : Input
{
public:
	this(size_t numJoysticks)
	{
		super();

		keyboardArray ~= new KeyboardSDL();
		mouseArray ~= new MouseSDL();

		// Small hack to allow hotplug.
		num := numJoysticks;
		if (num < 8) {
			num = 8;
		}

		joystickArray = new Joystick[](num);
		foreach (i; 0 .. num) {
			joystickArray[i] = new JoystickSDL(i);
		}
	}
}

class MouseSDL : Mouse
{
public:
	this()
	{

	}

	override fn setRelativeMode(value: bool)
	{
		SDL_SetRelativeMouseMode(value);
	}

	override fn getRelativeMode() bool
	{
		return cast(bool)SDL_GetRelativeMouseMode();
	}
}

class KeyboardSDL : Keyboard
{

}

class JoystickSDL : Joystick
{
private:
	mId: size_t;
	mStick: SDL_Joystick*;


public:
	this(size_t id)
	{
		mId = id;
	}

	@property override fn enabled(status: bool) bool
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

	@property override fn enabled() bool
	{
		return mStick !is null;
	}
}
