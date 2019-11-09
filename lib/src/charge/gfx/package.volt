// Copyright 2016-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Include everything from gfx.
 *
 * @ingroup gfx
 */
module charge.gfx;

/*!
 * @defgroup gfx Graphics
 * @brief Graphics helper code, based on OpenGL.
 */

public import charge.gfx.gl;
public import charge.gfx.gfx : gfxLoaded;
public import charge.gfx.aa :
	AA;
public import charge.gfx.draw :
	destroy,
	reference,
	drawShader,
	drawSamplerLinear,
	drawSamplerNearest,
	DrawBuffer,
	DrawVertex,
	DrawVertexBuilder;
public import charge.gfx.buffer :
	destroy,
	reference,
	Buffer,
	Builder,
	IndirectData,
	IndirectBuffer;
public import charge.gfx.shader :
	destroy,
	Shader;
public import charge.gfx.simple :
	destroy,
	reference,
	simpleShader,
	SimpleBuffer,
	SimpleVertex,
	SimpleVertexBuilder;
public import charge.gfx.compiler :
	Src,
	CompSrc,
	VertSrc,
	GeomSrc,
	FragSrc,
	Compiler;
public import charge.gfx.target :
	reference,
	Target,
	DefaultTarget,
	Framebuffer,
	FramebufferMSAA;
public import charge.gfx.texture :
	reference,
	Texture,
	Texture2D;
public import charge.gfx.timer :
	Timer;
public import charge.gfx.timetracker :
	TimeTracker;
public import charge.gfx.bitmapfont :
	BitmapState,
	BitmapGlyphWidth = GlyphWidth,
	BitmapGlyphHeight = GlyphHeight,
	buildVertices,
	bitmapTexture;
public import charge.gfx.sync :
	Sync;
public import charge.gfx.counters :
	destroy,
	Counters;
public import charge.gfx.helpers :
	TextureBlitter,
	FramebufferResizer;
