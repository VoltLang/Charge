// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.gfx.draw;

import charge.gfx.gl;
import charge.sys.memory;
import charge.math.color;


struct Vertex
{
	float x, y;
	float u, v;
	Color4b color;
}

class VertexBuilder : Builder
{
	this(size_t num)
	{
		reset(num);
	}

	final void reset(size_t num = 0)
	{
		resetStore(num * typeid(Vertex).size);
	}

	final void add(float x, float y, float u, float v)
	{
		Vertex vert;
		vert.x = x;
		vert.y = y;
		vert.u = u;
		vert.v = v;
		*cast(uint*)&vert.color = 0xffffffffU;
		add(&vert, 1);
	}

	final void add(float x, float y, float u, float v, Color4b color)
	{
		Vertex vert;
		vert.x = x;
		vert.y = y;
		vert.u = u;
		vert.v = v;
		vert.color = color;
		add(&vert, 1);
	}

	final void add(Vertex* vert, size_t num)
	{
		add(cast(void*)vert, num * typeid(Vertex).size);
	}

	alias add = Builder.add;

	final void bake(out GLuint vao, out GLuint buf)
	{
		// Setup vertex buffer and upload the data.
		glGenBuffers(1, &buf);
		glGenVertexArrays(1, &vao);

		// And the darkness bind them.
		glBindVertexArray(vao);
		glBindBuffer(GL_ARRAY_BUFFER, buf);

		glBufferData(GL_ARRAY_BUFFER, cast(GLsizeiptr)length, ptr, GL_STATIC_DRAW);

		auto stride = cast(GLsizei)typeid(Vertex).size;
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
