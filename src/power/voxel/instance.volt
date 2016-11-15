// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.voxel.instance;

import charge.sys.resource;
import charge.gfx;


struct InstanceData
{
	uint position, offset;
}

/**
 * VBO with no per vertex data but instead per instance data.
 */
class InstanceBuffer : GfxBuffer
{
public:
	GLsizei num;

public:
	global InstanceBuffer make(string name, GLsizei num, size_t instances)
	{
		void* dummy;
		auto buffer = cast(InstanceBuffer)Resource.alloc(
			typeid(InstanceBuffer), uri, name, 0, out dummy);
		buffer.__ctor(num, instances);
		return buffer;
	}

protected:
	this(GLsizei num, size_t instances)
	{
		super(0, 0);
		this.num = num;

		// Setup instance buffer and upload the data.
		glCreateBuffers(1, &buf);
		glCreateVertexArrays(1, &vao);

		// And the darkness bind them.
		glBindVertexArray(vao);

		glBindBuffer(GL_ARRAY_BUFFER, buf);

		instanceStride := cast(GLsizei)typeid(InstanceData).size;
		instancesLength := cast(GLsizei)instances * instanceStride;
		glBindBuffer(GL_ARRAY_BUFFER, buf);
		glBufferData(GL_ARRAY_BUFFER, cast(GLsizeiptr)instancesLength, null, GL_STATIC_DRAW);

		glVertexAttribIPointer(0, 4, GL_UNSIGNED_BYTE, instanceStride, null);
		glVertexAttribIPointer(1, 1, GL_UNSIGNED_INT, instanceStride, cast(void*)4);
		glVertexAttribDivisor(0, 1);
		glVertexAttribDivisor(1, 1);
		glEnableVertexAttribArray(0);
		glEnableVertexAttribArray(1);

		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindVertexArray(0);
	}
}
