// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for CoreWin32.
 */
module charge.core.win32;
version (Windows):

import core.exception;
import core.c.stdio;
import core.c.stdlib;
import core.c.string;
import core.c.windows;

import io = watt.io;
import watt.conv;

import charge.core;
import charge.core.common;
import charge.ctl.input;
import charge.ctl.mouse;
import charge.ctl.keyboard;
import charge.ctl.joystick;
import charge.gfx.gfx;
import charge.gfx.target;

import lib.gl;
import lib.gl.loader;
import lib.sdl2.keycode;
import lib.sdl2.mouse;

extern (Windows) { // TODO: Move to RT.
	fn GetWindowRect(HWND, RECT*) BOOL;
	enum SWP_NOCOPYBITS = 0x0100;
	enum SWP_NOACTIVATE = 0x0010;
	enum GWL_EXSTYLE = -20;
}

private global thisCore: CoreWin32;
extern(C) fn chargeCore(opts: CoreOptions) Core
{
	return new CoreWin32(opts);
}

extern(C) fn chargeQuit()
{
	PostQuitMessage(0);
}

class CoreWin32 : CommonCore
{
private:
	opts: CoreOptions;
	input: Input;
	windowMode: coreWindow;

	hDC: HDC = null;          //< GDI device context.
	hRC: HGLRC = null;        //< Rendering context.
	hWnd: HWND = null;        //< Window handle.
	hInstance: HINSTANCE;     //< Application instance.
	openglDll: HMODULE;       //< Handle to opengl32.dll.

	lastX: i32;  //< The last time we saw the mouse it was at this X.
	lastY: i32;  //< The last time we saw the mouse it was at this Y.

	enum gfxFlags = coreFlag.GFX | coreFlag.AUTO;

public:
	this(opts: CoreOptions)
	{
		super(opts.flags);
		thisCore = this;
		this.opts = opts;

		input = new InputWin32(0);

		if (opts.flags & gfxFlags) {
			initGfx();
		} else {
			assert(false);
		}

		foreach (initFunc; initFuncs) {
			initFunc();
		}
	}

	override fn panic(message: string)
	{
		io.writefln("PANIC: %s", message);
		exit(-1);
	}

	override fn getClipboardText() string
	{
		assert(false);
	}

	override fn resize(w: uint, h: uint, mode: coreWindow)
	{
		STYLE_BASIC :=      (WS_CLIPSIBLINGS | WS_CLIPCHILDREN);
		STYLE_FULLSCREEN := (WS_POPUP);
		STYLE_BORDERLESS := (WS_POPUP);
		STYLE_NORMAL :=     (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX);
		EX_NORMAL :=        (WS_EX_APPWINDOW | WS_EX_WINDOWEDGE);
		EX_BORDERLESS :=    (WS_EX_APPWINDOW);
		STYLE_RESIZABLE :=  (WS_THICKFRAME | WS_MAXIMIZEBOX);
		STYLE_MASK :=       (STYLE_FULLSCREEN | STYLE_BORDERLESS | STYLE_NORMAL | STYLE_RESIZABLE);

		if (windowMode == coreWindow.Fullscreen) {
			ChangeDisplaySettingsA(null, 0);  // Reset the display mode.
		}
		r: RECT;
		fn resetRect()
		{
			r.left = 0;
			r.right = cast(LONG)w;
			r.top = 0;
			r.bottom = cast(LONG)h;
		}
		resetRect();

		final switch (mode) {
		case coreWindow.Normal:
			changeStyle(ref r, STYLE_MASK, STYLE_NORMAL | STYLE_RESIZABLE, EX_NORMAL, true);
			break;
		case coreWindow.FullscreenDesktop:
			w = cast(u32)GetSystemMetrics(SM_CXSCREEN);
			h = cast(u32)GetSystemMetrics(SM_CYSCREEN);
			SetWindowPos(hWnd, null, 0, 0, cast(i32)w, cast(i32)h, 0);
			changeStyle(ref r, STYLE_MASK, STYLE_FULLSCREEN, EX_BORDERLESS, false);
			break;
		case coreWindow.Fullscreen:
			changeDisplayMode(w, h);
			changeStyle(ref r, STYLE_MASK, STYLE_FULLSCREEN, EX_BORDERLESS, true);
			break;
		}
		t := DefaultTarget.opCall();
		t.width = w;
		t.height = h;
		this.windowMode = mode;
	}

	override fn size(out w: uint, out h: uint, out mode: coreWindow)
	{
		if (!gfxLoaded) {
			throw new Exception("Gfx not initd!");
		}

		t := DefaultTarget.opCall();
		w = t.width;
		h = t.height;
		mode = this.windowMode;
	}

	override fn screenShot()
	{
		assert(false);
	}


	/*
	 *
	 * Loop functions from common.
	 *
	 */




protected:
	override fn getTicks() long
	{
		return GetTickCount();
	}

