/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2013 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
	 claim that you wrote the original software. If you use this software
	 in a product, an acknowledgment in the product documentation would be
	 appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
	 misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/
module lib.sdl2.video;
extern (C):

/*
 *  \file SDL_video.h
 *
 *  Header file for SDL video functions.
 */

import lib.sdl2.stdinc;
import lib.sdl2.pixels;
import lib.sdl2.rect;
import lib.sdl2.surface;

/**
 *  \brief  The structure that defines a display mode
 *
 *  \sa SDL_GetNumDisplayModes()
 *  \sa SDL_GetDisplayMode()
 *  \sa SDL_GetDesktopDisplayMode()
 *  \sa SDL_GetCurrentDisplayMode()
 *  \sa SDL_GetClosestDisplayMode()
 *  \sa SDL_SetWindowDisplayMode()
 *  \sa SDL_GetWindowDisplayMode()
 */
struct SDL_DisplayMode
{
	Uint32 format;			  /*< pixel format */
	int w;					  /*< width */
	int h;					  /*< height */
	int refresh_rate;		   /*< refresh rate (or zero for unspecified) */
	void *driverdata;		   /*< driver-specific data, initialize to 0 */
} 

/*
 *  \brief The type used to identify a window
 *
 *  \sa SDL_CreateWindow()
 *  \sa SDL_CreateWindowFrom()
 *  \sa SDL_DestroyWindow()
 *  \sa SDL_GetWindowData()
 *  \sa SDL_GetWindowFlags()
 *  \sa SDL_GetWindowGrab()
 *  \sa SDL_GetWindowPosition()
 *  \sa SDL_GetWindowSize()
 *  \sa SDL_GetWindowTitle()
 *  \sa SDL_HideWindow()
 *  \sa SDL_MaximizeWindow()
 *  \sa SDL_MinimizeWindow()
 *  \sa SDL_RaiseWindow()
 *  \sa SDL_RestoreWindow()
 *  \sa SDL_SetWindowData()
 *  \sa SDL_SetWindowFullscreen()
 *  \sa SDL_SetWindowGrab()
 *  \sa SDL_SetWindowIcon()
 *  \sa SDL_SetWindowPosition()
 *  \sa SDL_SetWindowSize()
 *  \sa SDL_SetWindowBordered()
 *  \sa SDL_SetWindowTitle()
 *  \sa SDL_ShowWindow()
 */
struct SDL_Window
{
}

/**
 *  \brief The flags on a window
 *
 *  \sa SDL_GetWindowFlags()
 */
alias SDL_WindowFlags = int;
enum : SDL_WindowFlags
{
	SDL_WINDOW_FULLSCREEN = 0x00000001,		 /*< fullscreen window */
	SDL_WINDOW_OPENGL = 0x00000002,			 /*< window usable with OpenGL context */
	SDL_WINDOW_SHOWN = 0x00000004,			  /*< window is visible */
	SDL_WINDOW_HIDDEN = 0x00000008,			 /*< window is not visible */
	SDL_WINDOW_BORDERLESS = 0x00000010,		 /*< no window decoration */
	SDL_WINDOW_RESIZABLE = 0x00000020,		  /*< window can be resized */
	SDL_WINDOW_MINIMIZED = 0x00000040,		  /*< window is minimized */
	SDL_WINDOW_MAXIMIZED = 0x00000080,		  /*< window is maximized */
	SDL_WINDOW_INPUT_GRABBED = 0x00000100,	  /*< window has grabbed input focus */
	SDL_WINDOW_INPUT_FOCUS = 0x00000200,		/*< window has input focus */
	SDL_WINDOW_MOUSE_FOCUS = 0x00000400,		/*< window has mouse focus */
	SDL_WINDOW_FULLSCREEN_DESKTOP = ( SDL_WINDOW_FULLSCREEN | 0x00001000 ),
	SDL_WINDOW_FOREIGN = 0x00000800,			 /*< window not created by SDL */
	SDL_WINDOW_ALLOW_HIGHDPI = 0x00002000,
	SDL_WINDOW_MOUSE_CAPTURE = 0x00004000,
	SDL_WINDOW_ALWAYS_ON_TOP = 0x00010000,
	SDL_WINDOW_SKIP_TASKBAR = 0x00020000,
	SDL_WINDOW_UTILITY = 0x00040000,
	SDL_WINDOW_POPUP_MENU = 0x00080000
}

/**
 *  \brief Used to indicate that you don't care what the window position is.
 */
