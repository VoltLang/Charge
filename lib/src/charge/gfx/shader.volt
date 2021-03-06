// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for Shader base class.
 *
 * @ingroup gfx
 */
module charge.gfx.shader;

import gl45 = lib.gl.gl45;

import lib.gl.gl33;

import io = watt.io;
import core = charge.core;
import math = charge.math;


/*!
 * Closes and sets reference to null.
 *
 * @param Object to be destroyed.
 */
fn destroy(ref obj: Shader)
{
	if (obj !is null) { obj.close(); obj = null; }
}

class Shader
{
public:
	name: string;
	id: GLuint;


public:
	this(name: string, vert: string, frag: string, attr: string[], tex: string[])
	{
		this.name = name;
		this.id = makeShaderVF(name, vert, frag, attr, tex);
	}

	this(name: string, vert: string, geom: string, frag: string)
	{
		this.name = name;
		this.id = makeShaderVGF(name, vert, geom, frag);
	}

	this(name: string, comp: string)
	{
		this.name = name;
		this.id = makeShaderC(name, comp);
	}

	this(name: string, id: GLuint)
	{
		this.name = name;
		this.id = id;
	}

	~this()
	{
		close();
	}


final:
	fn close()
	{
		if (id != 0) { glDeleteProgram(id); id = 0; }
	}

	fn bind()
	{
		glUseProgram(id);
	}

	fn unbind()
	{
		glUseProgram(0);
	}

	/*
	 * float4
	 */

	fn float4(name: const(char)*, count: int, value: f32*)
	{
		loc := glGetUniformLocation(id, name);
		glUniform4fv(loc, count, value);
	}

	fn float4(name: const(char)*, value: f32*)
	{
		float4(name, 1, value);
	}

	/*
	 * float3
	 */

	fn float3(name: const(char)*, count: int, value: f32*)
	{
		loc := glGetUniformLocation(id, name);
		glUniform3fv(loc, count, value);
	}

	fn float3(name: const(char)*, value: f32*)
	{
		float3(name, 1, value);
	}

	/*
	 * float2
	 */

	fn float2(name: const(char)*, count: int, value: f32*)
	{
		loc := glGetUniformLocation(id, name);
		glUniform2fv(loc, count, value);
	}

	fn float2(name: const(char)*, value: f32*)
	{
		float2(name, 1, value);
	}

	/*
	 * float1
	 */

	fn float1(name: const(char)*, count: int, value: f32*)
	{
		loc := glGetUniformLocation(id, name);
		glUniform1fv(loc, count, value);
	}

	fn float1(name: const(char)*, value: f32)
	{
		loc := glGetUniformLocation(id, name);
		glUniform1f(loc, value);
	}

	/*
	 * int4
	 */

	fn int4(name: const(char)*, value: i32*)
	{
		loc := glGetUniformLocation(id, name);
		glUniform4iv(loc, 1, value);
	}

	/*
	 * int3
	 */

	fn int3(name: const(char)*, value: i32*)
	{
		loc := glGetUniformLocation(id, name);
		glUniform3iv(loc, 1, value);
	}

	/*
	 * int2
	 */

	fn int2(name: const(char)*, value: i32*)
	{
		loc := glGetUniformLocation(id, name);
		glUniform2iv(loc, 1, value);
	}

	/*
	 * int1
	 */

	fn int1(name: const(char)*, value: i32)
	{
		loc := glGetUniformLocation(id, name);
		glUniform1i(loc, value);
	}

	/*
	 * Matrix
	 */

	fn matrix3(name: const(char)*, count: int, transpose: bool, ref mat: math.Matrix3x3f)
	{
		loc := glGetUniformLocation(id, name);
		glUniformMatrix3fv(loc, count, transpose, mat.ptr);
	}

	fn matrix4(name: const(char)*, count: int, transpose: bool, ref mat: math.Matrix4x4f)
	{
		loc := glGetUniformLocation(id, name);
		glUniformMatrix4fv(loc, count, transpose, mat.ptr);
	}

	/*
	 * Sampler
	 */

	fn sampler(name: const(char)*, value: i32)
	{
		loc := glGetUniformLocation(id, name);
		glUniform1i(loc, value);
	}
}

fn makeShaderC(name: string, comp: string) GLuint
{
	// Compile the shader.
	shader := createAndCompileShaderC(name, comp);

	// Linking the Shader Program.
	glLinkProgram(shader);

	// Check status and print any debug message.
	if (!printDebug(name, shader, true, "(comp)")) {
		glDeleteProgram(shader);
		return 0;
	}

	return shader;
}

fn makeShaderVF(name: string, vert: string, frag: string, attr: string[], texs: string[]) GLuint
{
	// Compile the shaders
	shader := createAndCompileShaderVF(name, vert, frag);

	// Setup vertex attributes, needs to done before linking.
	foreach (i, att; attr) {
		if (att is null) {
			continue;
		}
		glBindAttribLocation(shader, cast(uint)i, att.ptr);
	}

	// Linking the Shader Program
	glLinkProgram(shader);

	// Check status and print any debug message.
	if (!printDebug(name, shader, true, "(vert/frag)")) {
		glDeleteProgram(shader);
		return 0;
	}

	// Setup the texture units.
	glUseProgram(shader);
	foreach (i, tex; texs) {
		if (tex is null)
			continue;

		loc := glGetUniformLocation(shader, tex.ptr);
		glUniform1i(loc, cast(int)i);
	}
	glUseProgram(0);

	return shader;
}

