#version 450 core

// Defines the struct DataFmt
#include "voxel/data.glsl"


#define POWER_START %POWER_START%
#define POWER_LEVELS %POWER_LEVELS%
#define POWER_FINAL (POWER_START + POWER_LEVELS)

#define SRC_BASE_INDEX %SRC_BASE_INDEX%

#define DST_BASE_INDEX %DST_BASE_INDEX%
#define DST_COUNTER_INDEX %COUNTER_INDEX%

#define VOXEL_SIZE      (1.0 / (1 << (POWER_FINAL    )))
#define VOXEL_SIZE_HALF (1.0 / (1 << (POWER_FINAL + 1)))
#define VOXEL_RADII     (VOXEL_SIZE * sqrt(2.0))

#define X_SHIFT %X_SHIFT%
#define Y_SHIFT %Y_SHIFT%
#define Z_SHIFT %Z_SHIFT%

#if POWER_LEVELS == 1
layout (local_size_x = 8, local_size_y = 1, local_size_z = 1) in;
#elif POWER_LEVELS == 2
layout (local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
#else
#error "invalid power levels"
#endif

layout (binding = 0) uniform usamplerBuffer octree;

layout (binding = 0, std430) buffer BufferCounters
{
	uint ioCounters[];
};

layout (binding = 1, std430) buffer Data
{
	DataFmt uData;
};

layout (binding = 2, std430) buffer BufferVoxels
{
	uint ioVoxels[];
};


uint calcAddress(uint select, uint node, uint offset)
{
	int bits = int(select);
	uint toCount = bitfieldExtract(node, 0, bits);
	uint address = bitCount(toCount);
	return address + offset + bitfieldExtract(node, 16, 16);
}

void main(void)
{
	// The morton value for this position.
	uint morton = gl_LocalInvocationIndex;

	// Get the initial node adress and the packed position.
	uint offset = SRC_BASE_INDEX + gl_WorkGroupID.x * 3;
	uint xy = ioVoxels[offset + 0] << POWER_LEVELS;
	uint zobj = ioVoxels[offset + 1];
	uint x = bitfieldExtract(xy, 0, 16);
	uint y = bitfieldExtract(xy, 16, 16);
	uint z = bitfieldExtract(zobj, 0, 16) << POWER_LEVELS;
	uint obj = bitfieldExtract(zobj, 16, 16);
	offset = ioVoxels[offset + 2];

	// This is a unrolled loop.
	// Subdivide until empty node or found the node for this box.
	// Get the node.
	uint node = texelFetch(octree, int(offset)).r;

	// 3D bit selector, each element is in the range [0, 1].
	// Turn that into scalar in the range [0, 8].
	uint select = (morton >> ((POWER_LEVELS - 1) * 3)) & uint(0x07);
	if ((node & (uint(1) << select)) == uint(0)) {
		return;
	}


#define LOOPBODY(counter) \
	offset = calcAddress(select, node, offset);				\
	offset = texelFetch(octree, int(offset)).r;				\
	node = texelFetch(octree, int(offset)).r;				\
										\
	select = (morton >> ((POWER_LEVELS-counter) * 3)) & uint(0x07);		\
	if ((node & (uint(1) << select)) == uint(0)) {				\
		return;								\
	}

#if POWER_LEVELS == 2
	// Final loop body.
	LOOPBODY(2);
#endif

	// Update the position.
	x += (morton >> X_SHIFT) & 0x1;
	y += (morton >> Y_SHIFT) & 0x1;
	z += (morton >> Z_SHIFT) & 0x1;

#if POWER_LEVELS == 2
	x += (morton >> (X_SHIFT + 3 - 1)) & 0x2;
	y += (morton >> (Y_SHIFT + 3 - 1)) & 0x2;
	z += (morton >> (Z_SHIFT + 3 - 1)) & 0x2;
#endif

	// Calculate a position in the center of the voxel.
	vec4 v = vec4(vec3(x, y, z) * VOXEL_SIZE + VOXEL_SIZE_HALF, 1.0);

	// Test against the frustum.
	uint test =
		uint(dot(v, uData.objs[obj].planes[0]) < -VOXEL_RADII) |
		uint(dot(v, uData.objs[obj].planes[1]) < -VOXEL_RADII) |
		uint(dot(v, uData.objs[obj].planes[2]) < -VOXEL_RADII) |
		uint(dot(v, uData.objs[obj].planes[3]) < -VOXEL_RADII);
	if (test != 0) {
		return;
	}

	// Do final fetching of address here.
	offset = calcAddress(select, node, offset);
	offset = texelFetch(octree, int(offset)).r;

	// Setup where we should write.
	uint index = DST_BASE_INDEX;
	uint counterIndex = DST_COUNTER_INDEX;

	// Write out the data.
	index += atomicAdd(ioCounters[counterIndex], 1) * 3;
	ioVoxels[index + 0] = bitfieldInsert(x, y, 16, 16);
	ioVoxels[index + 1] = bitfieldInsert(z, obj, 16, 16);
	ioVoxels[index + 2] = offset;
}
