#version 450 core


#define NORMAL_GET getNormalCube
#define NORMAL_SAMPLER samplerCube

#define VOXEL_SRC %VOXEL_SRC%
#define POWER_START %POWER_START%

#define CUBE_POWER POWER_START
#define VOXEL_SIZE (1 << CUBE_POWER)
#define DIVISOR_INV (1.0 / VOXEL_SIZE)


layout (early_fragment_tests) in;

layout (location = 0) in vec3 inPosition;
layout (location = 1) in flat vec3 inMinEdge;
layout (location = 2) in flat uint inOffset;
layout (location = 3) in flat vec3 inNormal;

layout (binding = 1) uniform NORMAL_SAMPLER sNormal;

layout (location = 0) out vec4 outColor;

uniform vec3 uCameraPos;
uniform vec3 uLightNormal;
uniform mat3 uNormalMatrix;


vec3 getNormalCube()
{
	vec3 edgePos = (inPosition - inMinEdge) * VOXEL_SIZE * 2.0 - 1.0;
	vec3 val = texture(sNormal, edgePos).xyz;
	return uNormalMatrix * normalize(val * 2.0 - 1.0);
}

vec3 getNormal3D()
{
	// Sign that is never 0.0
	vec3 sign = step(0.5, (inPosition - inMinEdge) * VOXEL_SIZE) * 2.0 - 1.0;

	vec3 edgePos = inPosition * VOXEL_SIZE;
	vec4 val = texture(sNormal, edgePos);

	return uNormalMatrix * normalize(sign * val.xyz);
}

void main(void)
{
	vec3 normal = NORMAL_GET();
	vec3 color = unpackUnorm4x8(inOffset).rgb;

	float nDotL = max(dot(normal.xyz, -uLightNormal), 0.0);
	float factor = nDotL * 0.4 + 0.6;

	outColor = vec4(color * factor, 1.0);
}
