// Copyright 2011-2019, Jakob Bornecrantz.
// Copyright 2019-2022, Collabora, Ltd.
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

		this(core.start(opts));
	}

	this(core: core.Core)
	{
		// First
		mCore = core;

		// Gfx timers
		mFrameTime = new gfx.TimeTracker("frame");

		// Sys timers
		mLogicTime = new sys.TimeTracker("logic");
		mRenderTime = new sys.TimeTracker("gfx");
		mBuildTime = new sys.TimeTracker("build");
		mIdleTime = new sys.TimeTracker("idle");

		mCore.setClose(close);
		mCore.setUpdateActions(updateActions);
		mCore.setLogic(doLogic);
		mCore.setRenderPrepare(doRenderPrepare);
		mCore.setRenderView(doRenderView);
		mCore.setIdle(doIdle);

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
	 * Called every time actions should be updated, timepoint given is when
	 * next frame is to be displayed.
	 */
	abstract fn updateActions(timepoint: i64);

	/*!
	 * Called every logic step.
	 */
	abstract fn logic();

	/*!
	 * Called berfore renderView, multiple renderViews
	 * can be called per renderPrepare.
	 */
	abstract fn renderPrepare();

	/*!
	 * Called every frame.
	 */
	abstract fn renderView(t: gfx.Target, ref viewInfo: gfx.ViewInfo);

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

	fn doRenderPrepare()
	{
		renderPrepare();
	}

	fn doRenderView(t: gfx.Target, ref viewInfo: gfx.ViewInfo)
	{
		mRenderTime.start();
		mFrameTime.startFrame();
		scope(exit) {
			mFrameTime.endFrame();
			mRenderTime.stop();
		}

		renderView(t, ref viewInfo);

		// Core swaps target.
	}

	fn doIdle(diff: long)
	{
		mIdleTime.start();
		scope(exit) mIdleTime.stop();

		idle(diff);
	}
}
