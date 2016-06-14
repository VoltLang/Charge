// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.video;

import lib.sdl.types;
import lib.sdl.rwops;


enum SDL_ALPHA_OPAQUE      = 255;
enum SDL_ALPHA_TRANSPARENT = 0;

struct SDL_Rect {
	Sint16 x, y;
	Uint16 w, h;
}

struct SDL_Color
{
	Uint8 r;
	Uint8 g;
	Uint8 b;
	Uint8 unused;
}
alias SDL_Colour = SDL_Color;

struct SDL_Palette
{
	int       ncolors;
	SDL_Color *colors;
}

struct SDL_PixelFormat
{
	SDL_Palette *palette;
	Uint8  BitsPerPixel;
	Uint8  BytesPerPixel;
	Uint8  Rloss;
	Uint8  Gloss;
	Uint8  Bloss;
	Uint8  Aloss;
	Uint8  Rshift;
	Uint8  Gshift;
	Uint8  Bshift;
	Uint8  Ashift;
	Uint32 Rmask;
	Uint32 Gmask;
	Uint32 Bmask;
	Uint32 Amask;
	Uint32 colorkey;
	Uint8  alpha;
}

struct SDL_Surface
{
	Uint32 flags;
	SDL_PixelFormat *format;
	int w, h;
	Uint16 pitch;
	void *pixels;
	int offset;
	void *hwdata;
	SDL_Rect clip_rect;
	Uint32 unused1;
	Uint32 locked;
	void *map;
	uint format_version;
	int refcount;
}

enum SDL_SWSURFACE   = 0x00000000;
enum SDL_HWSURFACE   = 0x00000001;
enum SDL_ASYNCBLIT   = 0x00000004;

enum SDL_ANYFORMAT   = 0x10000000;
enum SDL_HWPALETTE   = 0x20000000;
enum SDL_DOUBLEBUF   = 0x40000000;
enum SDL_FULLSCREEN  = 0x80000000;
enum SDL_OPENGL      = 0x00000002;
enum SDL_OPENGLBLIT  = 0x0000000A;
enum SDL_RESIZABLE   = 0x00000010;
enum SDL_NOFRAME     = 0x00000020;

enum SDL_HWACCEL     = 0x00000100;
enum SDL_SRCCOLORKEY = 0x00001000;
enum SDL_RLEACCELOK  = 0x00002000;
enum SDL_RLEACCEL    = 0x00004000;
enum SDL_SRCALPHA    = 0x00010000;
enum SDL_PREALLOC    = 0x01000000;

struct SDL_VideoInfo
{
	Uint32 flags;
	Uint32 video_mem;
	SDL_PixelFormat *vfmt;
	int current_w;
	int current_h;
}

enum SDL_YV12_OVERLAY = 0x32315659;
enum SDL_IYUV_OVERLAY = 0x56555949;
enum SDL_YUY2_OVERLAY = 0x32595559;
enum SDL_UYVY_OVERLAY = 0x59565955;
enum SDL_YVYU_OVERLAY = 0x55595659;

struct SDL_Overlay
{
	Uint32 format;
	int w, h;
	int planes;
	Uint16 *pitches;
	Uint8 **pixels;

	void *hwfuncs;
	void *hwdata;

	Uint32 flags;
}

enum
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
    SDL_GL_SWAP_CONTROL
}

enum SDL_LOGPAL = 0x01;
enum SDL_PHYSPAL = 0x02;

enum SDL_GrabMode
{
	SDL_GRAB_QUERY = -1,
	SDL_GRAB_OFF = 0,
	SDL_GRAB_ON = 1,
	SDL_GRAB_FULLSCREEN
}

alias SDL_blit = /* XXX extern(C)*/ int function(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect);


//bool SDL_MUSTLOCK(SDL_Surface* surface) { return surface.offset || ((surface.flags & (SDL_HWSURFACE|SDL_ASYNCBLIT|SDL_RLEACCEL)) != 0); }
int SDL_SaveBMP(SDL_Surface* surface, char* file) { return SDL_SaveBMP_RW(surface, SDL_RWFromFile(file, "wb".ptr), 1); }
alias SDL_AllocSurface = SDL_CreateRGBSurface;
alias SDL_BlitSurface = SDL_UpperBlit;

