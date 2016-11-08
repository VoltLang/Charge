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
module lib.sdl2.rect;
extern (C):

struct SDL_Point
{
	int x;
	int y;
}

struct SDL_Rect
{
	int x, y;
	int w, h;
}

bool SDL_RectEmpty(SDL_Rect* r)
{
	return r is null || (r.w <= 0) || (r.h <= 0);
}

bool SDL_RectEquals(SDL_Rect* a, SDL_Rect* b)
{
	return a !is null && b !is null && a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h;
}

bool SDL_HasIntersection(in SDL_Rect*, in SDL_Rect*);
bool SDL_IntersectRect(in SDL_Rect*, in SDL_Rect*, SDL_Rect*);
bool SDL_UnionRect(in SDL_Rect*, in SDL_Rect*, SDL_Rect*);
bool SDL_EnclosePoints(in SDL_Point*, int, in SDL_Rect*, SDL_Rect*);
bool SDL_IntersectRectAndLine(in SDL_Rect*, int*, int*, int*, int*);
