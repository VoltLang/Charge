// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver 1.0).
/**
 * Source file for main Input processing and interface.
 */
module charge.ctl.input;

import watt.text.utf;

import lib.sdl.sdl;

//import charge.math.ints;
//import charge.util.signal;
//import charge.sys.logger;

import charge.ctl.device;
import charge.ctl.mouse;
import charge.ctl.keyboard;
import charge.ctl.joystick;


class Input
{
private:
/+
	mixin Logging;
+/

	global Input instance;
	Mouse[] mouseArray;
	Keyboard[] keyboardArray;
	Joystick[] joystickArray;

public:
/+
	Signal!(Device) hotplug;
	Signal!(uint, uint) resize;
	Signal!() quit;
+/

public:
	global Input opCall()
	{
		if (instance is null) {
			instance = new Input();
		}

		return instance;
	}

	Mouse mouse()
	{
		return mouseArray[0];
	}

	Keyboard keyboard()
	{
		return keyboardArray[0];
	}

	Joystick joystick()
	{
		return joystickArray[0];
	}

	Mouse[] mice()
	{
		return new mouseArray[0 .. $];
	}

	Keyboard[] keyboards()
	{
		return new keyboardArray[0 .. $];
	}

	Joystick[] joysticks()
	{
		return new joystickArray[0 .. $];
	}


	void tick()
	{
		SDL_Event e;

		SDL_JoystickUpdate();

		while(SDL_PollEvent(&e)) {
			switch (e.type) {
			case SDL_QUIT:
/+
				quit();
+/
				break;

			case SDL_VIDEORESIZE:
/+
				resize(cast(uint)e.resize.w, cast(uint)e.resize.h);
+/
				break;

			case SDL_JOYBUTTONDOWN:
				auto j = joystickArray[e.jbutton.which];
/+
				j.down(j, e.jbutton.button);
+/
				break;

			case SDL_JOYBUTTONUP:
				auto j = joystickArray[e.jbutton.which];
/+
				j.up(j, e.jbutton.button);
+/
				break;

			case SDL_JOYAXISMOTION:
				auto j = joystickArray[e.jbutton.which];
				j.handleAxis(e.jaxis.axis, e.jaxis.value);
				break;

			case SDL_KEYDOWN:
				size_t len;
				char[8] tmp;

				dchar unicode = e.key.keysym.unicode;

				auto k = keyboardArray[0];
				k.mod = e.key.keysym.mod;



				if (unicode == 27) {
					unicode = 0;
				}

				void sink(scope(char)[] t) {
					tmp[0 .. t.length] = t;
					len = t.length;
				}
				if (unicode) {
					encode(sink, unicode);
				}
/+
				k.down(k, e.key.keysym.sym, unicode, str);
+/
				break;

			case SDL_KEYUP:
				auto k = keyboardArray[0];
				k.mod = e.key.keysym.mod;
/+
				k.up(k, e.key.keysym.sym);
+/
				break;

			case SDL_MOUSEMOTION:
				auto m = mouseArray[0];
				m.state = cast(int)e.motion.state;
				m.x = cast(int)e.motion.x;
				m.y = cast(int)e.motion.y;
/+
				m.move(m, e.motion.xrel, e.motion.yrel);
+/
				break;

			case SDL_MOUSEBUTTONDOWN:
				auto m = mouseArray[0];
				m.state |= (1 << e.button.button);
				m.x = e.button.x;
				m.y = e.button.y;
/+
				m.down(m, e.button.button);
+/
				break;

			case SDL_MOUSEBUTTONUP:
				auto m = mouseArray[0];
				m.state = ~(1 << e.button.button) & m.state;
				m.x = e.button.x;
				m.y = e.button.y;
/+
				m.up(m, e.button.button);
+/
				break;

			default:
				break;
			}
		}
	}

private:
	this()
	{
		keyboardArray ~= new Keyboard();
		mouseArray ~= new Mouse();

		// Small hack to allow hotplug.
		auto num = SDL_NumJoysticks();
		if (num < 8) {
			num = 8;
		}

		joystickArray = new Joystick[](num);
		for (int i; i < num; i++) {
			joystickArray[i] = new Joystick(i);
		}
	}

	~this()
	{
/+
		hotplug.destruct();
		resize.destruct();
		quit.destruct();
+/
	}
}
