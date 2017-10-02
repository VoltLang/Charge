#version 450 core
#extension GL_ARB_shader_ballot : enable

#define POWER_START %POWER_START%
#define POWER_LEVELS %POWER_LEVELS%
#define POWER_FINAL (POWER_LEVELS + POWER_START)

#define COUNTER_INDEX %COUNTER_INDEX%
#define VOXEL_SRC %VOXEL_SRC%
#define VOXEL_DST %VOXEL_DST%

#define X_SHIFT %X_SHIFT%
#define Y_SHIFT %Y_SHIFT%
#define Z_SHIFT %Z_SHIFT%

#if POWER_LEVELS == 2
layout (local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
#elif POWER_LEVELS == 3
layout (local_size_x = 64, local_size_y = 8, local_size_z = 1) in;
#else
#error
#endif


layout (binding = 0) uniform usamplerBuffer octree;

layout (binding = 0, std430) buffer BufferCounters
{
	uint inoutCounters[];
};

struct DataFmt
{
	mat4 matrix;
	vec4 planes[4];
	vec4 cameraPos;
};

layout (binding = 1, std430) buffer Data
{
	DataFmt uData;
};

layout (binding = VOXEL_SRC, std430) buffer BufferIn
{
	uint inData[];
};

layout (binding = VOXEL_DST, std430) buffer BufferOut
{
	uint outData[];
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
	uint offset = (gl_WorkGroupID.x + gl_NumWorkGroups.x * gl_WorkGroupID.y) * 4;
	uint xy = inData[offset + 0] << POWER_LEVELS;
	uint x = bitfieldExtract(xy,  0, 16);
	uint y = bitfieldExtract(xy, 16, 16);
	uint z = inData[offset + 1] << POWER_LEVELS;
	offset = inData[offset + 2];

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

	x = bitfieldInsert(x, (select >> X_SHIFT) & 0x1, POWER_LEVELS - 1, 1);
	y = bitfieldInsert(y, (select >> Y_SHIFT) & 0x1, POWER_LEVELS - 1, 1);
	z = bitfieldInsert(z, (select >> Z_SHIFT) & 0x1, POWER_LEVELS - 1, 1);


#define LOOPBODY(counter) \
	offset = calcAddress(select, node, offset);				\
	offset = texelFetch(octree, int(offset)).r;				\
	node = texelFetch(octree, int(offset)).r;				\
										\
	select = (morton >> ((POWER_LEVELS-counter) * 3)) & uint(0x07);		\
	if ((node & (uint(1) << select)) == uint(0)) {				\
		return;								\
	}									\
										\
	x = bitfieldInsert(x, (select >> X_SHIFT) & 0x1, POWER_LEVELS - counter, 1);	\
	y = bitfieldInsert(y, (select >> Y_SHIFT) & 0x1, POWER_LEVELS - counter, 1);	\
	z = bitfieldInsert(z, (select >> Z_SHIFT) & 0x1, POWER_LEVELS - counter, 1);


	// Final loop body.
#if   POWER_LEVELS == 1
#elif POWER_LEVELS == 2
	LOOPBODY(2);
#elif POWER_LEVELS == 3
	LOOPBODY(2);
	LOOPBODY(3);
#else
#error "invalid power levels"
#endif

	offset = calcAddress(select, node, offset);
	offset = texelFetch(octree, int(offset)).r;

	uint index = atomicAdd(inoutCounters[COUNTER_INDEX], 1) * 3;
	outData[index + 0] = bitfieldInsert(x, y, 16, 16);
	outData[index + 1] = z;
	outData[index + 2] = offset;
}
