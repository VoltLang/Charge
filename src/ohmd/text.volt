// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module ohmd.text;

import lib.gl.gl45;

import gfx = charge.gfx;
import math = charge.math;

import charge.gfx.gl;


class Text
{
public:
	//! Text rendering stuff. @{
	textVbo: gfx.DrawBuffer;
	textBuilder: gfx.DrawVertexBuilder;
	textState: gfx.BitmapState;
	//! @}


public:
	this(text: string)
	{
		// Make the builder.
		textBuilder = new gfx.DrawVertexBuilder(text.length * 4u);

		// Setup the initial text state.
		textState.glyphWidth = cast(int)gfx.bitmapTexture.width / 16;
		textState.glyphHeight = cast(int)gfx.bitmapTexture.height / 16;
		textState.offX = 16;
		textState.offY = 16;
		gfx.buildVertices(ref textState, textBuilder, cast(ubyte[])text);

		// Create the first VBO.
		textVbo = gfx.DrawBuffer.make("power/exp/text", textBuilder);
	}

	fn close()
	{
		gfx.destroy(ref textBuilder);
		gfx.reference(ref textVbo, null);
	}

	fn update(text: string)
	{
		textBuilder.reset(text.length * 4u);
		gfx.buildVertices(ref textState, textBuilder, cast(ubyte[])text);
		textVbo.update(textBuilder);
	}

	fn draw(t: gfx.Target)
	{
		// Draw text.
		transform: math.Matrix4x4d;
		t.setMatrixToOrtho(ref transform);
		mat: math.Matrix4x4f;
		mat.setFrom(ref transform);

		gfx.drawShader.bind();
		gfx.drawShader.matrix4("matrix", 1, true, ref mat);

		glBindVertexArray(textVbo.vao);
		gfx.bitmapTexture.bind();

		glDrawArrays(GL_TRIANGLES, 0, textVbo.num);

		gfx.bitmapTexture.unbind();
		glBindVertexArray(0);
	}
}
