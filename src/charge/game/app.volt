// Copyright © 2011-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for App base classes.
 */
module charge.game.app;

import core = charge.core;
import sys = charge.sys;
import ctl = charge.ctl;
import gfx = charge.gfx;


abstract class App
{
protected:
	mCore: core.Core;
	mInput: ctl.Input;

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

	fn close()
	{
		mClosed = true;
	}

	final fn loop() i32
	{
		return mCore.loop();
	}

	abstract fn render(t: gfx.Target);
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
		scope(exit) mRenderTime.stop();

		t := gfx.DefaultTarget.opCall();
		t.bindDefault();
		render(t);
		// Core swaps default target.
	}

	fn doIdle(diff: long)
	{
		mIdleTime.start();
		scope(exit) mIdleTime.stop();

		idle(diff);
	}
}