enum SDL_WINDOWPOS_UNDEFINED_MASK = 0x1FFF0000;
int SDL_WINDOWPOS_UNDEFINED_DISPLAY(int X) { return SDL_WINDOWPOS_UNDEFINED_MASK | X; }
@property int SDL_WINDOWPOS_UNDEFINED() { return SDL_WINDOWPOS_UNDEFINED_DISPLAY(0); }
bool SDL_WINDOWPOS_ISUNDEFINED(int X) { return (X & 0xFFFF0000) == SDL_WINDOWPOS_UNDEFINED_MASK; }

/**
 *  \brief Used to indicate that the window position should be centered.
 */
enum SDL_WINDOWPOS_CENTERED_MASK = 0x2FFF0000;
int SDL_WINDOWPOS_CENTERED_DISPLAY(int X) { return SDL_WINDOWPOS_CENTERED_MASK | X; }
enum SDL_WINDOWPOS_CENTERED = SDL_WINDOWPOS_CENTERED_MASK;
bool SDL_WINDOWPOS_ISCENTERED(int X) { return (X & 0xFFFF0000) == SDL_WINDOWPOS_CENTERED_MASK; }

/**
 *  \brief Event subtype for window events
 */
alias SDL_WindowEventID = int;
enum : SDL_WindowEventID
{
	SDL_WINDOWEVENT_NONE,		   /*< Never used */
	SDL_WINDOWEVENT_SHOWN,		  /*< Window has been shown */
	SDL_WINDOWEVENT_HIDDEN,		 /*< Window has been hidden */
	SDL_WINDOWEVENT_EXPOSED,		/*< Window has been exposed and should be
										 redrawn */
	SDL_WINDOWEVENT_MOVED,		  /*< Window has been moved to data1, data2
									 */
	SDL_WINDOWEVENT_RESIZED,		/*< Window has been resized to data1xdata2 */
	SDL_WINDOWEVENT_SIZE_CHANGED,   /*< The window size has changed, either as a result of an API call or through the system or user changing the window size. */
	SDL_WINDOWEVENT_MINIMIZED,	  /*< Window has been minimized */
	SDL_WINDOWEVENT_MAXIMIZED,	  /*< Window has been maximized */
	SDL_WINDOWEVENT_RESTORED,	   /*< Window has been restored to normal size
										 and position */
	SDL_WINDOWEVENT_ENTER,		  /*< Window has gained mouse focus */
	SDL_WINDOWEVENT_LEAVE,		  /*< Window has lost mouse focus */
	SDL_WINDOWEVENT_FOCUS_GAINED,   /*< Window has gained keyboard focus */
	SDL_WINDOWEVENT_FOCUS_LOST,	 /*< Window has lost keyboard focus */
	SDL_WINDOWEVENT_CLOSE,		   /*< The window manager requests that the
										 window be closed */
	SDL_WINDOWEVENT_TAKE_FOCUS,
	SDL_WINDOWEVENT_HIT_TEST,
}

/**
 *  \brief An opaque handle to an OpenGL context.
 */
alias SDL_GLContext = void*;

/**
 *  \brief OpenGL configuration attributes
 */
alias SDL_GLattr = int;
enum : SDL_GLattr
{
	SDL_GL_RED_SIZE,
	SDL_GL_GREEN_SIZE,
	SDL_GL_BLUE_SIZE,
	SDL_GL_ALPHA_SIZE,
	SDL_GL_BUFFER_SIZE,
	SDL_GL_DOUBLEBUFFER,
	SDL_GL_DEPTH_SIZE,
	SDL_GL_STENCIL_SIZE,
	SDL_GL_ACCUM_RED_SIZE,
	SDL_GL_ACCUM_GREEN_SIZE,
	SDL_GL_ACCUM_BLUE_SIZE,
	SDL_GL_ACCUM_ALPHA_SIZE,
	SDL_GL_STEREO,
	SDL_GL_MULTISAMPLEBUFFERS,
	SDL_GL_MULTISAMPLESAMPLES,
	SDL_GL_ACCELERATED_VISUAL,
	SDL_GL_RETAINED_BACKING,
	SDL_GL_CONTEXT_MAJOR_VERSION,
	SDL_GL_CONTEXT_MINOR_VERSION,
	SDL_GL_CONTEXT_EGL,
	SDL_GL_CONTEXT_FLAGS,
	SDL_GL_CONTEXT_PROFILE_MASK,
	SDL_GL_SHARE_WITH_CURRENT_CONTEXT
}

alias SDL_GLprofile = int;
enum : SDL_GLprofile
{
	SDL_GL_CONTEXT_PROFILE_CORE		   = 0x0001,
	SDL_GL_CONTEXT_PROFILE_COMPATIBILITY  = 0x0002,
	SDL_GL_CONTEXT_PROFILE_ES			 = 0x0004
}

