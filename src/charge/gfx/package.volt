// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Include everything from gfx.
 */
module charge.gfx;

public import charge.gfx.gl;
public import charge.gfx.gfx : gfxLoaded;
public import charge.gfx.aa :
	GfxAA = AA;
public import charge.gfx.draw :
	gfxDestroy = destroy,
	gfxReference = reference,
	GfxDrawBuffer = DrawBuffer,
	GfxDrawVertex = DrawVertex,
	GfxDrawVertexBuilder = DrawVertexBuilder,
	gfxDrawShader = drawShader,
	gfxDrawSamplerLinear = drawSamplerLinear,
	gfxDrawSamplerNearest = drawSamplerNearest;
public import charge.gfx.buffer :
	gfxDestroy = destroy,
	gfxReference = reference,
	GfxBuffer = Buffer,
	GfxBuilder = Builder,
	GfxIndirectData = IndirectData,
	GfxIndirectBuffer = IndirectBuffer;
public import charge.gfx.shader :
	gfxDestroy = destroy,
	GfxShader = Shader;
public import charge.gfx.target :
	gfxReference = reference,
	GfxTarget = Target,
	GfxDefaultTarget = DefaultTarget,
	GfxFramebuffer = Framebuffer,
	GfxFramebufferMSAA = FramebufferMSAA;
public import charge.gfx.texture :
	gfxReference = reference,
	GfxTexture = Texture,
	GfxTexture2D = Texture2D;
public import charge.gfx.timer :
	GfxTimer = Timer;
public import charge.gfx.bitmapfont :
	GfxBitmapState = BitmapState,
	GfxBitmapGlyphWidth = GlyphWidth,
	GfxBitmapGlyphHeight = GlyphHeight,
	gfxBuildVertices = buildVertices,
	gfxBitmapTexture = bitmapTexture;
public import charge.gfx.sync :
	GfxSync = Sync;
public import charge.gfx.counters :
	gfxDestroy = destroy,
	GfxCounters = Counters;
public import charge.gfx.helpers :
	GfxTextureBlitter = TextureBlitter,
	GfxFramebufferResizer = FramebufferResizer;
