#version 450 core

layout (binding = 0) uniform atomic_uint counter;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout (binding = 0, std430) buffer BufferOut
{
	uint num_groups_x;
	uint num_groups_y;
	uint num_groups_z;
};


void main(void)
{
	num_groups_x = atomicCounter(counter);
	num_groups_y = 1;
	num_groups_z = 1;
}