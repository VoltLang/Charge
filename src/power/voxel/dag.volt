// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.voxel.dag;

import charge.sys.resource;
import charge.gfx;

import math = charge.math;


/**
 * VBO used for boxed base voxels.
 */
class DagBuffer : GfxBuffer
{
public:
	GLsizei num;


public:
	global DagBuffer make(string name, DagBuilder vb)
	{
		void* dummy;
		auto buffer = cast(DagBuffer)Resource.alloc(
			typeid(DagBuffer), uri, name, 0, out dummy);
		buffer.__ctor(0, 0);
		buffer.update(vb);
		return buffer;
	}

	void update(DagBuilder vb)
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

struct Vertex
{
	byte x, y, z, w;
}


class DagBuilder : GfxBuilder
{
	this(size_t num)
	{
		reset(num);
	}

	final void reset(size_t num = 0)
	{
		resetStore(num * typeid(Vertex).size);
	}

	final void add(i8 x, i8 y, i8 z, i8 w)
	{
		Vertex vert;
		vert.x = x;
		vert.y = y;
		vert.z = z;
		vert.w = w;

		add(&vert, 1);
	}

	final void add(Vertex* vert, size_t num)
	{
		add(cast(void*)vert, num * typeid(Vertex).size);
	}

	alias add = GfxBuilder.add;

	final void bake(out GLuint vao, out GLuint buf, out GLsizei num)
	{
		// Setup vertex buffer and upload the data.
		glGenBuffers(1, &buf);
		glGenVertexArrays(1, &vao);

		// And the darkness bind them.
		glBindVertexArray(vao);
		glBindBuffer(GL_ARRAY_BUFFER, buf);

		glBufferData(GL_ARRAY_BUFFER, cast(GLsizeiptr)length, ptr, GL_STATIC_DRAW);

		stride := cast(GLsizei)typeid(Vertex).size;
		glVertexAttribPointer(0, 4, GL_BYTE, 0, stride, null);
		glEnableVertexAttribArray(0);

		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindVertexArray(0);

		num = cast(GLsizei)length / stride;
	}
}
