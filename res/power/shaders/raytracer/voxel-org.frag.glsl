#version 450 core
#define MAX_ITERATIONS 500

layout (location = 0) in vec3 inPosition;
layout (location = 1) in vec3 inMinEdge;
layout (location = 2) in vec3 inMaxEdge;
layout (location = 3) in flat int inOffset;
layout (binding = 0) uniform isamplerBuffer octree;
layout (location = 0) out vec4 outColor;

uniform vec3 cameraPos;
uniform int tracePower;
uniform int splitPower;


vec3 rayAABBTest(vec3 rayOrigin, vec3 rayDir, vec3 aabbMin, vec3 aabbMax)
{
	float tMin, tMax;

	// Project ray through aabb
	vec3 invRayDir = 1.0 / rayDir;
	vec3 t1 = (aabbMin - rayOrigin) * invRayDir;
	vec3 t2 = (aabbMax - rayOrigin) * invRayDir;
	
	vec3 tmin = min(t1, t2);
	vec3 tmax = max(t1, t2);
	
	tMin = max(max(0.0, tmin.x), max(tmin.y, tmin.z));
	tMax = min(min(99999.0, tmax.x), min(tmax.y, tmax.z));
	
	vec3 result;
	result.x = (tMax > tMin) ? 1.0 : 0.0;
	result.y = tMin;
	result.z = tMax;
	return result;
}

bool trace(out vec4 finalColor, vec3 rayDir, vec3 rayOrigin)
{
	// Check for ray components being parallel to axes (i.e. values of 0).
	const float epsilon = 0.000001;	// Platform dependent value!
	if (abs(rayDir.x) <= epsilon) rayDir.x = epsilon * sign(rayDir.x);
	if (abs(rayDir.y) <= epsilon) rayDir.y = epsilon * sign(rayDir.y);
	if (abs(rayDir.z) <= epsilon) rayDir.z = epsilon * sign(rayDir.z);

	// Calculate inverse of ray direction once.
	vec3 invRayDir = 1.0 / rayDir;

	// Store maximum extents of voxel volume.
	vec3 minEdge = inMinEdge;
	vec3 maxEdge = inMaxEdge;
	float bias = maxEdge.x / 1000000.0;

	// Only process ray if it intersects voxel volume.
	float tMin, tMax;
	vec3 result = rayAABBTest(rayOrigin, rayDir, minEdge, maxEdge);
	tMin = result.y;
	tMax = result.z;

	if (result.x <= 0.0) {
		return false;
	}

	// Force initial ray position to start at the
	// camera origin if it is in the voxel box.
	tMin = max(0.0f, tMin);

	// Loop until ray exits volume.
	int itr = 0;
	while (tMin < tMax && ++itr < MAX_ITERATIONS) {
		vec3 pos = rayOrigin + rayDir * tMin;

		// Restart at top of tree.
		int offset = inOffset;

		// Which part of the space the voxel volume occupy.
		vec3 boxMin = inMinEdge;
		vec3 boxDim = inMaxEdge - inMinEdge;

		// Loop until a leaf or max subdivided node is found.
		for (int i = tracePower; i > 0; i--) {

			uint node = uint(texelFetchBuffer(octree, offset).r);

			boxDim *= 0.5f;
			vec3 s = step(boxMin + boxDim, pos);
			boxMin = boxMin + boxDim * s;
			uint select = uint(dot(s, vec3(4, 1, 2)));
			if ((node & (uint(1) << select)) == uint(0)) {
				break;
			}

			if (i <= 1) {
				int traceSize = (1 << splitPower);
				finalColor = vec4(mod(pos * traceSize, 1.0), 1.0);
				return true;
			}

			int bits = int(select + 1);
			uint toCount = bitfieldExtract(node, 0, bits);
			int address = int(bitCount(toCount));
			address += int(offset);

			offset = texelFetchBuffer(octree, address).r;
			if (offset == 0) {
				return true;
			}
		}

		// Update ray position to exit current node
		vec3 t0 = (boxMin - pos) * invRayDir;
		vec3 t1 = (boxMin + boxDim - pos) * invRayDir;
		vec3 tNext = max(t0, t1);
		tMin += min(tNext.x, min(tNext.y, tNext.z)) + bias;
	}

	return false;
}

void main(void)
{
	vec3 rayDir = normalize(inPosition - cameraPos);
	vec3 rayOrigin = inPosition;

	if (!trace(outColor, rayDir, rayOrigin)) {
		discard;
	}
}