	override fn doInput()
	{
		msg: MSG;
		if (PeekMessageA(&msg, null, 0, 0, PM_REMOVE) != 0) {
			if (msg.message != WM_QUIT) {
				TranslateMessage(&msg);
				DispatchMessageA(&msg);
			} else {
				mRunning = false;
				return;
			}
		}
	}

	override fn doRenderAndSwap()
	{
		renderDg();
		SwapBuffers(hDC);
	}

	override fn doSleep(diff: long)
	{
		Sleep(cast(DWORD)diff);
	}

	override fn doClose()
	{
		if (closeDg !is null) {
			closeDg();
		}
	}


private:
	fn changeDisplayMode(w: u32, h: u32)
	{
			dmScreenSettings: DEVMODE;
			memset(cast(void*)&dmScreenSettings, 0, typeid(DEVMODE).size);
			dmScreenSettings.dmSize = cast(WORD)typeid(DEVMODE).size;
			dmScreenSettings.dmPelsWidth = cast(DWORD)w;
			dmScreenSettings.dmPelsHeight = cast(DWORD)h;
			dmScreenSettings.dmBitsPerPel = 32;
			dmScreenSettings.dmFields = DM_BITSPERPEL | DM_PELSWIDTH | DM_PELSHEIGHT;

			hMonitor := MonitorFromWindow(hWnd, MONITOR_DEFAULTTOPRIMARY);
			moninfo: MONITORINFOEX;
			moninfo.cbSize = cast(DWORD)typeid(MONITORINFOEX).size;
			if (!GetMonitorInfoA(hMonitor, &moninfo)) {
				throw new Exception("failed to get monitor info");
			}

			if (ChangeDisplaySettingsExA(moninfo.szDevice.ptr, &dmScreenSettings, null, CDS_FULLSCREEN, null) != DISP_CHANGE_SUCCESSFUL) {
				throw new Exception("failed to change display mode");
			}
			// Make sure the window is in frame, if the resolution was lowered.
			SetWindowPos(hWnd, null, moninfo.rcMonitor.left, moninfo.rcMonitor.top,
				cast(i32)w, cast(i32)h, 0);
	}

	fn changeStyle(ref r: RECT, remove: DWORD, add: DWORD, exstyle: DWORD, adjust: bool)
	{
		dwStyle := cast(DWORD)GetWindowLongPtrA(hWnd, GWL_STYLE);
		dwStyle &= ~(remove);
		dwStyle |= add;

		SetWindowLongPtrA(hWnd, GWL_STYLE, cast(LONG_PTR)dwStyle);
		SetWindowLongPtrA(hWnd, GWL_EXSTYLE, cast(LONG_PTR)exstyle);

		if (adjust) {
			AdjustWindowRectEx(&r, dwStyle, FALSE, exstyle);
			ww := (r.right - r.left);
			hh := (r.bottom - r.top);
			flags := cast(UINT)SWP_NOMOVE | cast(UINT)SWP_NOACTIVATE | cast(UINT)SWP_NOCOPYBITS | cast(UINT)SWP_FRAMECHANGED;
			SetWindowPos(hWnd, null, 0, 0, ww, hh, flags);
		}
	}

	fn initGfx()
	{
		createGlWindow();

		if (GL_VERSION_4_5 && opts.openglDebug) {
			glDebugMessageCallback(glDebug, cast(void*)this);
		}

		printf("%s\n".ptr, glGetString(GL_VENDOR));
		printf("%s\n".ptr, glGetString(GL_VERSION));
		printf("%s\n".ptr, glGetString(GL_RENDERER));
	}

