#version 450 core

#define OCCLUDE_POWER %%
#define OCCLUDE_VOXELS (1 << OCCLUDE_POWER)
#define OCCLUDE_SIZE (1.0 / OCCLUDE_VOXELS)

layout (points) in;
layout (location = 0) in vec3[] inPosition;
layout (binding = 0) uniform isamplerBuffer octree;
layout (points, max_vertices = 1) out;
layout (xfb_buffer = 0, xfb_stride = 8) out outputBlock
{
	layout (xfb_offset = 0) uint outPosition;
	layout (xfb_offset = 4) uint outOffset;
};

uniform mat4 matrix;
uniform vec3 cameraPos;


int calcAddress(uint select, uint node, int offset)
{
	int bits = int(select + 1);
	uint toCount = bitfieldExtract(node, 0, bits);
	int address = int(bitCount(toCount));
	return address + int(offset);
}

bool findStart(vec3 pos, out int offset)
{
	// Which part of the space the voxel volume occupy.
	vec3 boxMin = vec3(0.0);
	float boxDim = OCCLUDE_VOXELS;

	// Initial node address.
	offset = 0;

	// Subdivid until empty node or found the node for this box.
	for (int i = OCCLUDE_POWER; i > 0; i--) {
		// Get the node.
		uint node = uint(texelFetch(octree, offset).r);

		boxDim *= 0.5f;
		vec3 s = step(boxMin + boxDim, pos);
		boxMin = boxMin + boxDim * s;
		uint select = uint(dot(s, vec3(4, 1, 2)));
		if ((node & (uint(1) << select)) == uint(0)) {
			return false;
		}

		offset = calcAddress(select, node, offset);
		offset = texelFetch(octree, offset).r;
	}

	return true;
}

void main(void)
{
	// Scale position with voxel size.
	vec3 pos = inPosition[0];

	// Is this split voxel position outside of voxel box.
	if (any(lessThan(pos, vec3(0.0))) ||
	    any(greaterThanEqual(pos, vec3(OCCLUDE_VOXELS)))) {
		return;
	}

	int tmpOffset;
	vec3 tmpMinEdge = inPosition[0];

	if (!findStart(tmpMinEdge, tmpOffset)) {
		return;
	}

	ivec3 ipos = ivec3(inPosition[0]);
	outPosition = uint(dot(ipos, ivec3(1, 256, 256*256)));
	outOffset = tmpOffset;
	EmitVertex();
	EndPrimitive();
}
