// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
module charge.gfx.gl;

static import watt.conv;
static import watt.io.std;

public import lib.gl;


fn glCheckError(file: const(char)[] = __FILE__, line: int = __LINE__) bool
{
	err := glGetError();
	if (!err) {
		return false;
	}

	code: string;
	switch (err) {
	case GL_INVALID_ENUM: code = "GL_INVALID_ENUM"; break;
	case GL_INVALID_OPERATION: code = "GL_INVALID_OPERATION"; break;
	case GL_INVALID_VALUE: code = "GL_INVALID_VALUE"; break;
	default: code = watt.conv.toString(err); break;
	}

	watt.io.std.writefln("%s:%s error: %s", file, line, code);
	return true;
}

fn glCheckFramebufferError(file: const(char)[] = __FILE__, line: int = __LINE__)
{
	status := glCheckFramebufferStatus(GL_FRAMEBUFFER);
	if (status == GL_FRAMEBUFFER_COMPLETE) {
		return;
	}

	code: string;
	switch (status) {
	case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
		code = "GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
		code = "GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER:
		code = "GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER:
		code = "GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER"; break;
	case GL_FRAMEBUFFER_UNSUPPORTED:
		code = "GL_FRAMEBUFFER_UNSUPPORTED"; break;
	case GL_FRAMEBUFFER_COMPLETE:
		code = "GL_FRAMEBUFFER_COMPLETE"; break;
	default:
		code = watt.conv.toString(status); break;
	}

	watt.io.std.writefln("%s:%s error: %s", file, line, code);
}

fn log2(x: u32) u32
{
	ans: u32 = 0;
	while (x = x >> 1) {
		ans++;
	}

	return ans;
}