	fn createGlWindow()
	{
		title := toStringz(opts.title);
		width := cast(i32)opts.width;
		height := cast(i32)opts.height;
		windowMode = this.windowMode;
		if (windowMode == coreWindow.FullscreenDesktop) {
			width = cast(i32)GetSystemMetrics(SM_CXSCREEN);
			height = cast(i32)GetSystemMetrics(SM_CYSCREEN);
		}
		pixelFormat: i32;
		wc: WNDCLASSA;
		dwExStyle: DWORD;
		dwStyle: DWORD;
		windowRect: RECT;
		windowRect.left = 0;
		windowRect.right = width;
		windowRect.top = 0;
		windowRect.bottom = height;

		hInstance = GetModuleHandleA(null);
		wc.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;  // Redraw on size, we unique DC.
		wc.lpfnWndProc = cast(WNDPROC)wndProc;
		wc.cbClsExtra = 0;
		wc.cbWndExtra = 0;
		wc.hInstance = hInstance;
		wc.hIcon = LoadIconA(null, cast(LPCSTR)cast(void*)IDI_WINLOGO);
		wc.hCursor = LoadCursorA(null, cast(LPCSTR)cast(void*)IDC_ARROW);
		wc.hbrBackground = null;
		wc.lpszMenuName = null;
		wc.lpszClassName = "OpenGL".ptr;

		if (!RegisterClassA(&wc)) {
			throw new Exception("failed to register window class");
		}

		if (windowMode == coreWindow.Fullscreen) {
			changeDisplayMode(cast(u32)width, cast(u32)height);
		}

		final switch (windowMode) {
		case coreWindow.Normal:
			dwExStyle = WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;
			dwStyle = WS_OVERLAPPEDWINDOW;
			break;
		case coreWindow.Fullscreen:
		case coreWindow.FullscreenDesktop:
			dwExStyle = WS_EX_APPWINDOW;
			dwStyle = WS_POPUP;
			break;
		}

		// Adjust window to true requested size.
		AdjustWindowRectEx(&windowRect, dwStyle, FALSE, dwExStyle);

		// Create the window.
		hWnd = CreateWindowExA(dwExStyle,
			"OpenGL".ptr,
			title,
			dwStyle | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
			0, 0,
			windowRect.right - windowRect.left,
			windowRect.bottom - windowRect.top,
			null, null,
			hInstance, null);
		if (hWnd is null) {
			killGlWindow();
			throw new Exception("couldn't create window");
		}

		pfd: PIXELFORMATDESCRIPTOR;
		memset(cast(void*)&pfd, 0, typeid(PIXELFORMATDESCRIPTOR).size);
		pfd.nSize = cast(WORD)typeid(PIXELFORMATDESCRIPTOR).size;  // Size of this Pixel Format Descriptor.
		pfd.nVersion = 1;
		// Must be an OpenGL window that supports double buffering.
		pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
		pfd.iPixelType = PFD_TYPE_RGBA;
		pfd.cAlphaBits = 8;
		pfd.cColorBits = 24;  // Not including alpha.
		pfd.cDepthBits = 24;  // Z-Buffer depth.
		pfd.cStencilBits = 8;

		hDC = GetDC(hWnd);
		if (hDC is null) {
			killGlWindow();
			throw new Exception("can't get gl device context");
		}

		pixelFormat = ChoosePixelFormat(hDC, &pfd);
		if (pixelFormat == 0) {
			killGlWindow();
			throw new Exception("can't find suitable pixel format");
		}

		if (!SetPixelFormat(hDC, pixelFormat, &pfd)) {
			killGlWindow();
			throw new Exception("can't set pixel format");
		}

		hRC = wglCreateContext(hDC);
		if (hRC is null) {
			killGlWindow();
			throw new Exception("can't create gl rendering context");
		}

		if (!wglMakeCurrent(hDC, hRC)) {
			killGlWindow();
			throw new Exception("can't activate gl rendering context");
		}

		openglDll = LoadLibraryA(toStringz("opengl32.dll"));
		if (openglDll is null) {
			killGlWindow();
			throw new Exception("couldn't get reference to opengl32.dll");
		}

		retval := gladLoadGL(loadFunc);
		if (!retval) {
			throw new Exception("couldn't load OpenGL functions");
		} else {
			gfxLoaded = true;
		}

		ShowWindow(hWnd, SW_SHOW);
		SetForegroundWindow(hWnd);
		SetFocus(hWnd);  // Keyboard focus.

		t := DefaultTarget.opCall();
		t.width = cast(uint)width;
		t.height = cast(uint)height;
		return;  // TODO: Crashes without this.
	}

	//! Correctly kill the window.
	fn killGlWindow()
	{
		if (hRC !is null) {
			// Release the rendering context, if we have one.
			if (!wglMakeCurrent(null, null)) {
				MessageBoxA(null, "Release of DC and RC failed.".ptr,
					"SHUTDOWN ERROR".ptr, MB_OK | MB_ICONINFORMATION);
			}
			if (!wglDeleteContext(hRC)) {
				MessageBoxA(null, "Release of rendering context failed.".ptr,
					"SHUTDOWN ERROR".ptr, MB_OK | MB_ICONINFORMATION);
			}
			hRC = null;
		}

		// Release the DC.
		if (hDC !is null && !ReleaseDC(hWnd, hDC)) {
			MessageBoxA(null, "Release Device Context Failed.".ptr,
				"SHUTDOWN ERROR".ptr, MB_OK | MB_ICONINFORMATION);
		}

		// Destroy the window.
		if (hWnd !is null && !DestroyWindow(hWnd)) {
			MessageBoxA(null, "Could not release hWnd.".ptr,
				"SHUTDOWN ERROR".ptr, MB_OK | MB_ICONINFORMATION);
		}

		// Unregister the window class.
		if (!UnregisterClassA("OpenGL", hInstance)) {
			MessageBoxA(null, "Could not unregister window class.".ptr,
				"SHUTDOWN ERROR".ptr, MB_OK | MB_ICONINFORMATION);
		}
	}

	fn loadFunc(c: string) void*
	{
		cstr := toStringz(c);
		ptr := wglGetProcAddress(cstr);
		if (ptr is null) {
			ptr = GetProcAddress(openglDll, cstr);
		}
		return ptr;
	}

