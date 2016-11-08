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
module lib.sdl2.events;
extern (C):

/*
 *  \file SDL_events.h
 *
 *  Include file for SDL event handling.
 */

import lib.sdl2.stdinc;
import lib.sdl2.error;
import lib.sdl2.video;
import lib.sdl2.keyboard;
import lib.sdl2.mouse;
import lib.sdl2.joystick;
import lib.sdl2.gamecontroller;
import lib.sdl2.quit;
import lib.sdl2.gesture;
import lib.sdl2.touch;

/* General keyboard/mouse state definitions */
enum SDL_RELEASED = 0;
enum SDL_PRESSED = 1;

/**
 * \brief The types of events that can be delivered.
 */
alias SDL_EventType = uint;
enum : SDL_EventType
{
    SDL_FIRSTEVENT     = 0,     /*< Unused (do not remove) */

    /* Application events */
    SDL_QUIT           = 0x100U, /*< User-requested quit */

    /* These application events have special meaning on iOS, see README-ios.txt for details */
    SDL_APP_TERMINATING = 0x101U,        /*< The application is being terminated by the OS
                                     Called on iOS in applicationWillTerminate()
                                     Called on Android in onDestroy()
                                */
    SDL_APP_LOWMEMORY = 0x102U,          /*< The application is low on memory, free memory if possible.
                                     Called on iOS in applicationDidReceiveMemoryWarning()
                                     Called on Android in onLowMemory()
                                */
    SDL_APP_WILLENTERBACKGROUND = 0x103U, /*< The application is about to enter the background
                                     Called on iOS in applicationWillResignActive()
                                     Called on Android in onPause()
                                */
    SDL_APP_DIDENTERBACKGROUND = 0x104U, /*< The application did enter the background and may not get CPU for some time
                                     Called on iOS in applicationDidEnterBackground()
                                     Called on Android in onPause()
                                */
    SDL_APP_WILLENTERFOREGROUND = 0x105U, /*< The application is about to enter the foreground
                                     Called on iOS in applicationWillEnterForeground()
                                     Called on Android in onResume()
                                */
    SDL_APP_DIDENTERFOREGROUND = 0x106U, /*< The application is now interactive
                                     Called on iOS in applicationDidBecomeActive()
                                     Called on Android in onResume()
                                */

    /* Window events */
    SDL_WINDOWEVENT    = 0x200U, /*< Window state change */
    SDL_SYSWMEVENT = 0x201U,             /*< System specific event */

    /* Keyboard events */
    SDL_KEYDOWN       = 0x300U, /*< Key pressed */
    SDL_KEYUP         = 0x301U, /*< Key released */
    SDL_TEXTEDITING   = 0x302U, /*< Keyboard text editing (composition) */
    SDL_TEXTINPUT     = 0x303U, /*< Keyboard text input */

    /* Mouse events */
    SDL_MOUSEMOTION    = 0x400U, /*< Mouse moved */
    SDL_MOUSEBUTTONDOWN = 0x401U,/*< Mouse button pressed */
    SDL_MOUSEBUTTONUP = 0x402U,  /*< Mouse button released */
    SDL_MOUSEWHEEL = 0x403U,     /*< Mouse wheel motion */

    /* Joystick events */
    SDL_JOYAXISMOTION  = 0x600U, /*< Joystick axis motion */
    SDL_JOYBALLMOTION = 0x601U, /*< Joystick trackball motion */
    SDL_JOYHATMOTION = 0x602U,  /*< Joystick hat position change */
    SDL_JOYBUTTONDOWN = 0x603U, /*< Joystick button pressed */
    SDL_JOYBUTTONUP = 0x604U,   /*< Joystick button released */
    SDL_JOYDEVICEADDED = 0x605U,/*< A new joystick has been inserted into the system */
    SDL_JOYDEVICEREMOVED = 0x606U,/*< An opened joystick has been removed */

    /* Game controller events */
    SDL_CONTROLLERAXISMOTION  = 0x650U, /*< Game controller axis motion */
    SDL_CONTROLLERBUTTONDOWN = 0x651U,          /*< Game controller button pressed */
    SDL_CONTROLLERBUTTONUP = 0x652U,            /*< Game controller button released */
    SDL_CONTROLLERDEVICEADDED = 0x653U,         /*< A new Game controller has been inserted into the system */
    SDL_CONTROLLERDEVICEREMOVED = 0x654U,       /*< An opened Game controller has been removed */
    SDL_CONTROLLERDEVICEREMAPPED = 0x655U,      /*< The controller mapping was updated */

