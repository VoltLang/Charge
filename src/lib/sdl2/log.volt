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
module lib.sdl2.log;
extern (C):


/*
 *  \file SDL_log.h
 *
 *  Simple log messages with categories and priorities.
 *
 *  By default logs are quiet, but if you're debugging SDL you might want:
 *
 *      SDL_LogSetAllPriority(SDL_LOG_PRIORITY_WARN);
 *
 *  Here's where the messages go on different platforms:
 *      Windows: debug output stream
 *      Android: log output
 *      Others: standard error output (stderr)
 */

import core.stdc.stdarg;

import lib.sdl2.stdinc;

/**
 *  \brief The maximum size of a log message
 *
 *  Messages longer than the maximum size will be truncated
 */
enum SDL_MAX_LOG_MESSAGE = 4096;

/**
 *  \brief The predefined log categories
 *
 *  By default the application category is enabled at the INFO level,
 *  the assert category is enabled at the WARN level, test is enabled
 *  at the VERBOSE level and all other categories are enabled at the
 *  CRITICAL level.
 */
enum
{
    SDL_LOG_CATEGORY_APPLICATION,
    SDL_LOG_CATEGORY_ERROR,
    SDL_LOG_CATEGORY_ASSERT,
    SDL_LOG_CATEGORY_SYSTEM,
    SDL_LOG_CATEGORY_AUDIO,
    SDL_LOG_CATEGORY_VIDEO,
    SDL_LOG_CATEGORY_RENDER,
    SDL_LOG_CATEGORY_INPUT,
    SDL_LOG_CATEGORY_TEST,

    /* Reserved for future SDL library use */
    SDL_LOG_CATEGORY_RESERVED1,
    SDL_LOG_CATEGORY_RESERVED2,
    SDL_LOG_CATEGORY_RESERVED3,
    SDL_LOG_CATEGORY_RESERVED4,
    SDL_LOG_CATEGORY_RESERVED5,
    SDL_LOG_CATEGORY_RESERVED6,
    SDL_LOG_CATEGORY_RESERVED7,
    SDL_LOG_CATEGORY_RESERVED8,
    SDL_LOG_CATEGORY_RESERVED9,
    SDL_LOG_CATEGORY_RESERVED10,

    /* Beyond this point is reserved for application use, e.g.
       enum {
           MYAPP_CATEGORY_AWESOME1 = SDL_LOG_CATEGORY_CUSTOM,
           MYAPP_CATEGORY_AWESOME2,
           MYAPP_CATEGORY_AWESOME3,
           ...
       };
     */
    SDL_LOG_CATEGORY_CUSTOM
}

/**
 *  \brief The predefined log priorities
 */
alias SDL_LogPriority = int;
enum : SDL_LogPriority
{
    SDL_LOG_PRIORITY_VERBOSE = 1,
    SDL_LOG_PRIORITY_DEBUG,
    SDL_LOG_PRIORITY_INFO,
    SDL_LOG_PRIORITY_WARN,
    SDL_LOG_PRIORITY_ERROR,
    SDL_LOG_PRIORITY_CRITICAL,
    SDL_NUM_LOG_PRIORITIES
}


/**
 *  \brief Set the priority of all log categories
 */
void SDL_LogSetAllPriority(SDL_LogPriority priority);

/**
 *  \brief Set the priority of a particular log category
 */
void SDL_LogSetPriority(int category,
                                                SDL_LogPriority priority);

/**
 *  \brief Get the priority of a particular log category
 */
SDL_LogPriority SDL_LogGetPriority(int category);

/**
 *  \brief Reset all priorities to default.
 *
 *  \note This is called in SDL_Quit().
 */
void SDL_LogResetPriorities();

/**
 *  \brief Log a message with SDL_LOG_CATEGORY_APPLICATION and SDL_LOG_PRIORITY_INFO
 */
void SDL_Log(const char *fmt, ...);

/**
 *  \brief Log a message with SDL_LOG_PRIORITY_VERBOSE
 */
void SDL_LogVerbose(int category, const char *fmt, ...);

/**
 *  \brief Log a message with SDL_LOG_PRIORITY_DEBUG
 */
void SDL_LogDebug(int category, const char *fmt, ...);

/**
 *  \brief Log a message with SDL_LOG_PRIORITY_INFO
 */
void SDL_LogInfo(int category, const char *fmt, ...);

/**
 *  \brief Log a message with SDL_LOG_PRIORITY_WARN
 */
void SDL_LogWarn(int category, const char *fmt, ...);

/**
 *  \brief Log a message with SDL_LOG_PRIORITY_ERROR
 */
void SDL_LogError(int category, const char *fmt, ...);

/**
 *  \brief Log a message with SDL_LOG_PRIORITY_CRITICAL
 */
void SDL_LogCritical(int category, const char *fmt, ...);

/**
 *  \brief Log a message with the specified category and priority.
 */
void SDL_LogMessage(int category,
                                            SDL_LogPriority priority,
                                            const char *fmt, ...);

/**
 *  \brief Log a message with the specified category and priority.
 */
void SDL_LogMessageV(int category,
                                             SDL_LogPriority priority,
                                             const char *fmt, va_list ap);

/**
 *  \brief The prototype for the log output function
 */
alias SDL_LogOutputFunction = void function(void*, int, SDL_LogPriority, const(char)*);

/**
 *  \brief Get the current log output function.
 */
void SDL_LogGetOutputFunction(SDL_LogOutputFunction *callback, void **userdata);

/**
 *  \brief This function allows you to replace the default log output
 *         function with one of your own.
 */
void SDL_LogSetOutputFunction(SDL_LogOutputFunction callback, void *userdata);

