// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for App base classes.
 */
module charge.game.app;

import core = charge.core;
import sys = charge.sys;
import ctl = charge.ctl;
import gfx = charge.gfx;

import charge.gfx.gl;


abstract class App
{
protected:
	mCore: core.Core;
	mInput: ctl.Input;

	// Gfx timers
	mFrameTime: gfx.TimeTracker;

	// Sys timers
	mRenderTime: sys.TimeTracker;
	mLogicTime: sys.TimeTracker;
	mBuildTime: sys.TimeTracker;
	mIdleTime: sys.TimeTracker;


private:
	mClosed: bool;


public:
	this(core.Options opts = null)
	{
		if (opts is null) {
			opts = new core.Options();
		}

		// Gfx timers
		mFrameTime = new gfx.TimeTracker("frame");

		// Sys timers
		mRenderTime = new sys.TimeTracker("gfx");
		mLogicTime = new sys.TimeTracker("logic");
		mBuildTime = new sys.TimeTracker("build");
		mIdleTime = new sys.TimeTracker("idle");

		mCore = core.start(opts);
		mCore.setRender(doRender);
		mCore.setIdle(doIdle);
		mCore.setLogic(doLogic);
		mCore.setClose(close);

		mInput = ctl.Input.opCall();
	}

	~this()
	{
		assert(mClosed);
	}

	/*!
	 * Called by the core when it is shutting down.
	 */
	fn close()
	{
		mClosed = true;
	}

	/*!
	 * Simple function that dispatches to the charge core.
	 */
	final fn loop() i32
	{
		return mCore.loop();
	}

	/*!
	 * Called every frame.
	 */
	abstract fn render(t: gfx.Target, ref viewInfo: gfx.ViewInfo);

	/*!
	 * Called every logic step.
	 */
	abstract fn logic();

	/*!
	 * Idle is a bit missleading name, this function is always called after
	 * a frame is completed. Time is the difference between when the next
	 * logic step should happen and the current time, so it can be a
	 * negative value if we are behind (often happens when rendering
	 * takes to long to complete).
	 */
	abstract fn idle(time: long);


private:
	fn doLogic()
	{
		mLogicTime.start();
		scope(exit) mLogicTime.stop();

		logic();
	}

	fn doRender()
	{
		mRenderTime.start();
		mFrameTime.startFrame();
		scope(exit) {
			mFrameTime.endFrame();
			mRenderTime.stop();
		}

		t := gfx.DefaultTarget.opCall();
		t.bindDefault();

		// Only info we have is that it's suitable for ortho.
		viewInfo: gfx.ViewInfo;
		viewInfo.suitableForOrtho = true;

		render(t, ref viewInfo);

		// Core swaps default target.
	}

	fn doIdle(diff: long)
	{
		mIdleTime.start();
		scope(exit) mIdleTime.stop();

		idle(diff);
	}
}
