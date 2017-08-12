// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.entity;

import math = charge.math;
import charge.gfx.gl;

import voxel.svo.design : Create;

/*!
 * A single entity that points into a SVO tree.
 */
class Entity
{
	data: Data;
	frame: size_t;
	frames: u32[];
	index: size_t;


public:
	this(data: Data, frames: u32[])
	{
		this.data = data;
		this.frames = frames;

		assert(frames.length > 0);
		te: EntityEntry;
		te.start = frames[0];
		te.rot = math.Quatf.opCall();

		index = data.trees.length;
		data.trees ~= te;
	}

	fn stepFrame()
	{
		if (++frame >= frames.length) {
			frame = 0;
		}

		entry.start = frames[frame];
	}

	@property fn start() u32 { return entry.start; }


protected:
	final @property fn entry() EntityEntry*
	{
		return &data.trees[index];
	}
}

/*!
 * Entity data kept in a array.
 */
struct EntityEntry
{
	//! Position of this Tree.
	pos: math.Point3f;
	//! Starting address of this Tree.
	start: u32;
	//! Rotation of this Tree.
	rot: math.Quatf;
}

/*!
 * Holds data for multiple SVO trees and Entities.
 */
class Data
{
public:
	data: u32[];
	trees: EntityEntry[];
	create: Create;

	texture: GLuint;
	buffer: GLuint;


public:
	this(ref create: Create, data: void[])
	{
		this.create = create;
		this.data = cast(u32[])data;

		glCreateBuffers(1, &buffer);
		glNamedBufferData(buffer, cast(GLsizeiptr)data.length, data.ptr, GL_STATIC_DRAW);

		glCreateTextures(GL_TEXTURE_BUFFER, 1, &texture);
		glTextureBuffer(texture, GL_R32UI, buffer);
	}

	fn count(obj: Entity, levels: u32) size_t
	{
		return decend(data, levels, obj.start);
	}

}

private:

final fn decend(data: u32[], level: u32, addr: u32) u32
{
	level--;

	if (level == 0) {
		return __llvm_ctpop(data[addr] & 0xff);
	}

	ret: u32;
	bits := data[addr];
	count := (bits >> 16u) & 0xffff;
	foreach (i; 0u .. 8u) {
		if ((bits & (1 << i)) == 0) {
			continue;
		}

		ret += decend(data, level, data[addr + count++]);
	}

	return ret;
}

@mangledName("llvm.ctpop.i32")
fn __llvm_ctpop(bits: u32) u32;
