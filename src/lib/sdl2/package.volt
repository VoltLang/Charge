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
module lib.sdl2.sdl2;
extern (C):
version (!Windows):

/*
 *  \file SDL.h
 *
 *  Main include header for the SDL library
 */

/*
 *  \mainpage Simple DirectMedia Layer (SDL)
 *
 *  http://www.libsdl.org/
 *
 *  \section intro_sec Introduction
 *
 *  This is the Simple DirectMedia Layer, a general API that provides low
 *  level access to audio, keyboard, mouse, joystick, 3D hardware via OpenGL,
 *  and 2D framebuffer across multiple platforms.
 *
 *  SDL is written in C, but works with C++ natively, and has bindings to
 *  several other languages, including Ada, C#, Eiffel, Erlang, Euphoria,
 *  Guile, Haskell, Java, Lisp, Lua, ML, Objective C, Pascal, Perl, PHP,
 *  Pike, Pliant, Python, Ruby, and Smalltalk.
 *
 *  This library is distributed under the zlib license, which can be
 *  found in the file  "COPYING".  This license allows you to use SDL
 *  freely for any purpose as long as you retain the copyright notice.
 *
 *  The best way to learn how to use SDL is to check out the header files in
 *  the "include" subdirectory and the programs in the "test" subdirectory.
 *  The header files and test programs are well commented and always up to date.
 *  More documentation and FAQs are available online at:
 *      http://wiki.libsdl.org/
 *
 *  If you need help with the library, or just want to discuss SDL related
 *  issues, you can join the developers mailing list:
 *      http://www.libsdl.org/mailing-list.php
 *
 *  Enjoy!
 *      Sam Lantinga                (slouken@libsdl.org)
 */

public import lib.sdl2._assert;
public import lib.sdl2.audio;
public import lib.sdl2.blendmode;
public import lib.sdl2.clipboard;
public import lib.sdl2.cpuinfo;
public import lib.sdl2.error;
public import lib.sdl2.events;
public import lib.sdl2.filesystem;
public import lib.sdl2.gamecontroller;
public import lib.sdl2.gesture;
public import lib.sdl2.haptic;
public import lib.sdl2.hints;
public import lib.sdl2.joystick;
public import lib.sdl2.keyboard;
public import lib.sdl2.keycode;
public import lib.sdl2.loadso;
public import lib.sdl2.log;
public import lib.sdl2.messagebox;
public import lib.sdl2.mouse;
public import lib.sdl2.mutex;
public import lib.sdl2.pixels;
public import lib.sdl2.platform;
public import lib.sdl2.power;
public import lib.sdl2.quit;
public import lib.sdl2.rect;
public import lib.sdl2.render;
public import lib.sdl2.rwops;
public import lib.sdl2.scancode;
public import lib.sdl2.shape;
public import lib.sdl2.stdinc;
public import lib.sdl2.surface;
public import lib.sdl2.thread;
public import lib.sdl2.timer;
public import lib.sdl2.touch;
public import lib.sdl2.video;

/* As of version 0.5, SDL is loaded dynamically into the application */

/**
 *  \name SDL_INIT_*
 *
 *  These are the flags which may be passed to SDL_Init().  You should
 *  specify the subsystems which you will be using in your application.
 */
/* */
enum SDL_INIT_TIMER = 0x00000001;
enum SDL_INIT_AUDIO = 0x00000010;
enum SDL_INIT_VIDEO = 0x00000020;  /*< SDL_INIT_VIDEO implies SDL_INIT_EVENTS */
enum SDL_INIT_JOYSTICK = 0x00000200;  /*< SDL_INIT_JOYSTICK implies SDL_INIT_EVENTS */
enum SDL_INIT_HAPTIC = 0x00001000;
enum SDL_INIT_GAMECONTROLLER = 0x00002000;  /*< SDL_INIT_GAMECONTROLLER implies SDL_INIT_JOYSTICK */
enum SDL_INIT_EVENTS = 0x00004000;
enum SDL_INIT_NOPARACHUTE = 0x00100000;  /*< Don't catch fatal signals */
enum SDL_INIT_EVERYTHING = ( 
                SDL_INIT_TIMER | SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_EVENTS | 
                SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC | SDL_INIT_GAMECONTROLLER 
            );
/* */

/**
 *  This function initializes  the subsystems specified by \c flags
 *  Unless the ::SDL_INIT_NOPARACHUTE flag is set, it will install cleanup
 *  signal handlers for some commonly ignored fatal signals (like SIGSEGV).
 */
 int  SDL_Init(Uint32 flags);

/**
 *  This function initializes specific SDL subsystems
 */
 int  SDL_InitSubSystem(Uint32 flags);

/**
 *  This function cleans up specific SDL subsystems
 */
 void  SDL_QuitSubSystem(Uint32 flags);

/**
 *  This function returns a mask of the specified subsystems which have
 *  previously been initialized.
 *
 *  If \c flags is 0, it returns a mask of all initialized subsystems.
 */
 Uint32  SDL_WasInit(Uint32 flags);

/**
 *  This function cleans up all initialized subsystems. You should
 *  call it upon all exit conditions.
 */
 void  SDL_Quit();