alias SDL_GLcontextFlag = int;
enum : SDL_GLcontextFlag
{
	SDL_GL_CONTEXT_DEBUG_FLAG			  = 0x0001,
	SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG = 0x0002,
	SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG	  = 0x0004,
	SDL_GL_CONTEXT_RESET_ISOLATION_FLAG	= 0x0008
}


/* Function prototypes */

/**
 *  \brief Get the number of video drivers compiled into SDL
 *
 *  \sa SDL_GetVideoDriver()
 */
int SDL_GetNumVideoDrivers();

/**
 *  \brief Get the name of a built in video driver.
 *
 *  \note The video drivers are presented in the order in which they are
 *		normally checked during initialization.
 *
 *  \sa SDL_GetNumVideoDrivers()
 */
const char * SDL_GetVideoDriver(int index);

/**
 *  \brief Initialize the video subsystem, optionally specifying a video driver.
 *
 *  \param driver_name Initialize a specific driver by name, or NULL for the
 *					 default video driver.
 *
 *  \return 0 on success, -1 on error
 *
 *  This function initializes the video subsystem; setting up a connection
 *  to the window manager, etc, and determines the available display modes
 *  and pixel formats, but does not initialize a window or graphics mode.
 *
 *  \sa SDL_VideoQuit()
 */
int SDL_VideoInit(const char *driver_name);

/**
 *  \brief Shuts down the video subsystem.
 *
 *  This function closes all windows, and restores the original video mode.
 *
 *  \sa SDL_VideoInit()
 */
void SDL_VideoQuit();

/**
 *  \brief Returns the name of the currently initialized video driver.
 *
 *  \return The name of the current video driver or NULL if no driver
 *		  has been initialized
 *
 *  \sa SDL_GetNumVideoDrivers()
 *  \sa SDL_GetVideoDriver()
 */
const char * SDL_GetCurrentVideoDriver();

/**
 *  \brief Returns the number of available video displays.
 *
 *  \sa SDL_GetDisplayBounds()
 */
int SDL_GetNumVideoDisplays();

/**
 *  \brief Get the name of a display in UTF-8 encoding
 *
 *  \return The name of a display, or NULL for an invalid display index.
 *
 *  \sa SDL_GetNumVideoDisplays()
 */
const char * SDL_GetDisplayName(int displayIndex);

/**
 *  \brief Get the desktop area represented by a display, with the primary
 *		 display located at 0,0
 *
 *  \return 0 on success, or -1 if the index is out of range.
 *
 *  \sa SDL_GetNumVideoDisplays()
 */
int SDL_GetDisplayBounds(int displayIndex, SDL_Rect * rect);

/**
 *  \brief Get the usable desktop area represented by a display, with the
 *         primary display located at 0,0
 *
 *  This is the same area as SDL_GetDisplayBounds() reports, but with portions
 *  reserved by the system removed. For example, on Mac OS X, this subtracts
 *  the area occupied by the menu bar and dock.
 *
 *  Setting a window to be fullscreen generally bypasses these unusable areas,
 *  so these are good guidelines for the maximum space available to a
 *  non-fullscreen window.
 *
 *  \return 0 on success, or -1 if the index is out of range.
 *
 *  \sa SDL_GetDisplayBounds()
 *  \sa SDL_GetNumVideoDisplays()
 */
int SDL_GetDisplayUsableBounds(int displayIndex, SDL_Rect * rect);

/**
 *  \brief Returns the number of available display modes.
 *
 *  \sa SDL_GetDisplayMode()
 */
int SDL_GetNumDisplayModes(int displayIndex);

/**
 *  \brief Fill in information about a specific display mode.
 *
 *  \note The display modes are sorted in this priority:
 *		\li bits per pixel -> more colors to fewer colors
 *		\li width -> largest to smallest
 *		\li height -> largest to smallest
 *		\li refresh rate -> highest to lowest
 *
 *  \sa SDL_GetNumDisplayModes()
 */
int SDL_GetDisplayMode(int displayIndex, int modeIndex,
											   SDL_DisplayMode * mode);

/**
 *  \brief Fill in information about the desktop display mode.
 */
int SDL_GetDesktopDisplayMode(int displayIndex, SDL_DisplayMode * mode);

/**
 *  \brief Fill in information about the current display mode.
 */
int SDL_GetCurrentDisplayMode(int displayIndex, SDL_DisplayMode * mode);


