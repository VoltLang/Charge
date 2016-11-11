#version 450 core
#define MAX_ITERATIONS 500

layout (location = 0) in vec3 inPosition;
layout (location = 1) in flat vec3 inMinEdge;
layout (location = 2) in flat vec3 inMaxEdge;
layout (location = 3) in flat int inOffset;
layout (binding = 0) uniform isamplerBuffer octree;
layout (location = 0) out vec4 outColor;

uniform vec3 cameraPos;
uniform int tracePower;
uniform int splitPower;


void rayAABBTest(vec3 rayDirInv, vec3 aabbMin, vec3 aabbMax,
		out float tMin, out float tMax)
{
	// Project ray through aabb
	vec3 t1 = (aabbMin - inPosition) * rayDirInv;
	vec3 t2 = (aabbMax - inPosition) * rayDirInv;
	
	vec3 tmin = min(t1, t2);
	vec3 tmax = max(t1, t2);
	
	tMin = max(max(0.0, tmin.x), max(tmin.y, tmin.z));
	tMax = min(min(99999.0, tmax.x), min(tmax.y, tmax.z));
}

uint saveNode[10];
int saveNodeAddr[10];
int saveOffset[10];
int saveOffsetAddr[10];

uint getNode(int i, int addr)
{
	if (saveNodeAddr[i] == addr) {
		return saveNode[i];
	}

	uint node = uint(texelFetch(octree, addr).r);
	saveNodeAddr[i] = addr;
	saveNode[i] = node;
	return node;
}

int getOffset(int i, int addr)
{
	if (saveOffsetAddr[i] == addr) {
		return saveOffset[i];
	}

	int offset = texelFetch(octree, addr).r;
	saveOffsetAddr[i] = addr;
	saveOffset[i] = offset;
	return offset;
}

void main(void)
{
	vec3 rayDir = normalize(inPosition - cameraPos);
	vec3 rayDirInv = 1 / rayDir;

	// Check for ray components being parallel to axes (i.e. values of 0).
	const float epsilon = 0.000001;	// Platform dependent value!
	if (abs(rayDir.x) <= epsilon) rayDir.x = epsilon * sign(rayDir.x);
	if (abs(rayDir.y) <= epsilon) rayDir.y = epsilon * sign(rayDir.y);
	if (abs(rayDir.z) <= epsilon) rayDir.z = epsilon * sign(rayDir.z);

	// Only process ray if it intersects voxel volume.
	float tMin, tMax;
	rayAABBTest(rayDirInv, inMinEdge, inMaxEdge, tMin, tMax);

	// Force initial ray position to start at the
	// camera origin if it is in the voxel box.
	tMin = max(0.0f, tMin);

	for (int k; k < 10; k++) {
		saveOffsetAddr[k] = -1;
		saveNodeAddr[k] = -1;
	}

	// Loop until ray exits volume.
	bool hit = false;
	int itr = 0;
	while (tMin < tMax && ++itr < MAX_ITERATIONS) {
		// Restart at top of tree.
		int offset = inOffset;

		// Which part of the space the voxel volume occupy.
		vec3 boxMin = inMinEdge;
		float boxDim = inMaxEdge.x - inMinEdge.x;

		// Loop until a leaf or max subdivided node is found.
		for (int i = tracePower; i > 0; i--) {
			uint node = getNode(i, offset);

			boxDim *= 0.5f;
			vec3 pos = inPosition + tMin * rayDir;
			vec3 s = step(boxMin + boxDim, pos);
			boxMin = boxMin + boxDim * s;
			uint select = uint(s.x * 4 + s.y * 1 + s.z * 2);
			if ((node & (uint(1) << select)) == uint(0)) {
				break;
			}

			if (i <= 1) {
				float traceSize = float(1 << splitPower);
				pos -= inMinEdge;
				outColor = vec4(mod(pos * traceSize, 1.0), 1.0);
				return;
			}

			int bits = int(select + 1);
			uint toCount = bitfieldExtract(node, 0, bits);
			int address = int(bitCount(toCount));
			address += int(offset);

			offset = getOffset(i, address);
		}

		if (hit) {
			break;
		}

		// Update ray position to exit current node
		vec3 pos = inPosition + tMin * rayDir;
		vec3 t0 = (boxMin - pos) * rayDirInv;
		vec3 t1 = (boxMin + boxDim - pos) * rayDirInv;
		vec3 tNext = max(t0, t1);
		tMin += min(tNext.x, min(tNext.y, tNext.z)) + epsilon;
	}

	discard;
}
