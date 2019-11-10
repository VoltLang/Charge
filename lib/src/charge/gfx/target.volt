// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for Target(s), that is FBOs and DefaultTarget.
 *
 * @ingroup gfx
 */
module charge.gfx.target;

import core.exception;

import lib.gl.gl33;

import sys = charge.sys;
import math = charge.math;

import charge.gfx.gl;
import charge.gfx.texture;


/*!
 * Dereference and reference helper function.
 *
 * @param dec Object to dereference passed by reference, set to `inc`.
 * @param inc Object to reference.
 * @ingroup gfx
 * @{
 */
fn reference(ref dec: Target, inc: Target)
{
	if (inc !is null) { inc.incRef(); }
	if (dec !is null) { dec.decRef(); }
	dec = inc;
}

fn reference(ref dec: DefaultTarget, inc: DefaultTarget)
{
	if (inc !is null) { inc.incRef(); }
	if (dec !is null) { dec.decRef(); }
	dec = inc;
}

fn reference(ref dec: ExtTarget, inc: ExtTarget)
{
	if (inc !is null) { inc.incRef(); }
	if (dec !is null) { dec.decRef(); }
	dec = inc;
}

fn reference(ref dec: Framebuffer, inc: Framebuffer)
{
	if (inc !is null) { inc.incRef(); }
	if (dec !is null) { dec.decRef(); }
	dec = inc;
}

fn reference(ref dec: FramebufferMSAA, inc: FramebufferMSAA)
{
	if (inc !is null) { inc.incRef(); }
	if (dec !is null) { dec.decRef(); }
	dec = inc;
}
//! @}

/*!
 * Base texture class.
 *
 * @ingroup gfx
 */
abstract class Target : sys.Resource
{
public:
	enum string uri = "target://";

	fbo: GLuint;

	width: uint;
	height: uint;


protected:
	mCopyFilter: GLuint;


public:
	~this()
	{
		if (fbo != 0) {
			glDeleteFramebuffers(1, &fbo);
			fbo = 0;
		}
	}

	fn bind(old: Target)
	{
		old.unbind();

		glBindFramebuffer(GL_FRAMEBUFFER, fbo);
		glViewport(0, 0, cast(int)width, cast(int)height);
	}

	fn unbind()
	{

	}

	fn bindAndCopyFrom(src: Target)
	{
		bind(src);

		glBindFramebuffer(GL_READ_FRAMEBUFFER, src.fbo);

		glDrawBuffer(GL_BACK);
		glBlitFramebuffer(
			0, 0, cast(GLint)src.width, cast(GLint)src.height,
			0, 0, cast(GLint)width, cast(GLint)height,
			GL_COLOR_BUFFER_BIT, mCopyFilter);

		glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo);
	}

	abstract fn setMatrixToOrtho(ref mat: math.Matrix4x4d);
	abstract fn setMatrixToOrtho(ref mat: math.Matrix4x4d, width: f32, height: f32);
	abstract fn setMatrixToProjection(ref mat: math.Matrix4x4d, fov: f32, near: f32, far: f32);


protected:
	this(fbo: GLuint, width: uint, height: uint, copyFilter: GLuint)
	{
		this.fbo = fbo;
		this.width = width;
		this.height = height;
		this.mCopyFilter = copyFilter;

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

	override final fn setMatrixToOrtho(ref mat: math.Matrix4x4d)
	{
		setMatrixToOrtho(ref mat, cast(f32)width, cast(f32)height);
	}

	override final fn setMatrixToOrtho(ref mat: math.Matrix4x4d, width: f32, height: f32)
	{
		mat.setToOrtho(0.0f, width, height, 0.0f, -1.0f, 1.0f);
	}

	override final fn setMatrixToProjection(ref mat: math.Matrix4x4d, fov: f32, near: f32, far: f32)
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
		t := cast(DefaultTarget)sys.Resource.alloc(typeid(DefaultTarget),
		                                           uri, filename, 0,
		                                           out dummy);
		t.__ctor(0, 0);
		mInstance = t;

		return t;
	}

	global fn close()
	{
		reference(ref mInstance, null);
	}


