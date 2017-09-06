// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.voxel.boxel;

import sys = charge.sys;
import gfx = charge.gfx;
import math = charge.math;

import charge.gfx.gl;


/*!
 * VBO used for boxed base voxels.
 */
class BoxelBuffer : gfx.Buffer
{
public:
	num: GLsizei;


public:
	global fn make(name: string, vb: BoxelBuilder) BoxelBuffer
	{
		dummy: void*;
		buffer := cast(BoxelBuffer)sys.Resource.alloc(
			typeid(BoxelBuffer), uri, name, 0, out dummy);
		buffer.__ctor(0, 0);
		buffer.update(vb);
		return buffer;
	}

	fn update(vb: BoxelBuilder)
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
	x, y, z: float;
	color: math.Color4b;

	fn opCall(x: f32, y: f32, z: f32, color: math.Color4b) Vertex
	{
		vert: Vertex;
		vert.x = x;
		vert.y = y;
		vert.z = z;
		vert.color = color;
		return vert;
	}
}

class BoxelBuilder : gfx.Builder
{
	this(num: size_t)
	{
		reset(num);
	}

	final fn reset(num: size_t = 0)
	{
		resetStore(12 * num * typeid(Vertex).size);
	}

	final fn addCube(x: f32, y: f32, z: f32, color: math.Color4b)
	{
		vert: Vertex[24];
		color.a = 0;
		vert[ 0] = Vertex.opCall(  x, 1+y,   z, color);
		vert[ 1] = Vertex.opCall(  x,   y,   z, color);
		vert[ 2] = Vertex.opCall(1+x,   y,   z, color);
		vert[ 3] = Vertex.opCall(1+x, 1+y,   z, color);

		color.a = 1;
		vert[ 4] = Vertex.opCall(  x,   y, 1+z, color);
		vert[ 5] = Vertex.opCall(  x, 1+y, 1+z, color);
		vert[ 6] = Vertex.opCall(1+x, 1+y, 1+z, color);
		vert[ 7] = Vertex.opCall(1+x,   y, 1+z, color);

		color.a = 2;
		vert[ 8] = Vertex.opCall(  x,   y,   z, color);
		vert[ 9] = Vertex.opCall(  x, 1+y,   z, color);
		vert[10] = Vertex.opCall(  x, 1+y, 1+z, color);
		vert[11] = Vertex.opCall(  x,   y, 1+z, color);

		color.a = 3;
		vert[12] = Vertex.opCall(1+x, 1+y,   z, color);
		vert[13] = Vertex.opCall(1+x,   y,   z, color);
		vert[14] = Vertex.opCall(1+x,   y, 1+z, color);
		vert[15] = Vertex.opCall(1+x, 1+y, 1+z, color);

		color.a = 4;
		vert[16] = Vertex.opCall(  x,   y,   z, color);
		vert[17] = Vertex.opCall(  x,   y, 1+z, color);
		vert[18] = Vertex.opCall(1+x,   y, 1+z, color);
		vert[19] = Vertex.opCall(1+x,   y,   z, color);

		color.a = 5;
		vert[20] = Vertex.opCall(  x, 1+y, 1+z, color);
		vert[21] = Vertex.opCall(  x, 1+y,   z, color);
		vert[22] = Vertex.opCall(1+x, 1+y,   z, color);
		vert[23] = Vertex.opCall(1+x, 1+y, 1+z, color);

		add(vert.ptr, 24);
	}

	final fn add(vert: Vertex*, num: size_t)
	{
		add(cast(void*)vert, num * typeid(Vertex).size);
	}

	alias add = gfx.Builder.add;

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
		glVertexAttribPointer(0, 3, GL_FLOAT, 0, stride, null);
		glVertexAttribPointer(1, 4, GL_UNSIGNED_BYTE, 1, stride, cast(void*)(3 * 4));
		glEnableVertexAttribArray(0);
		glEnableVertexAttribArray(1);

		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindVertexArray(0);

		num = cast(GLsizei)length / stride;
	}
}
