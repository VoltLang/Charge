// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.gfx.aa;

import charge.gfx.target;


struct AA
{
public:
	fbo: Framebuffer;


public:
	fn breakApart()
	{
		if (fbo !is null) { fbo.decRef(); fbo = null; }
	}

	fn bind(t: Target)
	{
		setupFramebuffer(t);
		fbo.bind(t);
	}

	fn resolveToAndBind(t: Target)
	{
		t.bindAndCopyFrom(fbo);
	}

	fn setupFramebuffer(t: Target)
	{
		if (fbo !is null &&
		    t.width == fbo.width &&
		    t.height == fbo.height) {
			return;
		}

		if (fbo !is null) { fbo.decRef(); fbo = null; }
		fbo = FramebufferMSAA.make("power/exp/fbo", t.width, t.height, 8);
	}
}
