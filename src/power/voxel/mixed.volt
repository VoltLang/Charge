// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.voxel.mixed;

import watt.text.string;
import watt.text.format;
import watt.io.file;

import charge.gfx;
import charge.sys.resource;

import math = charge.math;

import power.util.counters;
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




class Mixed
{
public:
	counters: Counters;


protected:
	mTrace: GfxShader;

	/// The number of levels that we trace.
	mTracePower: i32;
	mTracePowerStr: string;

	mOctTexture: GLuint;
	mFeedbackQuery: GLuint;

	mVAO: GLuint;

	mIndexBuffer: GLuint;


public:
	this(octTexture: GLuint)
	{
		counters = new Counters("trace");

		mTracePower = 2;
		mTracePowerStr = format("#define TRACE_POWER %s", mTracePower);

		createIndexBuffer();

		glCreateVertexArrays(1, &mVAO);
		glVertexArrayElementBuffer(mVAO, mIndexBuffer);

		mOctTexture = octTexture;
		glGenQueries(1, &mFeedbackQuery);

		vert, geom, frag: string;

		vert = cast(string)read("res/power/shaders/mixed/trace.vert.glsl");
		frag = cast(string)read("res/power/shaders/mixed/trace.frag.glsl");
		mTrace = makeShaderVGF("mixed.trace", vert, null, frag);
	}

	void close()
	{
		if (counters !is null) {
			counters.close();
			counters = null;
		}
		if (mTrace !is null) {
			mTrace.breakApart();
			mTrace = null;
		}
	}

	fn draw(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		glCheckError();

		counters.start(0);
		glBindTextureUnit(0, mOctTexture);

		setupStaticTrace(ref camPosition, ref mat);
		glCullFace(GL_FRONT);
		glEnable(GL_CULL_FACE);

		glBindVertexArray(mVAO);
		glDrawElements(GL_TRIANGLE_STRIP, 14, GL_UNSIGNED_INT, null);
		glBindVertexArray(mVAO);

		glDisable(GL_CULL_FACE);
		glUseProgram(0);

		glBindTextureUnit(0, 0);
		counters.stop(0);

		glCheckError();
	}


private:
	fn createIndexBuffer()
	{
		/*
		 * bitRakes' tri-strip cube, modified to fit OpenGL.
		 *
		 * Its still a bit DXy so backsides of triangles are out.
		 *
		 * 6-------2-------3-------7
		 * |  E __/|\__ A  |  H __/|   
		 * | __/   |   \__ | __/   |   
		 * |/   D  |  B   \|/   I  |
		 * 4-------0-------1-------5
		 *         |  C __/|
		 *         | __/   |  Cube = 8 vertices
		 *         |/   J  |  =================
		 *         4-------5  Single Strip: 3 2 1 0 4 2 6 3 7 1 5 4 7 6
		 *         |\__ K  |  12 triangles:     A B C D E F G H I J K L
		 *         |   \__ |
		 *         |  L   \|         Left  D+E
		 *         6-------7        Right  H+I
		 *         |\__ G  |         Back  K+L
		 *         |   \__ |        Front  A+B
		 *         |  F   \|          Top  F+G
		 *         2-------3       Bottom  C+J
		 *
		 */

		data := [3, 2, 1, 0, 4, 2, 6, 3, 7, 1, 5, 4, 7, 6, 6, 3+8];
		ptr := cast(void*)data.ptr;
		length := cast(GLsizeiptr)(data.length * 4);

		glCreateBuffers(1, &mIndexBuffer);
		glNamedBufferData(mIndexBuffer, length, ptr, GL_STATIC_DRAW);
	}

	fn setupStaticTrace(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		mTrace.bind();
		mTrace.matrix4("matrix", 1, false, mat.ptr);
		mTrace.float3("cameraPos".ptr, camPosition.ptr);
	}

	fn makeShaderVGF(name: string, vert: string, geom: string, frag: string) GfxShader
	{
		vert = replaceShaderStrings(vert);
		geom = replaceShaderStrings(geom);
		frag = replaceShaderStrings(frag);
		return new GfxShader(name, vert, geom, frag);
	}

	fn replaceShaderStrings(shader: string) string
	{
		shader = replace(shader, "#define TRACE_POWER %%",   mTracePowerStr);
		return shader;
	}
}
