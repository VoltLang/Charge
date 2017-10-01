// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.pipeline;

import io = watt.io;

import watt.text.string;
import watt.text.format;
import watt.math.floating;

import gfx = charge.gfx;
import math = charge.math;

import charge.gfx.gl;

import voxel.svo.util;
import voxel.svo.design;
import voxel.svo.entity;
import voxel.svo.shaders;
import voxel.svo.buffers;


/*!
 * Checks if we can run voxel graphics code, return null on success.
 */
fn checkGraphics() string
{
	str: string;

	// Need OpenGL 4.5 now.
	if (!GL_VERSION_4_5) {
		str ~= "Need at least GL 4.5\n";
	}

	// For texture functions.
	if (!GL_ARB_texture_storage && !GL_VERSION_4_5) {
		str ~= "Need GL_ARB_texture_storage or OpenGL 4.5\n";
	}

	// For samplers functions.
	if (!GL_ARB_sampler_objects && !GL_VERSION_3_3) {
		str ~= "Need GL_ARB_sampler_objects or OpenGL 3.3\n";
	}

	// For shaders.
	if (!GL_ARB_ES2_compatibility) {
		str ~= "Need GL_ARB_ES2_compatibility\n";
	}
	if (!GL_ARB_explicit_attrib_location) {
		str ~= "Need GL_ARB_explicit_attrib_location\n";
	}
	if (!GL_ARB_shader_ballot) {
		str ~= "Need GL_ARB_shader_ballot\n";
	}
	if (!GL_ARB_shader_atomic_counter_ops && !GL_AMD_shader_atomic_counter_ops) {
		str ~= "Need GL_ARB_shader_atomic_counter_ops\n";
		str ~=  " or GL_AMD_shader_atomic_counter_ops\n";
	}

	return str;
}

/*!
 * Input to the draw call that renders the SVO.
 */
struct Draw
{
	camMVP: math.Matrix4x4d;
	cullMVP: math.Matrix4x4d;
	camPos: math.Point3f; pad0: f32;
	cullPos: math.Point3f; pad1: f32;
	frame, targetWidth, targetHeight: u32; fov: f32;
}

/*!
 * A single SVO rendering pipeline.
 */
abstract class Pipeline
{
public:
	counters: gfx.Counters;
	name: string;


public:
	this(name: string, counters: gfx.Counters)
	{
		this.name = name;
		this.counters = counters;
	}

	abstract fn close();
	abstract fn draw(ref input: Draw);
}

/*!
 * A single SVO rendering pipeline.
 */
class TestPipeline : Pipeline
{
public:
	data: Data;


public:
	this(data: Data)
	{
		this.data = data;
		super("test", new gfx.Counters("test"));
	}

	override fn close()
	{

	}

	override fn draw(ref input: Draw)
	{

	}
}