    /* Touch events */
    SDL_FINGERDOWN      = 0x700U,
    SDL_FINGERUP = 0x701U,
    SDL_FINGERMOTION = 0x702U,

    /* Gesture events */
    SDL_DOLLARGESTURE   = 0x800U,
    SDL_DOLLARRECORD = 0x801U,
    SDL_MULTIGESTURE = 0x802U,

    /* Clipboard events */
    SDL_CLIPBOARDUPDATE = 0x900U, /*< The clipboard changed */

    /* Drag and drop events */
    SDL_DROPFILE        = 0x1000U, /*< The system requests a file open */

    /* Events ::SDL_USEREVENT through ::SDL_LASTEVENT are for your use,
     *  and should be allocated with SDL_RegisterEvents()
     */
    SDL_USEREVENT    = 0x8000U,

    /*
     *  This last event is only for bounding internal arrays
     */
    SDL_LASTEVENT    = 0xFFFFU
}

/**
 *  \brief Fields shared by every event
 */
struct SDL_CommonEvent
{
    Uint32 type;
    Uint32 timestamp;
}

/**
 *  \brief Window state change event data (event.window.*)
 */
struct SDL_WindowEvent
{
    Uint32 type;        /*< ::SDL_WINDOWEVENT */
    Uint32 timestamp;
    Uint32 windowID;    /*< The associated window */
    Uint8 event;        /*< ::SDL_WindowEventID */
    Uint8 padding1;
    Uint8 padding2;
    Uint8 padding3;
    Sint32 data1;       /*< event dependent data */
    Sint32 data2;       /*< event dependent data */
}

/**
 *  \brief Keyboard button event structure (event.key.*)
 */
struct SDL_KeyboardEvent
{
    Uint32 type;        /*< ::SDL_KEYDOWN or ::SDL_KEYUP */
    Uint32 timestamp;
    Uint32 windowID;    /*< The window with keyboard focus, if any */
    Uint8 state;        /*< ::SDL_PRESSED or ::SDL_RELEASED */
    Uint8 repeat;       /*< Non-zero if this is a key repeat */
    Uint8 padding2;
    Uint8 padding3;
    SDL_Keysym keysym;  /*< The key that was pressed or released */
}

enum SDL_TEXTEDITINGEVENT_TEXT_SIZE = (32);
/**
 *  \brief Keyboard text editing event structure (event.edit.*)
 */
struct SDL_TextEditingEvent
{
    Uint32 type;                                /*< ::SDL_TEXTEDITING */
    Uint32 timestamp;
    Uint32 windowID;                            /*< The window with keyboard focus, if any */
    char[32] text;  /*< The editing text */
    Sint32 start;                               /*< The start cursor of selected editing text */
    Sint32 length;                              /*< The length of selected editing text */
}


enum SDL_TEXTINPUTEVENT_TEXT_SIZE = (32);
/**
 *  \brief Keyboard text input event structure (event.text.*)
 */
struct SDL_TextInputEvent
{
    Uint32 type;                              /*< ::SDL_TEXTINPUT */
    Uint32 timestamp;
    Uint32 windowID;                          /*< The window with keyboard focus, if any */
    char[32] text;  /*< The input text */
}

/**
 *  \brief Mouse motion event structure (event.motion.*)
 */
struct SDL_MouseMotionEvent
{
    Uint32 type;        /*< ::SDL_MOUSEMOTION */
    Uint32 timestamp;
    Uint32 windowID;    /*< The window with mouse focus, if any */
    Uint32 which;       /*< The mouse instance id, or SDL_TOUCH_MOUSEID */
    Uint32 state;       /*< The current button state */
    Sint32 x;           /*< X coordinate, relative to window */
    Sint32 y;           /*< Y coordinate, relative to window */
    Sint32 xrel;        /*< The relative motion in the X direction */
    Sint32 yrel;        /*< The relative motion in the Y direction */
}

/**
 *  \brief Mouse button event structure (event.button.*)
 */
