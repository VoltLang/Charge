// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.gfx.buffer;

import sys = charge.sys;

import charge.gfx.gl;


/*!
 * Dereference and reference helper function.
 *
 * @param dec Object to dereference passed by reference, set to `inc`.
 * @param inc Object to reference.
 * @{
 */
fn reference(ref dec: Buffer, inc: Buffer)
{
	if (inc !is null) { inc.incRef(); }
	if (dec !is null) { dec.decRef(); }
	dec = inc;
}

fn reference(ref dec: IndirectBuffer, inc: IndirectBuffer)
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
fn destroy(ref obj: Builder)
{
	if (obj !is null) { obj.close(); obj = null; }
}

class Buffer : sys.Resource
{
public:
	enum string uri = "buf://";
	vao: GLuint;
	buf: GLuint;


public:
	~this()
	{
		deleteBuffers();
	}


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
			sys.cFree(mPtr);
			mPtr = null;
		}
		mPos = 0;
		mSize = 0;
	}

	final fn add(input: void*, size: size_t)
	{
		if (mPos + size >= mSize) {
			mSize += mPos + size;
			mPtr = sys.cRealloc(mPtr, mSize);
		}
		mPtr[mPos .. mPos + size] = input[0 .. size];
		mPos += size;
	}

	fn resetStore(size: size_t)
	{
		if (mSize < size) {
			sys.cFree(mPtr);
			mPtr = sys.cMalloc(size);
			mSize = size;
		}
		mPos = 0;
	}
}

/*!
 * Follows the OpenGL spec for input to draw arrays indirection fuctions.
 *
 * glDrawArraysIndirect
 * glMultiDrawArraysIndirect
 */
struct IndirectData
{
	count: GLuint;
	instanceCount: GLuint;
	first: GLuint;
	baseInstance: GLuint;
}

/*!
 * Inderect buffer for use with OpenGL darw arrays indirect functions.
 *
 * glDrawArraysIndirect
 * glMultiDrawArraysIndirect
 */
class IndirectBuffer : sys.Resource
{
public:
	buf: GLuint;
	num: GLsizei;


public:
	~this()
	{
		if (buf) { glDeleteBuffers(1, &buf); buf = 0; }
	}

	global fn make(name: string, data: IndirectData[]) IndirectBuffer
	{
		dummy: void*;
		buffer := cast(IndirectBuffer)sys.Resource.alloc(
			typeid(IndirectBuffer), Buffer.uri, name, 0, out dummy);
		buffer.__ctor(data);
		return buffer;
	}


protected:
	this(data: IndirectData[])
	{
		super();
		this.num = cast(GLsizei)data.length;

		indirectStride := cast(GLsizei)typeid(IndirectData).size;
		indirectLength := num * indirectStride;

		glCreateBuffers(1, &buf);
		glNamedBufferStorage(buf, indirectLength, cast(void*)data.ptr, GL_DYNAMIC_STORAGE_BIT);
		glCheckError();
	}
}
