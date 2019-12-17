// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for CoreSDL.
 *
 * @ingroup core
 */
module charge.core.sdl;
version (!Windows):

import core.exception;
import core.c.stdio : fprintf, fflush, stderr;
import core.c.stdlib : exit;

import io = watt.io;

import watt.conv : toStringz;
import watt.library;
import watt.text.utf;

import lib.gl.gl45;

import gfx = charge.gfx;

import charge.core;
import charge.gfx.gl;
import charge.gfx.gfx;
import charge.gfx.target;
import charge.ctl.input;
import charge.ctl.mouse;
import charge.ctl.keyboard;
import charge.ctl.joystick;
import charge.sys.resource;
import charge.sys.memheader;
import charge.core.common;
import charge.util.properties;

import lib.sdl2;
import lib.gl.loader;


/*
 *
 * Exported functions.
 *
 */

@mangledName("chargeStart") fn start(opts: Options) Core
{
	return new CoreSDL(opts);
}

@mangledName("chargeQuit") fn quit()
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

/*!
 * Multi-platform Core based on SDL.
 *
 * @ingroup core
 */
class CoreSDL : CommonCore
{
private:
	opts: Options;

	input: Input;

	title: string;
	screenshotNum: int;
	windowMode: WindowMode;

	noVideo: bool;

	/* surface for window */
	window: SDL_Window*;
	glcontext: SDL_GLContext;

	/* run time libraries */
	glu: Library;
	sdl: Library;

	enum gfxFlags = Flag.GFX | Flag.AUTO;


public:
	this(opts: Options)
	{
		this.opts = opts;
		super(opts.flags);

		if (opts.flags & gfxFlags) {
			initWithGfx();
		} else {
			initWithoutGfx();
		}

		this.input = new InputSDL(0);

		foreach (initFunc; gInitFuncs) {
			initFunc();
		}
	}

	override fn panic(msg: string)
	{
		io.error.writefln("panic");
		io.error.writefln("%s", msg);
		io.error.flush();
		exit(-1);
	}

	override fn getClipboardText() string
	{
		if (!gfxLoaded) {
			return null;
		}
		return null;
	}

	override fn screenShot()
	{
	}

	override fn resize(w: uint, h: uint, mode: WindowMode)
	{
		if (!gfxLoaded) {
			return;
		}

		this.windowMode = mode;
		final switch (mode) with (WindowMode) {
		case Normal:
			SDL_SetWindowSize(window, cast(int)w, cast(int)h);
			SDL_SetWindowFullscreen(window, 0);
			SDL_SetWindowBordered(window, true);
			version (Windows) SDL_SetWindowResizable(window, true);
			break;
		case FullscreenDesktop:
			SDL_SetWindowFullscreen(window,
				SDL_WINDOW_FULLSCREEN_DESKTOP);
			break;
		case Fullscreen:
			// TODO add ways to get modes.
			SDL_SetWindowSize(window, cast(int)w, cast(int)h);
			SDL_SetWindowFullscreen(window,
				SDL_WINDOW_FULLSCREEN);
			break;
		}

		t := DefaultTarget.opCall();
		t.width = w;
		t.height = h;
	}

	override fn size(out w: uint, out h: uint, out mode: WindowMode)
	{
		if (!gfxLoaded) {
			return;
		}

		t := DefaultTarget.opCall();
		w = t.width;
		h = t.height;
		mode = this.windowMode;
	}


protected:
	override fn getTicks() long
	{
		return SDL_GetTicks();
	}