struct SDL_MouseButtonEvent
{
    Uint32 type;        /*< ::SDL_MOUSEBUTTONDOWN or ::SDL_MOUSEBUTTONUP */
    Uint32 timestamp;
    Uint32 windowID;    /*< The window with mouse focus, if any */
    Uint32 which;       /*< The mouse instance id, or SDL_TOUCH_MOUSEID */
    Uint8 button;       /*< The mouse button index */
    Uint8 state;        /*< ::SDL_PRESSED or ::SDL_RELEASED */
    Uint8 padding1;
    Uint8 padding2;
    Sint32 x;           /*< X coordinate, relative to window */
    Sint32 y;           /*< Y coordinate, relative to window */
}

/**
 *  \brief Mouse wheel event structure (event.wheel.*)
 */
struct SDL_MouseWheelEvent
{
    Uint32 type;        /*< ::SDL_MOUSEWHEEL */
    Uint32 timestamp;
    Uint32 windowID;    /*< The window with mouse focus, if any */
    Uint32 which;       /*< The mouse instance id, or SDL_TOUCH_MOUSEID */
    Sint32 x;           /*< The amount scrolled horizontally */
    Sint32 y;           /*< The amount scrolled vertically */
}

/**
 *  \brief Joystick axis motion event structure (event.jaxis.*)
 */
struct SDL_JoyAxisEvent
{
    Uint32 type;        /*< ::SDL_JOYAXISMOTION */
    Uint32 timestamp;
    SDL_JoystickID which; /*< The joystick instance id */
    Uint8 axis;         /*< The joystick axis index */
    Uint8 padding1;
    Uint8 padding2;
    Uint8 padding3;
    Sint16 value;       /*< The axis value (range: -32768 to 32767) */
    Uint16 padding4;
}

/**
 *  \brief Joystick trackball motion event structure (event.jball.*)
 */
struct SDL_JoyBallEvent
{
    Uint32 type;        /*< ::SDL_JOYBALLMOTION */
    Uint32 timestamp;
    SDL_JoystickID which; /*< The joystick instance id */
    Uint8 ball;         /*< The joystick trackball index */
    Uint8 padding1;
    Uint8 padding2;
    Uint8 padding3;
    Sint16 xrel;        /*< The relative motion in the X direction */
    Sint16 yrel;        /*< The relative motion in the Y direction */
}

/**
 *  \brief Joystick hat position change event structure (event.jhat.*)
 */
struct SDL_JoyHatEvent
{
    Uint32 type;        /*< ::SDL_JOYHATMOTION */
    Uint32 timestamp;
    SDL_JoystickID which; /*< The joystick instance id */
    Uint8 hat;          /*< The joystick hat index */
    Uint8 value;        /*< The hat position value.
                         *   \sa ::SDL_HAT_LEFTUP ::SDL_HAT_UP ::SDL_HAT_RIGHTUP
                         *   \sa ::SDL_HAT_LEFT ::SDL_HAT_CENTERED ::SDL_HAT_RIGHT
                         *   \sa ::SDL_HAT_LEFTDOWN ::SDL_HAT_DOWN ::SDL_HAT_RIGHTDOWN
                         *
                         *   Note that zero means the POV is centered.
                         */
    Uint8 padding1;
    Uint8 padding2;
}

/**
 *  \brief Joystick button event structure (event.jbutton.*)
 */
struct SDL_JoyButtonEvent
{
    Uint32 type;        /*< ::SDL_JOYBUTTONDOWN or ::SDL_JOYBUTTONUP */
    Uint32 timestamp;
    SDL_JoystickID which; /*< The joystick instance id */
    Uint8 button;       /*< The joystick button index */
    Uint8 state;        /*< ::SDL_PRESSED or ::SDL_RELEASED */
    Uint8 padding1;
    Uint8 padding2;
}

/**
 *  \brief Joystick device event structure (event.jdevice.*)
 */
struct SDL_JoyDeviceEvent
{
    Uint32 type;        /*< ::SDL_JOYDEVICEADDED or ::SDL_JOYDEVICEREMOVED */
    Uint32 timestamp;
    Sint32 which;       /*< The joystick device index for the ADDED event, instance id for the REMOVED event */
}


/**
 *  \brief Game controller axis motion event structure (event.caxis.*)
 */