	global extern(C) fn glDebug(source: GLuint, type: GLenum, id: GLenum,
								severity: GLenum, length: GLsizei,
								msg: const(GLchar*), data: GLvoid*)
	{
		printf("#OGL# %.*s\n", length, msg);
	}

	global extern(Windows) fn wndProc(hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM) LRESULT
	{
		switch (uMsg) {
		case WM_SYSCOMMAND:
			switch (cast(i32)wParam) {
			case SC_SCREENSAVE:
			case SC_MONITORPOWER:
				// Prevent monitor from entering powersave, or the screensaver from launching.
				return null;
			default: break;
			}
			break;
		case WM_CLOSE:
			PostQuitMessage(0);
			return null;
		case WM_KEYDOWN:
		case WM_SYSKEYDOWN:
			k := thisCore.input.keyboard;
			if (k.down !is null) {
				k.down(k, keymap[WindowsScanCodeToSDLScanCode(lParam, wParam)]);
			}
			break;
		case WM_UNICHAR:
			if (cast(DWORD)wParam == UNICODE_NOCHAR) {
				return cast(LRESULT)1;
			}
			goto case;
		case WM_CHAR:
			text: char[5];
			if (WIN_ConvertUTF32toUTF8(cast(u32)wParam, text.ptr)) {
				k := thisCore.input.keyboard;
				if (k.text !is null) {
					i: size_t;
					for (; i < text.length && text[i]; i++) {}
					if (i > 1 || text[0] >= 32) {
						k.text(k, text[0 .. i]);
					}
					return null;
				}
			}
			break;
		case WM_KEYUP:
		case WM_SYSKEYUP:
			k := thisCore.input.keyboard;
			if (k.up !is null) {
				k.up(k, keymap[WindowsScanCodeToSDLScanCode(lParam, wParam)]);
			}
			break;
		case WM_MOUSEMOVE:
			m := thisCore.input.mouse;
			mx := GET_X_LPARAM(lParam);
			my := GET_Y_LPARAM(lParam);
			deltax := mx - thisCore.lastX;
			deltay := my - thisCore.lastY;
			thisCore.lastX = mx;
			thisCore.lastY = my;
			if (!m.getRelativeMode()) {
				m.x = mx;
				m.y = my;
			}
			if (m.move !is null) {
				m.move(m, deltax, deltay);
			}
			return null;
		case WM_LBUTTONDOWN:
			sendMouse(SDL_BUTTON_LEFT, true, lParam);
			break;
		case WM_RBUTTONDOWN:
			sendMouse(SDL_BUTTON_RIGHT, true, lParam);
			break;
		case WM_MBUTTONDOWN:
			sendMouse(SDL_BUTTON_MIDDLE, true, lParam);
			break;
		case WM_XBUTTONDOWN:
			btn := GET_XBUTTON_WPARAM(wParam) == 1 ? SDL_BUTTON_X1 : SDL_BUTTON_X2;
			sendMouse(btn, true, lParam);
			break;
		case WM_LBUTTONUP:
			sendMouse(SDL_BUTTON_LEFT, false, lParam);
			break;
		case WM_RBUTTONUP:
			sendMouse(SDL_BUTTON_RIGHT, false, lParam);
			break;
		case WM_MBUTTONUP:
			sendMouse(SDL_BUTTON_MIDDLE, false, lParam);
			break;
		case WM_XBUTTONUP:
			btn := GET_XBUTTON_WPARAM(wParam) == 1 ? SDL_BUTTON_X1 : SDL_BUTTON_X2;
			sendMouse(btn, false, lParam);
			break;
		case WM_SIZE:
			// This be routed to a as of yet non-excisting resizeDg
			t := DefaultTarget.opCall();
			t.width = LOWORD(cast(DWORD)lParam);
			t.height = HIWORD(cast(DWORD)lParam);
			//thisCore.resize(LOWORD(cast(DWORD)lParam), HIWORD(cast(DWORD)lParam));
			break;
		case WM_PAINT:
			return null;
		case WM_ERASEBKGND:
			return cast(LRESULT)1;
		default: break;
		}
		return DefWindowProcA(hWnd, uMsg, wParam, lParam);
	}
}

fn sendMouse(button: i32, down: bool, lParam: LPARAM)
{
	m := thisCore.input.mouse;
	m.x = GET_X_LPARAM(lParam);
	m.y = GET_Y_LPARAM(lParam);
	if (down) {
		m.state |= cast(u32)(1 << button);
		if (m.down !is null) {
			m.down(m, button);
		}
	} else {
		m.state = cast(u32)~(1 << button) & m.state;
		if (m.up !is null) {
			m.up(m, button);
		}
	}
}

class InputWin32 : Input
{
public:
	this(size_t numJoysticks)
	{
		super();

		keyboardArray ~= new KeyboardWin32();
		mouseArray ~= new MouseWin32();

		// Small hack to allow hotplug.
		num := numJoysticks;
		if (num < 8) {
			num = 8;
		}

		joystickArray = new Joystick[](num);
		foreach (i; 0 .. num) {
			joystickArray[i] = new JoystickWin32(i);
		}
	}
}

