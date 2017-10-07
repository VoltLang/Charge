#version 450 core

// Defines the struct DataFmt
#include "voxel/data.glsl"


#define VOXEL_SRC %VOXEL_SRC%
#define POWER_START %POWER_START%

#define CUBE_POWER POWER_START
#define DIVISOR (1 << CUBE_POWER)
#define DIVISOR_INV (1.0 / DIVISOR)


layout (location = 0) out vec3 outPosition;
layout (location = 1) out flat vec3 outMinEdge;
layout (location = 2) out flat uint outOffset;

layout (binding = 1, std430) buffer Data
{
	DataFmt uData;
};

layout (binding = VOXEL_SRC, std430) buffer BufferIn
{
	uint inData[];
};


uvec4 unpack_2_10_10_10(uint data)
{
	return uvec4(
		(data >>  0) & 0x3FF,
		(data >> 10) & 0x3FF,
		(data >> 20) & 0x3FF,
		(data >> 30) & 0x003);
}

uvec4 unpack_16_16_16_16(uint data1, uint data2)
{
	return uvec4(
		(data1 >>  0) & 0xFFFF,
		(data1 >> 16) & 0xFFFF,
		(data2 >>  0) & 0xFFFF,
		(data2 >> 16) & 0xFFFF);
}

void main(void)
{
	uint index = (gl_VertexID / 8) * 3;

	uint inPos1 =   inData[index + 0];
	uint inPos2 =   inData[index + 1];
	uint inOffset = inData[index + 2];

	// Extrat the positions and object id.
	uvec4 upos = unpack_16_16_16_16(inPos1, inPos2);
	uint obj = upos.w;

	// Generate the front lower left corner position.
	vec3 pos = vec3(upos.xyz) * DIVISOR_INV;

	// We draw only half a cube and flip the bits in order
	// to draw the other side, this saves 1/8 shader instances
	// and half a the triangles (not counting the extra di)
	uint bits =   (pos.x > uData.objs[obj].cameraPos.x ? 0x01 : 0x00);
	bits = bits | (pos.y > uData.objs[obj].cameraPos.y ? 0x02 : 0x00);
	bits = bits | (pos.z > uData.objs[obj].cameraPos.z ? 0x04 : 0x00);
	bits = gl_VertexID ^ bits;

	outMinEdge = pos;
	outOffset = inOffset;

	vec3 offsetPos = vec3(
		 bits       & 0x1,
		(bits >> 1) & 0x1,
		(bits >> 2) & 0x1) * DIVISOR_INV + pos;

	outPosition = offsetPos;
	gl_Position = uData.objs[obj].matrix * vec4(offsetPos, 1.0);
}
