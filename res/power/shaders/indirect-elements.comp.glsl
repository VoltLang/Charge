#version 450 core
#ifdef GL_ARB_shader_atomic_counter_ops
#extension GL_ARB_shader_atomic_counter_ops : require
#define atomicCounterExchange atomicCounterExchangeARB
#else
#extension GL_AMD_shader_atomic_counter_ops : require
#endif

#define INDIRECT_SRC %%
#define INDIRECT_DST %%

layout (binding = 0) uniform atomic_uint counter[8];

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout (binding = INDIRECT_DST, std430) buffer BufferOut
{
	uint count;
	uint primCount;
	uint firstIndex;
	uint baseVertex;
	uint baseInstance;
};


void main(void)
{
	count = atomicCounterExchange(counter[INDIRECT_SRC], 0) * 12;
	primCount = 1;
	firstIndex = 0;
	baseVertex = 0;
	baseInstance = 0;
}
