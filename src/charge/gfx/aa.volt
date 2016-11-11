// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.gfx.aa;

import charge.core;
import charge.gfx.gl;
import charge.gfx.draw;
import charge.gfx.target;
import charge.gfx.shader;
import charge.gfx.buffer;
import charge.gfx.texture;
import charge.sys.resource;
import charge.math.color;
import charge.math.matrix;


struct AA
{
public:
	Framebuffer fbo;


public:
	fn breakApart()
	{
		if (fbo !is null) { fbo.decRef(); fbo = null; }
	}

	fn bind(t: Target)
	{
		setupFramebuffer(t);
		t.unbind();
		fbo.bind();
	}

	fn unbindAndDraw(t: Target)
	{
		Matrix4x4f mat;
		mat.setToIdentity();

		fbo.unbind();
		t.bind();

		// Clear the screen.
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		drawShader.bind();
		drawShader.matrix4("matrix", 1, true, mat.u.a.ptr);

		glBindVertexArray(aaVbo.vao);
		fbo.color.bind();
		glBindSampler(0, aaSampler);

		glDrawArrays(GL_TRIANGLE_STRIP, 0, aaVbo.num);

		glBindSampler(0, 0);
		fbo.color.unbind();
		glBindVertexArray(0);

		drawShader.unbind();
	}

	fn setupFramebuffer(t: Target)
	{
		if (fbo !is null &&
		    (t.width * 2) == fbo.width &&
		    (t.height * 2) == fbo.height) {
			return;
		}

		if (fbo !is null) { fbo.decRef(); fbo = null; }
		fbo = Framebuffer.make("power/exp/fbo", t.width * 2, t.height * 2);
	}
}

/// Quad vbo.
global DrawBuffer aaVbo;

/// Sampler to use with the shader.
global GLuint aaSampler;


/*
 *
 * Shader setup code.
 *
 */

global this()
{
	Core.addInitAndCloseRunners(initAA, closeAA);
}

void initAA()
{
	auto b = new DrawVertexBuilder(6);
	b.add(-1.f, -1.f, 0.f, 0.f);
	b.add( 1.f, -1.f, 1.f, 0.f);
	b.add( 1.f,  1.f, 1.f, 1.f);
	b.add( 1.f,  1.f, 1.f, 1.f);
	b.add(-1.f,  1.f, 0.f, 1.f);
	b.add(-1.f, -1.f, 0.f, 0.f);
	aaVbo = DrawBuffer.make("power/aaQuad", b);

	// Setup sampler
	glGenSamplers(1, &aaSampler);
	glSamplerParameteri(aaSampler, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glSamplerParameteri(aaSampler, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
}

void closeAA()
{
	if (aaSampler) { glDeleteSamplers(1, &aaSampler); aaSampler = 0; }
	if (aaVbo !is null) { aaVbo.decRef(); aaVbo = null; }
}
