// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for CommonCore.
 */
module charge.platform.core.common;

import core.exception;
import charge.core;
import charge.util.properties;


abstract class CommonCore : Core
{
protected:
/+
	// Not using mixin, because we are pretending to be Core.
	static Logger l;
+/

	Properties p;

/+
	/* run time libraries */
	Library ode;
	Library openal;
	Library alut;

	/* for sound, should be move to sfx */
	ALCdevice* alDevice;
	ALCcontext* alContext;

	bool odeLoaded; /**< did we load the ODE library */
	bool openalLoaded; /**< did we load the OpenAL library */
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

	enum phyFlags = coreFlag.PHY | coreFlag.AUTO;
	enum sfxFlags = coreFlag.SFX | coreFlag.AUTO;

	void delegate() logicDg;
	void delegate() closeDg;
	void delegate() renderDg;
	void delegate(long) idleDg;

public:
	override void setIdle(void delegate(long) dg) {
		if (dg is null) {
			idleDg = defaultIdle;
		} else {
			idleDg = dg;
		}
	}

	override void setRender(void delegate() dg) {
		if (dg is null) {
			renderDg = defaultDg;
		} else {
			renderDg = dg;
		}
	}

	override void setLogic(void delegate() dg) {
		if (dg is null) {
			logicDg = defaultDg;
		} else {
			logicDg = dg;
		}
	}

	override void setClose(void delegate() dg) {
		if (dg is null) {
			closeDg = defaultDg;
		} else {
			closeDg = dg;
		}
	}

protected:
/+
	global this()
	{
		// Pretend to be the Core class when logging.
		l = Logger(Core.classinfo);
	}
+/

	this(coreFlag flags)
	{
		super(flags);

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
			initSubSystem(coreFlag.PHY);
		}

		if (flags & sfxFlags) {
			initSubSystem(coreFlag.SFX);
		}
	}

	override void initSubSystem(coreFlag flag)
	{
		auto not = coreFlag.PHY | coreFlag.SFX;

		if (flag & ~not) {
			throw new Exception("Flag not supported");
		}

		if (flag == not) {
			throw new Exception("More then one flag not supported");
		}

/+
		if (flag & coreFlag.PHY) {
			if (phyLoaded) {
				return;
			}

			flags |= coreFlag.PHY;
			loadPhy();
			initPhy(p);

			if (phyLoaded) {
				return;
			}

			flags &= ~coreFlag.PHY;
			throw new Exception("Could not load PHY");
		}
+/

/+
		if (flag & coreFlag.SFX) {
			if (sfxLoaded) {
				return;
			}

			flags |= coreFlag.SFX;
			loadSfx();
			initSfx(p);

			if (sfxLoaded) {
				return;
			}

			flags &= ~coreFlag.SFX;
			throw new Exception("Could not load SFX");
		}
+/
	}

	void notLoaded(coreFlag mask, string name)
	{
/+
		if (flags & mask) {
			l.fatal("Could not load %s, crashing bye bye!", name);
		} else {
			l.info("%s not found, this not an error.", name);
		}
+/
	}

	Properties properties()
	{
		return p;
	}


	/*
	 *
	 * Default delegate methods.
	 *
	 */


	void defaultIdle(long)
	{
		// This method intentionally left empty.
	}

	void defaultDg()
	{
		// This method intentionally left empty.
	}


	/*
	 *
	 * Init and close functions
	 *
	 */


	void loadPhy()
	{
/+
		if (odeLoaded) {
			return;
		}

		version(DynamicODE) {
			ode = Library.loads(libODEname);
			if (ode is null) {
				notLoaded(coreFlag.PHY, "ODE");
			} else {
				loadODE(&ode.symbol);
				odeLoaded = true;
			}
		} else {
			odeLoaded = true;
		}
+/
	}

	void loadSfx()
	{
/+
		if (openalLoaded) {
			return;
		}

		openal = Library.loads(libOpenALname);
		alut = Library.loads(libALUTname);

		if (!openal) {
			notLoaded(coreFlag.SFX, "OpenAL");
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

	void initSettings()
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

	void saveSettings()
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

	void initPhy(Properties p)
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

	void closePhy()
	{
/+
		if (!phyLoaded) {
			return;
		}

		dCloseODE();

		phyLoaded = false;
+/
	}

	void initSfx(Properties p)
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

	void closeSfx()
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