class MouseWin32 : Mouse
{
private:
	bool mRelativeMode;

public:
	this()
	{

	}

	override fn setRelativeMode(value: bool)
	{
		mRelativeMode = value;
		if (value) {
			SetCapture(thisCore.hWnd);
			ShowCursor(FALSE);
		} else {
			ReleaseCapture();
			ShowCursor(TRUE);
		}
	}

	override fn getRelativeMode() bool
	{
		return mRelativeMode;
	}
}

class KeyboardWin32 : Keyboard
{

}

fn WIN_ConvertUTF32toUTF8(codepoint: u32, text: char*) bool
{
    if (codepoint <= 0x7F) {
        text[0] = cast(char) codepoint;
        text[1] = '\0';
    } else if (codepoint <= 0x7FF) {
		text[0] = cast(char)(0xC0 | ((codepoint >> 6) & 0x1F));
		text[1] = cast(char)(0x80 | (codepoint & 0x3F));
        text[2] = '\0';
    } else if (codepoint <= 0xFFFF) {
		text[0] = cast(char)(0xE0 | ((codepoint >> 12) & 0x0F));
		text[1] = cast(char)(0x80 | ((codepoint >> 6) & 0x3F));
		text[2] = cast(char)(0x80 | cast(char) (codepoint & 0x3F));
        text[3] = '\0';
    } else if (codepoint <= 0x10FFFF) {
		text[0] = cast(char)(0xF0 | ((codepoint >> 18) & 0x0F));
		text[1] = cast(char)(0x80 | ((codepoint >> 12) & 0x3F));
		text[2] = cast(char)(0x80 | ((codepoint >> 6) & 0x3F));
		text[3] = cast(char)(0x80 | (codepoint & 0x3F));
        text[4] = '\0';
    } else {
        return false;
    }
    return true;
}

