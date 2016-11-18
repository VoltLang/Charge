// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.experiments.raytracer;

import watt.math;
import watt.io.file;
import watt.algorithm;
import watt.text.format;
import io = watt.io;

import charge.ctl;
import charge.gfx;
import charge.core;
import charge.game;
import charge.sys.memory;
import charge.sys.resource;

import math = charge.math;

import power.voxel.dag;
import power.voxel.boxel;
import power.voxel.instance;
import power.experiments.viewer;

fn loadDag(filename: string, out data: void[])
{
	// Setup raytracing code.
	data = read(filename);
	f32ptr := cast(f32*)data.ptr;
	u32ptr := cast(u32*)data.ptr;
	u64ptr := cast(u64*)data.ptr;

	id := u64ptr[0];
	frames := u64ptr[1];
	resolution := u64ptr[2];
	dataSizeInU32 := u64ptr[3];
	minX := f32ptr[ 8];
	minY := f32ptr[ 9];
	minZ := f32ptr[10];
	maxX := f32ptr[11];
	maxY := f32ptr[12];
	maxZ := f32ptr[13];

	// Calculate offset to data, both values are orignally in u32s.
	offset := (frames + 14UL) * 4;
	data = data[offset .. offset + dataSizeInU32 * 4];

/*
	io.writefln("id:         %016x", id);
	io.writefln("frames:     %s", frames);
	io.writefln("resolution: %s", resolution);
	io.writefln("ndwords:    %s", dataSizeInU32);
	io.writefln("rootMin:    %s %s %s", cast(f64)minX, cast(f64)minY, cast(f64)minZ);
	io.writefln("rootMax:    %s %s %s", cast(f64)maxX, cast(f64)maxY, cast(f64)maxZ);

	io.writefln("%s %s", dataSizeInU32 * 4, data.length);
	foreach (i; 0U .. 128U) {
		io.writefln("%04x: %08x", i, u32ptr[(offset / 4) + i]);
	}
*/
}

class RayTracer : Viewer
{
public:

	mPick: bool;
	asvo: AdvancedSVO;
	ssvo: SimpleSVO;
	query: GLuint;
	queryInFlight: bool;
	samples: math.Average;


	/**
	 * For ray tracing.
	 * @{
	 */
	octBuffer: GLuint;
	octTexture: GLuint;
	/**
	 * @}
	 */


public:
	this(GameSceneManager g)
	{
		super(g);
		mPick = true;

		glGenQueries(1, &query);

		data: void[];
		loadDag("res/alley.dag", out data);

		glCreateBuffers(1, &octBuffer);
		glNamedBufferData(octBuffer, cast(GLsizeiptr)data.length, data.ptr, GL_STATIC_DRAW);

		glCreateTextures(GL_TEXTURE_BUFFER, 1, &octTexture);
		glTextureBuffer(octTexture, GL_R32UI, octBuffer);

		ssvo = new SimpleSVO(octTexture);
		asvo = new AdvancedSVO(octTexture);
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override fn close()
	{
		super.close();

		if (octTexture) { glDeleteTextures(1, &octTexture); octTexture = 0; }
		if (octBuffer) { glDeleteBuffers(1, &octBuffer); octBuffer = 0; }
	}

	override fn keyDown(device: CtlKeyboard, keycode: int, c: dchar, m: scope const(char)[])
	{
		switch (keycode) {
		case 'e': mPick = !mPick; break;
		case 'r': ssvo.triggerPatchStart(); break;
		case 't': ssvo.triggerPatchSize(); break;
		case 'y': ssvo.triggerShader(); break;
		default: super.keyDown(device, keycode, c, m);
		}	
	}


	/*
	 *
	 * Viewer methods.
	 *
	 */

	override fn renderScene(t: GfxTarget)
	{
		// Clear the screen.
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgram(0);

		view: math.Matrix4x4f;
		view.setToLookFrom(ref camPosition, ref camRotation);

		proj: math.Matrix4x4f;
		t.setMatrixToProjection(ref proj, 45.f, 0.0001f, 256.f);
		proj.setToMultiply(ref view);
		proj.transpose();


		shouldEnd: bool;
		if (!queryInFlight) {
			glBeginQuery(GL_TIME_ELAPSED, query);
			shouldEnd = true;
		}

		if (mPick) {
			asvo.draw(ref camPosition, ref proj);
		} else {
			ssvo.draw(ref camPosition, ref proj);
		}

		if (shouldEnd) {
			glEndQuery(GL_TIME_ELAPSED);
			queryInFlight = true;
		}

		// Check for last frames query.
		checkQuery(t);

		glDisable(GL_DEPTH_TEST);
	}

	fn checkQuery(t: GfxTarget)
	{
		if (!queryInFlight) {
			return;
		}

		available: GLint;
		glGetQueryObjectiv(query, GL_QUERY_RESULT_AVAILABLE, &available);
		if (!available) {
			return;
		}

		timeElapsed: GLuint64;
		glGetQueryObjectui64v(query, GL_QUERY_RESULT, &timeElapsed);
		queryInFlight = false;

		avg := samples.add(timeElapsed);

		str := `Info:
Elapsed time:
 last: %02sms
 avg:  %02sms
Resolution: %sx%s
w a s d - move camera
e - advanced: %s
r - patch start level: %s
t - patch size: %s^3
y - shader: %s
p - reset position`;

		text := format(str,
			timeElapsed / 1_000_000_000.0 * 1_000.0,
			avg / 1_000_000_000.0 * 1_000.0,
			t.width, t.height,
			mPick,
			ssvo.mPatchStartLevel,
			ssvo.mPatchSize,
			ssvo.mShaderNames[ssvo.mShaderIndex]);

		updateText(text);
	}
}

fn calcAlign(pos: i32, level: i32) i32
{
	shift := level + 1;
	size := 1 << level;
	return ((pos + size) >> shift) << shift;
}

fn calcNumMorton(dim: i32) i32
{
	return dim * dim * dim;
}

class AdvancedSVO
{
protected:
	mVbo: DagBuffer;
	mInstance: InstanceBuffer;
	mIndirect: GfxIndirectBuffer;

