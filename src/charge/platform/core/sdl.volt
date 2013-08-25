// Copyright © 2011-2013, Jakob Bornecrantz.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for CoreSDL.
 */
module charge.platform.core.sdl;

import core.stdc.stdio : printf;
import core.stdc.stdlib : exit;

import charge.core;
import charge.util.properties;
import charge.platform.core.common;

import watt.library;
import lib.sdl.sdl;
import lib.sdl.loader;
import lib.gles;
import lib.gles.loader;

version (Emscripten) {
	extern(C) void emscripten_set_main_loop(void function(), int fps, int infloop);
	extern(C) void emscripten_cancel_main_loop();
}

extern(C) Core chargeCore(CoreOptions opts)
{
	return new CoreSDL(opts);
}

extern(C) void chargeQuit()
{
	// If SDL haven't been loaded yet.
	version (DynamicSDL) {
		if (SDL_PushEvent is null)
			return;
	}

	SDL_Event event;
	event.type = SDL_QUIT;
	SDL_PushEvent(&event);

	return;
}

class CoreSDL : CommonCore
{
private:
	CoreOptions opts;

	string title;
	int screenshotNum;
	uint width, height; //< Current size of the main window
	bool fullscreen; //< Should we be fullscreen
	bool fullscreenAutoSize; //< Only used at start

	bool initedGfx;
	bool initedNoGfx;

	/* surface for window */
	SDL_Surface *s;

	/* run time libraries */
	Library glu;
	Library sdl;


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
		super(opts.flags);

		loadLibraries();

		if (opts.flags & gfxFlags) {
			initGfx(p);
		} else {
			initNoGfx(p);
		}

		for (size_t i; i < initFuncs.length; i++)
			initFuncs[i]();

		return;
	}

	void close()
	{
		if (closeDg !is null)
			closeDg();

		for (size_t i; i < closeFuncs.length; i++)
			closeFuncs[i]();

		saveSettings();

/+
		Pool().clean();
+/

		closeSfx();
		closePhy();

		if (initedGfx) {
			closeGfx();
		}
		if (initedNoGfx) {
			closeNoGfx();
		}

		return;
	}

	override void panic(string msg)
	{
		printf("panic\n".ptr);
		exit(-1);
	}

	override string getClipboardText()
	{
		if (initedGfx)
			throw new Exception("Gfx not initd!");
		return null;
	}

	override void screenShot()
	{
		if (initedGfx)
			throw new Exception("Gfx not initd!");
		return;
	}

	override void resize(uint w, uint h)
	{
		this.resize(w, h, fullscreen);
		return;
	}

	override void resize(uint w, uint h, bool fullscreen)
	{
		if (!resizeSupported)
			return;

		if (initedGfx)
			throw new Exception("Gfx not initd!");
		return;
	}

	override void size(out uint w, out uint h, out bool fullscreen)
	{
		if (!initedGfx)
			throw new Exception("Gfx not initd!");

		w = this.width;
		h = this.height;
		fullscreen = this.fullscreen;
		return;
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

		return;
	}

	override int loop()
	{
		emscripten_set_main_loop(loopCb, 0, 0);
		return -1;
	}

} else {

	override int loop()
	{
		int keypress = 0;
		SDL_Event event;
		while (!keypress) {
			while (SDL_PollEvent(&event)) {
				if (cast(int)event.type == SDL_QUIT) {
					keypress = 1;
				} else if (cast(int)event.type == SDL_KEYDOWN) {
					keypress = 1;
				}
			}
			if (renderDg !is null) {
				renderDg();
			}
		}

		close();

		return 0;
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
			if (sdl is null)
				printf("Could not load SDL, crashing bye bye!\n".ptr);
			loadSDL(sdl.symbol);
		}
		return;
	}


	/*
	 *
	 * Init and close functions for subsystems
	 *
	 */


	void initNoGfx(Properties p)
	{
		initedNoGfx = true;
		SDL_Init(SDL_INIT_JOYSTICK);
		return;
	}

	void closeNoGfx()
	{
		if (!initedNoGfx)
			return;

		SDL_Quit();
		initedNoGfx = false;
		return;
	}

	void initGfx(Properties p)
	{
		SDL_Init(cast(uint)(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK));

		SDL_EnableUNICODE(1);

		width = 800;//p.getUint("w", defaultWidth);
		height = 600;//p.getUint("h", defaultHeight);
		fullscreen = false;//p.getBool("fullscreen", defaultFullscreen);
		fullscreenAutoSize = true;//p.getBool("fullscreenAutoSize", defaultFullscreenAutoSize);
		auto title = "Charge".ptr;

		SDL_WM_SetCaption(title, title);

		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

		int bits = SDL_OPENGL;
		if (resizeSupported)
 			bits |= SDL_RESIZABLE;
		if (fullscreen)
			bits |= SDL_FULLSCREEN;
		if (fullscreen && fullscreenAutoSize)
			width = height = 0;
		version (Emscripten)
			bits = 0x04000000; // Emscripten is SDL1.3

		//l.bug("w: ", width, " h: ", height);

		s = SDL_SetVideoMode(
				cast(int)width,
				cast(int)height,
				0,
				cast(uint)bits
			);

		// Readback size
		width = cast(uint)s.w;
		height = cast(uint)s.h;

		gladLoadGLES2(SDL_GL_GetProcAddress);

		printf("%s\n".ptr, glGetString(GL_VENDOR));
		printf("%s\n".ptr, glGetString(GL_VERSION));
		printf("%s\n".ptr, glGetString(GL_RENDERER));

/+
		auto numSticks = SDL_NumJoysticks();
		
		if (numSticks != 0)
			l.info("Found %s joystick%s", numSticks, numSticks != 1 ? "s" : "");
		else
			l.info("No joysticks found");
		for(int i; i < numSticks; i++)
			l.info("   %s", .toString(SDL_JoystickName(i)));
+/

/+
		// Check for minimum version.
		if (!GL_VERSION_2_1)
			panic(format("OpenGL 2.1 not supported, can not run %s", opts.title));

		if (!Renderer.init())
			panic(format("Missing graphics features, can not run %s", opts.title));
+/
		initedGfx = true;
		return;
	}

	void closeGfx()
	{
		if (!initedGfx)
			return;

		SDL_Quit();
		initedGfx = false;
		return;
	}

	void* loadFunc(string c)
	{
		return SDL_GL_GetProcAddress(c.ptr);
	}
}
