// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).

#include "stddef.h"

extern void* cMalloc(size_t, const char* file, int line);
extern void* cRealloc(void*, size_t, const char* file, int line);
extern void cFree(void*, const char* file, int line);

#define STBI_ONLY_PNG
#define STBI_ONLY_BMP
#define STBI_NO_STDIO
#define STBI_NO_HDR
#define STBI_NO_LINEAR
#define STBI_FAILURE_USERMSG

#define STBI_MALLOC(sz)           cMalloc(sz, __FILE__, __LINE__)
#define STBI_REALLOC(p,newsize)   cRealloc(p, newsize, __FILE__, __LINE__)
#define STBI_FREE(p)              cFree(p, __FILE__, __LINE__)

#define STB_IMAGE_IMPLEMENTATION

#include "stb_image.h"
