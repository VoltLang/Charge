// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Include everything from gfx.
 */
module charge.gfx;

public import charge.gfx.gl;
public import charge.gfx.gfx : gfxLoaded;
public import charge.gfx.aa :
	GfxAA = AA;
public import charge.gfx.draw :
	GfxDrawBuffer = DrawBuffer, GfxDrawVertex = DrawVertex,
	GfxDrawVertexBuilder = DrawVertexBuilder, gfxDrawShader = drawShader;
public import charge.gfx.buffer :
	GfxBuffer = Buffer, GfxBuilder = Builder,
	GfxIndirectData = IndirectData, GfxIndirectBuffer = IndirectBuffer;
public import charge.gfx.shader :
	GfxShader = Shader;
public import charge.gfx.target :
	GfxTarget = Target, GfxFramebuffer = Framebuffer;
public import charge.gfx.texture : 
	GfxTexture = Texture, GfxTexture2D = Texture2D;
public import charge.gfx.bitmapfont :
	GfxBitmapState = BitmapState, gfxBuildVertices = buildVertices,
	gfxBitmapTexture = bitmapTexture;
