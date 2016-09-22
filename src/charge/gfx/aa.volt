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
		fbo.unbind();
		t.bind();

		// Clear the screen.
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		aaShader.bind();

		glBindVertexArray(aaVbo.vao);
		fbo.color.bind();
		glBindSampler(0, aaSampler);

		glDrawArrays(GL_QUADS, 0, aaVbo.num);

		glBindSampler(0, 0);
		fbo.color.unbind();
		glBindVertexArray(0);
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

/// Shader to be used to blit the texture.
global Shader aaShader;

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
	auto b = new DrawVertexBuilder(4);
	b.add(-1.f, -1.f, -1.f, -1.f);
	b.add( 1.f, -1.f,  1.f, -1.f);
	b.add( 1.f,  1.f,  1.f,  1.f);
	b.add(-1.f,  1.f, -1.f,  1.f);
	aaVbo = DrawBuffer.make("power/aaQuad", b);

	// Setup sampler
	glGenSamplers(1, &aaSampler);
	glSamplerParameteri(aaSampler, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glSamplerParameteri(aaSampler, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	aaShader = new Shader(aaVertex130, aaFragment130,
	                      ["position", "uv", "color"], ["tex"]);
}

void closeAA()
{
	if (aaSampler) { glDeleteSamplers(1, &aaSampler); aaSampler = 0; }
	if (aaVbo !is null) { aaVbo.decRef(); aaVbo = null; }

	aaShader.breakApart();
	aaShader = null;
}

enum string aaVertex130 = `
#version 130

attribute vec2 position;

varying vec2 uvFS;


void main(void)
{
	uvFS = (position / 2 + 0.5);
	uvFS.y = 1 - uvFS.y;
	gl_Position = vec4(position, 0.0, 1.0);
}
`;

enum string aaFragment130 = `
#version 130

uniform sampler2D color;

varying vec2 uvFS;


void main(void)
{
	// Get color.
	vec4 c = texture(color, uvFS);

	gl_FragColor = vec4(c.xyz, 1.0);
}
`;
