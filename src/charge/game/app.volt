// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for App base classes.
 */
module charge.game.app;

import lib.sdl.sdl;

import charge.core;
import charge.ctl.input;
import charge.ctl.keyboard;
import charge.ctl.mouse;
import charge.gfx.target;
//import charge.sys.tracker;


abstract class App
{
public:
	Core c;
	Input input;

protected:
/+
	TimeTracker networkTime;
	TimeTracker renderTime;
	TimeTracker logicTime;
	TimeTracker inputTime;
	TimeTracker buildTime;
	TimeTracker idleTime;
+/

private:
	bool closed;

public:
	this(CoreOptions opts = null)
	{
		if (opts is null) {
			opts = new CoreOptions();
		}

		c = chargeCore(opts);

		c.setRender(doRender);
		c.setIdle(doIdle);
		c.setLogic(doLogic);
		c.setClose(close);

		input = Input.opCall();
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
		assert(closed);
	}

	void close()
	{
		closed = true;
	}

	abstract void render(Target t);
	abstract void logic();

	/**
	 * Idle is a bit missleading name, this function is always called after
	 * a frame is completed. Time is the difference between when the next
	 * logic step should happen and the current time, so it can be a
	 * negative value if we are behind (often happens when rendering
	 * takes to long to complete).
	 */
	abstract void idle(long time);


private final:
	void doLogic()
	{
/+
		logicTime.start();
		scope(exit) logicTime.stop();
+/
		logic();
	}

	void doRender()
	{
/+
		renderTime.start();
		scope(exit) renderTime.stop();
+/
		auto t = DefaultTarget.opCall();
		t.bind();
		render(t);
		// Core swaps default target.
	}

	void doIdle(long diff)
	{
/+
		idleTime.start();
		scope(exit) idleTime.stop();
+/
		idle(diff);
	}
}