fn WindowsScanCodeToSDLScanCode(lParam: LPARAM, wParam: WPARAM) SDL_Scancode
{
	code: SDL_Scancode;
	bIsExtended: char;
	nScanCode: i32 = cast(i32)((cast(ptrdiff_t)lParam >> 16) & 0xFF);

	/* 0x45 here to work around both pause and numlock sharing the same scancode, so use the VK key to tell them apart */
	if (nScanCode == 0 || nScanCode == 0x45) {
		switch(cast(size_t)wParam) {
		case VK_CLEAR: return SDL_SCANCODE_CLEAR;
		case VK_MODECHANGE: return SDL_SCANCODE_MODE;
		case VK_SELECT: return SDL_SCANCODE_SELECT;
		case VK_EXECUTE: return SDL_SCANCODE_EXECUTE;
		case VK_HELP: return SDL_SCANCODE_HELP;
		case VK_PAUSE: return SDL_SCANCODE_PAUSE;
		case VK_NUMLOCK: return SDL_SCANCODE_NUMLOCKCLEAR;

		case VK_F13: return SDL_SCANCODE_F13;
		case VK_F14: return SDL_SCANCODE_F14;
		case VK_F15: return SDL_SCANCODE_F15;
		case VK_F16: return SDL_SCANCODE_F16;
		case VK_F17: return SDL_SCANCODE_F17;
		case VK_F18: return SDL_SCANCODE_F18;
		case VK_F19: return SDL_SCANCODE_F19;
		case VK_F20: return SDL_SCANCODE_F20;
		case VK_F21: return SDL_SCANCODE_F21;
		case VK_F22: return SDL_SCANCODE_F22;
		case VK_F23: return SDL_SCANCODE_F23;
		case VK_F24: return SDL_SCANCODE_F24;

		case VK_OEM_NEC_EQUAL: return SDL_SCANCODE_KP_EQUALS;
		case VK_BROWSER_BACK: return SDL_SCANCODE_AC_BACK;
		case VK_BROWSER_FORWARD: return SDL_SCANCODE_AC_FORWARD;
		case VK_BROWSER_REFRESH: return SDL_SCANCODE_AC_REFRESH;
		case VK_BROWSER_STOP: return SDL_SCANCODE_AC_STOP;
		case VK_BROWSER_SEARCH: return SDL_SCANCODE_AC_SEARCH;
		case VK_BROWSER_FAVORITES: return SDL_SCANCODE_AC_BOOKMARKS;
		case VK_BROWSER_HOME: return SDL_SCANCODE_AC_HOME;
		case VK_VOLUME_MUTE: return SDL_SCANCODE_AUDIOMUTE;
		case VK_VOLUME_DOWN: return SDL_SCANCODE_VOLUMEDOWN;
		case VK_VOLUME_UP: return SDL_SCANCODE_VOLUMEUP;

		case VK_MEDIA_NEXT_TRACK: return SDL_SCANCODE_AUDIONEXT;
		case VK_MEDIA_PREV_TRACK: return SDL_SCANCODE_AUDIOPREV;
		case VK_MEDIA_STOP: return SDL_SCANCODE_AUDIOSTOP;
		case VK_MEDIA_PLAY_PAUSE: return SDL_SCANCODE_AUDIOPLAY;
		case VK_LAUNCH_MAIL: return SDL_SCANCODE_MAIL;
		case VK_LAUNCH_MEDIA_SELECT: return SDL_SCANCODE_MEDIASELECT;

		case VK_OEM_102: return SDL_SCANCODE_NONUSBACKSLASH;

		case VK_ATTN: return SDL_SCANCODE_SYSREQ;
		case VK_CRSEL: return SDL_SCANCODE_CRSEL;
		case VK_EXSEL: return SDL_SCANCODE_EXSEL;
		case VK_OEM_CLEAR: return SDL_SCANCODE_CLEAR;

		case VK_LAUNCH_APP1: return SDL_SCANCODE_APP1;
		case VK_LAUNCH_APP2: return SDL_SCANCODE_APP2;

		default: return SDL_SCANCODE_UNKNOWN;
		}
	}

	if (nScanCode > 127) {
		return SDL_SCANCODE_UNKNOWN;
	}

	code = windows_scancode_table[nScanCode];

	bIsExtended = (cast(ptrdiff_t)lParam & (1 << 24)) != 0;
	if (!bIsExtended) {
		switch (code) {
		case SDL_SCANCODE_HOME:
			return SDL_SCANCODE_KP_7;
		case SDL_SCANCODE_UP:
			return SDL_SCANCODE_KP_8;
		case SDL_SCANCODE_PAGEUP:
			return SDL_SCANCODE_KP_9;
		case SDL_SCANCODE_LEFT:
			return SDL_SCANCODE_KP_4;
		case SDL_SCANCODE_RIGHT:
			return SDL_SCANCODE_KP_6;
		case SDL_SCANCODE_END:
			return SDL_SCANCODE_KP_1;
		case SDL_SCANCODE_DOWN:
			return SDL_SCANCODE_KP_2;
		case SDL_SCANCODE_PAGEDOWN:
			return SDL_SCANCODE_KP_3;
		case SDL_SCANCODE_INSERT:
			return SDL_SCANCODE_KP_0;
		case SDL_SCANCODE_DELETE:
			return SDL_SCANCODE_KP_PERIOD;
		case SDL_SCANCODE_PRINTSCREEN:
			return SDL_SCANCODE_KP_MULTIPLY;
		default:
			break;
		}
	} else {
		switch (code) {
		case SDL_SCANCODE_RETURN:
			return SDL_SCANCODE_KP_ENTER;
		case SDL_SCANCODE_LALT:
			return SDL_SCANCODE_RALT;
		case SDL_SCANCODE_LCTRL:
			return SDL_SCANCODE_RCTRL;
		case SDL_SCANCODE_SLASH:
			return SDL_SCANCODE_KP_DIVIDE;
		case SDL_SCANCODE_CAPSLOCK:
			return SDL_SCANCODE_KP_PLUS;
		default:
			break;
		}
	}

	return code;
}