fn makeShaderVGF(name: string, vert: string, geom: string, frag: string) GLuint
{
	// Compile the shaders
	shader := createAndCompileShaderVGF(name, vert, geom, frag);

	// Linking the Shader Program
	glLinkProgram(shader);

	// Check status and print any debug message.
	if (!printDebug(name, shader, true, "(vert/geom/frag)")) {
		glDeleteProgram(shader);
		return 0;
	}

	return shader;
}

fn createAndCompileShaderC(name: string, comp: string) GLuint
{
	assert(comp.length > 0);

	// Create the handels
	compShader := glCreateShader(gl45.GL_COMPUTE_SHADER);
	programShader := glCreateProgram();

	// Attach the shader to a program handel.
	glAttachShader(programShader, compShader);

	// Load and compile the Compute Shader
	compileShaderLog(name, compShader, comp, "comp");

	// The shader object is not needed any more,
	// the programShader is the complete shader to be used.
	glDeleteShader(compShader);

	return programShader;
}

fn createAndCompileShaderVF(name: string, vert: string, frag: string) GLuint
{
	assert(vert.length > 0 && frag.length > 0);

	// Create the handels
	vertShader := glCreateShader(GL_VERTEX_SHADER);
	fragShader := glCreateShader(GL_FRAGMENT_SHADER);
	programShader := glCreateProgram();

	// Attach the shaders to a program handel.
	glAttachShader(programShader, vertShader);
	glAttachShader(programShader, fragShader);

	// Load and compile the Vertex Shader
	compileShaderLog(name, vertShader, vert, "vert");

	// Load and compile the Fragment Shader
	compileShaderLog(name, fragShader, frag, "frag");

	// The shader objects are not needed any more,
	// the programShader is the complete shader to be used.
	glDeleteShader(vertShader);
	glDeleteShader(fragShader);

	return programShader;
}

fn createAndCompileShaderVGF(name: string, vert: string, geom: string, frag: string) GLuint
{
	// Create the handel
	programShader := glCreateProgram();

	// Load and compile the Vertex Shader
	if (vert.length > 0) {
		vertShader := glCreateShader(GL_VERTEX_SHADER);
		glAttachShader(programShader, vertShader);

		compileShaderLog(name, vertShader, vert, "vert");

		// The shader objects are not needed any more.
		glDeleteShader(vertShader);
	}

	// Load and compile the Fragment Shader
	if (geom.length > 0) {
		geomShader := glCreateShader(GL_GEOMETRY_SHADER);
		glAttachShader(programShader, geomShader);

		compileShaderLog(name, geomShader, geom, "geom");

		// The shader objects are not needed any more.
		glDeleteShader(geomShader);
	}

	// Load and compile the Fragment Shader
	if (frag.length > 0) {
		fragShader := glCreateShader(GL_FRAGMENT_SHADER);
		glAttachShader(programShader, fragShader);

		compileShaderLog(name, fragShader, frag, "frag");

		// The shader objects are not needed any more.
		glDeleteShader(fragShader);
	}

	// The programShader is the complete shader to be used.
	return programShader;
}

fn compileShader(shader: GLuint, source: string)
{
	ptr: const(char)*;
	length: int;

	ptr = source.ptr;
	length = cast(int)source.length - 1;
	glShaderSource(shader, 1, &ptr, &length);
	glCompileShader(shader);
}

fn compileShaderLog(name: string, shader: GLuint, source: string, type: string)
{
	// Compile.
	compileShader(shader, source);

	// Print any debug message
	printDebug(name, shader, false, type);
}

fn getInfoLog(shader: GLuint, program: bool) string
{
	// Instead of pointers, realy bothersome.
	length: GLint;

	// Get the length.
	if (program) {
		glGetProgramiv(shader, GL_INFO_LOG_LENGTH, &length);
	} else {
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
	}

	buffer: char[];
	if (length > 2) {
		// Add a trailing zero just in case.
		buffer = new char[](length + 1);
		buffer.ptr[length] = 0;

		if (program) {
			glGetProgramInfoLog(shader, length, &length, buffer.ptr);
		} else {
			glGetShaderInfoLog(shader, length, &length, buffer.ptr);
		}

		// Skip the trailing zero.
		buffer = buffer[0 .. length];
	}

	return cast(string)buffer;
}

fn getStatus(shader: GLuint, program: bool) bool
{
	// Instead of pointers, realy bothersome.
	status: GLint;

	// Get information about the log on this object.
	if (program) {
		glGetProgramiv(shader, GL_LINK_STATUS, &status);
	} else {
		glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
	}

	switch (status) {
	case GL_TRUE:
		return true;
	case GL_FALSE:
		return false;
	default:
		return false;
	}
}

fn printDebug(name: string, shader: GLuint, program: bool, type: string) bool
{
	// Get the status of the shader.
	status := getStatus(shader, program);

	// Get the info log, automatically returns null if just "ok".
	infoLog := getInfoLog(shader, program);

	if (status) {
		if (infoLog.length != 0 && program) {
			io.error.writef("shader \"%s\" %s status ok!\n%s", name, type, infoLog);
			io.error.flush();
		} else if (program && core.get().verbosePrinting) {
			io.error.writefln("shader \"%s\" %s status ok!", name, type);
			io.error.flush();
		}

		return true;
	} else {
		if (infoLog.length != 0) {
			io.error.writef("shader \"%s\" %s status error!\n%s", name, type, infoLog);
			io.error.flush();
		} else if (program) {
			io.error.writefln("shader \"%s\" %s status error!", name, type);
			io.error.flush();
		}

		return false;
	}
}
