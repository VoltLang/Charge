// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/**
 * Source file for Target(s), that is FBO's and DefaultTarget.
 */
module charge.gfx.target;

import charge.sys.file;
import charge.sys.resource;
import charge.gfx.gl;
import charge.gfx.texture;
import charge.math.matrix;


/**
 * Base texture class.
 */
abstract class Target : Resource
{
public:
	enum string uri = "target://";

	GLuint fbo;
	GLuint target;

	uint width;
	uint height;


public:
	final void bind()
	{
		glBindFramebuffer(target, fbo);
		glViewport(0, 0, cast(int)width, cast(int)height);
	}

	final void unbind()
	{
		glBindFramebuffer(target, 0);
	}

	abstract void setMatrixToOrtho(ref Matrix4x4f mat);
	abstract void setMatrixToOrtho(ref Matrix4x4f mat, float width, float height);
	abstract void setMatrixToProjection(ref Matrix4x4f mat, f32 fov, f32 near, f32 far);


protected:
	this(GLuint fbo, uint width, uint height)
	{
		this.fbo = fbo;
		this.width = width;
		this.height = height;
		this.target = GL_FRAMEBUFFER;

		super();
	}

	~this()
	{
		if (fbo != 0) {
			glDeleteFramebuffers(1, &fbo);
			fbo = 0;
		}
	}
}

final class DefaultTarget : Target
{
private:
	global DefaultTarget mInstance;


public:
	override final void setMatrixToOrtho(ref Matrix4x4f mat)
	{
		setMatrixToOrtho(ref mat, cast(float)width, cast(float)height);
	}

	override final void setMatrixToOrtho(ref Matrix4x4f mat, float width, float height)
	{
		mat.setToOrtho(0.0f, width, height, 0.0f, -1.0f, 1.0f);
	}

	override final void setMatrixToProjection(ref Matrix4x4f mat, f32 fov, f32 near, f32 far)
	{
		mat.setToPerspective(fov, cast(f32)width / cast(f32)height, near, far);
	}

	global DefaultTarget opCall()
	{
		if (mInstance !is null) {
			return mInstance;
		}

		string filename = "%default";

		void* dummy;
		auto t = cast(DefaultTarget)Resource.alloc(typeid(DefaultTarget),
		                                           uri, filename,
		                                           0, out dummy);
		t.__ctor(0, 0);
		mInstance = t;

		return t;
	}

	global void close()
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
	Texture color;
	Texture depth;


public:
	override final void setMatrixToOrtho(ref Matrix4x4f mat)
	{
		setMatrixToOrtho(ref mat, cast(float)width, cast(float)height);
	}

	override final void setMatrixToOrtho(ref Matrix4x4f mat, float width, float height)
	{
		mat.setToOrtho(0.0f, width, 0.0f, height, -1.0f, 1.0f);
	}

	override final void setMatrixToProjection(ref Matrix4x4f mat, f32 fov, f32 near, f32 far)
	{
		mat.setToPerspective(fov, cast(f32)width / cast(f32)height, near, far);
	}

	global Framebuffer make(string name, uint width, uint height)
	{
		uint levels = 1;

		Texture color = Texture2D.make(
			name:name, width:width, height:height,
			levels:levels, depth:false);
		Texture depth = Texture2D.make(
			name:name, width:width, height:height,
			levels:levels, depth:true);

		GLuint fbo;
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

		void* dummy;
		auto t = cast(Framebuffer)Resource.alloc(typeid(Framebuffer),
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

	~this()
	{
		if (color !is null) { color.decRef(); color = null; }
		if (depth !is null) { depth.decRef(); depth = null; }
	}
}
