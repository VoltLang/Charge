// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Helper classes to keep track of framebuffers and blit textures.
 */
module charge.gfx.helpers;

import lib.gl.gl33;

import math = charge.math;

import charge.gfx.gl;
import charge.gfx.draw;
import charge.gfx.buffer;
import charge.gfx.target;
import charge.gfx.texture;


struct FramebufferResizer
{
public:
	fbo: Framebuffer;


public:
	fn close()
	{
		reference(ref fbo, null);
	}

	fn bind(t: Target, width: u32, height: u32)
	{
		setupFramebuffer(t, width, height);
		fbo.bind(t);
	}

	fn unbind(t: Target)
	{
		t.bind(fbo);
	}

	fn setupFramebuffer(t: Target, width: u32, height: u32)
	{
		if (fbo !is null &&
		    width == fbo.width &&
		    height == fbo.height) {
			return;
		}

		reference(ref fbo, null);
		fbo = Framebuffer.make("power/exp/fbo", width, height);
	}

	@property fn color() Texture
	{
		if (fbo !is null) {
			return fbo.color;
		} else {
			return null;
		}
	}
}

struct TextureBlitter
{
private:
	lastX, lastY: i32;
	lastW, lastH: u32;
	vbo: DrawBuffer;
	builder: DrawVertexBuilder;


public:
	fn close()
	{
		destroy(ref builder);
		reference(ref vbo, null);
	}

	fn blit(t: Target, texture: Texture, x: i32, y: i32)
	{
		updateVBO(x, y, texture.width, texture.height);

		// Draw text
		transform: math.Matrix4x4d;
		t.setMatrixToOrtho(ref transform);
		mat: math.Matrix4x4f;
		mat.setFrom(ref transform);

		drawShader.bind();
		drawShader.matrix4("matrix", 1, true, ref mat);

		glBindVertexArray(vbo.vao);
		texture.bind();
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glDrawArrays(GL_TRIANGLES, 0, vbo.num);

		glDisable(GL_BLEND);
		texture.unbind();
		glBindVertexArray(0);
	}

	fn updateVBO(x: i32, y: i32, w: u32, h: u32)
	{
		if (vbo !is null &&
		    lastX == x && lastY == y &&
		    lastW == w && lastH == h) {
			return;
		}

		if (builder is null) {
			builder = new DrawVertexBuilder(6u);
		}

		dstX1 := cast(f32)x;
		dstY1 := cast(f32)y;
		dstX2 := cast(f32)(x + cast(i32)w);
		dstY2 := cast(f32)(y + cast(i32)h);

		srcX1 := 0.0f;
		srcY1 := 0.0f;
		srcX2 := 1.0f;
		srcY2 := 1.0f;

		builder.reset(6u);
		builder.add(dstX1, dstY1, srcX1, srcY1);
		builder.add(dstX1, dstY2, srcX1, srcY2);
		builder.add(dstX2, dstY2, srcX2, srcY2);
		builder.add(dstX2, dstY2, srcX2, srcY2);
		builder.add(dstX2, dstY1, srcX2, srcY1);
		builder.add(dstX1, dstY1, srcX1, srcY1);

		if (vbo is null) {
			vbo = DrawBuffer.make("gfx/blitter", builder);
		} else {
			vbo.update(builder);
		}
	}
}