struct SDL_ControllerAxisEvent
{
    Uint32 type;        /*< ::SDL_CONTROLLERAXISMOTION */
    Uint32 timestamp;
    SDL_JoystickID which; /*< The joystick instance id */
    Uint8 axis;         /*< The controller axis (SDL_GameControllerAxis) */
    Uint8 padding1;
    Uint8 padding2;
    Uint8 padding3;
    Sint16 value;       /*< The axis value (range: -32768 to 32767) */
    Uint16 padding4;
}


/**
 *  \brief Game controller button event structure (event.cbutton.*)
 */
struct SDL_ControllerButtonEvent
{
    Uint32 type;        /*< ::SDL_CONTROLLERBUTTONDOWN or ::SDL_CONTROLLERBUTTONUP */
    Uint32 timestamp;
    SDL_JoystickID which; /*< The joystick instance id */
    Uint8 button;       /*< The controller button (SDL_GameControllerButton) */
    Uint8 state;        /*< ::SDL_PRESSED or ::SDL_RELEASED */
    Uint8 padding1;
    Uint8 padding2;
}


/**
 *  \brief Controller device event structure (event.cdevice.*)
 */
struct SDL_ControllerDeviceEvent
{
    Uint32 type;        /*< ::SDL_CONTROLLERDEVICEADDED, ::SDL_CONTROLLERDEVICEREMOVED, or ::SDL_CONTROLLERDEVICEREMAPPED */
    Uint32 timestamp;
    Sint32 which;       /*< The joystick device index for the ADDED event, instance id for the REMOVED or REMAPPED event */
}


/**
 *  \brief Touch finger event structure (event.tfinger.*)
 */
struct SDL_TouchFingerEvent
{
    Uint32 type;        /*< ::SDL_FINGERMOTION or ::SDL_FINGERDOWN or ::SDL_FINGERUP */
    Uint32 timestamp;
    SDL_TouchID touchId; /*< The touch device id */
    SDL_FingerID fingerId;
    float x;            /*< Normalized in the range 0...1 */
    float y;            /*< Normalized in the range 0...1 */
    float dx;           /*< Normalized in the range 0...1 */
    float dy;           /*< Normalized in the range 0...1 */
    float pressure;     /*< Normalized in the range 0...1 */
}


/**
 *  \brief Multiple Finger Gesture Event (event.mgesture.*)
 */
struct SDL_MultiGestureEvent
{
    Uint32 type;        /*< ::SDL_MULTIGESTURE */
    Uint32 timestamp;
    SDL_TouchID touchId; /*< The touch device index */
    float dTheta;
    float dDist;
    float x;
    float y;
    Uint16 numFingers;
    Uint16 padding;
}


/**
 * \brief Dollar Gesture Event (event.dgesture.*)
 */
struct SDL_DollarGestureEvent
{
    Uint32 type;        /*< ::SDL_DOLLARGESTURE */
    Uint32 timestamp;
    SDL_TouchID touchId; /*< The touch device id */
    SDL_GestureID gestureId;
    Uint32 numFingers;
    float error;
    float x;            /*< Normalized center of gesture */
    float y;            /*< Normalized center of gesture */
}


/**
 *  \brief An event used to request a file open by the system (event.drop.*)
 *         This event is disabled by default, you can enable it with SDL_EventState()
 *  \note If you enable this event, you must free the filename in the event.
 */
struct SDL_DropEvent
{
    Uint32 type;        /*< ::SDL_DROPFILE */
    Uint32 timestamp;
    char *file;         /*< The file name, which should be freed with SDL_free() */
}


/**
 *  \brief The "quit requested" event
 */
struct SDL_QuitEvent
{
    Uint32 type;        /*< ::SDL_QUIT */
    Uint32 timestamp;
}

/**
 *  \brief OS Specific event
 */
struct SDL_OSEvent
{
    Uint32 type;        /*< ::SDL_QUIT */
    Uint32 timestamp;
}

/**
 *  \brief A user-defined event type (event.user.*)
 */
struct SDL_UserEvent
{
    Uint32 type;        /*< ::SDL_USEREVENT through ::SDL_LASTEVENT-1 */
    Uint32 timestamp;
    Uint32 windowID;    /*< The associated window if any */
    Sint32 code;        /*< User defined event code */
    void *data1;        /*< User defined data pointer */
    void *data2;        /*< User defined data pointer */
}


