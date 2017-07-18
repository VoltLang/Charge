// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.buffers;

import charge.gfx;


/*!
 * Generates a index buffer for cubes using bitRakes' tri-strip cube.
 * Modified to fit OpenGL. Its still a bit DXy so backsides of triangles
 * are out.
 *
 *     6-------2-------3-------7
 *     |  E __/|\__ A  |  H __/|
 *     | __/   |   \__ | __/   |
 *     |/   D  |  B   \|/   I  |
 *     4-------0-------1-------5
 *             |  C __/|
 *             | __/   |  Cube = 8 vertices
 *             |/   J  |  =================
 *             4-------5  Single Strip: 3 2 1 0 4 2 6 3 7 1 5 4 7 6
 *             |\__ K  |  12 triangles:     A B C D E F G H I J K L
 *             |   \__ |
 *             |  L   \|         Left  D+E
 *             6-------7        Right  H+I
 *             |\__ G  |         Back  K+L
 *             |   \__ |        Front  A+B
 *             |  F   \|          Top  F+G
 *             2-------3       Bottom  C+J
 */
fn createIndexBuffer(numVoxels: u32) GLuint
{
	//data: u32[] = [3, 2, 1, 0, 4, 2, 6, 3, 7, 1, 5, 4, 7, 6, 6, 3+8];
	  data: u32[] = [4, 5, 6, 7, 2, 3, 3, 7, 1, 5, 5, 4+8];
	length := cast(GLsizeiptr)(data.length * numVoxels * 4);

	buffer: u32;
	glCreateBuffers(1, &buffer);
	glNamedBufferData(buffer, length, null, GL_STATIC_DRAW);
	ptr := cast(u32*)glMapNamedBuffer(buffer, GL_WRITE_ONLY);

	foreach (i; 0 .. numVoxels) {
		foreach (d; data) {
			*ptr = d + i * 8;
			ptr++;
		}
	}

	glUnmapNamedBuffer(buffer);

	return buffer;
}

/*!
 * Returns a buffer with a triangle list for drawing quads.
 *
 * They share the same last vertex index.
 * Its still a bit DXy so backsides of triangles are out.
 *
 *     6-------2-------3
 *     |  C __/|\__ B  |
 *     | __/   |   \__ |
 *     |/   D  |  A   \|
 *     4-------0-------1   Half cube = 4 vertices
 *             |  E __/|   =================
 *             | __/   |   16 indicies: 0 2 1 2 3 1 4 6 2 0 4 2 0 1 4 1 5 4
 *             |/   F  |   6 triangles:     A     B     C     D     E     F
 *             4-------5
 *
 *           2-------3
 *          /|       |
 *         / |       |
 *        6  |       |
 *        |  0-------1
 *        | /       /
 *        |/       /
 *        4-------5
 */
fn createIndexBufferQuads(numVoxels: u32) GLuint
{
	data: u32[] = [0, 2, 1, 2, 3, 1, 4, 6, 2, 0, 4, 2, 0, 1, 4, 1, 5, 4];
	length := cast(GLsizeiptr)(data.length * numVoxels * 4);

	buffer: u32;
	glCreateBuffers(1, &buffer);
	glNamedBufferData(buffer, length, null, GL_STATIC_DRAW);
	ptr := cast(u32*)glMapNamedBuffer(buffer, GL_WRITE_ONLY);

	foreach (i; 0 .. numVoxels) {
		foreach (d; data) {
			*ptr = d + i * 8;
			ptr++;
		}
	}

	glUnmapNamedBuffer(buffer);

	return buffer;
}
