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
	extern(C) void emscripten_set_main_loop(void function(), int fps, int infloop);
	extern(C) void emscripten_cancel_main_loop();
}


/*
 *
 * Exported functions.
 *
 */

extern(C) Core chargeCore(CoreOptions opts)
{
	return new CoreSDL(opts);
}

extern(C) void chargeQuit()
{
	// If SDL haven't been loaded yet.
	version (!StaticSDL) {
		if (SDL_PushEvent is null) {
			return;
		}
	}

	SDL_Event event;
	event.type = SDL_QUIT;
	SDL_PushEvent(&event);
}

class CoreSDL : CommonCore
{
private:
	CoreOptions opts;

	Input input;

	string title;
	int screenshotNum;
	bool fullscreen; //< Should we be fullscreen
	bool fullscreenAutoSize; //< Only used at start

	bool noVideo;

	/* surface for window */
	SDL_Window* window;
	SDL_GLContext glcontext;

	/* run time libraries */
	Library glu;
	Library sdl;

	bool running;

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
	this(CoreOptions opts)
	{
		this.opts = opts;
		this.running = true;
		super(opts.flags);

		loadLibraries();

		if (opts.flags & gfxFlags) {
			initGfx(p);
		} else {
			initNoGfx(p);
		}

		this.input = new InputSDL(0);

		for (size_t i; i < initFuncs.length; i++) {
			initFuncs[i]();
		}
	}

	void close()
	{
		if (closeDg !is null) {
			closeDg();
		}

		for (size_t i; i < closeFuncs.length; i++)
			closeFuncs[i]();

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

	override void panic(string msg)
	{
		printf("panic\n".ptr);
		exit(-1);
	}

	override string getClipboardText()
	{
		if (gfxLoaded)
			throw new Exception("Gfx not initd!");
		return null;
	}

	override void screenShot()
	{
		if (gfxLoaded) {
			throw new Exception("Gfx not initd!");
		}
	}

	override void resize(uint w, uint h)
	{
		this.resize(w, h, fullscreen);
	}

	override void resize(uint w, uint h, bool fullscreen)
	{
		if (!resizeSupported) {
			return;
		}

		if (gfxLoaded) {
			throw new Exception("Gfx not initd!");
		}
	}

	override void size(out uint w, out uint h, out bool fullscreen)
	{
		if (!gfxLoaded) {
			throw new Exception("Gfx not initd!");
		}

		auto t = DefaultTarget.opCall();
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

	extern(C) global void loopCb()
	{
		SDL_Event event;
		bool quitSet;

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

	override int loop()
	{
		emscripten_set_main_loop(loopCb, 0, 0);
		return -1;
	}

} else {

	override int loop()
	{
		long now = SDL_GetTicks();
		long step = 10;
		long where = now;
		long last = now;

		int keypress = 0;

		bool changed; //< Tracks if should render
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

			long diff = (step + where) - now;
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

	void doInput()
	{
		SDL_Event e;

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
				auto j = input.joystickArray[e.jbutton.which];
				if (j.down is null) {
					break;
				}
				j.down(j, e.jbutton.button);
				break;

			case SDL_JOYBUTTONUP:
				auto j = input.joystickArray[e.jbutton.which];
				if (j.up is null) {
					break;
				}
				j.up(j, e.jbutton.button);
				break;

			case SDL_JOYAXISMOTION:
				auto j = input.joystickArray[e.jbutton.which];
				j.handleAxis(e.jaxis.axis, e.jaxis.value);
				break;

			case SDL_KEYDOWN:
				auto k = input.keyboard;
				//k.mod = e.key.keysym.mod;

				if (k.down is null) {
					break;
				}
				k.down(k, e.key.keysym.sym, 0, null);
				break;

			case SDL_KEYUP:
				auto k = input.keyboard;
				//k.mod = e.key.keysym.mod;

				if (k.up is null) {
					break;
				}
				k.up(k, e.key.keysym.sym);
				break;

			case SDL_MOUSEMOTION:
				auto m = input.mouse;
				m.state = e.motion.state;
				m.x = e.motion.x;
				m.y = e.motion.y;

				if (m.move is null) {
					break;
				}
				m.move(m, e.motion.xrel, e.motion.yrel);
				break;

			case SDL_MOUSEBUTTONDOWN:
				auto m = input.mouse;
				m.state |= cast(u32)(1 << e.button.button);
				m.x = e.button.x;
				m.y = e.button.y;

				if (m.move is null) {
					break;
				}
				m.down(m, e.button.button);
				break;

			case SDL_MOUSEBUTTONUP:
				auto m = input.mouse;
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

	void loadLibraries()
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


	void initNoGfx(Properties p)
	{
		noVideo = true;
		SDL_Init(SDL_INIT_JOYSTICK);
	}

	void closeNoGfx()
	{
		if (!noVideo) {
			return;
		}

		SDL_Quit();
		noVideo = false;
	}

	void initGfx(Properties p)
	{
		SDL_Init(cast(uint)(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK));

		uint width = opts.width;
		uint height = opts.height;
		fullscreen = false;//p.getBool("fullscreen", defaultFullscreen);
		fullscreenAutoSize = true;//p.getBool("fullscreenAutoSize", defaultFullscreenAutoSize);
		bool windowDecorations = opts.windowDecorations;
		auto title = (opts.title ~ "\0").ptr;

		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
		SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
		SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

		uint bits = SDL_WINDOW_OPENGL;
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
		int w, h;
		auto t = DefaultTarget.opCall();
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

	SDL_GLContext createCoreGL(int major, int minor)
	{
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, major);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, minor);
		return SDL_GL_CreateContext(window);
	}

	void closeGfx()
	{
		if (!gfxLoaded) {
			return;
		}

		DefaultTarget.close();

		SDL_Quit();
		gfxLoaded = false;
	}

	void* loadFunc(string c)
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
		auto num = numJoysticks;
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

	override void setRelativeMode(bool value)
	{
		SDL_SetRelativeMouseMode(value);
	}

	override bool getRelativeMode()
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
	size_t mId;
	SDL_Joystick* mStick;


public:
	this(size_t id)
	{
		mId = id;
	}

	@property override bool enabled(bool status)
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

	@property override bool enabled()
	{
		return mStick !is null;
	}
}
