#version 450 core

#define POWER_START %POWER_START%
#define POWER_LEVELS 2
#define SPLIT_SIZE (1.0 / (1 << POWER_START))
#define SPLIT_SIZE_INV (1 << POWER_START)

#define NUM_VOXELS (1 << POWER_LEVELS)

#define VOXEL_POWER (POWER_START + POWER_LEVELS)
#define TRACER_POWER POWER_LEVELS

#define X_SHIFT %X_SHIFT%
#define Y_SHIFT %Y_SHIFT%
#define Z_SHIFT %Z_SHIFT%

#define X_MUL (1 << (POWER_LEVELS * X_SHIFT))
#define Y_MUL (1 << (POWER_LEVELS * Y_SHIFT))
#define Z_MUL (1 << (POWER_LEVELS * Z_SHIFT))

layout (location = 0) in vec3 inPosition;
layout (location = 1) in flat vec3 inMinEdge;
layout (location = 2) in flat uint inOffset;
layout (binding = 0) uniform isamplerBuffer octree;
layout (location = 0) out vec4 outColor;

uniform vec3 uCameraPos;


void rayAABBTest(vec3 rayDir, vec3 pos, vec3 aabbMin, vec3 aabbMax,
		out float tMin, out float tMax)
{
	// Project ray through aabb
	vec3 t1 = (aabbMin - pos) / rayDir;
	vec3 t2 = (aabbMax - pos) / rayDir;
	
	vec3 tmin = min(t1, t2);
	vec3 tmax = max(t1, t2);
	
	tMin = max(max(0.0, tmin.x), max(tmin.y, tmin.z));
	tMax = min(tmax.x, min(tmax.y, tmax.z));
}

uint calcFlagsAddress(uint select)
{
	return inOffset + 1 + (select >> 4);
}

uint calcColorAddress(uint select, uint flags)
{
	select %= 16;
	uint offsetFlags = bitfieldExtract(flags, 16, 16);
	uint offsetBits = bitCount(bitfieldExtract(flags, 0, int(select)));
	return inOffset + offsetFlags + offsetBits;
}

float getOfPossibleDepth(float d)
{
	return smoothstep(0.0, 6.92820323, d);
}

void main(void)
{
	vec3 rayDir = normalize(inPosition - uCameraPos);
	vec3 pos = ((inPosition - inMinEdge) * SPLIT_SIZE_INV) * NUM_VOXELS;

	// Check for ray components being parallel to axes (i.e. values of 0).
	const float epsilon = 0.000001;	// Platform dependent value!
	if (abs(rayDir.x) <= epsilon) rayDir.x = epsilon * sign(rayDir.x);
	if (abs(rayDir.y) <= epsilon) rayDir.y = epsilon * sign(rayDir.y);
	if (abs(rayDir.z) <= epsilon) rayDir.z = epsilon * sign(rayDir.z);

	// Only process ray if it intersects voxel volume.
	float tMin = 0.0, tMax = 0.0;
	rayAABBTest(rayDir, pos, vec3(0.0), vec3(NUM_VOXELS), tMin, tMax);

/*
	if (tMin > -1.0) {
		outColor = vec4(vec3(Z_MUL / 32.0), 1.0);
		return;
	}
*/

	uint select = 0;
	uint flags = 0;
	int i = 0;

	while (true) {
		vec3 workPos;
		uint offset;
		vec3 t0, t1, tNext;


		workPos = pos + rayDir * tMin;
		workPos = floor(max(min(workPos, 3.99999), 0.0));

		select = uint(dot(workPos, vec3(X_MUL, Y_MUL, Z_MUL)));
		offset = calcFlagsAddress(select);
		flags = uint(texelFetch(octree, int(offset)).r);

		if (0 != (flags & (1 << (select % 16)))) {
			break;
		}

		vec3 testPos = pos + rayDir * tMin;
		workPos = floor(testPos);
		t0 = (        workPos - testPos) / rayDir;
		t1 = ((workPos + 1.0) - testPos) / rayDir;
		tNext = max(t0, t1);
		tMin += max(min(tNext.x, min(tNext.y, tNext.z)) + epsilon, epsilon);

		if ((int(i++ > 8) | int(tMin >= tMax)) != 0) {
			//outColor = vec4(1.0, 0.0, 0.0, 1.0);
			discard;
		}
	}

	//outColor = vec4(vec3(0.5), 1.0);
//	uint dataOffset = inOffset + offset +
//		bitCount(bitfieldExtract(bitsAndOffset, 0, int(select)));
	uint offset = calcColorAddress(select, flags);
	uint color = uint(texelFetch(octree, int(offset)).r);
	outColor = unpackUnorm4x8(color);
	//outColor = vec4(floor(pos) / NUM_VOXELS, 1.0);
/*
*/
}