	mFeedback: GfxShader;
	mTracer: GfxShader;

	/// Total number of levels in the SVO.
	mVoxelPower: i32;

	/// The number of levels that we subdivide.
	mTraceUpperPower: i32;

	/// The number of levels that we trace.
	mTraceLowerPower: i32;

	mOctTexture: GLuint;
	mFeedbackQuery: GLuint;


public:
	this(octTexture: GLuint)
	{
		mVoxelPower = 11;
		mTraceUpperPower = 4;
		mTraceLowerPower = 4;

		mOctTexture = octTexture;
		glGenQueries(1, &mFeedbackQuery);

		vert := cast(string)read("res/power/shaders/svo/voxel-tracer.vert.glsl");
		geom := cast(string)read("res/power/shaders/svo/voxel-tracer.geom.glsl");
		frag := cast(string)read("res/power/shaders/svo/voxel-tracer.frag.glsl");
		mTracer = new GfxShader("svo.voxel.tracer", vert, geom, frag, null, null);

		vert = cast(string)read("res/power/shaders/svo/voxel-feedback.vert.glsl");
		geom = cast(string)read("res/power/shaders/svo/voxel-feedback.geom.glsl");
		frag = cast(string)read("res/power/shaders/svo/voxel-feedback.frag.glsl");
		mFeedback = new GfxShader("svo.voxel.feedback", vert, geom, frag, null, null);

		numMorton := calcNumMorton(32);
		b := new DagBuilder(cast(size_t)numMorton);
		foreach (i; 0 .. numMorton) {
			vals: u32[3];
			math.decode3(cast(u64)i, out vals);

			x := cast(i32)vals[0];
			y := cast(i32)vals[1];
			z := cast(i32)vals[2];

			x = x % 2 == 1 ? -x >> 1 : x >> 1;
			y = y % 2 == 1 ? -y >> 1 : y >> 1;
			z = z % 2 == 1 ? -z >> 1 : z >> 1;

			b.add(cast(i8)x, cast(i8)y, cast(i8)z, 1);
		}
		mVbo = DagBuffer.make("power/dag", b);
		mInstance = InstanceBuffer.make("power.voxel.trace", 16*16*16, cast(size_t)numMorton);

		ind: GfxIndirectData[1];
		ind[0].count = cast(GLuint)calcNumMorton(1 << mTraceUpperPower);
		ind[0].instanceCount = 1;
		ind[0].first = 0;
		ind[0].baseInstance = 0;

		mIndirect = GfxIndirectBuffer.make("power.voxel.indirect", ind);
	}

	fn draw(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		// The octtree texture buffer is used for all shaders.
		glBindTextureUnit(0, mOctTexture);

		// We first do a initial pruning of cubes. This is put into a
		// feedback buffer that is used as data to the raytracing step.
		setupStaticFeedback(ref camPosition, ref mat);

		// Setup the transform feedback state
		glEnable(GL_RASTERIZER_DISCARD);
		glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, mInstance.buf);
		glBeginQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN, mFeedbackQuery);
		glBeginTransformFeedback(GL_POINTS);

		glBindVertexArray(mVbo.vao);
		glDrawArrays(GL_POINTS, 0, mVbo.num);
		glBindVertexArray(0);