/**
 *  \brief Get the closest match to the requested display mode.
 *
 *  \param displayIndex The index of display from which mode should be queried.
 *  \param mode The desired display mode
 *  \param closest A pointer to a display mode to be filled in with the closest
 *				 match of the available display modes.
 *
 *  \return The passed in value \c closest, or NULL if no matching video mode
 *		  was available.
 *
 *  The available display modes are scanned, and \c closest is filled in with the
 *  closest mode matching the requested mode and returned.  The mode format and
 *  refresh_rate default to the desktop mode if they are 0.  The modes are
 *  scanned with size being first priority, format being second priority, and
 *  finally checking the refresh_rate.  If all the available modes are too
 *  small, then NULL is returned.
 *
 *  \sa SDL_GetNumDisplayModes()
 *  \sa SDL_GetDisplayMode()
 */
SDL_DisplayMode * SDL_GetClosestDisplayMode(int displayIndex, const SDL_DisplayMode * mode, SDL_DisplayMode * closest);

/**
 *  \brief Get the display index associated with a window.
 *
 *  \return the display index of the display containing the center of the
 *		  window, or -1 on error.
 */
int SDL_GetWindowDisplayIndex(SDL_Window * window);

/**
 *  \brief Set the display mode used when a fullscreen window is visible.
 *
 *  By default the window's dimensions and the desktop format and refresh rate
 *  are used.
 *
 *  \param window The window for which the display mode should be set.
 *  \param mode The mode to use, or NULL for the default mode.
 *
 *  \return 0 on success, or -1 if setting the display mode failed.
 *
 *  \sa SDL_GetWindowDisplayMode()
 *  \sa SDL_SetWindowFullscreen()
 */
int SDL_SetWindowDisplayMode(SDL_Window * window,
													 const SDL_DisplayMode
														 * mode);

/**
 *  \brief Fill in information about the display mode used when a fullscreen
 *		 window is visible.
 *
 *  \sa SDL_SetWindowDisplayMode()
 *  \sa SDL_SetWindowFullscreen()
 */
int SDL_GetWindowDisplayMode(SDL_Window * window,
													 SDL_DisplayMode * mode);

/**
 *  \brief Get the pixel format associated with the window.
 */
Uint32 SDL_GetWindowPixelFormat(SDL_Window * window);

/**
 *  \brief Create a window with the specified position, dimensions, and flags.
 *
 *  \param title The title of the window, in UTF-8 encoding.
 *  \param x	 The x position of the window, ::SDL_WINDOWPOS_CENTERED, or
 *			   ::SDL_WINDOWPOS_UNDEFINED.
 *  \param y	 The y position of the window, ::SDL_WINDOWPOS_CENTERED, or
 *			   ::SDL_WINDOWPOS_UNDEFINED.
 *  \param w	 The width of the window.
 *  \param h	 The height of the window.
 *  \param flags The flags for the window, a mask of any of the following:
 *			   ::SDL_WINDOW_FULLSCREEN, ::SDL_WINDOW_OPENGL,
 *			   ::SDL_WINDOW_SHOWN,	  ::SDL_WINDOW_BORDERLESS,
 *			   ::SDL_WINDOW_RESIZABLE,  ::SDL_WINDOW_MAXIMIZED,
 *			   ::SDL_WINDOW_MINIMIZED,  ::SDL_WINDOW_INPUT_GRABBED.
 *
 *  \return The id of the window created, or zero if window creation failed.
 *
 *  \sa SDL_DestroyWindow()
 */
SDL_Window * SDL_CreateWindow(const char *title,
													  int x, int y, int w,
													  int h, Uint32 flags);

/**
 *  \brief Create an SDL window from an existing native window.
 *
 *  \param data A pointer to driver-dependent window creation data
 *
 *  \return The id of the window created, or zero if window creation failed.
 *
 *  \sa SDL_DestroyWindow()
 */
SDL_Window * SDL_CreateWindowFrom(const void *data);

/**
 *  \brief Get the numeric ID of a window, for logging purposes.
 */
Uint32 SDL_GetWindowID(SDL_Window * window);

/**
 *  \brief Get a window from a stored ID, or NULL if it doesn't exist.
 */
SDL_Window * SDL_GetWindowFromID(Uint32 id);

/**
 *  \brief Get the window flags.
 */
Uint32 SDL_GetWindowFlags(SDL_Window * window);

/**
 *  \brief Set the title of a window, in UTF-8 format.
 *
 *  \sa SDL_GetWindowTitle()
 */
void SDL_SetWindowTitle(SDL_Window * window,
												const char *title);

/**
 *  \brief Get the title of a window, in UTF-8 format.
 *
 *  \sa SDL_SetWindowTitle()
 */
const char * SDL_GetWindowTitle(SDL_Window * window);

/**
 *  \brief Set the icon for a window.
 *
 *  \param window The window for which the icon should be set.
 *  \param icon The icon for the window.
 */
void SDL_SetWindowIcon(SDL_Window * window,
											   SDL_Surface * icon);

