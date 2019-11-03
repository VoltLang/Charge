// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for misc gfx things.
 */
module charge.gfx.gfx;


/*!
 * Has gfx been loaded.
 */
global gfxLoaded: bool;

/*!
 * Cached information about the current rendderer, set at init by the core.
 */
global gfxRendererInfo: RendererInfo;

/*!
 * Holds information about a renderer, this derived from looking at extensions
 * and various string that the rendering API exposes.
 */
struct RendererInfo
{
	glVendor, glVersion, glRenderer: string;
	isGL, isAMD, isNVIDIA, isINTEL, isMESA, isConfidentInDetection: bool;
}
