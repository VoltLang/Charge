#version 450 core

#define SPLIT_POWER 0
#define SPLIT_SIZE 1.0
#define TRACE_POWER 2
#define MAX_ITERATIONS 500

layout (location = 0) in vec3 inPosition;
layout (location = 1) in flat vec3 inMinEdge;
layout (location = 2) in flat ivec3 array;
layout (location = 0) out vec4 outColor;

uniform vec3 cameraPos;


int getBits(int select)
{
	int data = (select >= 4) ? array.y : array.x;
	return (data >> (8 * (select % 4))) & 0xff;
}

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
	int bits = int(select + 1);
	uint toCount = bitfieldExtract(node, 0, bits);
	int address = int(bitCount(toCount));
	return address + int(offset);
}

void main(void)
{
	vec3 rayDir = normalize(inPosition - cameraPos);

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
	bool hit = false;
	while (tMin < tMax) {
		// Restart at top of tree.

		// Which part of the space the voxel volume occupy.
		vec3 boxMin = inMinEdge;
		float boxDim = SPLIT_SIZE;

		do {
			boxDim *= 0.5f;
			vec3 pos = inPosition + rayDir * tMin;
			vec3 s = step(boxMin + boxDim, pos);
			boxMin = boxMin + boxDim * s;
			int select = int(s.x * 1 + s.y * 2 + s.z * 4);
			int bits = getBits(select);
			if (bits == int(0)) {
				break;
			}

			boxDim *= 0.5f;
			s = step(boxMin + boxDim, pos);
			boxMin = boxMin + boxDim * s;
			select = int(s.x * 1 + s.y * 2 + s.z * 4);
			if ((bits & (int(1) << select)) == uint(0)) {
				break;
			}

			hit = true;
			break;

		} while (false);

		if (hit) {
			break;
		}

		// Update ray position to exit current node
		vec3 pos = inPosition + rayDir * tMin;
		vec3 t0 = (boxMin - pos) / rayDir;
		vec3 t1 = (boxMin + boxDim - pos) / rayDir;
		vec3 tNext = max(t0, t1);
		tMin += min(tNext.x, min(tNext.y, tNext.z)) + epsilon;
	}

	if (hit) {
		float traceSize = float(1 << TRACE_POWER);
		vec3 pos = inPosition + rayDir * tMin;
		outColor = vec4(mod((pos - inMinEdge) * traceSize, 1.0), 1.0);
	} else {
		discard;
	}
}
