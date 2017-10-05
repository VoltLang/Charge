// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for Shader Compiler code.
 */
module charge.gfx.compiler;

import io = watt.io;

import watt.text.string;
import watt.text.format;

import core = charge.core;
import math = charge.math;

import lib.gl;

import charge.gfx.shader;


struct Src
{
public:
	src: string;
	filename: string;


public:
	fn addInternalStart(filename: string)
	{
		this.filename = .addInternalStart(filename);
	}

	fn setup(src: string, filename: string, add: bool = false)
	{
		this.src = src;
		if (add) {
			addInternalStart(filename);
		} else {
			this.filename = filename;
		}
	}
}

struct VertSrc
{
public:
	src: Src;


public:
	fn setup(src: string, filename: string, add: bool = false)
	{
		this.src.setup(src, filename, add);
	}
}

struct GeomSrc
{
public:
	src: Src;


public:
	fn setup(src: string, filename: string, add: bool = false)
	{
		this.src.setup(src, filename, add);
	}
}

struct FragSrc
{
public:
	src: Src;


public:
	fn setup(src: string, filename: string, add: bool = false)
	{
		this.src.setup(src, filename, add);
	}
}

struct CompSrc
{
public:
	src: Src;


public:
	fn setup(src: string, filename: string, add: bool = false)
	{
		this.src.setup(src, filename, add);
	}
}


class Compiler
{
public:
	fn compile(ref comp: CompSrc, name: string) Shader
	{
		id := makeShader(this, ref comp, name);
		return new Shader(name, id);
	}

	fn compile(ref vert: VertSrc, ref frag: FragSrc, name: string) Shader
	{
		id := makeShader(this, ref vert, ref frag, name);
		return new Shader(name, id);
	}
}

private:


class IncludeFile
{
public:
	lookupName: string;
	fullName: string;
	src: string;


public:
	this(lookupName: string, fullName: string, src: string)
	{
		this.lookupName = lookupName;
		this.fullName = fullName;
		this.src = src;
	}
}

fn makeShader(c: Compiler, ref comp: CompSrc, name: string) GLuint
{
	// Create the program shader.
	programShader := glCreateProgram();

	// Compile the shader.
	attachAndCompileShader(c, ref comp, name, programShader);

	// Linking the Shader Program.
	glLinkProgram(programShader);

	// Check status and print any debug message.
	if (!printDebug(name, programShader)) {
		glDeleteProgram(programShader);
		return 0;
	}

	return programShader;
}

fn makeShader(c: Compiler, ref vert: VertSrc, ref frag: FragSrc, name: string) GLuint
{
	// Create the program shader.
	programShader := glCreateProgram();

	// Compile the shader.
	attachAndCompileShader(c, ref vert, name, programShader);
	attachAndCompileShader(c, ref frag, name, programShader);

	// Linking the Shader Program.
	glLinkProgram(programShader);

	// Check status and print any debug message.
	if (!printDebug(name, programShader)) {
		glDeleteProgram(programShader);
		return 0;
	}

	return programShader;
}

fn attachAndCompileShader(c: Compiler, ref comp: CompSrc, name: string,
                          programShader: GLuint)
{
	// Create and attach the shader to a program handel.
	compShader := glCreateShader(GL_COMPUTE_SHADER);
	glAttachShader(programShader, compShader);

	// Do the compile.
	compileShaderLog(c, ref comp.src, name, compShader);
}

fn attachAndCompileShader(c: Compiler, ref vert: VertSrc, name: string,
                          programShader: GLuint)
{
	// Create and attach the shader to a program handel.
	vertShader := glCreateShader(GL_VERTEX_SHADER);
	glAttachShader(programShader, vertShader);

	// Do the compile.
	compileShaderLog(c, ref vert.src, name, vertShader);
}

fn attachAndCompileShader(c: Compiler, ref frag: FragSrc, name: string,
                          programShader: GLuint)
{
	// Create and attach the shader to a program handel.
	fragShader := glCreateShader(GL_FRAGMENT_SHADER);
	glAttachShader(programShader, fragShader);

	// Do the compile.
	compileShaderLog(c, ref frag.src, name, fragShader);
}

fn compileShaderLog(c: Compiler, ref src: Src, name: string, shader: GLuint)
{
	assert(src.src.length > 0);

	// Load and compile the Compute Shader.
	compileShader(shader, src.src);

	// Print debug info.
	printDebug(name, shader, ref src);

	// The shader object is not needed any more,
	// the programShader is the complete shader to be used.
	glDeleteShader(shader);
}

fn replaceErrors(log: string, filename: string) string
{
	log = replace(log, "ERROR: 0", filename);
	log = replace(log, ": error(#", " error: (#");
	return log;
}

fn addInternalStart(filename: string) string
{
	file := __FILE__;
	version (Windows) {
		end := "src\\charge\\gfx\\compiler.volt";
	} else {
		end := "src/charge/gfx/compiler.volt";
	}

	return replace(file, end, filename);
}

fn printDebug(name: string, shader: GLuint, ref src: Src) bool
{
	// Get the status of the compile.
	status := getStatus(shader, false);

	infoLog := getInfoLog(shader, false);

	infoLog = replaceErrors(infoLog, src.filename);

	if (status) {
		return true;
	} else {
		// Only print an error if we got a message.
		if (infoLog.length != 0) {
			io.error.writef("shader \"%s\" status error!\n%s", name, infoLog);
			io.error.flush();
		}

		return false;
	}
}

fn printDebug(name: string, programShader: GLuint) bool
{
	// Get the status of the compile.
	status := getStatus(programShader, true);

	infoLog := getInfoLog(programShader, true);

	if (status) {
		if (infoLog.length != 0) {
			io.error.writef("shader \"%s\" status ok!\n%s", name, infoLog);
			io.error.flush();
		} else if (core.get().verbosePrinting) {
			io.error.writefln("shader \"%s\" status ok!", name);
			io.error.flush();
		}

		return true;
	} else {
		if (infoLog.length != 0) {
			io.error.writef("shader \"%s\" status error!\n%s", name, infoLog);
			io.error.flush();
		} else if (true) {
			io.error.writefln("shader \"%s\" status error!", name);
			io.error.flush();
		}

		return false;
	}
}
