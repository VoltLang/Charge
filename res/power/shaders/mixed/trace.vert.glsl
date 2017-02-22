#version 450 core

layout (location = 0) out flat ivec3 array;

uniform mat4 matrix;


void main(void)
{
	// Generate coords on the fly.
	float x = float(gl_VertexID & 0x1);
	float y = float((gl_VertexID >> 1) & 0x1);
	float z = float((gl_VertexID >> 2) & 0x1);
	gl_Position = matrix * vec4(x, y, z, 1.0);

	array = ivec3(255, 0, 255);
}
