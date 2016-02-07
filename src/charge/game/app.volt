// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for App base classes.
 */
module charge.game.app;

import lib.sdl.sdl;

//import charge.util.vector;
import charge.core;
import charge.ctl.input;
import charge.ctl.keyboard;
import charge.ctl.mouse;
//import charge.gfx.gfx;
//import charge.gfx.sync;
//import charge.gfx.target;
//import charge.sys.tracker;
//import charge.sys.resource;


abstract class App
{
protected:
	Core c;
	Input input;

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

	abstract void render();
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
		render();
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
