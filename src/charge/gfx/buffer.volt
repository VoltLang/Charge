// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.gfx.buffer;

import charge.gfx.gl;
import charge.sys.memory;
import charge.sys.resource;


class Buffer : Resource
{
public:
	enum string uri = "buf://";
	GLuint vao;
	GLuint buf;


protected:
	void deleteBuffers()
	{
		if (buf) { glDeleteBuffers(1, &buf); buf = 0; }
		if (vao) { glDeleteVertexArrays(1, &vao); vao = 0; }	
	}


private:
	this(GLuint vao, GLuint buf)
	{
		this.vao = vao;
		this.buf = buf;
		super();
	}

	~this()
	{
		deleteBuffers();
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
