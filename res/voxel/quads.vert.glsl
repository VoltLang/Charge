#version 450 core

#define VOXEL_SRC %VOXEL_SRC%
#define POWER_START %POWER_START%

#define CUBE_POWER POWER_START
#define DIVISOR (1 << CUBE_POWER)
#define DIVISOR_INV (1.0 / DIVISOR)


layout (location = 0) out vec3 outPosition;
layout (location = 1) out flat vec3 outMinEdge;
layout (location = 2) out flat uint outOffset;
layout (location = 3) out flat vec3 outNormal;


uniform mat4 uMatrix;
uniform mat3 uNormalMatrix;
uniform vec3 uCameraPos;

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

uint getFlipBits(vec3 pos)
{
	uint bits =   (uCameraPos.x > pos.x ? 0x01 : 0x00);
	bits = bits | (uCameraPos.y > pos.y ? 0x02 : 0x00);
	bits = bits | (uCameraPos.z > pos.z ? 0x04 : 0x00);
	return bits;
}

vec3 getNormal(uint bits)
{
	uint face = (gl_VertexID & 0x07);
	face = (face << 2) | (face >> 1);

	int nx = int((face >> 0) & 1);
	int ny = int((face >> 1) & 1);
	int nz = int((face >> 2) & 1);
	nx = ((int(bits) >> 0) & nx) * 2 - nx;
	ny = ((int(bits) >> 1) & ny) * 2 - ny;
	nz = ((int(bits) >> 2) & nz) * 2 - nz;

	return vec3(nx, ny, nz);
}

vec3 getOffsetPosition(vec3 pos, uint bits)
{
	bits = (gl_VertexID & 0x07) ^ bits;
	return vec3(
		(bits >> 0) & 0x1,
		(bits >> 1) & 0x1,
		(bits >> 2) & 0x1) * DIVISOR_INV + pos;
}

void main(void)
{
	uint index = (gl_VertexID / 8) * 3;

	uint inPos1 =   inData[index + 0];
	uint inPos2 =   inData[index + 1];
	uint inOffset = inData[index + 2];

	// Generate coords on the fly.
	uvec3 upos = unpack_16_16_16_16(inPos1, inPos2).xyz;

	// Generate the front lower left corner position.
	vec3 pos = vec3(upos) * DIVISOR_INV;

	// We draw only half a cube and flip the bits in order
	// to draw the other side, this saves 1/8 shader instances
	// and half a the triangles (not counting the extra di)
	uint bits = getFlipBits(pos);
	vec3 offsetPos = getOffsetPosition(pos, bits);
	vec3 normal = getNormal(bits);

	outMinEdge = pos;
	outOffset = inOffset;
	outNormal = uNormalMatrix * normal;
	outPosition = offsetPos;
	gl_Position = uMatrix * vec4(offsetPos, 1.0);
}
