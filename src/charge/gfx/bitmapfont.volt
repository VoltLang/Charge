// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.gfx.bitmapfont;

import charge.gfx.draw;


struct BitmapState
{
	int offX;
	int offY;
	int glyphWidth;
	int glyphHeight;
}

enum tabSize = 4;


/**
 * Computes the size of the bounding box for the given text.
 */
void buildSize(ref BitmapState s, scope const(ubyte)[] text,
               out uint width, out uint height)
{
	if (text is null) {
		return;
	}

	int max, x, y;
	foreach (c; text) {
		switch (c) {
		case '\t':
			x += tabSize - (x % tabSize);
			break;
		case '\n':
			y++;
			goto case;
		case '\r':
			x = 0;
			break;
		default:
			max = x > max ? x : max;
			x++;
			break;
		}
	}

	width = cast(uint)((max + 1) * s.glyphWidth);
	height = cast(uint)((y + 1) * s.glyphHeight);
}

/**
 * Builds the vertices in builder of the given text.
 * Uses quads, so for vertices per glyph.
 */
void buildVertices(ref BitmapState s, DrawVertexBuilder b,
                   scope const(ubyte)[] text)
{
	int x, y;
	foreach (c; text) {
		switch (c) {
		case '\t':
			x += (tabSize - (x % tabSize));
			break;
		case '\n':
			y++;
			goto case;
		case '\r':
			x = 0;
			break;
		default:
			int X = s.offX + x * s.glyphWidth;
			int Y = s.offY + y * s.glyphHeight;
			buildVertex(ref s, b, X, Y, c);
			x++;
			break;
		}
	}
}

void buildVertex(ref BitmapState s, DrawVertexBuilder b, int x, int y, ubyte c)
{
	float dstX1 = cast(float)x;
	float dstY1 = cast(float)y;
	float dstX2 = cast(float)(x + s.glyphWidth);
	float dstY2 = cast(float)(y + s.glyphHeight);

	float srcX1 = (1.0f / 16.0f) * (c % 16);
	float srcY1 = (1.0f / 16.0f) * (c / 16);
	float srcX2 = (1.0f / 16.0f) + srcX1;
	float srcY2 = (1.0f / 16.0f) + srcY1;

	b.add(dstX1, dstY1, srcX1, srcY1);
	b.add(dstX1, dstY2, srcX1, srcY2);
	b.add(dstX2, dstY2, srcX2, srcY2);
	b.add(dstX2, dstY1, srcX2, srcY1);
}
