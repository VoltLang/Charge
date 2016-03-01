// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for CoreSDL.
 */
module charge.platform.core.sdl;

import core.stdc.stdio : printf;
import core.stdc.stdlib : exit;

import watt.library;
import watt.text.utf;

import charge.core;
import charge.gfx.gfx;
import charge.gfx.target;
import charge.ctl.input;
import charge.util.properties;
import charge.platform.core.common;

import lib.sdl.sdl;
import lib.sdl.loader;
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
	version (DynamicSDL) {
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
	SDL_Surface *s;

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
	} else version (DynamicSDL) {
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

		this.input = Input.opCall();

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
			SDL_GL_SwapBuffers();
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
				SDL_GL_SwapBuffers();
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

			case SDL_VIDEORESIZE:
				auto t = DefaultTarget.opCall();
				t.width = cast(uint)e.resize.w;
				t.height = cast(uint)e.resize.h;
				break;

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
				k.mod = e.key.keysym.mod;

				// Early out.
				if (k.down is null) {
					break;
				}

				size_t len;
				char[8] tmp;
				dchar unicode = e.key.keysym.unicode;
				if (unicode == 27) {
					unicode = 0;
				}

				void sink(scope const(char)[] t) {
					tmp[0 .. t.length] = t;
					len = t.length;
				}
				if (unicode) {
					encode(sink, unicode);
				}

				k.down(k, e.key.keysym.sym, unicode, tmp[0 .. len]);
				break;

			case SDL_KEYUP:
				auto k = input.keyboard;
				k.mod = e.key.keysym.mod;

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
				m.state |= (1 << e.button.button);
				m.x = e.button.x;
				m.y = e.button.y;

				if (m.move is null) {
					break;
				}
				m.down(m, e.button.button);
				break;

			case SDL_MOUSEBUTTONUP:
				auto m = input.mouse;
				m.state = ~(1 << e.button.button) & m.state;
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
		version (DynamicSDL) {
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

		SDL_EnableUNICODE(1);

		uint width = opts.width;
		uint height = opts.height;
		fullscreen = false;//p.getBool("fullscreen", defaultFullscreen);
		fullscreenAutoSize = true;//p.getBool("fullscreenAutoSize", defaultFullscreenAutoSize);
		bool windowDecorations = opts.windowDecorations;
		auto title = (opts.title ~ "\0").ptr;

		SDL_WM_SetCaption(title, title);

		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

		int bits = SDL_OPENGL;
		if (resizeSupported) {
 			bits |= SDL_RESIZABLE;
		}
		if (fullscreen) {
			bits |= SDL_FULLSCREEN;
		}
		if (!windowDecorations) {
			bits |= SDL_NOFRAME;
		}
		if (fullscreen && fullscreenAutoSize) {
			width = height = 0;
		}
		version (Emscripten) {
			bits = 0x04000000; // Emscripten is SDL1.3
		}

		//l.bug("w: ", width, " h: ", height);

		s = SDL_SetVideoMode(
				cast(int)width,
				cast(int)height,
				0,
				cast(uint)bits
			);

		// Readback size
		auto t = DefaultTarget.opCall();
		t.width = cast(uint)s.w;
		t.height = cast(uint)s.h;

		version (Emscripten) {
			gladLoadGLES2(loadFunc);
		} else {
			gladLoadGL(loadFunc);
		}

		printf("%s\n".ptr, glGetString(GL_VENDOR));
		printf("%s\n".ptr, glGetString(GL_VERSION));
		printf("%s\n".ptr, glGetString(GL_RENDERER));

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

/+
		// Check for minimum version.
		if (!GL_VERSION_2_1) {
			panic(format("OpenGL 2.1 not supported, can not run %s", opts.title));
		}

		if (!Renderer.init()) {
			panic(format("Missing graphics features, can not run %s", opts.title));
		}
+/
		gfxLoaded = true;
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
		return SDL_GL_GetProcAddress(c.ptr);
	}
}
