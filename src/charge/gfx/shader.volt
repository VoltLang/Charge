// Copyright © 2011-2013, Jakob Bornecrantz.
// See copyright notice in src/charge/license.d (BOOST ver 1.0).
/**
 * Source file for Shader base class.
 */
module charge.gfx.shader;

import core.stdc.stdio;
import lib.gles;


class Shader
{
public:
	GLuint id;

public:
	this(string vertex, string shader, string[] attr, string[] tex)
	{
		this.id = makeShader(vertex, shader, attr, tex);
		return;
	}

	this(GLuint id)
	{
		this.id = id;
		return;
	}

	~this()
	{
		if (id != 0) {
			glDeleteProgram(id);
		}
		id = 0;
		return;
	}

final:
	void breakApart()
	{
		if (id != 0) {
			glDeleteProgram(id);
		}
		id = 0;
		return;
	}

	void bind()
	{
		glUseProgram(id);
		return;
	}

	void unbind()
	{
		glUseProgram(0);
		return;
	}

	/*
	 * float4
	 */

	void float4(const(char)* name, int count, float *value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform4fv(loc, count, value);
		return;
	}

	void float4(const(char)* name, float* value)
	{
		float4(name, 1, value);
		return;
	}

	/*
	 * float3
	 */

	void float3(const(char)* name, int count, float* value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform3fv(loc, count, value);
		return;
	}

	void float3(const(char)* name, float* value)
	{
		float3(name, 1, value);
		return;
	}

	/*
	 * float2
	 */

	void float2(const(char)* name, int count, float* value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform2fv(loc, count, value);
		return;
	}

	void float2(const(char)* name, float* value)
	{
		float2(name, 1, value);
		return;
	}

	/*
	 * float1
	 */

	void float1(const(char)* name, int count, float* value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform1fv(loc, count, value);
		return;
	}


	void float1(const(char)* name, float value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform1f(loc, value);
		return;
	}

	/*
	 * Matrix
	 */

	void matrix4(const(char)* name, int count, bool transpose, float* value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniformMatrix4fv(loc, count, transpose, value);
		return;
	}

	/*
	 * Sampler
	 */

	void sampler(const(char)* name, int value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform1i(loc, value);
		return;
	}
}

GLuint makeShader(string vert, string frag, string[] attr, string[] texs)
{
	// Compile the shaders
	GLuint shader = createAndCompileShader(vert, frag);

	// Setup vertex attributes, needs to done before linking.
	for (size_t i; i < attr.length; i++) {
		if (attr[i] is null)
			continue;

		glBindAttribLocation(shader, cast(uint)i, attr[i].ptr);
	}

	// Linking the Shader Program
	glLinkProgram(shader);

	// Check status and print any debug message.
	if (!printDebug(shader, true, "program (vert/frag)")) {
		glDeleteProgram(shader);
		return 0;
	}

	// Setup the texture units.
	glUseProgram(shader);
	for (size_t i; i < texs.length; i++) {
		if (texs[i] is null)
			continue;

		int loc = glGetUniformLocation(shader, texs[i].ptr);
		glUniform1i(loc, cast(int)i);
	}
	glUseProgram(0);

	return shader;
}

static GLuint createAndCompileShader(string vertex, string fragment)
{
	// Create the handels
	uint vertexShader = glCreateShader(GL_VERTEX_SHADER);
	uint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
	uint programShader = glCreateProgram();

	// Attach the shaders to a program handel.
	glAttachShader(programShader, vertexShader);
	glAttachShader(programShader, fragmentShader);

	// Load and compile the Vertex Shader
	compileShader(vertexShader, vertex, "vertex");

	// Load and compile the Fragment Shader
	compileShader(fragmentShader, fragment, "fragment");

	// The shader objects are not needed any more,
	// the programShader is the complete shader to be used.
	glDeleteShader(vertexShader);
	glDeleteShader(fragmentShader);

	return programShader;
}

void compileShader(GLuint shader, string source, string type)
{
	const(char)* ptr;
	int length;

	ptr = source.ptr;
	length = cast(int)source.length - 1;
	glShaderSource(shader, 1, &ptr, &length);
	glCompileShader(shader);

	// Print any debug message
	printDebug(shader, false, type);
	return;
}

bool printDebug(GLuint shader, bool program, string type)
{
	// Instead of pointers, realy bothersome.
	GLint status;
	GLint length;

	// Get information about the log on this object.
	if (program) {
		glGetProgramiv(shader, GL_LINK_STATUS, &status);
		glGetProgramiv(shader, GL_INFO_LOG_LENGTH, &length);
	} else {
		glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
	}

	char[] buffer;
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
			printf("%s status: ok!\n%s".ptr, type.ptr, buffer.ptr);
		} else if (program) {
			printf("%s status: ok!\n".ptr, type.ptr);
		}

		return true;

	case 0: //GL_FALSE:
		if (length != 0) {
			printf("%s status: bad!\n%s".ptr, type.ptr, buffer.ptr);
		} else {
			printf("%s status: bad!\n".ptr, type.ptr);
		}

		return false;

	default:
		if (length != 0) {
			printf("%s status: %i\n%s".ptr, type.ptr, status, buffer.ptr);
		} else {
			printf("%s status: %i\n".ptr, type.ptr, status);
		}

		return false;
	}
}
