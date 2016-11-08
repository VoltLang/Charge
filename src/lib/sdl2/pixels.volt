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
module lib.sdl2.pixels;
extern (C):

enum SDL_ALPHA_OPAQUE = 255;
enum SDL_ALPHA_TRANSPARENT = 0;

enum
{
	SDL_PIXELTYPE_UNKNOWN,
	SDL_PIXELTYPE_INDEX1,
	SDL_PIXELTYPE_INDEX4,
	SDL_PIXELTYPE_INDEX8,
	SDL_PIXELTYPE_PACKED8,
	SDL_PIXELTYPE_PACKED16,
	SDL_PIXELTYPE_PACKED32,
	SDL_PIXELTYPE_ARRAYU8,
	SDL_PIXELTYPE_ARRAYU16,
	SDL_PIXELTYPE_ARRAYU32,
	SDL_PIXELTYPE_ARRAYF16,
	SDL_PIXELTYPE_ARRAYF32
}

enum
{
	SDL_BITMAPORDER_NONE,
	SDL_BITMAPORDER_4321,
	SDL_BITMAPORDER_1234
}

enum
{
	SDL_PACKEDORDER_NONE,
	SDL_PACKEDORDER_XRGB,
	SDL_PACKEDORDER_RGBX,
	SDL_PACKEDORDER_ARGB,
	SDL_PACKEDORDER_RGBA,
	SDL_PACKEDORDER_XBGR,
	SDL_PACKEDORDER_BGRX,
	SDL_PACKEDORDER_ABGR,
	SDL_PACKEDORDER_BGRA
}

enum
{
	SDL_ARRAYORDER_NONE,
	SDL_ARRAYORDER_RGB,
	SDL_ARRAYORDER_RGBA,
	SDL_ARRAYORDER_ARGB,
	SDL_ARRAYORDER_BGR,
	SDL_ARRAYORDER_BGRA,
	SDL_ARRAYORDER_ABGR
}

enum
{
	SDL_PACKEDLAYOUT_NONE,
	SDL_PACKEDLAYOUT_332,
	SDL_PACKEDLAYOUT_4444,
	SDL_PACKEDLAYOUT_1555,
	SDL_PACKEDLAYOUT_5551,
	SDL_PACKEDLAYOUT_565,
	SDL_PACKEDLAYOUT_8888,
	SDL_PACKEDLAYOUT_2101010,
	SDL_PACKEDLAYOUT_1010102
}

