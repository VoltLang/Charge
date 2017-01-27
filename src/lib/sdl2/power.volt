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
module lib.sdl2.power;
extern (C):
version (!Windows):


/*
 *  \file SDL_power.h
 *
 *  Header for the SDL power management routines.
 */

import lib.sdl2.stdinc;

/**
 *  \brief The basic state for the system's power supply.
 */
alias SDL_PowerState = int;
enum : SDL_PowerState
{
    SDL_POWERSTATE_UNKNOWN,      /*< cannot determine power status */
    SDL_POWERSTATE_ON_BATTERY,   /*< Not plugged in, running on the battery */
    SDL_POWERSTATE_NO_BATTERY,   /*< Plugged in, no battery available */
    SDL_POWERSTATE_CHARGING,     /*< Plugged in, charging battery */
    SDL_POWERSTATE_CHARGED       /*< Plugged in, battery charged */
}


/**
 *  \brief Get the current power supply details.
 *
 *  \param secs Seconds of battery life left. You can pass a NULL here if
 *              you don't care. Will return -1 if we can't determine a
 *              value, or we're not running on a battery.
 *
 *  \param pct Percentage of battery life left, between 0 and 100. You can
 *             pass a NULL here if you don't care. Will return -1 if we
 *             can't determine a value, or we're not running on a battery.
 *
 *  \return The state of the battery (if any).
 */
SDL_PowerState SDL_GetPowerInfo(int *secs, int *pct);

