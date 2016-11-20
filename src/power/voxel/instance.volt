// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.voxel.instance;

import charge.sys.resource;
import charge.gfx;


struct InstanceData
{
	position, offset: uint;
}

/**
 * VBO with no per vertex data but instead per instance data.
 */
class InstanceBuffer : GfxBuffer
{
public:
	global fn make(name: string, instances: GLsizei) InstanceBuffer
	{
		dummy: void*;
		buffer := cast(InstanceBuffer)Resource.alloc(
			typeid(InstanceBuffer), uri, name, 0, out dummy);
		buffer.__ctor(instances);
		return buffer;
	}


protected:
	this(instances: GLsizei)
	{
		super(0, 0);

		// Create buffers.
		glCreateBuffers(1, &buf);
		glCreateVertexArrays(1, &vao);

		// Make the stride and length
		instanceStride := cast(GLsizei)typeid(InstanceData).size;
		instancesLength := instances * instanceStride;

		// Create the storage for the buffer.
		glNamedBufferStorage(buf, instancesLength, null, GL_DYNAMIC_STORAGE_BIT);

		glBindBuffer(GL_ARRAY_BUFFER, buf);

		glBindVertexArray(vao);
		glVertexAttribIPointer(0, 4, GL_UNSIGNED_BYTE, instanceStride, null);
		glVertexAttribIPointer(1, 1, GL_UNSIGNED_INT, instanceStride, cast(void*)4);
		glEnableVertexAttribArray(0);
		glEnableVertexAttribArray(1);
		glVertexAttribDivisor(0, 1);
		glVertexAttribDivisor(1, 1);
		glBindVertexArray(0);

		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}
}


struct VisibilityData
{
	visibile: int;
}

/**
 * VBO with no per vertex data but instead per instance data.
 */
class OccludeBuffer : Resource
{
public:
	instanceBuffer: GLuint;
	visibilityBuffer: GLuint;
	vaoPerVertex: GLuint;
	vaoPerInstance: GLuint;
	vaoPrune: GLuint;


public:
	global fn make(name: string, num: GLsizei) OccludeBuffer
	{
		assert(num > 0);
		dummy: void*;
		buffer := cast(OccludeBuffer)Resource.alloc(
			typeid(OccludeBuffer), GfxBuffer.uri, name, 0, out dummy);
		buffer.__ctor(num);
		return buffer;
	}


protected:
	this(num: GLsizei)
	{
		// Setup instance buffer and upload the data.
		glCreateBuffers(1, &instanceBuffer);
		glCreateBuffers(1, &visibilityBuffer);
		glCreateVertexArrays(1, &vaoPerVertex);
		glCreateVertexArrays(1, &vaoPerInstance);
		glCreateVertexArrays(1, &vaoPrune);

		// Make the stride and length
		instanceStride := cast(GLsizei)typeid(InstanceData).size;
		instancesLength := num * instanceStride;
		visibilityStride := cast(GLsizei)typeid(VisibilityData).size;
		visibilityLength := num * visibilityStride;

		// Create the storage for the buffers.
		glNamedBufferStorage(instanceBuffer, instancesLength, null, GL_DYNAMIC_STORAGE_BIT);
		glNamedBufferStorage(visibilityBuffer, visibilityLength, null, GL_DYNAMIC_STORAGE_BIT);

		glBindBuffer(GL_ARRAY_BUFFER, instanceBuffer);

		glBindVertexArray(vaoPerVertex);
		glVertexAttribIPointer(0, 4, GL_UNSIGNED_BYTE, instanceStride, null);
		glVertexAttribIPointer(1, 1, GL_UNSIGNED_INT, instanceStride, cast(void*)4);
		glEnableVertexAttribArray(0);
		glEnableVertexAttribArray(1);

		glBindVertexArray(vaoPerInstance);
		glVertexAttribIPointer(0, 4, GL_UNSIGNED_BYTE, instanceStride, null);
		glVertexAttribIPointer(1, 1, GL_UNSIGNED_INT, instanceStride, cast(void*)4);
		glEnableVertexAttribArray(0);
		glEnableVertexAttribArray(1);
		glVertexAttribDivisor(0, 1);
		glVertexAttribDivisor(1, 1);

		glBindVertexArray(vaoPrune);
		glVertexAttribIPointer(0, 1, GL_UNSIGNED_INT, instanceStride, null);
		glVertexAttribIPointer(1, 1, GL_UNSIGNED_INT, instanceStride, cast(void*)4);
		glEnableVertexAttribArray(0);
		glEnableVertexAttribArray(1);
		glBindBuffer(GL_ARRAY_BUFFER, visibilityBuffer);
		glVertexAttribIPointer(2, 1, GL_UNSIGNED_INT, visibilityStride, null);
		glEnableVertexAttribArray(2);

		glBindVertexArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}
}
