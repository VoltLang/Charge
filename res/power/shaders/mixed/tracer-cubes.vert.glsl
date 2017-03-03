#version 450 core

#define LIST_POWER 9
#define DIVISOR (1 << LIST_POWER)
#define DIVISOR_INV (1.0 / DIVISOR)


layout (location = 0) out vec3 outPosition;
layout (location = 1) out flat vec3 outMinEdge;
layout (location = 2) out flat vec3 outMaxEdge;
layout (location = 3) out flat uint outOffset;

uniform mat4 matrix;

layout (binding = 0, std430) buffer BufferIn
{
	uint inData[];
};


uint decode(uint x, uint shift)
{
	x =   (x >> shift)  & 0x49249249U;
	x = (x ^ (x >> 2))  & 0xc30c30c3U;
	x = (x ^ (x >> 4))  & 0x0f00f00fU;
	x = (x ^ (x >> 8))  & 0xff0000ffU;
	x = (x ^ (x >> 16)) & 0x0000ffffU;
	return x;
}

void main(void)
{
	uint index = (gl_VertexID / 8) * 2;

	uint inPos =    inData[index];
	uint inOffset = inData[index + 1];


	// Generate coords on the fly.
	ivec3 off = ivec3(gl_VertexID & 0x1, (gl_VertexID >> 1) & 0x1, gl_VertexID >> 2 & 0x1);

	ivec3 ipos = ivec3(
		decode(inPos, 2),
		decode(inPos, 0),
		decode(inPos, 1));

	vec3 minEdge = vec3(ipos) * DIVISOR_INV;
	outMinEdge = minEdge;
	outMaxEdge = minEdge + vec3(1.0) * DIVISOR_INV;
	outOffset = inOffset;

	vec3 pos = vec3(ipos + off) * DIVISOR_INV;
	outPosition = pos;
	gl_Position = matrix * vec4(pos, 1.0);
}
