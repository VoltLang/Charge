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
module lib.sdl2.touch;
extern (C):

/*
 *  \file SDL_touch.h
 *
 *  Include file for SDL touch event handling.
 */

import lib.sdl2.stdinc;

alias SDL_TouchID = Sint64;
alias SDL_FingerID = Sint64;

struct SDL_Finger
{
    SDL_FingerID id;
    float x;
    float y;
    float pressure;
}

/* Used as the device ID for mouse events simulated with touch input */
@property uint SDL_TOUCH_MOUSEID() { return cast(Uint32)-1; }


/* Function prototypes */

/**
 *  \brief Get the number of registered touch devices.
 */
int SDL_GetNumTouchDevices();

/**
 *  \brief Get the touch ID with the given index, or 0 if the index is invalid.
 */
SDL_TouchID SDL_GetTouchDevice(int index);

/**
 *  \brief Get the number of active fingers for a given touch device.
 */
int SDL_GetNumTouchFingers(SDL_TouchID touchID);

/**
 *  \brief Get the finger object of the given touch, with the given index.
 */
SDL_Finger * SDL_GetTouchFinger(SDL_TouchID touchID, int index);