struct SDL_SysWMmsg {}

/**
 *  \brief A video driver dependent system event (event.syswm.*)
 *         This event is disabled by default, you can enable it with SDL_EventState()
 *
 *  \note If you want to use this event, you should include SDL_syswm.h.
 */
struct SDL_SysWMEvent
{
    Uint32 type;        /*< ::SDL_SYSWMEVENT */
    Uint32 timestamp;
    SDL_SysWMmsg *msg;  /*< driver dependent data, defined in SDL_syswm.h */
}

/**
 *  \brief General event structure
 */
union SDL_Event
{
    Uint32 type;                    /*< Event type, shared with all events */
    SDL_CommonEvent common;         /*< Common event data */
    SDL_WindowEvent window;         /*< Window event data */
    SDL_KeyboardEvent key;          /*< Keyboard event data */
    SDL_TextEditingEvent edit;      /*< Text editing event data */
    SDL_TextInputEvent text;        /*< Text input event data */
    SDL_MouseMotionEvent motion;    /*< Mouse motion event data */
    SDL_MouseButtonEvent button;    /*< Mouse button event data */
    SDL_MouseWheelEvent wheel;      /*< Mouse wheel event data */
    SDL_JoyAxisEvent jaxis;         /*< Joystick axis event data */
    SDL_JoyBallEvent jball;         /*< Joystick ball event data */
    SDL_JoyHatEvent jhat;           /*< Joystick hat event data */
    SDL_JoyButtonEvent jbutton;     /*< Joystick button event data */
    SDL_JoyDeviceEvent jdevice;     /*< Joystick device change event data */
    SDL_ControllerAxisEvent caxis;      /*< Game Controller axis event data */
    SDL_ControllerButtonEvent cbutton;  /*< Game Controller button event data */
    SDL_ControllerDeviceEvent cdevice;  /*< Game Controller device event data */
    SDL_QuitEvent quit;             /*< Quit request event data */
    SDL_UserEvent user;             /*< Custom event data */
    SDL_SysWMEvent syswm;           /*< System dependent window event data */
    SDL_TouchFingerEvent tfinger;   /*< Touch finger event data */
    SDL_MultiGestureEvent mgesture; /*< Gesture event data */
    SDL_DollarGestureEvent dgesture; /*< Gesture event data */
    SDL_DropEvent drop;             /*< Drag and drop event data */

    /* This is necessary for ABI compatibility between Visual C++ and GCC
       Visual C++ will respect the push pack pragma and use 52 bytes for
       this structure, and GCC will use the alignment of the largest datatype
       within the union, which is 8 bytes.

       So... we'll add padding to force the size to be 56 bytes for both.
    */
    Uint8[56] padding;
}


/* Function prototypes */

/**
 *  Pumps the event loop, gathering events from the input devices.
 *
 *  This function updates the event queue and internal input device state.
 *
 *  This should only be run in the thread that sets the video mode.
 */
void SDL_PumpEvents();

/* */
alias SDL_eventaction = int;
enum : SDL_eventaction
{
    SDL_ADDEVENT,
    SDL_PEEKEVENT,
    SDL_GETEVENT
}

/**
 *  Checks the event queue for messages and optionally returns them.
 *
 *  If \c action is ::SDL_ADDEVENT, up to \c numevents events will be added to
 *  the back of the event queue.
 *
 *  If \c action is ::SDL_PEEKEVENT, up to \c numevents events at the front
 *  of the event queue, within the specified minimum and maximum type,
 *  will be returned and will not be removed from the queue.
 *
 *  If \c action is ::SDL_GETEVENT, up to \c numevents events at the front
 *  of the event queue, within the specified minimum and maximum type,
 *  will be returned and will be removed from the queue.
 *
 *  \return The number of events actually stored, or -1 if there was an error.
 *
 *  This function is thread-safe.
 */
int SDL_PeepEvents(SDL_Event * events, int numevents,
                                           SDL_eventaction action,
                                           Uint32 minType, Uint32 maxType);
/* */

/**
 *  Checks to see if certain event types are in the event queue.
 */
SDL_bool  SDL_HasEvent(Uint32 type);
SDL_bool  SDL_HasEvents(Uint32 minType, Uint32 maxType);

/**
 *  This function clears events from the event queue
 */