private:
	this(uint width, uint height)
	{
		super(0, width, height, GL_LINEAR);
	}
}

/*!
 * Target for a FBO made outside of charge, takes ownership of the fbo.
 */
class ExtTarget : Target
{
public:
	override final fn setMatrixToOrtho(ref mat: math.Matrix4x4d)
	{
		throw new Exception("setMatrixToOrtho is deprecated");
	}

	override final fn setMatrixToOrtho(ref mat: math.Matrix4x4d, width: f32, height: f32)
	{
		throw new Exception("setMatrixToOrtho is deprecated");
	}

	override final fn setMatrixToProjection(ref mat: math.Matrix4x4d, fov: f32, near: f32, far: f32)
	{
		throw new Exception("setMatrixToOrtho is deprecated");
	}

	global fn make(name: string, fbo: GLuint, width: uint, height: uint) ExtTarget
	{
		dummy: void*;
		t := cast(ExtTarget)sys.Resource.alloc(typeid(ExtTarget),
		                                         uri, name,
		                                         0, out dummy);
		t.__ctor(fbo, width, height);

		return t;
	}


protected:
	this(fdo: GLuint, width: u32, height: u32)
	{
		super(fdo, width, height, GL_LINEAR);
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
		charge.gfx.texture.reference(ref color, null);
		charge.gfx.texture.reference(ref depth, null);
	}

	override final fn setMatrixToOrtho(ref mat: math.Matrix4x4d)
	{
		setMatrixToOrtho(ref mat, cast(f32)width, cast(f32)height);
	}

	override final fn setMatrixToOrtho(ref mat: math.Matrix4x4d, width: f32, height: f32)
	{
		mat.setToOrtho(0.0f, width, 0.0f, height, -1.0f, 1.0f);
	}

	override final fn setMatrixToProjection(ref mat: math.Matrix4x4d, fov: f32, near: f32, far: f32)
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
		t := cast(Framebuffer)sys.Resource.alloc(typeid(Framebuffer),
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
		super(fbo, width, height, GL_LINEAR);
	}
}

class FramebufferMSAA : Target
{
public:
	color: Texture;
	depth: Texture;


public:
	~this()
	{
		charge.gfx.texture.reference(ref color, null);
		charge.gfx.texture.reference(ref depth, null);
	}

	override fn bind(old: Target)
	{
		super.bind(old);
		glEnable(GL_MULTISAMPLE);
	}

	override fn unbind()
	{
		glDisable(GL_MULTISAMPLE);
	}

	override final fn setMatrixToOrtho(ref mat: math.Matrix4x4d)
	{
		setMatrixToOrtho(ref mat, cast(f32)width, cast(f32)height);
	}

	override final fn setMatrixToOrtho(ref mat: math.Matrix4x4d, width: f32, height: f32)
	{
		mat.setToOrtho(0.0f, width, 0.0f, height, -1.0f, 1.0f);
	}

	override final fn setMatrixToProjection(ref mat: math.Matrix4x4d, fov: f32, near: f32, far: f32)
	{
		mat.setToPerspective(fov, cast(f32)width / cast(f32)height, near, far);
	}

	global fn make(name: string, width: uint, height: uint, samples: uint) Framebuffer
	{
		levels: uint = 1;

		color := Texture2D.makeRGBA8MSAA(name, width, height, samples);
		depth := Texture2D.makeDepth24MSAA(name, width, height, samples);

		fbo: GLuint;
		glGenFramebuffers(1, &fbo);
		glBindFramebuffer(GL_FRAMEBUFFER, fbo);
		glFramebufferTexture2D(
			GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
			color.target, color.id, 0);
		glFramebufferTexture2D(
			GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
			depth.target, depth.id, 0);

		glCheckFramebufferError();
		glBindFramebuffer(GL_FRAMEBUFFER, 0);

		dummy: void*;
		t := cast(Framebuffer)sys.Resource.alloc(typeid(Framebuffer),
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
		super(fbo, width, height, GL_NEAREST);
	}
}