/**
 *  \brief Associate an arbitrary named pointer with a window.
 *
 *  \param window   The window to associate with the pointer.
 *  \param name	 The name of the pointer.
 *  \param userdata The associated pointer.
 *
 *  \return The previous value associated with 'name'
 *
 *  \note The name is case-sensitive.
 *
 *  \sa SDL_GetWindowData()
 */
void* SDL_SetWindowData(SDL_Window * window,
												const char *name,
												void *userdata);

/**
 *  \brief Retrieve the data pointer associated with a window.
 *
 *  \param window   The window to query.
 *  \param name	 The name of the pointer.
 *
 *  \return The value associated with 'name'
 *
 *  \sa SDL_SetWindowData()
 */
void * SDL_GetWindowData(SDL_Window * window,
												const char *name);

/**
 *  \brief Set the position of a window.
 *
 *  \param window   The window to reposition.
 *  \param x		The x coordinate of the window, ::SDL_WINDOWPOS_CENTERED, or
					::SDL_WINDOWPOS_UNDEFINED.
 *  \param y		The y coordinate of the window, ::SDL_WINDOWPOS_CENTERED, or
					::SDL_WINDOWPOS_UNDEFINED.
 *
 *  \note The window coordinate origin is the upper left of the display.
 *
 *  \sa SDL_GetWindowPosition()
 */
void SDL_SetWindowPosition(SDL_Window * window,
												   int x, int y);

/**
 *  \brief Get the position of a window.
 *
 *  \param window   The window to query.
 *  \param x		Pointer to variable for storing the x position, may be NULL
 *  \param y		Pointer to variable for storing the y position, may be NULL
 *
 *  \sa SDL_SetWindowPosition()
 */
void SDL_GetWindowPosition(SDL_Window * window,
												   int *x, int *y);

/**
 *  \brief Set the size of a window's client area.
 *
 *  \param window   The window to resize.
 *  \param w		The width of the window, must be >0
 *  \param h		The height of the window, must be >0
 *
 *  \note You can't change the size of a fullscreen window, it automatically
 *		matches the size of the display mode.
 *
 *  \sa SDL_GetWindowSize()
 */
void SDL_SetWindowSize(SDL_Window * window, int w,
											   int h);

/**
 *  \brief Get the size of a window's client area.
 *
 *  \param window   The window to query.
 *  \param w		Pointer to variable for storing the width, may be NULL
 *  \param h		Pointer to variable for storing the height, may be NULL
 *
 *  \sa SDL_SetWindowSize()
 */
void SDL_GetWindowSize(SDL_Window * window, int *w,
											   int *h);

/**
 *  \brief Get the size of a window's borders (decorations) around the client area.
 *
 *  \param window The window to query.
 *  \param top Pointer to variable for storing the size of the top border. NULL is permitted.
 *  \param left Pointer to variable for storing the size of the left border. NULL is permitted.
 *  \param bottom Pointer to variable for storing the size of the bottom border. NULL is permitted.
 *  \param right Pointer to variable for storing the size of the right border. NULL is permitted.
 *
 *  \return 0 on success, or -1 if getting this information is not supported.
 *
 *  \note if this function fails (returns -1), the size values will be
 *        initialized to 0, 0, 0, 0 (if a non-NULL pointer is provided), as
 *        if the window in question was borderless.
 */
int SDL_GetWindowBordersSize(SDL_Window* window, int* top, int* left, int* bottom, int* right);

/**
 *  \brief Set the minimum size of a window's client area.
 *
 *  \param window	The window to set a new minimum size.
 *  \param min_w	 The minimum width of the window, must be >0
 *  \param min_h	 The minimum height of the window, must be >0
 *
 *  \note You can't change the minimum size of a fullscreen window, it
 *		automatically matches the size of the display mode.
 *
 *  \sa SDL_GetWindowMinimumSize()
 *  \sa SDL_SetWindowMaximumSize()
 */
void SDL_SetWindowMinimumSize(SDL_Window * window,
													  int min_w, int min_h);

/**
 *  \brief Get the minimum size of a window's client area.
 *
 *  \param window   The window to query.
 *  \param w		Pointer to variable for storing the minimum width, may be NULL
 *  \param h		Pointer to variable for storing the minimum height, may be NULL
 *
 *  \sa SDL_GetWindowMaximumSize()
 *  \sa SDL_SetWindowMinimumSize()
 */
void SDL_GetWindowMinimumSize(SDL_Window * window,
													  int *w, int *h);

/**
 *  \brief Set the maximum size of a window's client area.
 *
 *  \param window	The window to set a new maximum size.
 *  \param max_w	 The maximum width of the window, must be >0
 *  \param max_h	 The maximum height of the window, must be >0
 *
 *  \note You can't change the maximum size of a fullscreen window, it
 *		automatically matches the size of the display mode.
 *
 *  \sa SDL_GetWindowMaximumSize()
 *  \sa SDL_SetWindowMinimumSize()
 */
