// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.audio;

import lib.sdl.types;
import lib.sdl.rwops;


struct SDL_AudioSpec
{
	int    freq;
	Uint16 format;
	Uint8  channels;
	Uint8  silence;
	Uint16 samples;
	Uint16 padding;
	Uint32 size;

	extern (C) void function(void *userdata, Uint8 *stream, int len) callback;
	void *userdata;
}

enum AUDIO_U8     = 0x0008;
enum AUDIO_S8     = 0x8008;
enum AUDIO_U16LSB = 0x0010; /* little */
enum AUDIO_S16LSB = 0x8010;
enum AUDIO_U16MSB = 0x1010; /* big */
enum AUDIO_S16MSB = 0x9010;

version(LittleEndian)
{
	enum AUDIO_U16SYS = AUDIO_U16LSB;
	enum AUDIO_S16SYS = AUDIO_S16LSB;
}
else
{
	enum AUDIO_U16SYS = AUDIO_U16MSB;
	enum AUDIO_S16SYS = AUDIO_S16MSB;
}

version(!StaticSDL) @loadDynamic:
extern(C):
SDL_AudioSpec* SDL_LoadWAV_RW(SDL_RWops *src, int freesrc, SDL_AudioSpec *spec, Uint8 **audio_buf, Uint32 *audio_len);
void SDL_FreeWAV(Uint8 *audio_buf);
