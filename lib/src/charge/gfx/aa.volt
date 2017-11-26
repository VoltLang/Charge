// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.gfx.aa;

import charge.gfx.target;
import charge.gfx.timetracker;


struct AA
{
public:
	enum Kind
	{
		None,
		Double,
		MSAA4,
		MSAA8,
		MSAA16,
	}


public:
	tl: TimeTracker;
	fbo: Target;
	kind: Kind;
	currentMSAA: u32;


public:
	fn close()
	{
		reference(ref fbo, null);
	}

	fn toggle()
	{
		kind++;
		if (kind > Kind.MSAA16) {
			kind = Kind.None;
		}
	}

	fn getName() string
	{
		final switch (kind) with (Kind) {
		case None: return "none";
		case Double: return "2x";
		case MSAA4: return "msaa4";
		case MSAA8: return "msaa8";
		case MSAA16: return "msaa16";
		}
	}

	fn bind(t: Target)
	{
		setupFramebuffer(t);
		if (t !is fbo) {
			fbo.bind(t);
		}
	}

	fn resolveToAndBind(t: Target)
	{
		if (t !is fbo) {
			tl.start();
			t.bindAndCopyFrom(fbo);
			tl.stop();
		}
	}

	fn setupFramebuffer(t: Target)
	{
		msaa: u32;
		factor: u32;

		final switch (kind) with (Kind) {
		case None: factor = 1; msaa = 0; break;
		case Double: factor = 2; msaa = 0; break;
		case MSAA4: factor = 1; msaa = 4; break;
		case MSAA8: factor = 1; msaa = 8; break;
		case MSAA16: factor = 1; msaa = 16; break;
		}

		width := t.width * factor;
		height := t.height * factor;

		if (fbo !is null &&
		    msaa == currentMSAA &&
		    width == fbo.width &&
		    height == fbo.height) {
			return;
		}

		if (tl is null) {
			tl = new TimeTracker("aa");
		}

		currentMSAA = msaa;

		if (msaa != 0) {
			reference(ref fbo, null);
			fbo = FramebufferMSAA.make("power/exp/fbo", width, height, msaa);
		} else if (width == t.width && height == t.height) {
			reference(ref fbo, t);
		} else {
			reference(ref fbo, null);
			fbo = Framebuffer.make("power/exp/fbo", width, height);
		}
	}
}
