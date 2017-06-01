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
module lib.sdl2.rwops;
extern (C):
version (!Windows):

/*
 *  \file SDL_rwops.h
 *
 *  This file provides a general interface for SDL to read and write
 *  data streams.  It can easily be extended to files, memory, etc.
 */

import core.c.stdio;

import lib.sdl2.stdinc;
import lib.sdl2.error;


/* RWops Types */
enum SDL_RWOPS_UNKNOWN   = 0;   /* Unknown stream type */
enum SDL_RWOPS_WINFILE   = 1;   /* Win= 3;= 2; file */
enum SDL_RWOPS_STDFILE   = 2;   /* Stdio file */
enum SDL_RWOPS_JNIFILE   = 3;   /* Android asset */
enum SDL_RWOPS_MEMORY    = 4;   /* Memory stream */
enum SDL_RWOPS_MEMORY_RO = 5;   /* Read-Only memory stream */

/*!
 * This is the read/write operation structure -- very basic.
 */
struct SDL_RWops
{
    /*!
     *  Return the size of the file in this rwops, or -1 if unknown
     */
    Sint64 function(SDL_RWops*) size;

    /*!
     *  Seek to \c offset relative to \c whence, one of stdio's whence values:
     *  RW_SEEK_SET, RW_SEEK_CUR, RW_SEEK_END
     *
     *  \return the final offset in the data stream, or -1 on error.
     */
    Sint64 function(SDL_RWops*, Sint64, int) seek;

    /*!
     *  Read up to \c maxnum objects each of size \c size from the data
     *  stream to the area pointed at by \c ptr.
     *
     *  \return the number of objects read, or 0 at error or end of file.
     */
    size_t function(SDL_RWops*, void*, size_t, size_t) read;

    /*!
     *  Write exactly \c num objects each of size \c size from the area
     *  pointed at by \c ptr to data stream.
     *
     *  \return the number of objects written, or 0 at error or end of file.
     */
    size_t function(SDL_RWops*, const(void)*, size_t, size_t) write;

    /*!
     *  Close and free an allocated SDL_RWops structure.
     *
     *  \return 0 if successful or -1 on write error when flushing data.
     */
    int function(SDL_RWops*) close;

    Uint32 type;
    void* a, b, c;
}


/*!
 *  \name RWFrom functions
 *
 *  Functions to create SDL_RWops structures from various data streams.
 */
/* */

 SDL_RWops * SDL_RWFromFile(const char *file,
                                                  const char *mode);

 SDL_RWops * SDL_RWFromFP(FILE * fp,
                                                SDL_bool autoclose);

 SDL_RWops * SDL_RWFromMem(void *mem, int size);
 SDL_RWops * SDL_RWFromConstMem(const void *mem,
                                                      int size);

/* *//*RWFrom functions*/


 SDL_RWops * SDL_AllocRW();
 void  SDL_FreeRW(SDL_RWops * area);

enum RW_SEEK_SET = 0;       /*!< Seek from the beginning of data */
enum RW_SEEK_CUR = 1;      /*!< Seek relative to current read point */
enum RW_SEEK_END = 2;       /*!< Seek relative to the end of data */

/*!
 *  \name Read/write macros
 *
 *  Macros to easily read and write from an SDL_RWops structure.
 */
/* */
/* *//*Read/write macros*/


/*!
 *  \name Read endian functions
 *
 *  Read an item of the specified endianness and return in native format.
 */
/* */
 Uint8  SDL_ReadU8(SDL_RWops * src);
 Uint16  SDL_ReadLE16(SDL_RWops * src);
 Uint16  SDL_ReadBE16(SDL_RWops * src);
 Uint32  SDL_ReadLE32(SDL_RWops * src);
 Uint32  SDL_ReadBE32(SDL_RWops * src);
 Uint64  SDL_ReadLE64(SDL_RWops * src);
 Uint64  SDL_ReadBE64(SDL_RWops * src);
/* *//*Read endian functions*/

/*!
 *  \name Write endian functions
 *
 *  Write an item of native format to the specified endianness.
 */
/* */
 size_t  SDL_WriteU8(SDL_RWops * dst, Uint8 value);
 size_t  SDL_WriteLE16(SDL_RWops * dst, Uint16 value);
 size_t  SDL_WriteBE16(SDL_RWops * dst, Uint16 value);
 size_t  SDL_WriteLE32(SDL_RWops * dst, Uint32 value);
 size_t  SDL_WriteBE32(SDL_RWops * dst, Uint32 value);
 size_t  SDL_WriteLE64(SDL_RWops * dst, Uint64 value);
 size_t  SDL_WriteBE64(SDL_RWops * dst, Uint64 value);
/* *//*Write endian functions*/

