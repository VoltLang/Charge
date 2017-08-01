#version 450 core

#define POWER_LEVELS 2

#define VOXEL_SRC %VOXEL_SRC%
#define VOXEL_DST1 %VOXEL_DST1%

#define X_SHIFT %X_SHIFT%
#define Y_SHIFT %Y_SHIFT%
#define Z_SHIFT %Z_SHIFT%

#define LOCAL 4
layout (local_size_x = LOCAL, local_size_y = LOCAL, local_size_z = LOCAL) in;

layout (binding = 0) uniform usamplerBuffer octree;
layout (binding = 0) uniform atomic_uint counter[8];

layout (binding = VOXEL_SRC, std430) buffer BufferIn
{
	uint inData[];
};

layout (binding = VOXEL_DST1, std430) buffer BufferOut1
{
	uint outData1[];
};

/*
struct PackedData
{
	uint padding;
	uint offsetAndBits[4];
	uint data[];
}
*/

uint packRGB565(uint color)
{
	//uint ret = 0;
	//ret = bitfieldInsert(ret, ,  0, 5);
	uint ret = bitfieldInsert(color >>  3, color >> 10,  5, 6);
	ret = bitfieldInsert(ret, color >> 19, 11, 5);
	return ret;
}

void main(void)
{
	// The morton value for this position.
	uint morton = gl_LocalInvocationIndex;

	// Get the initial node adress and the packed position.
	uint inOffset = (gl_WorkGroupID.x + gl_NumWorkGroups.x * gl_WorkGroupID.y) * 3;
	uint packedPos1 = inData[inOffset + 0] << POWER_LEVELS;
	uint packedPos2 = inData[inOffset + 1] << POWER_LEVELS;
	uint packedOffset = inData[inOffset + 2];

	// Calculate where the offset and bits are for this voxel.
	uint offsetAndBitsAddress = packedOffset + 1 + morton / 16;

	// Fetch the data from the octree.
	uint offsetAndBits = texelFetch(octree, int(offsetAndBitsAddress)).r;

	// Extract data from the data.
	uint offset = bitfieldExtract(offsetAndBits, 16, 16);
	uint bits = bitfieldExtract(offsetAndBits, 0, 16);
	uint select = (morton % 16);

	// No Voxel here.
	if (((1 << select) & bits) == 0) {
		return;
	}

	uint dataOffset = packedOffset + offset +
		bitCount(bitfieldExtract(bits, 0, int(select)));
	uint data = texelFetch(octree, int(dataOffset)).r;
	//data = data >> ((dataOffset & 1) << 4);


#if 0
	packedPos1 = bitfieldInsert(packedPos1, gl_LocalInvocationID.x,  0,  2);
	packedPos1 = bitfieldInsert(packedPos1, gl_LocalInvocationID.y, 16,  2);
	packedPos2 = bitfieldInsert(packedPos2, gl_LocalInvocationID.z,  0,  2);
	packedPos2 = bitfieldInsert(packedPos2,       packRGB565(data), 16, 16);
#elif 0
	packedPos1 = bitfieldInsert(packedPos1,
		bitfieldExtract(morton, X_SHIFT + 3, 1),  1, 1);
	packedPos1 = bitfieldInsert(packedPos1,
		bitfieldExtract(morton, Y_SHIFT + 3, 1), 17, 1);
	packedPos2 = bitfieldInsert(packedPos2,
		bitfieldExtract(morton, Z_SHIFT + 3, 1),  1, 1);
	packedPos1 = bitfieldInsert(packedPos1,
		bitfieldExtract(morton, X_SHIFT, 1),  0, 1);
	packedPos1 = bitfieldInsert(packedPos1,
		bitfieldExtract(morton, Y_SHIFT, 1), 16, 1);
	packedPos2 = bitfieldInsert(packedPos2,
		bitfieldExtract(morton, Z_SHIFT, 1),  0, 1);
	packedPos2 = bitfieldInsert(packedPos2,
		packRGB565(data), 16, 16);
#else
	packedPos1 = bitfieldInsert(packedPos1,
		bitfieldExtract(morton, X_SHIFT + 3, 1),  1, 1);
	packedPos1 = bitfieldInsert(packedPos1,
		bitfieldExtract(morton, Y_SHIFT + 3, 1), 17, 1);
	packedPos2 = bitfieldInsert(packedPos2,
		bitfieldExtract(morton, Z_SHIFT + 3, 1),  1, 1);
	packedPos1 = bitfieldInsert(packedPos1,
		bitfieldExtract(morton, X_SHIFT, 1),  0, 1);
	packedPos1 = bitfieldInsert(packedPos1,
		bitfieldExtract(morton, Y_SHIFT, 1), 16, 1);
	packedPos2 = bitfieldInsert(packedPos2,
		bitfieldExtract(morton, Z_SHIFT, 1),  0, 1);
#endif

	uint index = atomicCounterIncrement(counter[VOXEL_DST1]) * 3;
	outData1[index + 0] = packedPos1;
	outData1[index + 1] = packedPos2;
	outData1[index + 2] = data;
}
