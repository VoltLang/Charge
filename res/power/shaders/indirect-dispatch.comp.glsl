#version 450 core
#ifdef GL_ARB_shader_atomic_counter_ops
#extension GL_ARB_shader_atomic_counter_ops : require
#define atomicCounterExchange atomicCounterExchangeARB
#else
#extension GL_AMD_shader_atomic_counter_ops : require
#endif


#define INDIRECT_SRC %%
#define INDIRECT_DST %%

layout (binding = 0, offset = (INDIRECT_SRC * 4)) uniform atomic_uint counter;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout (binding = INDIRECT_DST, std430) buffer BufferOut
{
	uint num_groups_x;
	uint num_groups_y;
	uint num_groups_z;
};


void main(void)
{
	num_groups_x = atomicCounterExchange(counter, 0);
	num_groups_y = 1;
	num_groups_z = 1;
}
