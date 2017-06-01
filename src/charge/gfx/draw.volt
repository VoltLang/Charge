// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.gfx.draw;

import charge.core;
import charge.gfx.gl;
import charge.gfx.shader;
import charge.gfx.buffer;
import charge.sys.resource;
import charge.math.color;


/*!
 * VBO used for 2D drawing operations.
 */
class DrawBuffer : Buffer
{
public:
	num: GLsizei;


public:
	global fn make(name: string, vb: DrawVertexBuilder) DrawBuffer
	{
		dummy: void*;
		buffer := cast(DrawBuffer)Resource.alloc(
			typeid(DrawBuffer), uri, name, 0, out dummy);
		buffer.__ctor(0, 0);
		buffer.update(vb);
		return buffer;
	}

	fn update(vb: DrawVertexBuilder)
	{
		deleteBuffers();
		vb.bake(out vao, out buf, out num);
	}

protected:
	this(GLuint vao, GLuint buf)
	{
		super(vao, buf);
	}
}


/*!
 * Shader to be used with the vertex format in this file.
 *
 * It has one shader uniform called 'matrix' that is the.
 */
global drawShader: Shader;


/*!
 * Vertex format.
 */
struct DrawVertex
{
	x, y: f32;
	u, v: f32;
	color: Color4b;
}


class DrawVertexBuilder : Builder
{
	this(size_t num)
	{
		reset(num);
	}

	final fn reset(num: size_t = 0)
	{
		resetStore(num * typeid(DrawVertex).size);
	}

	final fn add(x: f32, y: f32, u: f32, v: f32)
	{
		vert: DrawVertex;
		vert.x = x;
		vert.y = y;
		vert.u = u;
		vert.v = v;
		*cast(uint*)&vert.color = 0xffffffffU;
		add(&vert, 1);
	}

	final fn add(x: f32, y: f32, u: f32, v: f32, color: Color4b)
	{
		vert: DrawVertex;
		vert.x = x;
		vert.y = y;
		vert.u = u;
		vert.v = v;
		vert.color = color;
		add(&vert, 1);
	}

	final fn add(vert: DrawVertex*, num: size_t)
	{
		add(cast(void*)vert, num * typeid(DrawVertex).size);
	}

	alias add = Builder.add;

	final fn bake(out vao: GLuint, out buf: GLuint, out num: GLsizei)
	{
		// Setup vertex buffer and upload the data.
		glGenBuffers(1, &buf);
		glGenVertexArrays(1, &vao);

		// And the darkness bind them.
		glBindVertexArray(vao);
		glBindBuffer(GL_ARRAY_BUFFER, buf);

		glBufferData(GL_ARRAY_BUFFER, cast(GLsizeiptr)length, ptr, GL_STATIC_DRAW);

		stride := cast(GLsizei)typeid(DrawVertex).size;
		glVertexAttribPointer(0, 2, GL_FLOAT, 0, stride, null);
		glVertexAttribPointer(1, 2, GL_FLOAT, 0, stride, cast(void*)(4 * 2));
		glVertexAttribPointer(2, 4, GL_UNSIGNED_BYTE, 1, stride, cast(void*)(4 * 4));
		glEnableVertexAttribArray(0);
		glEnableVertexAttribArray(1);
		glEnableVertexAttribArray(2);

		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindVertexArray(0);

		num = cast(GLsizei)length / stride;
	}
}


/*
 *
 * Shader setup code.
 *
 */

global this()
{
	Core.addInitAndCloseRunners(initDraw, closeDraw);
}

fn initDraw()
{
	drawShader = new Shader("charge.gfx.draw", vertexShaderES,
	                    fragmentShaderES,
	                    ["position", "uv", "color"],
	                    ["tex"]);
}

fn closeDraw()
{
	drawShader.breakApart();
	drawShader = null;
}

enum string vertexShaderES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

attribute vec2 position;
attribute vec2 uv;
attribute vec4 color;

uniform mat4 matrix;

varying vec2 uvFs;
varying vec4 colorFs;

void main(void)
{
	uvFs = uv;
	colorFs = color;
	gl_Position = matrix * vec4(position, 0.0, 1.0);
}
`;

enum string fragmentShaderES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

varying vec2 tx;
uniform sampler2D tex;

varying vec2 uvFs;
varying vec4 colorFs;

void main(void)
{
	vec4 t = texture2D(tex, uvFs);
	gl_FragColor = t * colorFs;
}
`;
