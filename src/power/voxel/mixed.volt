// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.voxel.mixed;

import charge.gfx.gl;

import voxel.svo;


class Mixed : Pipeline
{
public:
	alias CreateInput = Create;
	alias DrawInput = Draw;


public:
	this(octTexture: GLuint, ref create: Create)
	{
		super(octTexture, ref create, Pipeline.Kind.Raycube);
	}
}
