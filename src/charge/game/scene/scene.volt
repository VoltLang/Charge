// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Scene base class and SceneManager interface.
 */
module charge.game.scene.scene;

import charge.gfx.target;


/**
 * A scene often is a level, menu overlay or a loading screen.
 */
abstract class Scene
{
public:
	enum Flag {
		TakesInput    = 0x01,
		Transparent   = 0x02,
		Blocker       = 0x04,
		AlwaysOnTop   = 0x08,
	}

	enum Type {
		Background = 0,
		Game = Flag.TakesInput | Flag.Blocker,
		Menu = Flag.TakesInput | Flag.Transparent,
		Overlay = Flag.AlwaysOnTop | Flag.Transparent,
	}

	Flag flags;

protected:
	SceneManager mManager;

public:
	this(SceneManager sm, Type type)
	{
		this.mManager = sm;
		this.flags = cast(Flag)type;
	}

	/**
	 * Step the game logic one step.
	 */
	abstract void logic();

	/**
	 * Render view of this scene into target.
	 */
	abstract void render(Target t);

	/**
	 * Install all input listeners.
	 */
	abstract void assumeControl();

	/**
	 * Uninstall all input listeners.
	 */
	abstract void dropControl();

	/**
	 * Shutdown this scene, this is called by the SceneManager.
	 *
	 * And should not be called by other code.
	 */
	abstract void close();
}

/**
 * A interface back to the main controller, often the main game loop.
 */
interface SceneManager
{
public:
	/**
	 * Push this scene to top of the stack.
	 */
	void push(Scene r);

	/**
	 * Remove this scene from the stack.
	 */
	void remove(Scene r);

	/**
	 * The given scene wants to be deleted.
	 */
	void closeMe(Scene r);

/+
	/**
	 * Add a callback to be run on idle time.
	 */
	void addBuilder(bool delegate() dg);

	/**
	 * Remove a builder callback.
	 */
	void removeBuilder(bool delegate() dg);
+/
}