void SDL_SetWindowMaximumSize(SDL_Window * window,
													  int max_w, int max_h);

/**
 *  \brief Get the maximum size of a window's client area.
 *
 *  \param window   The window to query.
 *  \param w		Pointer to variable for storing the maximum width, may be NULL
 *  \param h		Pointer to variable for storing the maximum height, may be NULL
 *
 *  \sa SDL_GetWindowMinimumSize()
 *  \sa SDL_SetWindowMaximumSize()
 */
void SDL_GetWindowMaximumSize(SDL_Window * window,
													  int *w, int *h);

/**
 *  \brief Set the border state of a window.
 *
 *  This will add or remove the window's SDL_WINDOW_BORDERLESS flag and
 *  add or remove the border from the actual window. This is a no-op if the
 *  window's border already matches the requested state.
 *
 *  \param window The window of which to change the border state.
 *  \param bordered SDL_FALSE to remove border, SDL_TRUE to add border.
 *
 *  \note You can't change the border state of a fullscreen window.
 *
 *  \sa SDL_GetWindowFlags()
 */
void SDL_SetWindowBordered(SDL_Window * window,
												   SDL_bool bordered);

/**
 *  \brief Set the user-resizable state of a window.
 *
 *  This will add or remove the window's SDL_WINDOW_RESIZABLE flag and
 *  allow/disallow user resizing of the window. This is a no-op if the
 *  window's resizable state already matches the requested state.
 *
 *  \param window The window of which to change the resizable state.
 *  \param resizable SDL_TRUE to allow resizing, SDL_FALSE to disallow.
 *
 *  \note You can't change the resizable state of a fullscreen window.
 *
 *  \sa SDL_GetWindowFlags()
 */
void SDL_SetWindowResizable(SDL_Window* window, SDL_bool resizable);

/**
 *  \brief Show a window.
 *
 *  \sa SDL_HideWindow()
 */
void SDL_ShowWindow(SDL_Window * window);

/**
 *  \brief Hide a window.
 *
 *  \sa SDL_ShowWindow()
 */
void SDL_HideWindow(SDL_Window * window);

/**
 *  \brief Raise a window above other windows and set the input focus.
 */
void SDL_RaiseWindow(SDL_Window * window);

/**
 *  \brief Make a window as large as possible.
 *
 *  \sa SDL_RestoreWindow()
 */
void SDL_MaximizeWindow(SDL_Window * window);

/**
 *  \brief Minimize a window to an iconic representation.
 *
 *  \sa SDL_RestoreWindow()
 */
void SDL_MinimizeWindow(SDL_Window * window);

/**
 *  \brief Restore the size and position of a minimized or maximized window.
 *
 *  \sa SDL_MaximizeWindow()
 *  \sa SDL_MinimizeWindow()
 */
void SDL_RestoreWindow(SDL_Window * window);

/**
 *  \brief Set a window's fullscreen state.
 *
 *  \return 0 on success, or -1 if setting the display mode failed.
 *
 *  \sa SDL_SetWindowDisplayMode()
 *  \sa SDL_GetWindowDisplayMode()
 */
int SDL_SetWindowFullscreen(SDL_Window * window,
													Uint32 flags);

/**
 *  \brief Get the SDL surface associated with the window.
 *
 *  \return The window's framebuffer surface, or NULL on error.
 *
 *  A new surface will be created with the optimal format for the window,
 *  if necessary. This surface will be freed when the window is destroyed.
 *
 *  \note You may not combine this with 3D or the rendering API on this window.
 *
 *  \sa SDL_UpdateWindowSurface()
 *  \sa SDL_UpdateWindowSurfaceRects()
 */
SDL_Surface * SDL_GetWindowSurface(SDL_Window * window);

/**
 *  \brief Copy the window surface to the screen.
 *
 *  \return 0 on success, or -1 on error.
 *
 *  \sa SDL_GetWindowSurface()
 *  \sa SDL_UpdateWindowSurfaceRects()
 */
int SDL_UpdateWindowSurface(SDL_Window * window);

/**
 *  \brief Copy a number of rectangles on the window surface to the screen.
 *
 *  \return 0 on success, or -1 on error.
 *
 *  \sa SDL_GetWindowSurface()
 *  \sa SDL_UpdateWindowSurfaceRect()
 */
int SDL_UpdateWindowSurfaceRects(SDL_Window * window,
														 const SDL_Rect * rects,
														 int numrects);