	override fn doInput()
	{
		e: SDL_Event;

		SDL_JoystickUpdate();

		while(SDL_PollEvent(&e)) {
			switch (e.type) {
			case SDL_QUIT:
				mRunning = false;
				break;

			case SDL_WINDOWEVENT:
				switch (e.window.event) {
				case SDL_WINDOWEVENT_RESIZED:
					auto t = DefaultTarget.opCall();
					t.width = cast(uint)e.window.data1;
					t.height = cast(uint)e.window.data2;
					break;
				default:
				}
				break;

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
				j := cast(JoystickSDL)input.joystickArray[e.jbutton.which];
				j.handleEvent(ref e);
				break;

			case SDL_TEXTEDITING:
				i: size_t;
				for (; i < e.edit.text.length && e.edit.text[i]; i++) {}

				// Noop for now.
				break;

			case SDL_TEXTINPUT:
				i: size_t;
				for (; i < e.text.text.length && e.text.text[i]; i++) {}

				k := input.keyboard;
				if (k.text is null) {
					break;
				}
				k.text(k, e.text.text[0 .. i]);
				break;

			case SDL_KEYDOWN:
				k := input.keyboard;
				//k.mod = e.key.keysym.mod;

				if (k.down is null) {
					break;
				}
				k.down(k, e.key.keysym.sym);
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

	override fn doRenderAndSwap()
	{
		t := gfx.DefaultTarget.opCall();
		t.bindDefault();

		// Only info we have is that it's suitable for ortho.
		viewInfo: gfx.ViewInfo;
		viewInfo.suitableForOrtho = true;

		renderDg(t, ref viewInfo);
		SDL_GL_SwapWindow(window);
	}

	override fn doSleep(diff: long)
	{
		SDL_Delay(cast(uint)diff);
	}

	override fn doClose()
	{
		closeDg();

		foreach (closeFunc; gCloseFuncs) {
			closeFunc();
		}

		saveSettings();

		p := Pool.opCall();
		p.collect();

		closeSfx();
		closePhy();

		if (opts.flags & gfxFlags) {
			closeWithGfx();
		} else {
			closeWithoutGfx();
		}

		p.cleanAndLeakCheck(io.output.write);
		cMemoryPrintAll(io.output.write);
		io.output.flush();
	}


private:
	/*
	 *
	 * Init and close functions without gfx.
	 *
	 */


	fn initWithoutGfx()
	{
		SDL_Init(0);
	}

	fn closeWithoutGfx()
	{
		SDL_Quit();
		noVideo = false;
	}


	/*
	 *
	 * Init and close functions with gfx.
	 *
	 */

	fn initWithGfx()
	{
		SDL_Init(cast(uint)(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK));

		width := opts.width;
		height := opts.height;
		windowMode = opts.windowMode;
		title := opts.title.toStringz();

		if (opts.openglDebug) {
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS,
			                    SDL_GL_CONTEXT_DEBUG_FLAG);
		}
		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
		SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
		SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

		bits: uint = SDL_WINDOW_OPENGL;
		final switch (windowMode) with (WindowMode) {
		case Normal:
			bits |= SDL_WINDOW_RESIZABLE;
			break;
		case FullscreenDesktop:
			bits |= SDL_WINDOW_FULLSCREEN_DESKTOP;
			break;
		case Fullscreen:
			// TODO add ways to get modes.
			bits |= SDL_WINDOW_FULLSCREEN;
			break;
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

			if (GL_VERSION_4_5 && opts.openglDebug) {
				glDebugMessageCallback(glDebug, cast(void*)this);
			}

			runDetection();
			printDetection();
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

	fn closeWithGfx()
	{
		DefaultTarget.close();

		SDL_Quit();
		gfxLoaded = false;
	}

	fn createCoreGL(major: int, minor: int) SDL_GLContext
	{
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, major);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, minor);
		return SDL_GL_CreateContext(window);
	}

	fn loadFunc(c: string) void*
	{
		return SDL_GL_GetProcAddress(toStringz(c));
	}

	global extern(C) fn glDebug(source: GLuint, type: GLenum, id: GLenum,
	                            severity: GLenum, length: GLsizei,
	                            msg: const(GLchar*), data: GLvoid*)
	{
		fprintf(stderr, "#OGL# %.*s\n", length, msg);
		fflush(stderr);
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

	final fn handleEvent(ref e: SDL_Event)
	{
		handleAxis(e.jaxis.axis, e.jaxis.value);
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
