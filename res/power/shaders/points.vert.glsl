#version 450 core

#define VOXEL_SRC %VOXEL_SRC%
#define POWER_START %POWER_START%
#define POWER_LEVELS %POWER_LEVELS%

#define CUBE_POWER POWER_START
#define DIVISOR (1 << CUBE_POWER)
#define DIVISOR_INV (1.0 / DIVISOR)
#define POINT_SIZE (DIVISOR_INV * 1.414213562373095 + (DIVISOR_INV / 32.0))


layout (location = 0) out vec3 outPosition;
layout (location = 1) out flat uint outColor;

uniform mat4 matrix;
uniform vec3 cameraPos;
uniform float pointScale;

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

uint unpack_RGB565(uint data)
{
	uint ret = 0;
	ret = bitfieldInsert(ret,
		bitfieldExtract(data,  0+0, 5),  0+3, 5);
	ret = bitfieldInsert(ret,
		bitfieldExtract(data,  5+0, 6),  8+2, 6);
	ret = bitfieldInsert(ret,
		bitfieldExtract(data, 11+0, 5), 16+3, 5);
	return ret;
}

void main(void)
{
	uint index = gl_VertexID * 3;
	uint inData1 = inData[index + 0];
	uint inData2 = inData[index + 1];
	uint inData3 = inData[index + 2];

	// Extrat the positions.
	uvec4 upos = unpack_16_16_16_16(inData1, inData2);

	// Generate a position in the middle of the voxel.
	vec3 pos = vec3(upos.xyz) * DIVISOR_INV + DIVISOR_INV / 2.0;

	outColor = inData3;
	outPosition = pos;
	gl_Position = matrix * vec4(pos, 1.0);
	gl_PointSize = (pointScale * POINT_SIZE) / gl_Position.w;

/*
#define RED vec4(255.0, 0, 0, 255.0)
#define BLUE vec4(0, 0, 255.0, 255.0)
#define GREEN vec4(0, 255.0, 0, 255.0)
#define PURPLE vec4(255.0, 0.0, 255.0, 255.0)
#define FACTOR 0.99

	vec4 c = unpackUnorm4x8(inColor);
	if (gl_PointSize < 1.0) {
		outColor = packUnorm4x8(mix(GREEN, c, FACTOR));
	} else if (gl_PointSize > 2.0) {
		outColor = packUnorm4x8(mix(RED, c, FACTOR));
	} else if (gl_PointSize > 1.0) {
		outColor = packUnorm4x8(mix(PURPLE, c, FACTOR));
	}
*/
}
