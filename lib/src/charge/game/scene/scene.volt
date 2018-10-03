// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for Scene base class and Manager interface.
 */
module charge.game.scene.scene;

import gfx = charge.gfx;


/*!
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

	flags: Flag;


protected:
	mManager: Manager;


public:
	this(m: Manager, type: Type)
	{
		this.mManager = m;
		this.flags = cast(Flag)type;
	}

	/*!
	 * Step the game logic one step.
	 */
	abstract fn logic();

	/*!
	 * Render view of this scene into target.
	 */
	abstract fn render(gfx.Target);

	/*!
	 * Install all input listeners.
	 */
	abstract fn assumeControl();

	/*!
	 * Uninstall all input listeners.
	 */
	abstract fn dropControl();

	/*!
	 * Shutdown this scene, this is called by the Manager.
	 *
	 * And should not be called by other code.
	 */
	abstract fn close();
}

/*!
 * A interface back to the main controller, often the main game loop.
 */
interface Manager
{
public:
	/*!
	 * Push this scene to top of the stack.
	 */
	fn push(Scene);

	/*!
	 * Remove this scene from the stack.
	 */
	fn remove(Scene);

	/*!
	 * The given scene wants to be deleted.
	 */
	fn closeMe(Scene);

/+
	/*!
	 * Add a callback to be run on idle time.
	 */
	fn addBuilder(dgt dg() bool);

	/*!
	 * Remove a builder callback.
	 */
	fn removeBuilder(dgt dg() bool);
+/
}