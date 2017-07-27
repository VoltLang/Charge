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
		    (t.width * 2) == fbo.width &&
		    (t.height * 2) == fbo.height) {
			return;
		}

		if (fbo !is null) { fbo.decRef(); fbo = null; }
		fbo = Framebuffer.make("power/exp/fbo", t.width * 2, t.height * 2);
	}
}
