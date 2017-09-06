// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.gfx.aa;

import charge.gfx.target;


struct AA
{
public:
	enum Kind
	{
		Invalid,
		Double,
		MSAA8,
	}

	enum DefaultKind = Kind.MSAA8;

public:
	fbo: Framebuffer;
	kind: Kind;
	currentMSAA: u32;


public:
	fn close()
	{
		reference(ref fbo, null);
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
		msaa: u32;
		factor: u32;

		final switch (kind) with (Kind) {
		case Invalid:
			kind = DefaultKind;
			goto case DefaultKind;
		case Double: factor = 2; break;
		case MSAA8: factor = 1; msaa = 8; break;
		}

		width := t.width * factor;
		height := t.height * factor;

		if (fbo !is null &&
		    msaa == currentMSAA &&
		    width == fbo.width &&
		    height == fbo.height) {
			return;
		}

		reference(ref fbo, null);
		currentMSAA = msaa;

		if (msaa == 0) {
			fbo = Framebuffer.make("power/exp/fbo", width, height);
		} else {
			fbo = FramebufferMSAA.make("power/exp/fbo", width, height, msaa);
		}
	}
}
