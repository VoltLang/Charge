// Copyright 2016-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
module voxel.svo.entity;

import math = charge.math;

import lib.gl.gl45;

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
	numLevels: u32;


public:
	this(data: Data, frames: u32[], numLevels: u32)
	{
		this.data = data;
		this.frames = frames;
		this.numLevels = numLevels;

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
	@property fn rot() math.Quatf { return entry.rot; }
	@property fn pos() math.Point3f { return entry.pos; }


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
