// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for App base classes.
 */
module charge.game.app;

import charge.core;
import charge.ctl;
import gfx = charge.gfx;


abstract class App
{
protected:
	mCore: Core;
	mInput: CtlInput;
/+
	networkTime: TimeTracker;
	renderTime: TimeTracker;
	logicTime: TimeTracker;
	inputTime: TimeTracker;
	buildTime: TimeTracker;
	idleTime: TimeTracker;
+/

private:
	mClosed: bool;


public:
	this(CoreOptions opts = null)
	{
		if (opts is null) {
			opts = new CoreOptions();
		}

		mCore = chargeCore(opts);
		mCore.setRender(doRender);
		mCore.setIdle(doIdle);
		mCore.setLogic(doLogic);
		mCore.setClose(close);

		mInput = CtlInput.opCall();
/+
		renderTime = new TimeTracker("gfx");
		inputTime = new TimeTracker("ctl");
		logicTime = new TimeTracker("logic");
		buildTime = new TimeTracker("build");
		idleTime = new TimeTracker("idle");
+/
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


private final:
	fn doLogic()
	{
/+
		logicTime.start();
		scope(exit) logicTime.stop();
+/
		logic();
	}

	fn doRender()
	{
/+
		renderTime.start();
		scope(exit) renderTime.stop();
+/
		t := gfx.DefaultTarget.opCall();
		t.bindDefault();
		render(t);
		// Core swaps default target.
	}

	fn doIdle(diff: long)
	{
/+
		idleTime.start();
		scope(exit) idleTime.stop();
+/
		idle(diff);
	}
}
