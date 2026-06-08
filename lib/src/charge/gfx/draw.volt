// Copyright 2016-2026, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Super simple 2D drawing helper.
 *
 * @ingroup gfx
 */
module charge.gfx.draw;

import lib.gl.gl33;

import core = charge.core;
import sys = charge.sys;
import math = charge.math;

import charge.gfx.gl;
import charge.gfx.shader;
import charge.gfx.buffer;


/*!
 * Dereference and reference helper function.
 *
 * @param dec Object to dereference passed by reference, set to `inc`.
 * @param inc Object to reference.
 * @{
 */
fn reference(ref dec: DrawBuffer, inc: DrawBuffer)
{
	if (inc !is null) { inc.incRef(); }
	if (dec !is null) { dec.decRef(); }
	dec = inc;
}
//! @}

/*!
 * Closes and sets reference to null.
 *
 * @param Object to be destroyed.
 */
fn destroy(ref obj: DrawVertexBuilder)
{
	if (obj !is null) { obj.close(); obj = null; }
}

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
		buffer := cast(DrawBuffer)sys.Resource.alloc(
			typeid(DrawBuffer), uri, name, 0, out dummy);
		buffer.__ctor();
		buffer.update(vb);
		return buffer;
	}

	fn update(vb: DrawVertexBuilder)
	{
		vb.bake(ref vao, ref buf, ref bufSize, out num);
	}

protected:
	this()
	{
		super();
	}
}


/*!
 * Shader to be used with the vertex format in this file.
 *
 * It has one shader uniform called 'matrix' that is the.
 */
global drawShader: Shader;
global drawSamplerLinear: GLuint;
global drawSamplerNearest: GLuint;

/*!
 * Vertex format.
 */
struct DrawVertex
{
	x, y: f32;
	u, v: f32;
	color: math.Color4b;
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

	final fn add(x: f32, y: f32, u: f32, v: f32, color: math.Color4b)
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

	final fn bake(ref vao: GLuint, ref buf: GLuint, ref bufSize: GLsizeiptr, out num: GLsizei)
	{
		dataSize := cast(GLsizeiptr)length;
		stride := cast(GLsizei)typeid(DrawVertex).size;
		num = cast(GLsizei)length / stride;

		if (buf) {
			glBindBuffer(GL_ARRAY_BUFFER, buf);
			if (dataSize <= bufSize) {
				// Update the buffer if it's big enough.
				glBufferSubData(GL_ARRAY_BUFFER, 0, dataSize, ptr);
			} else {
				// Grow the buffer if it's too small.
				glBufferData(GL_ARRAY_BUFFER, dataSize, ptr, GL_STATIC_DRAW);
				bufSize = dataSize;
			}
			glBindBuffer(GL_ARRAY_BUFFER, 0);
		} else {
			glGenBuffers(1, &buf);
			glGenVertexArrays(1, &vao);

			glBindVertexArray(vao);
			glBindBuffer(GL_ARRAY_BUFFER, buf);
			glBufferData(GL_ARRAY_BUFFER, dataSize, ptr, GL_STATIC_DRAW);
			bufSize = dataSize;

			glVertexAttribPointer(0, 2, GL_FLOAT, 0, stride, null);
			glVertexAttribPointer(1, 2, GL_FLOAT, 0, stride, cast(void*)(4 * 2));
			glVertexAttribPointer(2, 4, GL_UNSIGNED_BYTE, 1, stride, cast(void*)(4 * 4));
			glEnableVertexAttribArray(0);
			glEnableVertexAttribArray(1);
			glEnableVertexAttribArray(2);

			glBindBuffer(GL_ARRAY_BUFFER, 0);
			glBindVertexArray(0);
		}
	}
}


/*
 *
 * Shader setup code.
 *
 */

global this()
{
	core.addInitAndCloseRunners(initDraw, closeDraw);
}

fn initDraw()
{
	glGenSamplers(1, &drawSamplerLinear); 
	glSamplerParameteri(drawSamplerLinear, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glSamplerParameteri(drawSamplerLinear, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glGenSamplers(1, &drawSamplerNearest);
	glSamplerParameteri(drawSamplerNearest, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
	glSamplerParameteri(drawSamplerNearest, GL_TEXTURE_MAG_FILTER, GL_NEAREST); 

	drawShader = new Shader("charge.gfx.draw", vertexShaderES,
	                    fragmentShaderES,
	                    ["position", "uv", "color"],
	                    ["tex"]);
}

fn closeDraw()
{
	charge.gfx.shader.destroy(ref drawShader);

	if (drawSamplerLinear) { glDeleteSamplers(1, &drawSamplerLinear); drawSamplerLinear = 0; }
	if (drawSamplerNearest) { glDeleteSamplers(1, &drawSamplerNearest); drawSamplerNearest = 0; }
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
