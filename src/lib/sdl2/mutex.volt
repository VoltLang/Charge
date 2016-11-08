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
module lib.sdl2.mutex;
extern (C):


/*
 *  \file SDL_mutex.h
 *
 *  Functions to provide thread synchronization primitives.
 */

import lib.sdl2.stdinc;
import lib.sdl2.error;

/**
 *  Synchronization functions which can time out return this value
 *  if they time out.
 */
enum SDL_MUTEX_TIMEDOUT = 1;

/**
 *  This is the timeout value which corresponds to never time out.
 */
@property Uint32 SDL_MUTEX_MAXWAIT() { return cast(Uint32) ~0; }



/**
 *  \name Mutex functions
 */
/* */

/* The SDL mutex structure, defined in SDL_mutex.c */
struct SDL_mutex {}

/**
 *  Create a mutex, initialized unlocked.
 */
SDL_mutex * SDL_CreateMutex();

/**
 *  Lock the mutex.
 *
 *  \return 0, or -1 on error.
 */
int  SDL_LockMutex(SDL_mutex * mutex);

/**
 *  Try to lock the mutex
 *
 *  \return 0, SDL_MUTEX_TIMEDOUT, or -1 on error
 */
int  SDL_TryLockMutex(SDL_mutex * mutex);

/**
 *  Unlock the mutex.
 *
 *  \return 0, or -1 on error.
 *
 *  \warning It is an error to unlock a mutex that has not been locked by
 *           the current thread, and doing so results in undefined behavior.
 */
int  SDL_UnlockMutex(SDL_mutex * mutex);

/**
 *  Destroy a mutex.
 */
void  SDL_DestroyMutex(SDL_mutex * mutex);

/* *//*Mutex functions*/


/**
 *  \name Semaphore functions
 */
/* */

/* The SDL semaphore structure, defined in SDL_sem.c */
struct SDL_semaphore {}

/**
 *  Create a semaphore, initialized with value, returns NULL on failure.
 */
SDL_semaphore * SDL_CreateSemaphore(Uint32 initial_value);

/**
 *  Destroy a semaphore.
 */
void  SDL_DestroySemaphore(SDL_semaphore* sem);

/**
 *  This function suspends the calling thread until the semaphore pointed
 *  to by \c sem has a positive count. It then atomically decreases the
 *  semaphore count.
 */
int  SDL_SemWait(SDL_semaphore* sem);

/**
 *  Non-blocking variant of SDL_SemWait().
 *
 *  \return 0 if the wait succeeds, ::SDL_MUTEX_TIMEDOUT if the wait would
 *          block, and -1 on error.
 */
int  SDL_SemTryWait(SDL_semaphore* sem);

/**
 *  Variant of SDL_SemWait() with a timeout in milliseconds.
 *
 *  \return 0 if the wait succeeds, ::SDL_MUTEX_TIMEDOUT if the wait does not
 *          succeed in the allotted time, and -1 on error.
 *
 *  \warning On some platforms this function is implemented by looping with a
 *           delay of 1 ms, and so should be avoided if possible.
 */
int  SDL_SemWaitTimeout(SDL_semaphore* sem, Uint32 ms);

/**
 *  Atomically increases the semaphore's count (not blocking).
 *
 *  \return 0, or -1 on error.
 */
int  SDL_SemPost(SDL_semaphore* sem);

/**
 *  Returns the current count of the semaphore.
 */
Uint32  SDL_SemValue(SDL_semaphore* sem);

/* *//*Semaphore functions*/


/**
 *  \name Condition variable functions
 */
/* */

/* The SDL condition variable structure, defined in SDL_cond.c */
struct SDL_cond {}

/**
 *  Create a condition variable.
 *
 *  Typical use of condition variables:
 *
 *  Thread A:
 *    SDL_LockMutex(lock);
 *    while ( ! condition ) {
 *        SDL_CondWait(cond, lock);
 *    }
 *    SDL_UnlockMutex(lock);
 *
 *  Thread B:
 *    SDL_LockMutex(lock);
 *    ...
 *    condition = true;
 *    ...
 *    SDL_CondSignal(cond);
 *    SDL_UnlockMutex(lock);
 *
 *  There is some discussion whether to signal the condition variable
 *  with the mutex locked or not.  There is some potential performance
 *  benefit to unlocking first on some platforms, but there are some
 *  potential race conditions depending on how your code is structured.
 *
 *  In general it's safer to signal the condition variable while the
 *  mutex is locked.
 */
SDL_cond * SDL_CreateCond();

/**
 *  Destroy a condition variable.
 */
void  SDL_DestroyCond(SDL_cond * cond);

/**
 *  Restart one of the threads that are waiting on the condition variable.
 *
 *  \return 0 or -1 on error.
 */
int  SDL_CondSignal(SDL_cond * cond);

/**
 *  Restart all threads that are waiting on the condition variable.
 *
 *  \return 0 or -1 on error.
 */
int  SDL_CondBroadcast(SDL_cond * cond);

/**
 *  Wait on the condition variable, unlocking the provided mutex.
 *
 *  \warning The mutex must be locked before entering this function!
 *
 *  The mutex is re-locked once the condition variable is signaled.
 *
 *  \return 0 when it is signaled, or -1 on error.
 */
int  SDL_CondWait(SDL_cond * cond, SDL_mutex * mutex);

/**
 *  Waits for at most \c ms milliseconds, and returns 0 if the condition
 *  variable is signaled, ::SDL_MUTEX_TIMEDOUT if the condition is not
 *  signaled in the allotted time, and -1 on error.
 *
 *  \warning On some platforms this function is implemented by looping with a
 *           delay of 1 ms, and so should be avoided if possible.
 */
int  SDL_CondWaitTimeout(SDL_cond * cond,
                                                SDL_mutex * mutex, Uint32 ms);

/* *//*Condition variable functions*/


/* Ends C function definitions when using C++ */
