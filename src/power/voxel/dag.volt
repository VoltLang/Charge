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
	num: GLsizei;


public:
	global fn make(name: string, vb: DagBuilder) DagBuffer
	{
		dummy: void*;
		buffer := cast(DagBuffer)Resource.alloc(
			typeid(DagBuffer), uri, name, 0, out dummy);
		buffer.__ctor(0, 0);
		buffer.update(vb);
		return buffer;
	}

	fn update(vb: DagBuilder)
	{
		deleteBuffers();
		vb.bake(out vao, out buf, out num);
	}


protected:
	this(vao: GLuint, buf: GLuint)
	{
		super(vao, buf);
	}
}

struct Vertex
{
	x, y, z, w: i8;
}


class DagBuilder : GfxBuilder
{
public:
	this(num: size_t)
	{
		reset(num);
	}

	final fn reset(num: size_t = 0)
	{
		resetStore(num * typeid(Vertex).size);
	}

	final fn add(x: i8, y: i8, z: i8, w: i8)
	{
		vert: Vertex;
		vert.x = x;
		vert.y = y;
		vert.z = z;
		vert.w = w;

		add(&vert, 1);
	}

	final fn add(vert: Vertex*, num: size_t)
	{
		add(cast(void*)vert, num * typeid(Vertex).size);
	}

	alias add = GfxBuilder.add;

	final fn bake(out vao: GLuint, out buf: GLuint, out num: GLsizei)
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
