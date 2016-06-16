// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.gfx.draw;

import charge.core;
import charge.gfx.gl;
import charge.gfx.shader;
import charge.gfx.buffer;
import charge.sys.memory;
import charge.sys.resource;
import charge.math.color;


/**
 * VBO used for 2D drawing operations.
 */
class DrawBuffer : Buffer
{
public:
	GLsizei num;


public:
	global DrawBuffer make(string name, DrawVertexBuilder vb)
	{
		void* dummy;
		buffer := cast(DrawBuffer)Resource.alloc(
			typeid(DrawBuffer), uri, name, 0, out dummy);
		buffer.__ctor(0, 0);
		buffer.update(vb);
		return buffer;
	}

	void update(DrawVertexBuilder vb)
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


/**
 * Shader to be used with the vertex format in this file.
 *
 * It has one shader uniform called 'matrix' that is the.
 */
global Shader drawShader;


/**
 * Vertex format.
 */
struct DrawVertex
{
	float x, y;
	float u, v;
	Color4b color;
}


class DrawVertexBuilder : Builder
{
	this(size_t num)
	{
		reset(num);
	}

	final void reset(size_t num = 0)
	{
		resetStore(num * typeid(DrawVertex).size);
	}

	final void add(float x, float y, float u, float v)
	{
		DrawVertex vert;
		vert.x = x;
		vert.y = y;
		vert.u = u;
		vert.v = v;
		*cast(uint*)&vert.color = 0xffffffffU;
		add(&vert, 1);
	}

	final void add(float x, float y, float u, float v, Color4b color)
	{
		DrawVertex vert;
		vert.x = x;
		vert.y = y;
		vert.u = u;
		vert.v = v;
		vert.color = color;
		add(&vert, 1);
	}

	final void add(DrawVertex* vert, size_t num)
	{
		add(cast(void*)vert, num * typeid(DrawVertex).size);
	}

	alias add = Builder.add;

	final void bake(out GLuint vao, out GLuint buf, out GLsizei num)
	{
		// Setup vertex buffer and upload the data.
		glGenBuffers(1, &buf);
		glGenVertexArrays(1, &vao);

		// And the darkness bind them.
		glBindVertexArray(vao);
		glBindBuffer(GL_ARRAY_BUFFER, buf);

		glBufferData(GL_ARRAY_BUFFER, cast(GLsizeiptr)length, ptr, GL_STATIC_DRAW);

		auto stride = cast(GLsizei)typeid(DrawVertex).size;
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

class Builder
{
private:
	void* mPtr;
	size_t mPos;
	size_t mSize;

public:
	final @property void* ptr() { return mPtr; }
	final @property size_t length() { return mPos; }

	~this()
	{
		close();
	}

	final void close()
	{
		if (mPtr !is null) {
			cFree(mPtr);
			mPtr = null;
		}
		mPos = 0;
		mSize = 0;
	}

	final void add(void* input, size_t size)
	{
		if (mPos + size >= mSize) {
			mSize += mPos + size;
			mPtr = cRealloc(mPtr, mSize);
		}
		mPtr[mPos .. mPos + size] = input[0 .. size];
		mPos += size;
	}

private:
	void resetStore(size_t size)
	{
		if (mSize < size) {
			cFree(mPtr);
			mPtr = cMalloc(size);
			mSize = size;
		}
		mPos = 0;
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

void initDraw()
{
	drawShader = new Shader(vertexShaderES,
	                    fragmentShaderES,
	                    ["position", "uv", "color"],
	                    ["tex"]);
}

void closeDraw()
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
