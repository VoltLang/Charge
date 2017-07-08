// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module ohmd.model;

import lib.gl.gl45;

import io = watt.io;
import watt.algorithm;

import math = charge.math;
import charge.gfx;

import voxel.loaders;


class VoxelModel
{
public:
	rot: math.Quatf;
	pos: math.Point3f;
	off: math.Vector3f;
	num: u32;

	buffer: GLuint;


public:
	static fn fromModel(vm: VoxelModel) VoxelModel
	{
		return new VoxelModel(vm.buffer, vm.num, ref vm.off);
	}

	static fn fromMagicalData(data: const(void)[]) VoxelModel
	{
		// Load the HMD model.
		l := new magica.Loader();
		l.loadFileFromData(data);
		arr := l.toBufferXYZ64ABGR32();

		num := cast(u32)arr.length / 3u;
		size := cast(GLsizeiptr)(arr.length * typeid(u32).size);

		// Create the storage for the buffer.
		buffer: GLuint;
		glCreateBuffers(1, &buffer);
		glNamedBufferStorage(buffer, size, cast(void*)arr.ptr,  0);

		off: math.Vector3f;
		calcOffset(arr, num, out off);

		return new VoxelModel(buffer, num, ref off);
	}


protected:
	this(buffer: GLuint, num: u32, ref off: math.Vector3f)
	{
		this.buffer = buffer;
		this.num = num;
		this.off = off;
		this.rot = math.Quatf.opCall();
		this.pos = math.Point3f.opCall(0.f, 0.f, 0.f);
	}
}


public:

fn calcOffset(data: const(u32)[], num: u32, out off: math.Vector3f)
{
	minX, minY, minZ: u32;
	maxX, maxY, maxZ: u32;
	minX = minY = minZ = u32.max;
	maxX = maxY = maxZ = u32.min;

	foreach (i; 0 .. num) {
		index := i * 3;
		x := (data[index + 0] >>  0) & 0xffff;
		y := (data[index + 0] >> 16) & 0xffff;
		z := (data[index + 1] >>  0) & 0xffff;

		minX = min(x, minX);
		minY = min(y, minY);
		minZ = min(z, minZ);
		maxX = max(x+1, maxX);
		maxY = max(y+1, maxY);
		maxZ = max(z+1, maxZ);
	}

	off = math.Vector3f.opCall(
		cast(f32)(maxX - minX),
		cast(f32)(maxY - minY),
		cast(f32)(maxZ - minZ));
	off.scale(0.5f);
	off += math.Vector3f.opCall(cast(f32)minX, cast(f32)minY, cast(f32)minZ);
}