private global windows_scancode_table: SDL_Scancode[] = 
[
	/*	0						1							2							3							4						5							6							7 */
	/*	8						9							A							B							C						D							E							F */
	SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_ESCAPE,		SDL_SCANCODE_1,				SDL_SCANCODE_2,				SDL_SCANCODE_3,			SDL_SCANCODE_4,				SDL_SCANCODE_5,				SDL_SCANCODE_6,			/* 0 */
	SDL_SCANCODE_7,				SDL_SCANCODE_8,				SDL_SCANCODE_9,				SDL_SCANCODE_0,				SDL_SCANCODE_MINUS,		SDL_SCANCODE_EQUALS,		SDL_SCANCODE_BACKSPACE,		SDL_SCANCODE_TAB,		/* 0 */

	SDL_SCANCODE_Q,				SDL_SCANCODE_W,				SDL_SCANCODE_E,				SDL_SCANCODE_R,				SDL_SCANCODE_T,			SDL_SCANCODE_Y,				SDL_SCANCODE_U,				SDL_SCANCODE_I,			/* 1 */
	SDL_SCANCODE_O,				SDL_SCANCODE_P,				SDL_SCANCODE_LEFTBRACKET,	SDL_SCANCODE_RIGHTBRACKET,	SDL_SCANCODE_RETURN,	SDL_SCANCODE_LCTRL,			SDL_SCANCODE_A,				SDL_SCANCODE_S,			/* 1 */

	SDL_SCANCODE_D,				SDL_SCANCODE_F,				SDL_SCANCODE_G,				SDL_SCANCODE_H,				SDL_SCANCODE_J,			SDL_SCANCODE_K,				SDL_SCANCODE_L,				SDL_SCANCODE_SEMICOLON,	/* 2 */
	SDL_SCANCODE_APOSTROPHE,	SDL_SCANCODE_GRAVE,			SDL_SCANCODE_LSHIFT,		SDL_SCANCODE_BACKSLASH,		SDL_SCANCODE_Z,			SDL_SCANCODE_X,				SDL_SCANCODE_C,				SDL_SCANCODE_V,			/* 2 */

	SDL_SCANCODE_B,				SDL_SCANCODE_N,				SDL_SCANCODE_M,				SDL_SCANCODE_COMMA,			SDL_SCANCODE_PERIOD,	SDL_SCANCODE_SLASH,			SDL_SCANCODE_RSHIFT,		SDL_SCANCODE_PRINTSCREEN,/* 3 */
	SDL_SCANCODE_LALT,			SDL_SCANCODE_SPACE,			SDL_SCANCODE_CAPSLOCK,		SDL_SCANCODE_F1,			SDL_SCANCODE_F2,		SDL_SCANCODE_F3,			SDL_SCANCODE_F4,			SDL_SCANCODE_F5,		/* 3 */

	SDL_SCANCODE_F6,			SDL_SCANCODE_F7,			SDL_SCANCODE_F8,			SDL_SCANCODE_F9,			SDL_SCANCODE_F10,		SDL_SCANCODE_NUMLOCKCLEAR,	SDL_SCANCODE_SCROLLLOCK,	SDL_SCANCODE_HOME,		/* 4 */
	SDL_SCANCODE_UP,			SDL_SCANCODE_PAGEUP,		SDL_SCANCODE_KP_MINUS,		SDL_SCANCODE_LEFT,			SDL_SCANCODE_KP_5,		SDL_SCANCODE_RIGHT,			SDL_SCANCODE_KP_PLUS,		SDL_SCANCODE_END,		/* 4 */

	SDL_SCANCODE_DOWN,			SDL_SCANCODE_PAGEDOWN,		SDL_SCANCODE_INSERT,		SDL_SCANCODE_DELETE,		SDL_SCANCODE_UNKNOWN,	SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_NONUSBACKSLASH,SDL_SCANCODE_F11,		/* 5 */
	SDL_SCANCODE_F12,			SDL_SCANCODE_PAUSE,			SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_LGUI,			SDL_SCANCODE_RGUI,		SDL_SCANCODE_APPLICATION,	SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_UNKNOWN,	/* 5 */

	SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_F13,		SDL_SCANCODE_F14,			SDL_SCANCODE_F15,			SDL_SCANCODE_F16,		/* 6 */
	SDL_SCANCODE_F17,			SDL_SCANCODE_F18,			SDL_SCANCODE_F19,			SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_UNKNOWN,	SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_UNKNOWN,	/* 6 */
	
	SDL_SCANCODE_INTERNATIONAL2,		SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_INTERNATIONAL1,		SDL_SCANCODE_UNKNOWN,	SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_UNKNOWN,	/* 7 */
	SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_INTERNATIONAL4,		SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_INTERNATIONAL5,		SDL_SCANCODE_UNKNOWN,	SDL_SCANCODE_INTERNATIONAL3,		SDL_SCANCODE_UNKNOWN,		SDL_SCANCODE_UNKNOWN	/* 7 */
];

