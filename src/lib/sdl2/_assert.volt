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
module lib.sdl2._assert;
extern (C):
version (!Windows):

alias SDL_assert_state = int;
enum : SDL_assert_state
{
    SDL_ASSERTION_RETRY,  /*< Retry the assert immediately. */
    SDL_ASSERTION_BREAK,  /*< Make the debugger trigger a breakpoint. */
    SDL_ASSERTION_ABORT,  /*< Terminate the program. */
    SDL_ASSERTION_IGNORE,  /*< Ignore the assert. */
    SDL_ASSERTION_ALWAYS_IGNORE  /*< Ignore the assert from now on. */
}

struct SDL_assert_data
{
    int always_ignore;
    uint trigger_count;
    const char *condition;
    const char *filename;
    int linenum;
    const char *_function;
    const SDL_assert_data *next;
}

alias SDL_AssertionHandler = SDL_assert_state function(in SDL_assert_data*, void*);

/**
 *  \brief Set an application-defined assertion handler.
 *
 *  This allows an app to show its own assertion UI and/or force the
 *  response to an assertion failure. If the app doesn't provide this, SDL
 *  will try to do the right thing, popping up a system-specific GUI dialog,
 *  and probably minimizing any fullscreen windows.
 *
 *  This callback may fire from any thread, but it runs wrapped in a mutex, so
 *  it will only fire from one thread at a time.
 *
 *  Setting the callback to NULL restores SDL's original internal handler.
 *
 *  This callback is NOT reset to SDL's internal handler upon SDL_Quit()!
 *
 *  \return SDL_assert_state value of how to handle the assertion failure.
 *
 *  \param handler Callback function, called when an assertion fails.
 *  \param userdata A pointer passed to the callback as-is.
 */
void  SDL_SetAssertionHandler(
                                            SDL_AssertionHandler handler,
                                            void *userdata);

/**
 *  \brief Get a list of all assertion failures.
 *
 *  Get all assertions triggered since last call to SDL_ResetAssertionReport(),
 *  or the start of the program.
 *
 *  The proper way to examine this data looks something like this:
 *
 *  <code>
 *  const SDL_assert_data *item = SDL_GetAssertionReport();
 *  while (item) {
 *      printf("'%s', %s (%s:%d), triggered %u times, always ignore: %s.\n",
 *             item->condition, item->function, item->filename,
 *             item->linenum, item->trigger_count,
 *             item->always_ignore ? "yes" : "no");
 *      item = item->next;
 *  }
 *  </code>
 *
 *  \return List of all assertions.
 *  \sa SDL_ResetAssertionReport
 */
const SDL_assert_data *  SDL_GetAssertionReport();

/**
 *  \brief Reset the list of all assertion failures.
 *
 *  Reset list of all assertions triggered.
 *
 *  \sa SDL_GetAssertionReport
 */
void  SDL_ResetAssertionReport();

