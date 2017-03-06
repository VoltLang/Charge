#version 450 core

#define INDIRECT_SRC %%
#define INDIRECT_DST %%

layout (binding = 0, offset = (INDIRECT_SRC * 4)) uniform atomic_uint counter;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout (binding = INDIRECT_DST, std430) buffer BufferOut
{
	uint count;
	uint primCount;
	uint first;
	uint baseInstance;
};


void main(void)
{
	count = atomicCounter(counter);
	primCount = 1;
	first = 0;
	baseInstance = 0;
}
