// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/*!
 * Source file for Target(s), that is FBO's and DefaultTarget.
 */
module charge.gfx.target;

import charge.sys.file;
import charge.sys.resource;
import charge.gfx.gl;
import charge.gfx.texture;
import charge.math.matrix;

import watt.io;

/*!
 * Base texture class.
 */
abstract class Target : Resource
{
public:
	enum string uri = "target://";

	fbo: GLuint;

	width: uint;
	height: uint;


public:
	~this()
	{
		if (fbo != 0) {
			glDeleteFramebuffers(1, &fbo);
			fbo = 0;
		}
	}

	final fn bind(old: Target)
	{
		glBindFramebuffer(GL_FRAMEBUFFER, fbo);
		glViewport(0, 0, cast(int)width, cast(int)height);
	}

	final fn bindAndCopyFrom(src: Target)
	{
		glBindFramebuffer(GL_READ_FRAMEBUFFER, src.fbo);
		glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fbo);

		glDrawBuffer(GL_BACK);
		glBlitFramebuffer(
			0, 0, cast(GLint)src.width, cast(GLint)src.height,
			0, 0, cast(GLint)width, cast(GLint)height,
			GL_COLOR_BUFFER_BIT, GL_LINEAR);

		glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo);
		glViewport(0, 0, cast(int)width, cast(int)height);
	}

	abstract fn setMatrixToOrtho(ref mat: Matrix4x4d);
	abstract fn setMatrixToOrtho(ref mat: Matrix4x4d, width: f32, height: f32);
	abstract fn setMatrixToProjection(ref mat: Matrix4x4d, fov: f32, near: f32, far: f32);


protected:
	this(GLuint fbo, uint width, uint height)
	{
		this.fbo = fbo;
		this.width = width;
		this.height = height;

		super();
	}
}

final class DefaultTarget : Target
{
private:
	global mInstance: DefaultTarget;


public:
	final fn bindDefault()
	{
		glBindFramebuffer(GL_FRAMEBUFFER, fbo);
		glViewport(0, 0, cast(int)width, cast(int)height);
	}

	override final fn setMatrixToOrtho(ref mat: Matrix4x4d)
	{
		setMatrixToOrtho(ref mat, cast(f32)width, cast(f32)height);
	}

	override final fn setMatrixToOrtho(ref mat: Matrix4x4d, width: f32, height: f32)
	{
		mat.setToOrtho(0.0f, width, height, 0.0f, -1.0f, 1.0f);
	}

	override final fn setMatrixToProjection(ref mat: Matrix4x4d, fov: f32, near: f32, far: f32)
	{
		mat.setToPerspective(fov, cast(f32)width / cast(f32)height, near, far);
	}

	global fn opCall() DefaultTarget
	{
		if (mInstance !is null) {
			return mInstance;
		}

		filename := "%default";

		dummy: void*;
		t := cast(DefaultTarget)Resource.alloc(typeid(DefaultTarget),
		                                           uri, filename,
		                                           0, out dummy);
		t.__ctor(0, 0);
		mInstance = t;

		return t;
	}

	global fn close()
	{
		if (mInstance !is null) {
			mInstance.decRef();
			mInstance = null;
		}
	}


private:
	this(uint width, uint height)
	{
		super(0, width, height);
	}
}

class Framebuffer : Target
{
public:
	color: Texture;
	depth: Texture;


public:
	~this()
	{
		if (color !is null) { color.decRef(); color = null; }
		if (depth !is null) { depth.decRef(); depth = null; }
	}

	override final fn setMatrixToOrtho(ref mat: Matrix4x4d)
	{
		setMatrixToOrtho(ref mat, cast(f32)width, cast(f32)height);
	}

	override final fn setMatrixToOrtho(ref mat: Matrix4x4d, width: f32, height: f32)
	{
		mat.setToOrtho(0.0f, width, 0.0f, height, -1.0f, 1.0f);
	}

	override final fn setMatrixToProjection(ref mat: Matrix4x4d, fov: f32, near: f32, far: f32)
	{
		mat.setToPerspective(fov, cast(f32)width / cast(f32)height, near, far);
	}

	global fn make(name: string, width: uint, height: uint) Framebuffer
	{
		levels: uint = 1;

		color := Texture2D.makeRGBA8(name, width, height, 1);
		depth := Texture2D.makeDepth24(name, width, height, 1);

		fbo: GLuint;
		glGenFramebuffers(1, &fbo);
		glBindFramebuffer(GL_FRAMEBUFFER, fbo);
		glFramebufferTexture2D(
			GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
			GL_TEXTURE_2D, color.id, 0);
		glFramebufferTexture2D(
			GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
			GL_TEXTURE_2D, depth.id, 0);

		glCheckFramebufferError();
		glBindFramebuffer(GL_FRAMEBUFFER, 0);

		dummy: void*;
		t := cast(Framebuffer)Resource.alloc(typeid(Framebuffer),
		                                     uri, name,
		                                     0, out dummy);
		t.__ctor(fbo, color, depth, width, height);

		return t;
	}


protected:
	this(GLuint fbo, Texture color, Texture depth, uint width, uint height)
	{
		this.color = color;
		this.depth = depth;
		super(fbo, width, height);
	}
}
