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
	vao: GLuint;
	buf: GLuint;


protected:
	fn deleteBuffers()
	{
		if (buf) { glDeleteBuffers(1, &buf); buf = 0; }
		if (vao) { glDeleteVertexArrays(1, &vao); vao = 0; }	
	}


private:
	this(vao: GLuint, buf: GLuint)
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
	mPtr: void*;
	mPos: size_t;
	mSize: size_t;

public:
	final @property fn ptr() void* { return mPtr; }
	final @property fn length() size_t { return mPos; }

	~this()
	{
		close();
	}

	final fn close()
	{
		if (mPtr !is null) {
			cFree(mPtr);
			mPtr = null;
		}
		mPos = 0;
		mSize = 0;
	}

	final fn add(input: void*, size: size_t)
	{
		if (mPos + size >= mSize) {
			mSize += mPos + size;
			mPtr = cRealloc(mPtr, mSize);
		}
		mPtr[mPos .. mPos + size] = input[0 .. size];
		mPos += size;
	}

private:
	fn resetStore(size: size_t)
	{
		if (mSize < size) {
			cFree(mPtr);
			mPtr = cMalloc(size);
			mSize = size;
		}
		mPos = 0;
	}
}