		glEndTransformFeedback();
		glEndQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN);
		glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, 0);
		glDisable(GL_RASTERIZER_DISCARD);


		// Retrive the number of entries written to the feedback buffer
		// write that into the instance number of the indirect buffer.
		glBindBuffer(GL_QUERY_BUFFER, mIndirect.buf);
		glGetQueryObjectuiv(mFeedbackQuery, GL_QUERY_RESULT, (cast(GLuint*)null) + 1);
		glBindBuffer(GL_QUERY_BUFFER, 0);


		// Draw the raytracing cubes, the shader will futher subdivide
		// the cubes into smaller cubes and then raytrace from them.
		setupStaticTrace(ref camPosition, ref mat);

		glCullFace(GL_FRONT);
		glEnable(GL_CULL_FACE);

		glBindVertexArray(mInstance.vao);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, mIndirect.buf);
		glDrawArraysIndirect(GL_POINTS, null);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, 0);
		glBindVertexArray(0);

		glDisable(GL_CULL_FACE);


		glBindTextureUnit(0, 0);
	}

	fn setupStaticFeedback(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		voxelsPerUnit := (1 << 3);
		position := math.Vector3f.opCall(camPosition);
		position.scale(cast(f32)voxelsPerUnit);
		position.floor();

		positionScale: math.Vector3f;
		positionScale.x = 1;
		positionScale.y = 1;
		positionScale.z = 1;

		positionOffset: math.Vector3f;
		getAlignedPosition(ref camPosition, out positionOffset,
		                   cast(f32)(1 << 3));

		mFeedback.bind();
		mFeedback.matrix4("matrix", 1, false, mat.ptr);
		mFeedback.float3("cameraPos".ptr, camPosition.ptr);
		mFeedback.float3("positionScale".ptr, positionScale.ptr);
		mFeedback.float3("positionOffset".ptr, positionOffset.ptr);
	}

	fn setupStaticTrace(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		mTracer.bind();
		mTracer.matrix4("matrix", 1, false, mat.ptr);
		mTracer.float3("cameraPos".ptr, camPosition.ptr);
	}


private:
	fn getAlignedPosition(ref camPosition: math.Point3f,
	                      out position: math.Vector3f,
	                      scaleFactor: f32)
	{
		position = math.Vector3f.opCall(camPosition);
		position.scale(scaleFactor);
		position.floor();

		vec := math.Vector3f.opCall(
			cast(f32)calcAlign(cast(i32)position.x, 0),
			cast(f32)calcAlign(cast(i32)position.y, 0),
			cast(f32)calcAlign(cast(i32)position.z, 0));
	}
}

class SimpleSVO
{
public:
	mVbo: DagBuffer;

	mShaders: GfxShader[4];
	mShaderNames: string[4];
	mShaderIndex: u32;
	mShader: GfxShader;
	mPatchSize: i32;
	mPatchMinSize: i32;
	mPatchMaxSize: i32;
	mPatchStartLevel: i32;
	mPatchStopLevel: i32;
	mVoxelPower: i32;
	mVoxelPerUnit: i32;

	mOctTexture: GLuint;


public:
	this(octTexture: GLuint)
	{
		mOctTexture = octTexture;
		mVoxelPower = 11;
		mVoxelPerUnit = (1 << mVoxelPower);
		mPatchSize = 16;
		mPatchMinSize = 4;
		mPatchMaxSize = 32;
		mPatchStartLevel = 1;
		mPatchStopLevel = 10;

		vert := cast(string)read("res/power/shaders/raytracer/voxel.vert.glsl");
		geom := cast(string)read("res/power/shaders/raytracer/voxel.geom.glsl");
		frag1 := cast(string)read("res/power/shaders/raytracer/voxel-amd.frag.glsl");
		frag2 := cast(string)read("res/power/shaders/raytracer/voxel-nvidia.frag.glsl");
		frag3 := cast(string)read("res/power/shaders/raytracer/voxel-org.frag.glsl");
		frag4 := cast(string)read("res/power/shaders/raytracer/voxel-notrace.frag.glsl");
		mShaders[0] = new GfxShader("voxel-amd", vert, geom, frag1, null, null);
		mShaders[1] = new GfxShader("voxel-nvidia", vert, geom, frag2, null, null);
		mShaders[2] = new GfxShader("voxel-org", vert, geom, frag3, null, null);
		mShaders[3] = new GfxShader("voxel-notrace", vert, geom, frag4, null, null);
		mShaderNames[0] = "AMD-OPTZ";
		mShaderNames[1] = "NV-OPTZ";
		mShaderNames[2] = "original";
		mShaderNames[3] = "no trace";
		mShader = mShaders[0];

		numMorton := calcNumMorton(mPatchMaxSize);
		b := new DagBuilder(cast(size_t)numMorton);
		foreach (i; 0 .. numMorton) {
			vals: u32[3];
			math.decode3(cast(u64)i, out vals);

			x := cast(i32)vals[0];
			y := cast(i32)vals[1];
			z := cast(i32)vals[2];

			x = x % 2 == 1 ? -x >> 1 : x >> 1;
			y = y % 2 == 1 ? -y >> 1 : y >> 1;
			z = z % 2 == 1 ? -z >> 1 : z >> 1;

			b.add(cast(i8)x, cast(i8)y, cast(i8)z, 1);
		}
		mVbo = DagBuffer.make("power/dag", b);
	}