/**
 *  \brief Set a window's input grab mode.
 *
 *  \param window The window for which the input grab mode should be set.
 *  \param grabbed This is SDL_TRUE to grab input, and SDL_FALSE to release input.
 *
 *  \sa SDL_GetWindowGrab()
 */
void SDL_SetWindowGrab(SDL_Window * window,
											   SDL_bool grabbed);

/**
 *  \brief Get a window's input grab mode.
 *
 *  \return This returns SDL_TRUE if input is grabbed, and SDL_FALSE otherwise.
 *
 *  \sa SDL_SetWindowGrab()
 */
SDL_bool SDL_GetWindowGrab(SDL_Window * window);

/**
 *  \brief Set the brightness (gamma correction) for a window.
 *
 *  \return 0 on success, or -1 if setting the brightness isn't supported.
 *
 *  \sa SDL_GetWindowBrightness()
 *  \sa SDL_SetWindowGammaRamp()
 */
int SDL_SetWindowBrightness(SDL_Window * window, float brightness);

/**
 *  \brief Get the brightness (gamma correction) for a window.
 *
 *  \return The last brightness value passed to SDL_SetWindowBrightness()
 *
 *  \sa SDL_SetWindowBrightness()
 */
float SDL_GetWindowBrightness(SDL_Window * window);

/**
 *  \brief Set the opacity for a window
 *
 *  \param window The window which will be made transparent or opaque
 *  \param opacity Opacity (0.0f - transparent, 1.0f - opaque) This will be
 *                 clamped internally between 0.0f and 1.0f.
 * 
 *  \return 0 on success, or -1 if setting the opacity isn't supported.
 *
 *  \sa SDL_GetWindowOpacity()
 */
int SDL_SetWindowOpacity(SDL_Window * window, float opacity);

/**
 *  \brief Get the opacity of a window.
 *
 *  If transparency isn't supported on this platform, opacity will be reported
 *  as 1.0f without error.
 *
 *  \param window The window in question.
 *  \param out_opacity Opacity (0.0f - transparent, 1.0f - opaque)
 *
 *  \return 0 on success, or -1 on error (invalid window, etc).
 *
 *  \sa SDL_SetWindowOpacity()
 */
int SDL_GetWindowOpacity(SDL_Window * window, float * out_opacity);

/**
 *  \brief Sets the window as a modal for another window (TODO: reconsider this function and/or its name)
 *
 *  \param modal_window The window that should be modal
 *  \param parent_window The parent window
 * 
 *  \return 0 on success, or -1 otherwise.
 */
int SDL_SetWindowModalFor(SDL_Window * modal_window, SDL_Window * parent_window);

/**
 *  \brief Explicitly sets input focus to the window.
 *
 *  You almost certainly want SDL_RaiseWindow() instead of this function. Use
 *  this with caution, as you might give focus to a window that's completely
 *  obscured by other windows.
 *
 *  \param window The window that should get the input focus
 * 
 *  \return 0 on success, or -1 otherwise.
 *  \sa SDL_RaiseWindow()
 */
int SDL_SetWindowInputFocus(SDL_Window * window);


/**
 *  \brief Set the gamma ramp for a window.
 *
 *  \param window The window for which the gamma ramp should be set.
 *  \param red The translation table for the red channel, or NULL.
 *  \param green The translation table for the green channel, or NULL.
 *  \param blue The translation table for the blue channel, or NULL.
 *
 *  \return 0 on success, or -1 if gamma ramps are unsupported.
 *
 *  Set the gamma translation table for the red, green, and blue channels
 *  of the video hardware.  Each table is an array of 256 16-bit quantities,
 *  representing a mapping between the input and output for that channel.
 *  The input is the index into the array, and the output is the 16-bit
 *  gamma value at that index, scaled to the output color precision.
 *
 *  \sa SDL_GetWindowGammaRamp()
 */
int SDL_SetWindowGammaRamp(SDL_Window * window,
												   const Uint16 * red,
												   const Uint16 * green,
												   const Uint16 * blue);

/**
 *  \brief Get the gamma ramp for a window.
 *
 *  \param window The window from which the gamma ramp should be queried.
 *  \param red   A pointer to a 256 element array of 16-bit quantities to hold
 *			   the translation table for the red channel, or NULL.
 *  \param green A pointer to a 256 element array of 16-bit quantities to hold
 *			   the translation table for the green channel, or NULL.
 *  \param blue  A pointer to a 256 element array of 16-bit quantities to hold
 *			   the translation table for the blue channel, or NULL.
 *
 *  \return 0 on success, or -1 if gamma ramps are unsupported.
 *
 *  \sa SDL_SetWindowGammaRamp()
 */
int SDL_GetWindowGammaRamp(SDL_Window * window,
												   Uint16 * red,
												   Uint16 * green,
												   Uint16 * blue);

