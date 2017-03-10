#version 450 core

#ifdef GL_ARB_shader_atomic_counter_ops
#extension GL_ARB_shader_atomic_counter_ops : require
// This define brought to you by crappy nVidia hardware/drivers.
// Good thing for us we only have one instance in flight at a time.
#define ATOMIC_RESET_UNSAFE(C) \
	atomicCounterAddARB(C, uint(-atomicCounter(C)))
#elif defined GL_AMD_shader_atomic_counter_ops
#extension GL_AMD_shader_atomic_counter_ops : require
#define ATOMIC_RESET_UNSAFE(C) atomicCounterExchange(C, 0)
#else
#error "No atomic ops"
#endif


#define INDIRECT_SRC %%
#define INDIRECT_DST %%

layout (binding = 0) uniform atomic_uint counter[8];

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout (binding = INDIRECT_DST, std430) buffer BufferOut
{
	uint num_groups_x;
	uint num_groups_y;
	uint num_groups_z;
};


void main(void)
{
	num_groups_x = ATOMIC_RESET_UNSAFE(counter[INDIRECT_SRC]);
	num_groups_y = 1;
	num_groups_z = 1;
}
