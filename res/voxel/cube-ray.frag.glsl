#version 450 core

#define POWER_START %POWER_START%
#define POWER_LEVELS %POWER_LEVELS%
#define SPLIT_SIZE (1.0 / (1 << POWER_START))

#define VOXEL_POWER (POWER_START + POWER_LEVELS)
#define TRACER_POWER POWER_LEVELS

#define X_SHIFT %X_SHIFT%
#define Y_SHIFT %Y_SHIFT%
#define Z_SHIFT %Z_SHIFT%

#define X_MUL (1 << X_SHIFT)
#define Y_MUL (1 << Y_SHIFT)
#define Z_MUL (1 << Z_SHIFT)


#if TRACER_POWER == 0
layout (early_fragment_tests) in;
#endif

layout (location = 0) in vec3 inPosition;
layout (location = 1) in flat vec3 inMinEdge;
layout (location = 2) in flat uint inOffset;
layout (binding = 0) uniform isamplerBuffer octree;
layout (location = 0) out vec4 outColor;

uniform vec3 uCameraPos;


void rayAABBTest(vec3 rayDir, vec3 aabbMin, vec3 aabbMax,
		out float tMin, out float tMax)
{
	// Project ray through aabb
	vec3 t1 = (aabbMin - inPosition) / rayDir;
	vec3 t2 = (aabbMax - inPosition) / rayDir;
	
	vec3 tmin = min(t1, t2);
	vec3 tmax = max(t1, t2);
	
	tMin = max(max(0.0, tmin.x), max(tmin.y, tmin.z));
	tMax = min(min(99999.0, tmax.x), min(tmax.y, tmax.z));
}

int calcAddress(uint select, uint node, int offset)
{
	int bits = int(select);
	uint toCount = bitfieldExtract(node, 0, bits);
	int address = int(bitCount(toCount));
	return address + offset + int(bitfieldExtract(node, 16, 16));
}

void main(void)
{
#if TRACER_POWER == 0
	outColor = unpackUnorm4x8(inOffset);
#else
	vec3 rayDir = normalize(inPosition - uCameraPos);

	// Check for ray components being parallel to axes (i.e. values of 0).
	const float epsilon = 0.000001;	// Platform dependent value!
	if (abs(rayDir.x) <= epsilon) rayDir.x = epsilon * sign(rayDir.x);
	if (abs(rayDir.y) <= epsilon) rayDir.y = epsilon * sign(rayDir.y);
	if (abs(rayDir.z) <= epsilon) rayDir.z = epsilon * sign(rayDir.z);

	// Only process ray if it intersects voxel volume.
	float tMin, tMax;
	rayAABBTest(rayDir, inMinEdge, inMinEdge + SPLIT_SIZE, tMin, tMax);

	// Force initial ray position to start at the
	// camera origin if it is in the voxel box.
	tMin = max(0.0f, tMin);

	// Loop until ray exits volume.

	int hit = 0;
	while (true) {
		// Restart at top of tree.

		// Which part of the space the voxel volume occupy.
		vec3 boxMin = inMinEdge;
		float boxDim = SPLIT_SIZE;
		do {

			int offset = int(inOffset);
			uint node = uint(texelFetch(octree, offset).r);

			boxDim *= 0.5f;
			vec3 pos = inPosition + rayDir * tMin;
			vec3 s = step(boxMin + boxDim, pos);
			boxMin = boxMin + boxDim * s;
			uint select = uint(s.x * X_MUL + s.y * Y_MUL + s.z * Z_MUL);
			if ((node & (uint(1) << select)) == uint(0)) {
				break;
			}

#define LOOPBODY() \
			offset = calcAddress(select, node, offset);		\
			offset = texelFetch(octree, offset).r;			\
			node = uint(texelFetch(octree, offset).r);		\
										\
			boxDim *= 0.5f;						\
			s = step(boxMin + boxDim, pos);				\
			boxMin = boxMin + boxDim * s;				\
			select = uint(s.x * X_MUL + s.y * Y_MUL + s.z * Z_MUL);	\
			if ((node & (uint(1) << select)) == uint(0)) {		\
				break;						\
			}

#if TRACER_POWER >= 2
	LOOPBODY();
#endif
#if TRACER_POWER >= 3
	LOOPBODY();
#endif
#if TRACER_POWER >= 4
	LOOPBODY();
#endif
#if TRACER_POWER >= 5
	LOOPBODY();
#endif
#if TRACER_POWER >= 6
	LOOPBODY();
#endif
#if TRACER_POWER >= 7
	LOOPBODY();
#endif
#if TRACER_POWER >= 8
	LOOPBODY();
#endif

			hit = calcAddress(select, node, offset);
			break;

		} while (false);

		if (hit != 0) {
			break;
		}

		// Update ray position to exit current node
		vec3 pos = inPosition + rayDir * tMin;
		vec3 t0 = (boxMin - pos) / rayDir;
		vec3 t1 = (boxMin + boxDim - pos) / rayDir;
		vec3 tNext = max(t0, t1);
		tMin += min(tNext.x, min(tNext.y, tNext.z)) + epsilon;

		if (tMin >= tMax) {
			discard;
		}
	}

	outColor = unpackUnorm4x8(uint(texelFetch(octree, hit).r));
#endif
}
