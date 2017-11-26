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
module lib.sdl2.gesture;
extern (C):
version (!Windows):

/*
 *  \file SDL_gesture.h
 *
 *  Include file for SDL gesture event handling.
 */

import lib.sdl2.stdinc;
import lib.sdl2.error;
import lib.sdl2.video;
import lib.sdl2.touch;
import lib.sdl2.rwops;

alias SDL_GestureID = Sint64;

/* Function prototypes */

/*!
 *  \brief Begin Recording a gesture on the specified touch, or all touches (-1)
 *
 *
 */
int SDL_RecordGesture(SDL_TouchID touchId);


/*!
 *  \brief Save all currently loaded Dollar Gesture templates
 *
 *
 */
int SDL_SaveAllDollarTemplates(SDL_RWops *src);

/*!
 *  \brief Save a currently loaded Dollar Gesture template
 *
 *
 */
int SDL_SaveDollarTemplate(SDL_GestureID gestureId,SDL_RWops *src);


/*!
 *  \brief Load Dollar Gesture templates from a file
 *
 *
 */
int SDL_LoadDollarTemplates(SDL_TouchID touchId, SDL_RWops *src);

