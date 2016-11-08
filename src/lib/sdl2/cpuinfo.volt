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
module lib.sdl2.cpuinfo;
extern (C):

import lib.sdl2.stdinc;

/* This is a guess for the cacheline size used for padding.
 * Most x86 processors have a 64 byte cache line.
 * The 64-bit PowerPC processors have a 128 byte cache line.
 * We'll use the larger value to be generally safe.
 */
enum SDL_CACHELINE_SIZE = 128;

/**
 *  This function returns the number of CPU cores available.
 */
int  SDL_GetCPUCount();

/**
 *  This function returns the L1 cache line size of the CPU
 *
 *  This is useful for determining multi-threaded structure padding
 *  or SIMD prefetch sizes.
 */
int  SDL_GetCPUCacheLineSize();

/**
 *  This function returns true if the CPU has the RDTSC instruction.
 */
SDL_bool  SDL_HasRDTSC();

/**
 *  This function returns true if the CPU has AltiVec features.
 */
SDL_bool  SDL_HasAltiVec();

/**
 *  This function returns true if the CPU has MMX features.
 */
SDL_bool  SDL_HasMMX();

/**
 *  This function returns true if the CPU has 3DNow! features.
 */
SDL_bool  SDL_Has3DNow();

/**
 *  This function returns true if the CPU has SSE features.
 */
SDL_bool  SDL_HasSSE();

/**
 *  This function returns true if the CPU has SSE2 features.
 */
SDL_bool  SDL_HasSSE2();

/**
 *  This function returns true if the CPU has SSE3 features.
 */
SDL_bool  SDL_HasSSE3();

/**
 *  This function returns true if the CPU has SSE4.1 features.
 */
SDL_bool  SDL_HasSSE41();

/**
 *  This function returns true if the CPU has SSE4.2 features.
 */
SDL_bool  SDL_HasSSE42();