enum
{
	SDL_PIXELFORMAT_UNKNOWN,
	SDL_PIXELFORMAT_INDEX1LSB = ((1 << 28) | (SDL_PIXELTYPE_INDEX1 << 24) | (SDL_BITMAPORDER_4321 << 20) | (0 << 16) | (1 << 8) | (0 << 0)),
	SDL_PIXELFORMAT_INDEX1MSB = ((1 << 28) | (SDL_PIXELTYPE_INDEX1 << 24) | (SDL_BITMAPORDER_1234 << 20) | (0 << 16) | (1 << 8) | (0 << 0)),
	SDL_PIXELFORMAT_INDEX4LSB = ((1 << 28) | (SDL_PIXELTYPE_INDEX4 << 24) | (SDL_BITMAPORDER_4321 << 20) | (0 << 16) | (4 << 8) | (0 << 0)),
	SDL_PIXELFORMAT_INDEX4MSB = ((1 << 28) | (SDL_PIXELTYPE_INDEX4 << 24) | (SDL_BITMAPORDER_1234 << 20) | (0 << 16) | (4 << 8) | (0 << 0)),
	SDL_PIXELFORMAT_INDEX8 = ((1 << 28) | (SDL_PIXELTYPE_INDEX8 << 24) | (0 << 20) | (0 << 16) | (8 << 8) | (1 << 0)),
	SDL_PIXELFORMAT_RGB332 = ((1 << 28) | (SDL_PIXELTYPE_PACKED8 << 24) | (SDL_PACKEDORDER_XRGB << 20) | (SDL_PACKEDLAYOUT_332 << 16) | (8 << 8) | (1 << 0)),
	SDL_PIXELFORMAT_RGB444 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_XRGB << 20) | (SDL_PACKEDLAYOUT_4444 << 16) | (12 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_RGB555 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_XRGB << 20) | (SDL_PACKEDLAYOUT_1555 << 16) | (15 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_BGR555 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_XBGR << 20) | (SDL_PACKEDLAYOUT_1555 << 16) | (15 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_ARGB4444 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_ARGB << 20) | (SDL_PACKEDLAYOUT_4444 << 16) | (16 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_RGBA4444 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_RGBA << 20) | (SDL_PACKEDLAYOUT_4444 << 16) | (16 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_ABGR4444 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_ABGR << 20) | (SDL_PACKEDLAYOUT_4444 << 16) | (16 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_BGRA4444 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_BGRA << 20) | (SDL_PACKEDLAYOUT_4444 << 16) | (16 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_ARGB1555 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_ARGB << 20) | (SDL_PACKEDLAYOUT_1555 << 16) | (16 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_RGBA5551 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_RGBA << 20) | (SDL_PACKEDLAYOUT_5551 << 16) | (16 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_ABGR1555 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_ABGR << 20) | (SDL_PACKEDLAYOUT_1555 << 16) | (16 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_BGRA5551 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_BGRA << 20) | (SDL_PACKEDLAYOUT_5551 << 16) | (16 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_RGB565 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_XRGB << 20) | (SDL_PACKEDLAYOUT_565 << 16) | (16 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_BGR565 = ((1 << 28) | (SDL_PIXELTYPE_PACKED16 << 24) | (SDL_PACKEDORDER_XBGR << 20) | (SDL_PACKEDLAYOUT_565 << 16) | (16 << 8) | (2 << 0)),
	SDL_PIXELFORMAT_RGB24 = ((1 << 28) | (SDL_PIXELTYPE_ARRAYU8 << 24) | (SDL_ARRAYORDER_RGB << 20) | (0 << 16) | (24 << 8) | (3 << 0)),
	SDL_PIXELFORMAT_BGR24 = ((1 << 28) | (SDL_PIXELTYPE_ARRAYU8 << 24) | (SDL_ARRAYORDER_BGR << 20) | (0 << 16) | (24 << 8) | (3 << 0)),
	SDL_PIXELFORMAT_RGB888 = ((1 << 28) | (SDL_PIXELTYPE_PACKED32 << 24) | (SDL_PACKEDORDER_XRGB << 20) | (SDL_PACKEDLAYOUT_8888 << 16) | (24 << 8) | (4 <<0)),
	SDL_PIXELFORMAT_RGBX8888 = ((1 << 28) | (SDL_PIXELTYPE_PACKED32 << 24) | (SDL_PACKEDORDER_RGBX << 20) | (SDL_PACKEDLAYOUT_8888 << 16) | (24 << 8) | (4 <<0)),
	SDL_PIXELFORMAT_BGR888 = ((1 << 28) | (SDL_PIXELTYPE_PACKED32 << 24) | (SDL_PACKEDORDER_XBGR << 20) | (SDL_PACKEDLAYOUT_8888 << 16) | (24 << 8) | (4 <<0)),
SDL_PIXELFORMAT_BGRX8888 =
		((1 << 28) | ((SDL_PIXELTYPE_PACKED32) << 24) | ((SDL_PACKEDORDER_BGRX) << 20) | ((SDL_PACKEDLAYOUT_8888) << 16) | ((24) << 8) | ((4) << 0)),
	SDL_PIXELFORMAT_ARGB8888 =
		((1 << 28) | ((SDL_PIXELTYPE_PACKED32) << 24) | ((SDL_PACKEDORDER_ARGB) << 20) | ((SDL_PACKEDLAYOUT_8888) << 16) | ((32) << 8) | ((4) << 0)),
	SDL_PIXELFORMAT_RGBA8888 =
		((1 << 28) | ((SDL_PIXELTYPE_PACKED32) << 24) | ((SDL_PACKEDORDER_RGBA) << 20) | ((SDL_PACKEDLAYOUT_8888) << 16) | ((32) << 8) | ((4) << 0)),
	SDL_PIXELFORMAT_ABGR8888 =
		((1 << 28) | ((SDL_PIXELTYPE_PACKED32) << 24) | ((SDL_PACKEDORDER_ABGR) << 20) | ((SDL_PACKEDLAYOUT_8888) << 16) | ((32) << 8) | ((4) << 0)),
	SDL_PIXELFORMAT_BGRA8888 =
		((1 << 28) | ((SDL_PIXELTYPE_PACKED32) << 24) | ((SDL_PACKEDORDER_BGRA) << 20) | ((SDL_PACKEDLAYOUT_8888) << 16) | ((32) << 8) | ((4) << 0)),
	SDL_PIXELFORMAT_ARGB2101010 =
		((1 << 28) | ((SDL_PIXELTYPE_PACKED32) << 24) | ((SDL_PACKEDORDER_ARGB) << 20) | ((SDL_PACKEDLAYOUT_2101010) << 16) | ((32) << 8) | ((4) << 0))
}

struct SDL_Color
{
	ubyte r;
	ubyte g;
	ubyte b;
	ubyte a;
}

struct SDL_Palette
{
	int ncolors;
	SDL_Color* colors;
	uint _version;
	int refcount;
}

struct SDL_PixelFormat
{
	uint format;
	SDL_Palette* palette;
	ubyte BitsPerPixel;
	ubyte BytesPerPixel;
	ushort padding;
	uint Rmask;
	uint Gmask;
	uint Bmask;
	uint Amask;
	ubyte Rloss;
	ubyte Gloss;
	ubyte Bloss;
	ubyte Aloss;
	ubyte Rshift;
	ubyte Gshift;
	ubyte Bshift;
	ubyte Ashift;
	int refcount;
	SDL_PixelFormat* next;
}

const(char)* SDL_GetPixelFormatName(uint);
bool SDL_PixelFormatEnumToMasks(uint, int*, uint*, uint*, uint*, uint*);
uint SDL_MasksToPixelFormatEnum(int, uint, uint, uint, uint);
SDL_PixelFormat* SDL_AllocFormat(uint);
void SDL_FreeFormat(SDL_PixelFormat*);
SDL_Palette* SDL_AllocPalette(int);
int SDL_SetPixelFormatPalette(SDL_PixelFormat*, SDL_Palette*);
int SDL_SetPaletteColors(SDL_Palette*, in SDL_Color*, int, int);
void SDL_FreePalette(SDL_Palette*);
uint SDL_MapRGB(in SDL_PixelFormat*, ubyte, ubyte, ubyte);
uint SDL_MapRGBA(in SDL_PixelFormat*, ubyte, ubyte, ubyte, ubyte);
void SDL_CalculateGammaRamp(float, ushort*);