private global keymap: SDL_Keycode[] = [
    0, 0, 0, 0,
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
    SDLK_RETURN,
    SDLK_ESCAPE,
    SDLK_BACKSPACE,
    SDLK_TAB,
    SDLK_SPACE,
    '-',
    '=',
    '[',
    ']',
    '\\',
    '#',
    ';',
    '\'',
    '`',
    ',',
    '.',
    '/',
    SDLK_CAPSLOCK,
    SDLK_F1,
    SDLK_F2,
    SDLK_F3,
    SDLK_F4,
    SDLK_F5,
    SDLK_F6,
    SDLK_F7,
    SDLK_F8,
    SDLK_F9,
    SDLK_F10,
    SDLK_F11,
    SDLK_F12,
    SDLK_PRINTSCREEN,
    SDLK_SCROLLLOCK,
    SDLK_PAUSE,
    SDLK_INSERT,
    SDLK_HOME,
    SDLK_PAGEUP,
    SDLK_DELETE,
    SDLK_END,
    SDLK_PAGEDOWN,
    SDLK_RIGHT,
    SDLK_LEFT,
    SDLK_DOWN,
    SDLK_UP,
    SDLK_NUMLOCKCLEAR,
    SDLK_KP_DIVIDE,
    SDLK_KP_MULTIPLY,
    SDLK_KP_MINUS,
    SDLK_KP_PLUS,
    SDLK_KP_ENTER,
    SDLK_KP_1,
    SDLK_KP_2,
    SDLK_KP_3,
    SDLK_KP_4,
    SDLK_KP_5,
    SDLK_KP_6,
    SDLK_KP_7,
    SDLK_KP_8,
    SDLK_KP_9,
    SDLK_KP_0,
    SDLK_KP_PERIOD,
    0,
    SDLK_APPLICATION,
    SDLK_POWER,
    SDLK_KP_EQUALS,
    SDLK_F13,
    SDLK_F14,
    SDLK_F15,
    SDLK_F16,
    SDLK_F17,
    SDLK_F18,
    SDLK_F19,
    SDLK_F20,
    SDLK_F21,
    SDLK_F22,
    SDLK_F23,
    SDLK_F24,
    SDLK_EXECUTE,
    SDLK_HELP,
    SDLK_MENU,
    SDLK_SELECT,
    SDLK_STOP,
    SDLK_AGAIN,
    SDLK_UNDO,
    SDLK_CUT,
    SDLK_COPY,
    SDLK_PASTE,
    SDLK_FIND,
    SDLK_MUTE,
    SDLK_VOLUMEUP,
    SDLK_VOLUMEDOWN,
    0, 0, 0,
    SDLK_KP_COMMA,
    SDLK_KP_EQUALSAS400,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    SDLK_ALTERASE,
    SDLK_SYSREQ,
    SDLK_CANCEL,
    SDLK_CLEAR,
    SDLK_PRIOR,
    SDLK_RETURN2,
    SDLK_SEPARATOR,
    SDLK_OUT,
    SDLK_OPER,
    SDLK_CLEARAGAIN,
    SDLK_CRSEL,
    SDLK_EXSEL,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    SDLK_KP_00,
    SDLK_KP_000,
    SDLK_THOUSANDSSEPARATOR,
    SDLK_DECIMALSEPARATOR,
    SDLK_CURRENCYUNIT,
    SDLK_CURRENCYSUBUNIT,
    SDLK_KP_LEFTPAREN,
    SDLK_KP_RIGHTPAREN,
    SDLK_KP_LEFTBRACE,
    SDLK_KP_RIGHTBRACE,
    SDLK_KP_TAB,
    SDLK_KP_BACKSPACE,
    SDLK_KP_A,
    SDLK_KP_B,
    SDLK_KP_C,
    SDLK_KP_D,
    SDLK_KP_E,
    SDLK_KP_F,
    SDLK_KP_XOR,
    SDLK_KP_POWER,
    SDLK_KP_PERCENT,
    SDLK_KP_LESS,
    SDLK_KP_GREATER,
    SDLK_KP_AMPERSAND,
    SDLK_KP_DBLAMPERSAND,
    SDLK_KP_VERTICALBAR,
    SDLK_KP_DBLVERTICALBAR,
    SDLK_KP_COLON,
    SDLK_KP_HASH,
    SDLK_KP_SPACE,
    SDLK_KP_AT,
    SDLK_KP_EXCLAM,
    SDLK_KP_MEMSTORE,
    SDLK_KP_MEMRECALL,
    SDLK_KP_MEMCLEAR,
    SDLK_KP_MEMADD,
    SDLK_KP_MEMSUBTRACT,
    SDLK_KP_MEMMULTIPLY,
    SDLK_KP_MEMDIVIDE,
    SDLK_KP_PLUSMINUS,
    SDLK_KP_CLEAR,
    SDLK_KP_CLEARENTRY,
    SDLK_KP_BINARY,
    SDLK_KP_OCTAL,
    SDLK_KP_DECIMAL,
    SDLK_KP_HEXADECIMAL,
    0, 0,
    SDLK_LCTRL,
    SDLK_LSHIFT,
    SDLK_LALT,
    SDLK_LGUI,
    SDLK_RCTRL,
    SDLK_RSHIFT,
    SDLK_RALT,
    SDLK_RGUI,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    SDLK_MODE,
    SDLK_AUDIONEXT,
    SDLK_AUDIOPREV,
    SDLK_AUDIOSTOP,
    SDLK_AUDIOPLAY,
    SDLK_AUDIOMUTE,
    SDLK_MEDIASELECT,
    SDLK_WWW,
    SDLK_MAIL,
    SDLK_CALCULATOR,
    SDLK_COMPUTER,
    SDLK_AC_SEARCH,
    SDLK_AC_HOME,
    SDLK_AC_BACK,
    SDLK_AC_FORWARD,
    SDLK_AC_STOP,
    SDLK_AC_REFRESH,
    SDLK_AC_BOOKMARKS,
    SDLK_BRIGHTNESSDOWN,
    SDLK_BRIGHTNESSUP,
    SDLK_DISPLAYSWITCH,
    SDLK_KBDILLUMTOGGLE,
    SDLK_KBDILLUMDOWN,
    SDLK_KBDILLUMUP,
    SDLK_EJECT,
    SDLK_SLEEP,
];

class JoystickWin32 : Joystick
{
private:
	mId: size_t;
//	mStick: SDL_Joystick*;


public:
	this(size_t id)
	{
		mId = id;
	}

	@property override fn enabled(status: bool) bool
	{
		/+
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
		return enabled;+/
		return false;
	}

	@property override fn enabled() bool
	{
		//return mStick !is null;
		return false;
	}
}