/**
 *  \brief Destroy a window.
 */
void SDL_DestroyWindow(SDL_Window * window);


/**
 *  \brief Returns whether the screensaver is currently enabled (default on).
 *
 *  \sa SDL_EnableScreenSaver()
 *  \sa SDL_DisableScreenSaver()
 */
SDL_bool SDL_IsScreenSaverEnabled();

/**
 *  \brief Allow the screen to be blanked by a screensaver
 *
 *  \sa SDL_IsScreenSaverEnabled()
 *  \sa SDL_DisableScreenSaver()
 */
void SDL_EnableScreenSaver();

/**
 *  \brief Prevent the screen from being blanked by a screensaver
 *
 *  \sa SDL_IsScreenSaverEnabled()
 *  \sa SDL_EnableScreenSaver()
 */
void SDL_DisableScreenSaver();


/**
 *  \name OpenGL support functions
 */
/* */

/**
 *  \brief Dynamically load an OpenGL library.
 *
 *  \param path The platform dependent OpenGL library name, or NULL to open the
 *			  default OpenGL library.
 *
 *  \return 0 on success, or -1 if the library couldn't be loaded.
 *
 *  This should be done after initializing the video driver, but before
 *  creating any OpenGL windows.  If no OpenGL library is loaded, the default
 *  library will be loaded upon creation of the first OpenGL window.
 *
 *  \note If you do this, you need to retrieve all of the GL functions used in
 *		your program from the dynamic library using SDL_GL_GetProcAddress().
 *
 *  \sa SDL_GL_GetProcAddress()
 *  \sa SDL_GL_UnloadLibrary()
 */
int SDL_GL_LoadLibrary(const char *path);

/**
 *  \brief Get the address of an OpenGL function.
 */
void * SDL_GL_GetProcAddress(const char *proc);

/**
 *  \brief Unload the OpenGL library previously loaded by SDL_GL_LoadLibrary().
 *
 *  \sa SDL_GL_LoadLibrary()
 */
void SDL_GL_UnloadLibrary();

/**
 *  \brief Return true if an OpenGL extension is supported for the current
 *		 context.
 */
SDL_bool SDL_GL_ExtensionSupported(const char
														   *extension);

/**
 *  \brief Set an OpenGL window attribute before window creation.
 */
int SDL_GL_SetAttribute(SDL_GLattr attr, int value);

/**
 *  \brief Get the actual value for an attribute from the current context.
 */
int SDL_GL_GetAttribute(SDL_GLattr attr, int *value);

/**
 *  \brief Create an OpenGL context for use with an OpenGL window, and make it
 *		 current.
 *
 *  \sa SDL_GL_DeleteContext()
 */
SDL_GLContext SDL_GL_CreateContext(SDL_Window *
														   window);

/**
 *  \brief Set up an OpenGL context for rendering into an OpenGL window.
 *
 *  \note The context must have been created with a compatible window.
 */
int SDL_GL_MakeCurrent(SDL_Window * window,
											   SDL_GLContext context);

/**
 *  \brief Get the currently active OpenGL window.
 */
SDL_Window* SDL_GL_GetCurrentWindow();

/**
 *  \brief Get the currently active OpenGL context.
 */
SDL_GLContext SDL_GL_GetCurrentContext();

/**
 *  \brief Set the swap interval for the current OpenGL context.
 *
 *  \param interval 0 for immediate updates, 1 for updates synchronized with the
 *				  vertical retrace. If the system supports it, you may
 *				  specify -1 to allow late swaps to happen immediately
 *				  instead of waiting for the next retrace.
 *
 *  \return 0 on success, or -1 if setting the swap interval is not supported.
 *
 *  \sa SDL_GL_GetSwapInterval()
 */
int SDL_GL_SetSwapInterval(int interval);

/**
 *  \brief Get the swap interval for the current OpenGL context.
 *
 *  \return 0 if there is no vertical retrace synchronization, 1 if the buffer
 *		  swap is synchronized with the vertical retrace, and -1 if late
 *		  swaps happen immediately instead of waiting for the next retrace.
 *		  If the system can't determine the swap interval, or there isn't a
 *		  valid current context, this will return 0 as a safe default.
 *
 *  \sa SDL_GL_SetSwapInterval()
 */
int SDL_GL_GetSwapInterval();

/**
 * \brief Swap the OpenGL buffers for a window, if double-buffering is
 *		supported.
 */
void SDL_GL_SwapWindow(SDL_Window * window);

/**
 *  \brief Delete an OpenGL context.
 *
 *  \sa SDL_GL_CreateContext()
 */
void SDL_GL_DeleteContext(SDL_GLContext context);

