#version 450 core

#undef LIST_DO_TAG
#define POWER_START %POWER_START%
#define POWER_LEVELS %POWER_LEVELS%
#define POWER_DISTANCE %POWER_DISTANCE%
#define POWER_FINAL (POWER_LEVELS + POWER_START)

#define VOXEL_SRC %VOXEL_SRC%
#define VOXEL_DST1 %VOXEL_DST1%
#define VOXEL_DST2 %VOXEL_DST2%


#define SIZE (1 << POWER_LEVELS)
layout(local_size_x = SIZE, local_size_y = SIZE, local_size_z = SIZE) in;

layout (binding = 0) uniform usamplerBuffer octree;
layout (binding = 0, offset = VOXEL_DST1 * 4) uniform atomic_uint counter1;
layout (binding = 0, offset = VOXEL_DST2 * 4) uniform atomic_uint counter2;

uniform vec3 cameraPos;

layout (binding = VOXEL_SRC, std430) buffer BufferIn
{
	uint inData[];
};

layout (binding = VOXEL_DST1, std430) buffer BufferOut1
{
	uint outData1[];
};

layout (binding = VOXEL_DST2, std430) buffer BufferOut2
{
	uint outData2[];
};



uint calcAddress(uint select, uint node, uint offset)
{
	int bits = int(select + 1);
	uint toCount = bitfieldExtract(node, 0, bits);
	uint address = bitCount(toCount);
	return address + offset;
}

uint decode(uint x, uint shift)
{
	x =   (x >> shift)  & 0x49249249U;
	x = (x ^ (x >> 2))  & 0xc30c30c3U;
	x = (x ^ (x >> 4))  & 0x0f00f00fU;
	x = (x ^ (x >> 8))  & 0xff0000ffU;
	x = (x ^ (x >> 16)) & 0x0000ffffU;
	return x;
}

void main(void)
{
	// The morton value for this position.
	uint morton = gl_LocalInvocationIndex;

	// Get the initial node adress and extra morton bits.
	uint offset = (gl_WorkGroupID.x + gl_NumWorkGroups.x * gl_WorkGroupID.y) * 2;
	uint extra = inData[offset + 0];
	offset =     inData[offset + 1];

	// This is a unrolled loop.
	// Subdivide until empty node or found the node for this box.
	// Get the node.
	uint node = texelFetch(octree, int(offset)).r;

	// 3D bit selector, each element is in the range [0, 1].
	// Turn that into scalar in the range [0, 8].
	uint select = (morton >> ((POWER_LEVELS-1) * 3)) & uint(0x07);
	if ((node & (uint(1) << select)) == uint(0)) {
		return;
	}


#define LOOPBODY(counter) \
	offset = calcAddress(select, node, offset);			\
	offset = texelFetch(octree, int(offset)).r;			\
	node = texelFetch(octree, int(offset)).r;			\
									\
	select = (morton >> ((POWER_LEVELS-counter) * 3)) & uint(0x07);	\
	if ((node & (uint(1) << select)) == uint(0)) {			\
		return;							\
	}								\

#if POWER_LEVELS >= 2
	LOOPBODY(2);
#endif
#if POWER_LEVELS >= 3
	LOOPBODY(3);
#endif
#if POWER_LEVELS >= 4
#error
#endif

	morton |= (extra << (POWER_LEVELS * 3));

	offset = calcAddress(select, node, offset);
	offset = texelFetch(octree, int(offset)).r;

#ifdef LIST_DO_TAG
	float invDiv = 1.0 / (1 << POWER_FINAL);
	float halfInvDiv = 1.0 / (1 << (POWER_FINAL + 1));

	vec3 pos = vec3(
		decode(morton, 2),
		decode(morton, 0),
		decode(morton, 1)) * invDiv + halfInvDiv;
	vec3 v1 = pos - cameraPos;
	float l = dot(v1, v1);
	if (l > POWER_DISTANCE) {
		uint index = atomicCounterIncrement(counter2) * 2;
		outData2[index] = morton;
		outData2[index + 1] = offset;
		return;
	}
#endif

	uint index = atomicCounterIncrement(counter1) * 2;
	outData1[index] = morton;
	outData1[index + 1] = offset;
}
