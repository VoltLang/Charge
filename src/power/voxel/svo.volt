// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.voxel.svo;

import watt.text.string;
import watt.text.format;
import watt.io.file;

import charge.gfx;
import charge.sys.resource;

import math = charge.math;

import power.voxel.dag;
import power.voxel.boxel;
import power.voxel.instance;


fn calcAlign(pos: i32, level: i32) i32
{
	shift := level + 1;
	size := 1 << level;
	return ((pos + size) >> shift) << shift;
}

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
	
fn calcNumMorton(dim: i32) i32
{
	return dim * dim * dim;
}


class SVO
{
public:
	timers: GfxTimer[4];


protected:
	mVbo: DagBuffer;
	mOccludeBuf: OccludeBuffer;
	mInstanceBuf: InstanceBuffer;
	mIndirectBuf: GfxIndirectBuffer;
	mTransformObj: GLuint;

	mFBOcclude: GLuint;
	mFBPrune: GLuint;

	mFeedback: GfxShader;
	mOcclude: GfxShader;
	mPrune: GfxShader;
	mTracer: GfxShader;

	/// Total number of levels in the SVO.
	mVoxelPower: i32;
	mVoxelPowerStr: string;

	/// Number of level that we do occlude tests on.
	mOccludePower: i32;
	mOccludePowerStr: string;

	/// The number of levels that we subdivide.
	mGeomPower: i32;
	mGeomPowerStr: string;

	/// The number of levels that we trace.
	mTracePower: i32;
	mTracePowerStr: string;

