#version 450 core

layout (location = 0) in uvec2 inVertex;

layout (location = 0) out ivec3 outPosition;
layout (location = 1) out uint outOffset;
/*
layout (binding = 0, std430) buffer BufferIn
{
	uint inData[];
};
*/

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
/*
	int index = gl_VertexID * 2;
	uint inPos    = inData[index];
	uint inOffset = inData[index + 1];
*/
	uint inPos = inVertex.x;
	uint inOffset = inVertex.y;

	outPosition = ivec3(
		decode(inPos, 2),
		decode(inPos, 0),
		decode(inPos, 1));
	outOffset = inOffset;
}
