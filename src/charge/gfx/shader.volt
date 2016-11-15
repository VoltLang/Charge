// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Shader base class.
 */
module charge.gfx.shader;

import watt.io;
import lib.gl;


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

	this(name: string, vert: string, geom: string, frag: string, attr: string[], tex: string[])
	{
		this.name = name;
		this.id = makeShaderVGF(name, vert, geom, frag, attr, tex);
	}

	this(name: string, id: GLuint)
	{
		this.name = name;
		this.id = id;
	}

	~this()
	{
		if (id != 0) {
			glDeleteProgram(id);
		}
		id = 0;
	}

final:
	fn breakApart()
	{
		if (id != 0) {
			glDeleteProgram(id);
		}
		id = 0;
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

	fn matrix4(name: const(char)*, count: int, transpose: bool, value: f32*)
	{
		loc := glGetUniformLocation(id, name);
		glUniformMatrix4fv(loc, count, transpose, value);
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
	if (!printDebug(name, shader, true, "program (vert/frag)")) {
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

fn makeShaderVGF(name: string, vert: string, geom: string, frag: string, attr: string[], texs: string[]) GLuint
{
	// Compile the shaders
	shader := createAndCompileShaderVGF(name, vert, geom, frag);

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
	if (!printDebug(name, shader, true, "program (vert/geom/frag)")) {
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

fn createAndCompileShaderVF(name: string, vert: string, frag: string) GLuint
{
	// Create the handels
	vertShader := glCreateShader(GL_VERTEX_SHADER);
	fragShader := glCreateShader(GL_FRAGMENT_SHADER);
	programShader := glCreateProgram();

	// Attach the shaders to a program handel.
	glAttachShader(programShader, vertShader);
	glAttachShader(programShader, fragShader);

	// Load and compile the Vertex Shader
	compileShader(name, vertShader, vert, "vert");

	// Load and compile the Fragment Shader
	compileShader(name, fragShader, frag, "frag");

	// The shader objects are not needed any more,
	// the programShader is the complete shader to be used.
	glDeleteShader(vertShader);
	glDeleteShader(fragShader);

	return programShader;
}

fn createAndCompileShaderVGF(name: string, vert: string, geom: string, frag: string) GLuint
{
	// Create the handels
	vertShader := glCreateShader(GL_VERTEX_SHADER);
	geomShader := glCreateShader(GL_GEOMETRY_SHADER);
	fragShader := glCreateShader(GL_FRAGMENT_SHADER);
	programShader := glCreateProgram();

	// Attach the shaders to a program handel.
	glAttachShader(programShader, vertShader);
	glAttachShader(programShader, geomShader);
	glAttachShader(programShader, fragShader);

	// Load and compile the Vertex Shader
	compileShader(name, vertShader, vert, "vert");

	// Load and compile the Fragment Shader
	compileShader(name, geomShader, geom, "geom");

	// Load and compile the Fragment Shader
	compileShader(name, fragShader, frag, "frag");

	// The shader objects are not needed any more,
	// the programShader is the complete shader to be used.
	glDeleteShader(vertShader);
	glDeleteShader(geomShader);
	glDeleteShader(fragShader);

	return programShader;
}

fn compileShader(name: string, shader: GLuint, source: string, type: string)
{
	ptr: const(char)*;
	length: int;

	ptr = source.ptr;
	length = cast(int)source.length - 1;
	glShaderSource(shader, 1, &ptr, &length);
	glCompileShader(shader);

	// Print any debug message
	printDebug(name, shader, false, type);
}

fn printDebug(name: string, shader: GLuint, program: bool, type: string) bool
{
	// Instead of pointers, realy bothersome.
	status: GLint;
	length: GLint;

	// Get information about the log on this object.
	if (program) {
		glGetProgramiv(shader, GL_LINK_STATUS, &status);
		glGetProgramiv(shader, GL_INFO_LOG_LENGTH, &length);
	} else {
		glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
	}

	buffer: char[];
	if (length > 2) {
		// Yes length+1 and just length.
		buffer = new char[](length + 1);
		buffer.ptr[length] = 0;

		if (program) {
			glGetProgramInfoLog(shader, length, &length, buffer.ptr);
		} else {
			glGetShaderInfoLog(shader, length, &length, buffer.ptr);
		}
	} else {
		length = 0;
	}

	switch (status) {
	case 1: //GL_TRUE:
		// Only print warnings from the linking stage.
		if (length != 0 && program) {
			writef("%s \"%s\" status ok!\n%s", type, name, buffer);
		} else if (program) {
			writefln("%s \"%s\" status ok!", type, name);
		}

		return true;

	case 0: //GL_FALSE:
		if (length != 0) {
			writef("%s \"%s\" status ok!\n%s", type, name, buffer);
		} else if (program) {
			writefln("%s \"%s\" status ok!", type, name);
		}

		return false;

	default:
		if (length != 0) {
			writef("%s \"%s\" status %s\n%s", type, name, status, buffer);
		} else if (program) {
			writefln("%s \"%s\" status %s", type, name, status);
		}

		return false;
	}
}
