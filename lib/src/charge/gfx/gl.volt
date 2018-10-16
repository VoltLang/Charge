// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
module charge.gfx.gl;

import io = watt.io;

import watt.conv;
import watt.text.string;

import lib.gl.gl33;

import charge.gfx.gfx;


fn glCheckError(loc: string = __LOCATION__) GLuint
{
	err := glGetError();
	if (err == GL_NO_ERROR) {
		return err;
	}

	code: string;
	switch (err) {
	case GL_NO_ERROR: code = "GL_NO_ERROR"; break;
	case GL_INVALID_ENUM: code = "GL_INVALID_ENUM"; break;
	case GL_INVALID_VALUE: code = "GL_INVALID_VALUE"; break;
	case GL_INVALID_OPERATION: code = "GL_INVALID_OPERATION"; break;
	case GL_INVALID_FRAMEBUFFER_OPERATION: code = "GL_INVALID_FRAMEBUFFER_OPERATION"; break;
	case GL_OUT_OF_MEMORY: code = "GL_OUT_OF_MEMORY"; break;
	// Not in core
	//case GL_STACK_UNDERFLOW: code = "GL_STACK_UNDERFLOW"; break;
	//case GL_STACK_OVERFLOW: code = "GL_STACK_OVERFLOW"; break;
	default: code = new "${err}"; break;
	}

	io.error.write(new "${loc} error: ${code}\n");
	io.error.flush();
	return err;
}

fn glCheckFramebufferError(loc: string = __LOCATION__) GLuint
{
	status := glCheckFramebufferStatus(GL_FRAMEBUFFER);
	if (status == GL_FRAMEBUFFER_COMPLETE) {
		return status;
	}

	code: string;
	switch (status) {
	case GL_FRAMEBUFFER_UNDEFINED:
		code = "GL_FRAMEBUFFER_UNDEFINED"; break;
	case GL_FRAMEBUFFER_UNSUPPORTED:
		code = "GL_FRAMEBUFFER_UNSUPPORTED"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
		code = "GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
		code = "GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER:
		code = "GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER:
		code = "GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE:
		code = "GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS:
		code = "GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS"; break;
	case GL_FRAMEBUFFER_COMPLETE:
		code = "GL_FRAMEBUFFER_COMPLETE"; break;
	default:
		code = new "${status}"; break;
	}

	io.error.write(new "${loc} error: ${code}\n");
	io.error.flush();
	return status;
}

fn runDetection()
{
	gfxRendererInfo.isGL = true;
	gfxRendererInfo.glVendor = toString(cast(const(char)*)glGetString(GL_VENDOR));
	gfxRendererInfo.glVersion = toString(cast(const(char)*)glGetString(GL_VERSION));
	gfxRendererInfo.glRenderer = toString(cast(const(char)*)glGetString(GL_RENDERER));

	if (gfxRendererInfo.glVendor == "ATI Technologies Inc.") {
		gfxRendererInfo.isAMD = true;
		gfxRendererInfo.isConfidentInDetection = true;
		return;
	}

	if (gfxRendererInfo.glVendor == "NVIDIA Corporation") {
		gfxRendererInfo.isNVIDIA = true;
		gfxRendererInfo.isConfidentInDetection = true;
		return;
	}

	if (gfxRendererInfo.glVendor == "X.Org" ||
	    gfxRendererInfo.glVendor.startsWith("AMD")) {
		gfxRendererInfo.isAMD = true;
		gfxRendererInfo.isConfidentInDetection = true;
	}
}

fn printDetection()
{
	if (!gfxRendererInfo.isGL) {
		return;
	}

	io.output.write("Found a OpenGL renderer.\n");
	io.output.writef("\tVendor:   %s\n", gfxRendererInfo.glVendor);
	io.output.writef("\tVersion:  %s\n", gfxRendererInfo.glVersion);
	io.output.writef("\tRenderer: %s\n", gfxRendererInfo.glRenderer);
	io.output.write("That we ");

	if (gfxRendererInfo.isConfidentInDetection) {
		io.output.write("know that:\n");
	} else {
		io.output.write("think that:\n");
	}

	if (gfxRendererInfo.isAMD) {
		io.output.write("\tits a AMD device\n");
	}
	if (gfxRendererInfo.isNVIDIA) {
		io.output.write("\tits a NVIDIA device\n");
	}
	if (gfxRendererInfo.isINTEL) {
		io.output.write("\tits a INTEL device\n");
	}
	if (gfxRendererInfo.isMESA) {
		io.output.write("\tits the Mesa driver\n");
	}
	io.output.flush();
}
