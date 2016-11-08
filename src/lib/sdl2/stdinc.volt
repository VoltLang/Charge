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
module lib.sdl2.stdinc;
extern (C):

/**
 *  \file SDL_stdinc.h
 *
 *  This is a general header that includes C language support.
 */

/**
 *  \name Basic data types
 */
/* */

alias SDL_bool = int;
enum
{
	SDL_FALSE = 0,
	SDL_TRUE = 1
}

/**
 * \brief A signed 8-bit integer type.
 */
alias Sint8 = byte;
/**
 * \brief An unsigned 8-bit integer type.
 */
alias Uint8 = ubyte;
/**
 * \brief A signed 16-bit integer type.
 */
alias Sint16 = short;
/**
 * \brief An unsigned 16-bit integer type.
 */
alias Uint16 = ushort;
/**
 * \brief A signed 32-bit integer type.
 */
alias Sint32 = int;
/**
 * \brief An unsigned 32-bit integer type.
 */
alias Uint32 = uint;

/**
 * \brief A signed 64-bit integer type.
 */
alias Sint64 = long;
/**
 * \brief An unsigned 64-bit integer type.
 */
alias Uint64 = ulong;

/* *//*Basic data types*/


void * SDL_malloc(size_t size);
void * SDL_calloc(size_t nmemb, size_t size);
void * SDL_realloc(void *mem, size_t size);
void  SDL_free(void *mem);

char * SDL_getenv(const char *name);
int  SDL_setenv(const char *name, const char *value, int overwrite);

void  SDL_qsort(void *base, size_t nmemb, size_t size, int function(in void*, in void*));

int  SDL_abs(int x);

int  SDL_isdigit(int x);
int  SDL_isspace(int x);
int  SDL_toupper(int x);
int  SDL_tolower(int x);

void * SDL_memset(void *dst, int c, size_t len);

void * SDL_memcpy(void *dst, const void *src, size_t len);

void *SDL_memcpy4(void *dst, const void *src, size_t dwords)
{
	return SDL_memcpy(dst, src, dwords * 4);
}

void * SDL_memmove(void *dst, const void *src, size_t len);
int  SDL_memcmp(const void *s1, const void *s2, size_t len);


size_t  SDL_strlen(const char *str);
size_t  SDL_strlcpy(char *dst, const char *src, size_t maxlen);
size_t  SDL_utf8strlcpy(char *dst, const char *src, size_t dst_bytes);
size_t  SDL_strlcat(char *dst, const char *src, size_t maxlen);
char * SDL_strdup(const char *str);
char * SDL_strrev(char *str);
char * SDL_strupr(char *str);
char * SDL_strlwr(char *str);
char * SDL_strchr(const char *str, int c);
char * SDL_strrchr(const char *str, int c);
char * SDL_strstr(const char *haystack, const char *needle);

char * SDL_itoa(int value, char *str, int radix);
char * SDL_uitoa(uint value, char *str, int radix);
char * SDL_ltoa(long value, char *str, int radix);
char * SDL_ultoa(ulong value, char *str, int radix);
char * SDL_lltoa(Sint64 value, char *str, int radix);
char * SDL_ulltoa(Uint64 value, char *str, int radix);

int  SDL_atoi(const char *str);
double  SDL_atof(const char *str);
long  SDL_strtol(const char *str, char **endp, int base);
ulong  SDL_strtoul(const char *str, char **endp, int base);
Sint64  SDL_strtoll(const char *str, char **endp, int base);
Uint64  SDL_strtoull(const char *str, char **endp, int base);
double  SDL_strtod(const char *str, char **endp);

int  SDL_strcmp(const char *str1, const char *str2);
int  SDL_strncmp(const char *str1, const char *str2, size_t maxlen);
int  SDL_strcasecmp(const char *str1, const char *str2);
int  SDL_strncasecmp(const char *str1, const char *str2, size_t len);

int  SDL_sscanf(const char *text, const char *fmt, ...);
int  SDL_snprintf(char *text, size_t maxlen, const char *fmt, ...);

double  SDL_atan(double x);
double  SDL_atan2(double x, double y);
double  SDL_ceil(double x);
double  SDL_copysign(double x, double y);
double  SDL_cos(double x);
float  SDL_cosf(float x);
double  SDL_fabs(double x);
double  SDL_floor(double x);
double  SDL_log(double x);
double  SDL_pow(double x, double y);
double  SDL_scalbn(double x, int n);
double  SDL_sin(double x);
float  SDL_sinf(float x);
double  SDL_sqrt(double x);

