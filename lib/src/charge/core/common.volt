// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for CommonCore.
 */
module charge.core.common;

import core.exception;
import charge.core;
import charge.util.properties;
import charge.sys.timetracker;


abstract class CommonCore : Core
{
protected:
/+
	// Not using mixin, because we are pretending to be Core.
	static Logger l;
+/

	p: Properties;

/+
	/* run time libraries */
	Library ode;
	Library openal;
	Library alut;

	/* for sound, should be move to sfx */
	ALCdevice* alDevice;
	ALCcontext* alContext;

	bool odeLoaded; /*!< did we load the ODE library */
	bool openalLoaded; /*!< did we load the OpenAL library */
+/

	/* name of libraries to load */
/+
	version (Windows) {
		enum string[] libODEname = ["ode.dll"];
		enum string[] libOpenALname = ["OpenAL32.dll"];
		enum string[] libALUTname = ["alut.dll"];
	} else version (Linux) {
		enum string[] libODEname = ["libode.so"];
		enum string[] libOpenALname = ["libopenal.so", "libopenal.so.1"];
		enum string[] libALUTname = ["libalut.so"];
	} else version (OSX) {
		enum string[] libODEname = ["./libode.dylib"];
		enum string[] libOpenALname = ["OpenAL.framework/OpenAL"];
		enum string[] libALUTname = ["./libalut.dylib"];
	}
+/

	enum phyFlags = Flag.PHY | Flag.AUTO;
	enum sfxFlags = Flag.SFX | Flag.AUTO;

	logicDg: dg();
	closeDg: dg();
	renderDg: dg();
	idleDg: dg(long);

	// Used for looping.
	mRunning: bool;
	mSleepTime: TimeTracker;


public:
	override fn loop() i32
	{
		now: long = getTicks();
		step: long = 10;
		where: long = now;
		last: long = now;
		changed: bool;

		while (mRunning) {
			now = getTicks();

			doInput();

			while (where < now) {
				doInput();

				logicDg();

				where = where + step;
				changed = true;
			}

			if (!mRunning) {
				break;
			}

			if (changed) {
				doRenderAndSwap();
				changed = false;
			}

			diff := (step + where) - now;
			idleDg(diff);

			diff = (step + where) - getTicks();
			if (diff > 0) {
				mSleepTime.start();
				doSleep(diff);
				mSleepTime.stop();
			}
		}

		doClose();

		return 0;
	}

	override fn setIdle(dgt: dg(long)) {
		if (dgt is null) {
			idleDg = defaultIdle;
		} else {
			idleDg = dgt;
		}
	}

	override fn setRender(dgt: dg()) {
		if (dgt is null) {
			renderDg = defaultDg;
		} else {
			renderDg = dgt;
		}
	}

	override fn setLogic(dgt: dg()) {
		if (dgt is null) {
			logicDg = defaultDg;
		} else {
			logicDg = dgt;
		}
	}

	override fn setClose(dgt: dg()) {
		if (dgt is null) {
			closeDg = defaultDg;
		} else {
			closeDg = dgt;
		}
	}

	override fn initSubSystem(flag: Flag)
	{
		not := Flag.PHY | Flag.SFX;

		if (flag & ~not) {
			throw new Exception("Flag not supported");
		}

		if (flag == not) {
			throw new Exception("More then one flag not supported");
		}

/+
		if (flag & Flag.PHY) {
			if (phyLoaded) {
				return;
			}

			flags |= Flag.PHY;
			loadPhy();
			initPhy(p);

			if (phyLoaded) {
				return;
			}

			flags &= ~Flag.PHY;
			throw new Exception("Could not load PHY");
		}
+/

/+
		if (flag & Flag.SFX) {
			if (sfxLoaded) {
				return;
			}

			flags |= Flag.SFX;
			loadSfx();
			initSfx(p);

			if (sfxLoaded) {
				return;
			}

			flags &= ~Flag.SFX;
			throw new Exception("Could not load SFX");
		}
+/
	}


protected:
	this(Flag flags)
	{
		super(flags);
		this.mRunning = true;
		this.mSleepTime = new TimeTracker("sleep");

		setRender(null);
		setLogic(null);
		setClose(null);
		setIdle(null);

		initSettings();

/+
		resizeSupported = p.getBool("forceResizeEnable", defaultForceResizeEnable);
+/
		// Init sub system
		if (flags & phyFlags) {
			initSubSystem(Flag.PHY);
		}

		if (flags & sfxFlags) {
			initSubSystem(Flag.SFX);
		}
	}


