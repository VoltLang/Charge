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
 * Information about a single view to be rendered,
 * passed alongside a @ref Target.
 *
 * @ingroup gfx
 */
struct ViewInfo
{
public:
	//! A fov to be used on the given target.
	fov: math.Fovf;

	//! Used in XR mode, gives the position of the view.
	position: math.Point3f;

	//! Used in XR mode, gives the rotation of the view.
	rotation: math.Quatf;

	//! Should the fov be used or can it be filled in.
	validFov: bool;

	//! Are @ref position and @rotation valid and should be used.
	validLocation: bool;

	/*!
	 * Is this view suitable for orthogonal rendering, that is it displayed
	 * on monitor like thing or is it a XR view.
	 */
	suitableForOrtho: bool;


public:
	fn ensureValidFov(fovy: f64, t: Target)
	{
		if (validFov) {
			return;
		}

		aspect := cast(f64)t.width / cast(f64)t.height;
		fov.setToFovyAspect(fovy, aspect);
		validFov = true;
	}
}

/*!
 * Base target class, allows you to bind and unbind targets.
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
		// Bind this target and unbind src.
		bind(src);

		// We are now bound as both buffers, read from src.
		glBindFramebuffer(GL_READ_FRAMEBUFFER, src.fbo);

		glDrawBuffer(GL_BACK);
		glBlitFramebuffer(
			0, 0, cast(GLint)src.width, cast(GLint)src.height,
			0, 0, cast(GLint)width, cast(GLint)height,
			GL_COLOR_BUFFER_BIT, mCopyFilter);

		// And make us bound in both buffers again.
		glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo);
	}

	final fn setMatrixToOrtho(ref mat: math.Matrix4x4d)
	{
		setMatrixToOrtho(ref mat, cast(f32)width, cast(f32)height);
	}

	final fn setMatrixToOrtho(ref mat: math.Matrix4x4d, width: f32, height: f32)
	{
		// Need to flip the ortho projection when rendering to the window.
		if (fbo == 0) {
			mat.setToOrtho(0.0f, width, height, 0.0f, -1.0f, 1.0f);
		} else {
			mat.setToOrtho(0.0f, width, 0.0f, height, -1.0f, 1.0f);
		}
	}


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

/*!
 * The default fbo in OpenGL, `glBindFramebuffer(GL_FRAMEBUFFER, 0)`.
 *
 * @ingroup gfx
 */
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
 *
 * @ingroup gfx
 */
class ExtTarget : Target
{
public:
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

/*!
 * A simple color + depth framebuffer.
 *
 * @ingroup gfx
 */
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
		t.__ctor(fbo, color, depth, width, height, GL_LINEAR);

		return t;
	}


protected:
	this(fbo: GLuint, color: Texture, depth: Texture,
	     width: uint, height: uint, filter: GLuint)
	{
		this.color = color;
		this.depth = depth;
		super(fbo, width, height, filter);
	}
}

/*!
 * A simple color + depth framebuffer, with MSAA textures.
 *
 * @ingroup gfx
 */
class FramebufferMSAA : Framebuffer
{
public:
	override fn bind(old: Target)
	{
		super.bind(old);
		glEnable(GL_MULTISAMPLE);
	}

	override fn unbind()
	{
		glDisable(GL_MULTISAMPLE);
	}

	global fn make(name: string, width: uint, height: uint, samples: uint) FramebufferMSAA
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
		t := cast(FramebufferMSAA)sys.Resource.alloc(typeid(FramebufferMSAA),
		                                             uri, name,
		                                             0, out dummy);
		t.__ctor(fbo, color, depth, width, height, GL_NEAREST);

		return t;
	}


protected:
	this(fbo: GLuint, color: Texture, depth: Texture,
	     width: uint, height: uint, filter: GLuint)
	{
		super(fbo, color, depth, width, height, filter);
	}
}
