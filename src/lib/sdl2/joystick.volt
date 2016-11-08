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

/**
 *  \file SDL_joystick.h
 *
 *  Include file for SDL joystick event handling
 *
 * The term "device_index" identifies currently plugged in joystick devices between 0 and SDL_NumJoysticks, with the exact joystick
 *   behind a device_index changing as joysticks are plugged and unplugged.
 *
 * The term "instance_id" is the current instantiation of a joystick device in the system, if the joystick is removed and then re-inserted
 *   then it will get a new instance_id, instance_id's are monotonically increasing identifiers of a joystick plugged in.
 *
 * The term JoystickGUID is a stable 128-bit identifier for a joystick device that does not change over time, it identifies class of
 *   the device (a X360 wired controller for example). This identifier is platform dependent.
 *
 *
 */
module lib.sdl2.joystick;
extern (C):

import lib.sdl2.stdinc;
import lib.sdl2.error;

/**
 *  \file SDL_joystick.h
 *
 *  In order to use these functions, SDL_Init() must have been called
 *  with the ::SDL_INIT_JOYSTICK flag.  This causes SDL to scan the system
 *  for joysticks, and load appropriate drivers.
 *
 *  If you would like to receive joystick updates while the application
 *  is in the background, you should set the following hint before calling
 *  SDL_Init(): SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS
 */

/* The joystick structure used to identify an SDL joystick */
struct _SDL_Joystick {}
alias SDL_Joystick = _SDL_Joystick;

/* A structure that encodes the stable unique id for a joystick device */
struct SDL_JoystickGUID {
    Uint8[16] data;
}

alias SDL_JoystickID = Sint32;


/* Function prototypes */
/**
 *  Count the number of joysticks attached to the system right now
 */
int  SDL_NumJoysticks();

/**
 *  Get the implementation dependent name of a joystick.
 *  This can be called before any joysticks are opened.
 *  If no name can be found, this function returns NULL.
 */
const char * SDL_JoystickNameForIndex(int device_index);

/**
 *  Open a joystick for use.
 *  The index passed as an argument refers tothe N'th joystick on the system.
 *  This index is the value which will identify this joystick in future joystick
 *  events.
 *
 *  \return A joystick identifier, or NULL if an error occurred.
 */
SDL_Joystick * SDL_JoystickOpen(int device_index);

/**
 *  Return the name for this currently opened joystick.
 *  If no name can be found, this function returns NULL.
 */
const char * SDL_JoystickName(SDL_Joystick * joystick);

/**
 *  Return the GUID for the joystick at this index
 */
SDL_JoystickGUID  SDL_JoystickGetDeviceGUID(int device_index);

/**
 *  Return the GUID for this opened joystick
 */
SDL_JoystickGUID  SDL_JoystickGetGUID(SDL_Joystick * joystick);

/**
 *  Return a string representation for this guid. pszGUID must point to at least 33 bytes
 *  (32 for the string plus a NULL terminator).
 */
void SDL_JoystickGetGUIDString(SDL_JoystickGUID guid, char *pszGUID, int cbGUID);

/**
 *  convert a string into a joystick formatted guid
 */
SDL_JoystickGUID  SDL_JoystickGetGUIDFromString(const char *pchGUID);

/**
 *  Returns SDL_TRUE if the joystick has been opened and currently connected, or SDL_FALSE if it has not.
 */
SDL_bool  SDL_JoystickGetAttached(SDL_Joystick * joystick);

/**
 *  Get the instance ID of an opened joystick or -1 if the joystick is invalid.
 */
SDL_JoystickID  SDL_JoystickInstanceID(SDL_Joystick * joystick);

/**
 *  Get the number of general axis controls on a joystick.
 */
int  SDL_JoystickNumAxes(SDL_Joystick * joystick);

/**
 *  Get the number of trackballs on a joystick.
 *
 *  Joystick trackballs have only relative motion events associated
 *  with them and their state cannot be polled.
 */
int  SDL_JoystickNumBalls(SDL_Joystick * joystick);

/**
 *  Get the number of POV hats on a joystick.
 */
int  SDL_JoystickNumHats(SDL_Joystick * joystick);

/**
 *  Get the number of buttons on a joystick.
 */
int  SDL_JoystickNumButtons(SDL_Joystick * joystick);

/**
 *  Update the current state of the open joysticks.
 *
 *  This is called automatically by the event loop if any joystick
 *  events are enabled.
 */
void  SDL_JoystickUpdate();

/**
 *  Enable/disable joystick event polling.
 *
 *  If joystick events are disabled, you must call SDL_JoystickUpdate()
 *  yourself and check the state of the joystick when you want joystick
 *  information.
 *
 *  The state can be one of ::SDL_QUERY, ::SDL_ENABLE or ::SDL_IGNORE.
 */
int  SDL_JoystickEventState(int state);

/**
 *  Get the current state of an axis control on a joystick.
 *
 *  The state is a value ranging from -32768 to 32767.
 *
 *  The axis indices start at index 0.
 */
Sint16  SDL_JoystickGetAxis(SDL_Joystick * joystick,
                                                   int axis);

/**
 *  \name Hat positions
 */
/* */
enum SDL_HAT_CENTERED = 0x00;
enum SDL_HAT_UP = 0x01;
enum SDL_HAT_RIGHT = 0x02;
enum SDL_HAT_DOWN = 0x04;
enum SDL_HAT_LEFT = 0x08;
enum SDL_HAT_RIGHTUP = (SDL_HAT_RIGHT|SDL_HAT_UP);
enum SDL_HAT_RIGHTDOWN = (SDL_HAT_RIGHT|SDL_HAT_DOWN);
enum SDL_HAT_LEFTUP = (SDL_HAT_LEFT|SDL_HAT_UP);
enum SDL_HAT_LEFTDOWN = (SDL_HAT_LEFT|SDL_HAT_DOWN);
/* */

/**
 *  Get the current state of a POV hat on a joystick.
 *
 *  The hat indices start at index 0.
 *
 *  \return The return value is one of the following positions:
 *           - ::SDL_HAT_CENTERED
 *           - ::SDL_HAT_UP
 *           - ::SDL_HAT_RIGHT
 *           - ::SDL_HAT_DOWN
 *           - ::SDL_HAT_LEFT
 *           - ::SDL_HAT_RIGHTUP
 *           - ::SDL_HAT_RIGHTDOWN
 *           - ::SDL_HAT_LEFTUP
 *           - ::SDL_HAT_LEFTDOWN
 */
Uint8  SDL_JoystickGetHat(SDL_Joystick * joystick,
                                                 int hat);

/**
 *  Get the ball axis change since the last poll.
 *
 *  \return 0, or -1 if you passed it invalid parameters.
 *
 *  The ball indices start at index 0.
 */
int  SDL_JoystickGetBall(SDL_Joystick * joystick,
                                                int ball, int *dx, int *dy);

/**
 *  Get the current state of a button on a joystick.
 *
 *  The button indices start at index 0.
 */
Uint8  SDL_JoystickGetButton(SDL_Joystick * joystick,
                                                    int button);

/**
 *  Close a joystick previously opened with SDL_JoystickOpen().
 */
void  SDL_JoystickClose(SDL_Joystick * joystick);

