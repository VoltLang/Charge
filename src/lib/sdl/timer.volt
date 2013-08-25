// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.timer;

import lib.sdl.types;


enum : Uint32
{
	SDL_TIMESLICE  = 10,
	SDL_RESOLUTION = 10,
}

alias SDL_TimerID = void*;

alias SDL_TimerCallback = /* XXX extern(C)*/ Uint32 function(Uint32);
alias SDL_NewTimerCallback = /* XXX extern(C)*/ Uint32 function(Uint32,void*);

version (DynamicSDL) @loadDynamic:
extern(C):
Uint32 SDL_GetTicks();
void SDL_Delay(Uint32);
int SDL_SetTimer(Uint32,SDL_TimerCallback);
SDL_TimerID SDL_AddTimer(Uint32,SDL_NewTimerCallback,void*);
SDL_bool SDL_RemoveTimer(SDL_TimerID);
