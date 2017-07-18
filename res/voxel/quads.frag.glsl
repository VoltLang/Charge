#version 450 core

#define VOXEL_SRC %VOXEL_SRC%
#define POWER_START %POWER_START%

#define CUBE_POWER POWER_START
#define VOXEL_SIZE (1 << CUBE_POWER)
#define DIVISOR_INV (1.0 / VOXEL_SIZE)


layout (location = 0) in vec3 inPosition;
layout (location = 1) in flat vec3 inMinEdge;
layout (location = 2) in flat uint inOffset;
layout (location = 3) in flat vec3 inNormal;

layout (binding = 0) uniform isamplerBuffer octree;

layout (location = 0) out vec4 outColor;

uniform vec3 uCameraPos;
uniform vec3 uLightDirection;

void main(void)
{
	float nDotL = max(dot(inNormal.xyz, -uLightDirection), 0.0) * 0.4 + 0.6;
	outColor = unpackUnorm4x8(inOffset) * nDotL;
}