void  SDL_FlushEvent(Uint32 type);
void  SDL_FlushEvents(Uint32 minType, Uint32 maxType);

/**
 *  \brief Polls for currently pending events.
 *
 *  \return 1 if there are any pending events, or 0 if there are none available.
 *
 *  \param event If not NULL, the next event is removed from the queue and
 *               stored in that area.
 */
int  SDL_PollEvent(SDL_Event * event);

/**
 *  \brief Waits indefinitely for the next available event.
 *
 *  \return 1, or 0 if there was an error while waiting for events.
 *
 *  \param event If not NULL, the next event is removed from the queue and
 *               stored in that area.
 */
int  SDL_WaitEvent(SDL_Event * event);

/**
 *  \brief Waits until the specified timeout (in milliseconds) for the next
 *         available event.
 *
 *  \return 1, or 0 if there was an error while waiting for events.
 *
 *  \param event If not NULL, the next event is removed from the queue and
 *               stored in that area.
 *  \param timeout The timeout (in milliseconds) to wait for next event.
 */
int  SDL_WaitEventTimeout(SDL_Event * event,
                                                 int timeout);

/**
 *  \brief Add an event to the event queue.
 *
 *  \return 1 on success, 0 if the event was filtered, or -1 if the event queue
 *          was full or there was some other error.
 */
int  SDL_PushEvent(SDL_Event * event);

alias SDL_EventFilter = int function(void *userdata, SDL_Event * event);

/**
 *  Sets up a filter to process all events before they change internal state and
 *  are posted to the internal event queue.
 *
 *  The filter is prototyped as:
 *  \code
 *      int SDL_EventFilter(void *userdata, SDL_Event * event);
 *  \endcode
 *
 *  If the filter returns 1, then the event will be added to the internal queue.
 *  If it returns 0, then the event will be dropped from the queue, but the
 *  internal state will still be updated.  This allows selective filtering of
 *  dynamically arriving events.
 *
 *  \warning  Be very careful of what you do in the event filter function, as
 *            it may run in a different thread!
 *
 *  There is one caveat when dealing with the ::SDL_QuitEvent event type.  The
 *  event filter is only called when the window manager desires to close the
 *  application window.  If the event filter returns 1, then the window will
 *  be closed, otherwise the window will remain open if possible.
 *
 *  If the quit event is generated by an interrupt signal, it will bypass the
 *  internal queue and be delivered to the application at the next event poll.
 */
void  SDL_SetEventFilter(SDL_EventFilter filter,
                                                void *userdata);

/**
 *  Return the current event filter - can be used to "chain" filters.
 *  If there is no event filter set, this function returns SDL_FALSE.
 */
SDL_bool  SDL_GetEventFilter(SDL_EventFilter * filter,
                                                    void **userdata);

/**
 *  Add a function which is called when an event is added to the queue.
 */
void  SDL_AddEventWatch(SDL_EventFilter filter,
                                               void *userdata);

/**
 *  Remove an event watch function added with SDL_AddEventWatch()
 */
void  SDL_DelEventWatch(SDL_EventFilter filter,
                                               void *userdata);

/**
 *  Run the filter function on the current event queue, removing any
 *  events for which the filter returns 0.
 */
void  SDL_FilterEvents(SDL_EventFilter filter,
                                              void *userdata);

/* */
enum SDL_QUERY = -1;
enum SDL_IGNORE = 0;
enum SDL_DISABLE = 0;
enum SDL_ENABLE = 1;

/**
 *  This function allows you to set the state of processing certain events.
 *   - If \c state is set to ::SDL_IGNORE, that event will be automatically
 *     dropped from the event queue and will not event be filtered.
 *   - If \c state is set to ::SDL_ENABLE, that event will be processed
 *     normally.
 *   - If \c state is set to ::SDL_QUERY, SDL_EventState() will return the
 *     current processing state of the specified event.
 */
Uint8  SDL_EventState(Uint32 type, int state);
/* */
Uint8 SDL_GetEventState(Uint32 type) { return SDL_EventState(type, SDL_QUERY); }

/**
 *  This function allocates a set of user-defined events, and returns
 *  the beginning event number for that set of events.
 *
 *  If there aren't enough user-defined events left, this function
 *  returns (Uint32)-1
 */
Uint32  SDL_RegisterEvents(int numevents);