	/*
	 *
	 * Common loop functions.
	 *
	 */

	abstract fn getTicks() long;
	abstract fn doInput();
	abstract fn doRenderAndSwap();
	abstract fn doSleep(diff: long);
	abstract fn doClose();


	/*
	 *
	 * Other helpers.
	 *
	 */

	fn notLoaded(mask: Flag, name: string)
	{
/+
		if (flags & mask) {
			l.fatal("Could not load %s, crashing bye bye!", name);
		} else {
			l.info("%s not found, this not an error.", name);
		}
+/
	}


	/*
	 *
	 * Default delegate methods.
	 *
	 */


	fn defaultIdle(long)
	{
		// This method intentionally left empty.
	}

	fn defaultDg()
	{
		// This method intentionally left empty.
	}


	/*
	 *
	 * Init and close functions
	 *
	 */


	fn loadPhy()
	{
/+
		if (odeLoaded) {
			return;
		}

		version(DynamicODE) {
			ode = Library.loads(libODEname);
			if (ode is null) {
				notLoaded(Flag.PHY, "ODE");
			} else {
				loadODE(&ode.symbol);
				odeLoaded = true;
			}
		} else {
			odeLoaded = true;
		}
+/
	}

	fn loadSfx()
	{
/+
		if (openalLoaded) {
			return;
		}

		openal = Library.loads(libOpenALname);
		alut = Library.loads(libALUTname);

		if (!openal) {
			notLoaded(Flag.SFX, "OpenAL");
		} else {
			openalLoaded = true;
			loadAL(&openal.symbol);
		}

		if (!alut)
			l.info("ALUT not found, this is not an error.");
		else
			loadALUT(&alut.symbol);
+/
	}

	fn initSettings()
	{
/+
		settingsFile = chargeConfigFolder ~ "/settings.ini";
		p = Properties(settingsFile);

		if (p is null) {
			l.warn("Failed to load settings useing defaults");

			p = new Properties;
		} else {
			l.info("Settings loaded: %s", settingsFile);
		}

		p.addIfNotSet("w", defaultWidth);
		p.addIfNotSet("h", defaultHeight);
		p.addIfNotSet("fullscreen", defaultFullscreen);
		p.addIfNotSet("fullscreenAutoSize", defaultFullscreenAutoSize);
		p.addIfNotSet("forceResizeEnable", defaultForceResizeEnable);
+/
	}

	fn saveSettings()
	{
/+
		auto ret = p.save(settingsFile);
		if (ret) {
			l.info("Settings saved: %s", settingsFile);
		} else {
			l.error("Failed to save settings file %s", settingsFile);
		}
+/
	}

	/*
	 *
	 * Init and close functions for subsystems
	 *
	 */

	fn initPhy()
	{
/+
		if (!odeLoaded) {
			return;
		}

		dInitODE2(0);
		dAllocateODEDataForThread(dAllocateMaskAll);

		phyLoaded = true;
+/
	}

	fn closePhy()
	{
/+
		if (!phyLoaded) {
			return;
		}

		dCloseODE();

		phyLoaded = false;
+/
	}

	fn initSfx()
	{
/+
		if (!openalLoaded) {
			return;
		}

		alDevice = alcOpenDevice(null);

		if (alDevice) {
			alContext = alcCreateContext(alDevice, null);
			alcMakeContextCurrent(alContext);

			sfxLoaded = true;
		}
+/
	}

	fn closeSfx()
	{
/+
		if (!openalLoaded) {
			return;
		}

		if (alContext) {
			alcDestroyContext(alContext);
		}
		if (alDevice) {
			alcCloseDevice(alDevice);
		}

		sfxLoaded = false;
+/
	}
}