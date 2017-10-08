#version 450 core

#define POWER_LEVELS 2

#define X_SHIFT %X_SHIFT%
#define Y_SHIFT %Y_SHIFT%
#define Z_SHIFT %Z_SHIFT%

#define SRC_BASE_INDEX %SRC_BASE_INDEX%

#define DST_COUNTER_INDEX %COUNTER_INDEX%


layout (local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout (binding = 0) uniform usamplerBuffer octree;

layout (binding = 0) uniform atomic_uint counter[8];

layout (binding = 3, std430) buffer BufferSort
{
	uint inVoxels[];
};

layout (binding = 4, std430) buffer BufferDouble
{
	uint outData[];
};


/*
struct PackedData
{
	uint padding;
	uint offsetAndBits[4];
	uint data[];
}
*/

void main(void)
{
	// The morton value for this position.
	uint morton = gl_LocalInvocationIndex;

	// Get the initial node adress and the packed position.
	uint inOffset = gl_WorkGroupID.x * 3;
	uint packedPos1 = inVoxels[inOffset + 0];
	uint packedPos2 = inVoxels[inOffset + 1];
	uint packedOffset = inVoxels[inOffset + 2];

	// Shift positions but keep object id as is.
	packedPos1 = packedPos1 << POWER_LEVELS;
	packedPos2 = bitfieldInsert(packedPos2, packedPos2 << POWER_LEVELS, 0, 16);
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


	uint index = atomicCounterIncrement(counter[DST_COUNTER_INDEX]) * 3;
	outData[index + 0] = packedPos1;
	outData[index + 1] = packedPos2;
	outData[index + 2] = data;
}