	fn triggerPatchStart()
	{
		mPatchStartLevel++;
		if (mPatchStartLevel > mPatchStopLevel) {
			mPatchStartLevel = 1;
		}
	}

	fn triggerPatchSize()
	{
		mPatchSize *= 2;
		if (mPatchSize > mPatchMaxSize) {
			mPatchSize = mPatchMinSize;
		}
	}

	fn triggerShader()
	{
		mShaderIndex++;
		if (mShaderIndex >= mShaders.length) {
			mShaderIndex = 0;
		}
		mShader = mShaders[mShaderIndex];	
	}

	fn close()
	{
		mShader = null;
		foreach (ref s; mShaders) {
			s.breakApart();
			s = null;
		}
	}

	fn draw(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		// Setup shader.
		mShader.bind();
		setupStatic(ref camPosition, ref mat);

		// Draw the array.
		glCullFace(GL_FRONT);
		glEnable(GL_CULL_FACE);
		glBindTextureUnit(0, mOctTexture);

		glBindVertexArray(mVbo.vao);

		foreach (i; mPatchStartLevel .. mPatchStopLevel+1) {
			drawLevel(ref camPosition, i);
		}

		glBindVertexArray(0);

		glBindTextureUnit(0, 0);
		glDisable(GL_CULL_FACE);
	}

	fn setupStatic(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		voxelsPerUnit := cast(f32)(1 << mVoxelPower);
		voxelSize := 1.0f / voxelsPerUnit;
		voxelSizeInv := voxelsPerUnit;

		mShader.matrix4("matrix", 1, false, mat.ptr);
		mShader.float3("cameraPos".ptr, camPosition.ptr);
		mShader.float1("voxelSize".ptr, voxelSize);
		mShader.float1("voxelSizeInv".ptr, voxelSizeInv);
	}

	fn drawLevel(ref camPosition: math.Point3f, level: i32)
	{
		splitPower := mVoxelPower - level;
		splitPerUnit := cast(f32)(1 << splitPower);
		splitSize := 1.0f / splitPerUnit;
		splitSizeInv := splitPerUnit;

		mShader.int1("splitPower".ptr, splitPower);
		mShader.float1("splitSize".ptr, splitSize);
		mShader.float1("splitSizeInv".ptr, splitSizeInv);
		mShader.int1("tracePower".ptr, level);

		pos := math.Vector3f.opCall(camPosition);
		pos.scale(cast(f32)mVoxelPerUnit);
		pos.floor();

		vec := math.Vector3f.opCall(
			cast(f32)calcAlign(cast(i32)pos.x, level),
			cast(f32)calcAlign(cast(i32)pos.y, level),
			cast(f32)calcAlign(cast(i32)pos.z, level));
		mShader.float3("offset".ptr, 1, vec.ptr);

		if (level <= mPatchStartLevel) {
			vec = math.Vector3f.opCall(0.0f, 0.0f, 0.0f);
			mShader.float3("lowerMin".ptr, 1, vec.ptr);
			mShader.float3("lowerMax".ptr, 1, vec.ptr);
		} else {
			lowerLevel := level-1;
			vec.x = cast(f32)calcAlign(cast(i32)pos.x, lowerLevel);
			vec.y = cast(f32)calcAlign(cast(i32)pos.y, lowerLevel);
			vec.z = cast(f32)calcAlign(cast(i32)pos.z, lowerLevel);
			vec -= cast(f32)((mPatchSize / 2) * (1 << lowerLevel));
			mShader.float3("lowerMin".ptr, 1, vec.ptr);
			vec += cast(f32)(mPatchSize * (1 << lowerLevel));
			mShader.float3("lowerMax".ptr, 1, vec.ptr);
		}
		vec.x = 1; vec.y = 1; vec.z = 1;
		vec.scale(cast(f32)(1 << level));
		mShader.float3("scale".ptr, 1, vec.ptr);

		glDrawArrays(GL_POINTS, 0, calcNumMorton(mPatchSize));
	}
}
