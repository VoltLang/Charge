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
layout (binding = 1) uniform sampler3D edge;

layout (location = 0) out vec4 outColor;

uniform vec3 uCameraPos;
uniform vec3 uLightDirection;
uniform mat3 uNormalMatrix;


float getEdgeFactorCube()
{
	vec3 edgePos = (inPosition - inMinEdge) * VOXEL_SIZE * 2.0 - 1.0;

	return texture(edge, normalize(edgePos)).r * 0.7;
}

float getEdgeFactor3D()
{
	vec3 edgePos = (inPosition - inMinEdge) * VOXEL_SIZE;

	return texture(edge, edgePos).r * 0.7;
}

vec3 getNormal(out float edgeFactor)
{
	// Sign that is never 0.0
	vec3 sign = step(0.5, (inPosition - inMinEdge) * VOXEL_SIZE) * 2.0 - 1.0;

	vec3 edgePos = inPosition * VOXEL_SIZE;
	vec4 val = texture(edge, edgePos);

	edgeFactor = val.a * 0.01;
	return uNormalMatrix * normalize(sign * val.xyz);
}

void main(void)
{
	float edgeFactor = 0.0;
	vec3 normal = getNormal(edgeFactor);
	vec3 color = unpackUnorm4x8(inOffset).rgb;

	float nDotL = max(dot(normal.xyz, -uLightDirection), 0.0);
	float factor = nDotL * 0.4 + 0.6;

	vec3 edgeColor = mix(color, vec3(1), 0.2);

	outColor = vec4(mix(color * factor, edgeColor, edgeFactor), 1.0);
}
