// Copyright 2016-2019, Jakob Bornecrantz.
// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0
module charge.gfx.simple;

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
fn reference(ref dec: SimpleBuffer, inc: SimpleBuffer)
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
fn destroy(ref obj: SimpleVertexBuilder)
{
	if (obj !is null) { obj.close(); obj = null; }
}

/*!
 * VBO used for simple drawing operations.
 */
class SimpleBuffer : Buffer
{
public:
	num: GLsizei;


public:
	global fn make(name: string, vb: SimpleVertexBuilder) SimpleBuffer
	{
		dummy: void*;
		buffer := cast(SimpleBuffer)sys.Resource.alloc(
			typeid(SimpleBuffer), uri, name, 0, out dummy);
		buffer.__ctor(0, 0);
		buffer.update(vb);
		return buffer;
	}

	fn update(vb: SimpleVertexBuilder)
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
global simpleShader: Shader;

/*!
 * Vertex format, vec3!f32 position, vec2!f32 coordinate and vec4!u8 color.
 */
struct SimpleVertex
{
	x, y, z: f32;
	u, v: f32;
	color: math.Color4b;
}

/*!
 * Building simple vertex buffers.
 */
class SimpleVertexBuilder : Builder
{
	this(size_t num)
	{
		reset(num);
	}

	final fn reset(num: size_t = 0)
	{
		resetStore(num * typeid(SimpleVertex).size);
	}

	final fn add(x: f32, y: f32, z: f32, u: f32, v: f32)
	{
		vert: SimpleVertex;
		vert.x = x;
		vert.y = y;
		vert.z = z;
		vert.u = u;
		vert.v = v;
		*cast(uint*)&vert.color = 0xffffffffU;
		add(&vert, 1);
	}

	final fn add(x: f32, y: f32, z: f32, u: f32, v: f32, color: math.Color4b)
	{
		vert: SimpleVertex;
		vert.x = x;
		vert.y = y;
		vert.z = z;
		vert.u = u;
		vert.v = v;
		vert.color = color;
		add(&vert, 1);
	}

	final fn add(vert: SimpleVertex*, num: size_t)
	{
		add(cast(void*)vert, num * typeid(SimpleVertex).size);
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

		stride := cast(GLsizei)typeid(SimpleVertex).size;
		glVertexAttribPointer(0, 3, GL_FLOAT, 0, stride, null);
		glVertexAttribPointer(1, 2, GL_FLOAT, 0, stride, cast(void*)(4 * 3));
		glVertexAttribPointer(2, 4, GL_UNSIGNED_BYTE, 1, stride, cast(void*)(4 * 5));
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
	core.addInitAndCloseRunners(initSimple, closeSimple);
}

fn initSimple()
{
	simpleShader = new Shader("charge.gfx.simple", vertexShaderES,
	                    fragmentShaderES,
	                    ["position", "uv", "color"],
	                    ["tex"]);
}

fn closeSimple()
{
	charge.gfx.shader.destroy(ref simpleShader);
}

enum string vertexShaderES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

attribute vec3 position;
attribute vec2 uv;
attribute vec4 color;

uniform mat4 matrix;

varying vec2 uvFs;
varying vec4 colorFs;

void main(void)
{
	uvFs = uv;
	colorFs = color;
	gl_Position = matrix * vec4(position, 1.0);
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