	mOctTexture: GLuint;
	mFeedbackQuery: GLuint;


public:
	this(octTexture: GLuint)
	{
		foreach (ref t; timers) {
			t.setup();
		}

		mVoxelPower = 11;
		mOccludePower = 5;
		mGeomPower = 3;
		mTracePower = 3;
		mVoxelPowerStr = format("#define VOXEL_POWER %s", mVoxelPower);
		mOccludePowerStr = format("#define OCCLUDE_POWER %s", mOccludePower);
		mGeomPowerStr = format("#define GEOM_POWER %s", mGeomPower);
		mTracePowerStr = format("#define TRACE_POWER %s", mTracePower);

		mOctTexture = octTexture;
		glGenQueries(1, &mFeedbackQuery);

		vert, geom, frag: string;

		vert = cast(string)read("res/power/shaders/svo/feedback.vert.glsl");
		geom = cast(string)read("res/power/shaders/svo/feedback.geom.glsl");
		mFeedback = makeShaderVGF("svo.feedback", vert, geom, null);

		vert = cast(string)read("res/power/shaders/svo/occlude.vert.glsl");
		geom = cast(string)read("res/power/shaders/svo/occlude.geom.glsl");
		frag = cast(string)read("res/power/shaders/svo/occlude.frag.glsl");
		mOcclude = makeShaderVGF("svo.occlude", vert, geom, frag);

		vert = cast(string)read("res/power/shaders/svo/prune.vert.glsl");
		geom = cast(string)read("res/power/shaders/svo/prune.geom.glsl");
		mPrune = makeShaderVGF("svo.prune", vert, geom, null);

		vert = cast(string)read("res/power/shaders/svo/tracer.vert.glsl");
		geom = cast(string)read("res/power/shaders/svo/tracer.geom.glsl");
		frag = cast(string)read("res/power/shaders/svo/tracer.frag.glsl");
		mTracer = makeShaderVGF("svo.tracer", vert, geom, frag);


		numMorton := calcNumMorton(1 << (mOccludePower + 1));
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

		ind: GfxIndirectData[1];
		ind[0].count = cast(GLuint)calcNumMorton(1 << mGeomPower);
		ind[0].instanceCount = 1;
		ind[0].first = 0;
		ind[0].baseInstance = 0;

		mIndirectBuf = GfxIndirectBuffer.make("svo.buffer.indirect", ind);

		mOccludeBuf = OccludeBuffer.make("svo.buffer.occlude", numMorton);
		mInstanceBuf = InstanceBuffer.make("svo.buffer.trace", numMorton);

		glCreateTransformFeedbacks(1, &mFBOcclude);
		glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, mFBOcclude);
		glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, mOccludeBuf.instanceBuffer);

		glCreateTransformFeedbacks(1, &mFBPrune);
		glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, mFBPrune);
		glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, mInstanceBuf.buf);

		glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, 0);
	}

	void close()
	{
		foreach (ref t; timers) {
			t.close();
		}
	}

	fn draw(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		glCheckError();

		// The octtree texture buffer is used for all shaders.
		glBindTextureUnit(0, mOctTexture);

		// We first do a initial pruning of cubes. This is put into a
		// feedback buffer that is used as data to the occlusion step.
		timers[0].start();
		setupStaticFeedback(ref camPosition, ref mat);

		// Setup the transform feedback state
		glEnable(GL_RASTERIZER_DISCARD);
		glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, mFBOcclude);
		glBeginTransformFeedback(GL_POINTS);

		glBindVertexArray(mVbo.vao);
		glDrawArrays(GL_POINTS, 0, mVbo.num);

		glEndTransformFeedback();
		glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, 0);
		glDisable(GL_RASTERIZER_DISCARD);
		timers[0].stop();


		//
		// Do occlusion testing, this generate a list of which aabb
		// that the feedback step generated are visible.
		timers[1].start();
		setupStaticOcclude(ref camPosition, ref mat);

		// Turn of depth and color write.
		glDepthMask(GL_FALSE);
		glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);

		visBuf := mOccludeBuf.visibilityBuffer;
		glClearNamedBufferData(visBuf, GL_RGBA8, GL_RGBA, GL_UNSIGNED_BYTE, null);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, visBuf);

		glBindVertexArray(mOccludeBuf.vaoPerVertex);
		glDrawTransformFeedback(GL_POINTS, mFBOcclude);

		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, 0);
		glDepthMask(GL_TRUE);
		glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
		timers[1].stop();


		//
		// Need to flush the caches between writing the occlusion data
		// and reading it back.
		glTextureBarrier();


		//
		// Use the occlusion testing to prune the list of aabb that are
		// visible, this is then used to generate the raytracing boxes.
		timers[2].start();
		setupStaticPrune(ref camPosition, ref mat);

		glEnable(GL_RASTERIZER_DISCARD);
		glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, mFBPrune);
		glBeginQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN, mFeedbackQuery);
		glBeginTransformFeedback(GL_POINTS);

		glBindVertexArray(mOccludeBuf.vaoPrune);
		glDrawTransformFeedback(GL_POINTS, mFBOcclude);

		glEndTransformFeedback();
		glEndQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN);
		glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, 0);
		glDisable(GL_RASTERIZER_DISCARD);
		timers[2].stop();


		//
		// Retrive the number of entries written to the pruned buffer
		// write that into the instance number of the indirect buffer.
		timers[3].start();
		glBindBuffer(GL_QUERY_BUFFER, mIndirectBuf.buf);
		glGetQueryObjectuiv(mFeedbackQuery, GL_QUERY_RESULT, (cast(GLuint*)null) + 1);
		glBindBuffer(GL_QUERY_BUFFER, 0);


		//
		// Draw the raytracing cubes, the shader will futher subdivide
		// the cubes into smaller cubes and then raytrace from them.
		setupStaticTrace(ref camPosition, ref mat);

		glCullFace(GL_FRONT);
		glEnable(GL_CULL_FACE);

		glBindVertexArray(mInstanceBuf.vao);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, mIndirectBuf.buf);
		glDrawArraysIndirect(GL_POINTS, null);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, 0);
		glBindVertexArray(0);

		glDisable(GL_CULL_FACE);
		timers[3].stop();


		// Unbind the octTexture.
		glBindTextureUnit(0, 0);
		glCheckError();
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
		                   cast(f32)(1 << mOccludePower));

		mFeedback.bind();
		mFeedback.matrix4("matrix", 1, false, mat.ptr);
		mFeedback.float3("cameraPos".ptr, camPosition.ptr);
		mFeedback.float3("positionScale".ptr, positionScale.ptr);
		mFeedback.float3("positionOffset".ptr, positionOffset.ptr);
	}

	fn setupStaticOcclude(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		mOcclude.bind();
		mOcclude.matrix4("matrix", 1, false, mat.ptr);
		mOcclude.float3("cameraPos".ptr, camPosition.ptr);
	}

	fn setupStaticPrune(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		mPrune.bind();
	}

	fn setupStaticTrace(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		mTracer.bind();
		mTracer.matrix4("matrix", 1, false, mat.ptr);
		mTracer.float3("cameraPos".ptr, camPosition.ptr);
	}


private:
	fn makeShaderVGF(name: string, vert: string, geom: string, frag: string) GfxShader
	{
		vert = replaceShaderStrings(vert);
		geom = replaceShaderStrings(geom);
		frag = replaceShaderStrings(frag);
		return new GfxShader(name, vert, geom, frag);
	}

	fn replaceShaderStrings(shader: string) string
	{
		shader = replace(shader, "#define VOXEL_POWER %%",   mVoxelPowerStr);
		shader = replace(shader, "#define OCCLUDE_POWER %%", mOccludePowerStr);
		shader = replace(shader, "#define GEOM_POWER %%",    mGeomPowerStr);
		shader = replace(shader, "#define TRACE_POWER %%",   mTracePowerStr);
		return shader;
	}
}