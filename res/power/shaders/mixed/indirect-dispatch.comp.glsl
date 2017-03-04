#version 450 core

layout (binding = 0) uniform atomic_uint counter;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout (binding = 0, std430) buffer BufferOut
{
	uint outData[];
};


void main(void)
{
	outData[0] = atomicCounter(counter);
	outData[1] = 1;
	outData[2] = 1;
}