version (!StaticSDL) @loadDynamic:
extern (C):
int SDL_VideoInit(char *driver_name, Uint32 flags);
void SDL_VideoQuit();
char * SDL_VideoDriverName(char *namebuf, int maxlen);
SDL_Surface * SDL_GetVideoSurface();
SDL_VideoInfo * SDL_GetVideoInfo();
int SDL_VideoModeOK(int width, int height, int bpp, Uint32 flags);
SDL_Rect ** SDL_ListModes(SDL_PixelFormat *format, Uint32 flags);
SDL_Surface * SDL_SetVideoMode(int width, int height, int bpp, Uint32 flags);
void SDL_UpdateRects(SDL_Surface *screen, int numrects, SDL_Rect *rects);
void SDL_UpdateRect(SDL_Surface *screen, Sint32 x, Sint32 y, Uint32 w, Uint32 h);
int SDL_Flip(SDL_Surface *screen);
int SDL_SetGamma(float red, float green, float blue);
int SDL_SetGammaRamp(Uint16 *red, Uint16 *green, Uint16 *blue);
int SDL_GetGammaRamp(Uint16 *red, Uint16 *green, Uint16 *blue);
int SDL_SetColors(SDL_Surface *surface, SDL_Color *colors, int firstcolor, int ncolors);
int SDL_SetPalette(SDL_Surface *surface, int flags, SDL_Color *colors, int firstcolor, int ncolors);
Uint32 SDL_MapRGB(SDL_PixelFormat *format, Uint8 r, Uint8 g, Uint8 b);
Uint32 SDL_MapRGBA(SDL_PixelFormat *format, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
void SDL_GetRGB(Uint32 pixel, SDL_PixelFormat *fmt, Uint8 *r, Uint8 *g, Uint8 *b);
void SDL_GetRGBA(Uint32 pixel, SDL_PixelFormat *fmt, Uint8 *r, Uint8 *g, Uint8 *b, Uint8 *a);
SDL_Surface * SDL_CreateRGBSurface(Uint32 flags, int width, int height, int depth, Uint32 Rmask, Uint32 Gmask, Uint32 Bmask, Uint32 Amask);
SDL_Surface * SDL_CreateRGBSurfaceFrom(void *pixels, int width, int height, int depth, int pitch, Uint32 Rmask, Uint32 Gmask, Uint32 Bmask, Uint32 Amask);
void SDL_FreeSurface(SDL_Surface *surface);
int SDL_LockSurface(SDL_Surface *surface);
void SDL_UnlockSurface(SDL_Surface *surface);
int SDL_SaveBMP_RW(SDL_Surface* surface, SDL_RWops*   dst, int freedst);
int SDL_SetColorKey(SDL_Surface *surface, Uint32 flag, Uint32 key);
int SDL_SetAlpha(SDL_Surface *surface, Uint32 flag, Uint8 alpha);
SDL_bool SDL_SetClipRect(SDL_Surface *surface, SDL_Rect *rect);
void SDL_GetClipRect(SDL_Surface *surface, SDL_Rect *rect);
SDL_Surface * SDL_ConvertSurface(SDL_Surface *src, SDL_PixelFormat *fmt, Uint32 flags);
int SDL_UpperBlit(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect);
int SDL_LowerBlit(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect);
int SDL_FillRect(SDL_Surface *dst, SDL_Rect *dstrect, Uint32 color);
SDL_Surface * SDL_DisplayFormat(SDL_Surface *surface);
SDL_Surface * SDL_DisplayFormatAlpha(SDL_Surface *surface);
SDL_Overlay * SDL_CreateYUVOverlay(int width, int height, Uint32 format, SDL_Surface *display);
int SDL_LockYUVOverlay(SDL_Overlay *overlay);
void SDL_UnlockYUVOverlay(SDL_Overlay *overlay);
int SDL_DisplayYUVOverlay(SDL_Overlay *overlay, SDL_Rect *dstrect);
void SDL_FreeYUVOverlay(SDL_Overlay *overlay);
int SDL_GL_LoadLibrary(char *path);
void * SDL_GL_GetProcAddress(const(char)* proc);
int SDL_GL_SetAttribute(int attr, int value);
int SDL_GL_GetAttribute(int attr, int* value);
void SDL_GL_SwapBuffers();
void SDL_GL_UpdateRects(int numrects, SDL_Rect* rects);
void SDL_GL_Lock();
void SDL_GL_Unlock();
void SDL_WM_SetCaption(const(char)* title, const(char)* icon);
void SDL_WM_GetCaption(char **title, char **icon);
void SDL_WM_SetIcon(SDL_Surface *icon, Uint8 *mask);
int SDL_WM_IconifyWindow();
int SDL_WM_ToggleFullScreen(SDL_Surface *surface);
SDL_GrabMode SDL_WM_GrabInput(SDL_GrabMode mode);
int SDL_SoftStretch(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect);
