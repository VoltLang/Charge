// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for SceneManagerApp base classes.
 */
module charge.game.scene.app;

import charge.core : CoreOptions, chargeQuit;

import charge.game.app;
import charge.game.scene.scene;


/**
 * Base class for games wishing to use Scenes, implements
 * most if not all needed SceneManager functions needed.
 */
abstract class SceneManagerApp : App, SceneManager
{
private:
	Scene[] vec;
	Scene[] del;
	Scene currentInput;

	bool dirty; //< Do we need to manage scenes.
	bool built; //< Have we built this logic pass.

	alias BuilderDg = bool delegate();
	BuilderDg[] builders;

public:
	this(CoreOptions opts = null)
	{
		super(opts);
	}

	~this()
	{
		assert(vec.length == 0);
		assert(del.length == 0);
		assert(builders.length == 0);
		assert(currentInput is null);
	}


	/*
	 *
	 * App functions
	 *
	 */

	override void close()
	{
		closeAll();
		while (vec.length || del.length) {
			closeAll();
			manageScenes();
		}

		super.close();
	}

	override void render()
	{
		//auto rt = DefaultTarget();

		size_t i = vec.length;
		foreach_reverse(r; vec) {
			i--;
			if (r.flags & Scene.Flag.Blocker) {
				break;
			}
		}

		for (; i < vec.length; i++) {
			vec[i].render();
		}

		//rt.swap();
	}

	override void logic()
	{
		// This make sure we at least call
		// the builders once per frame.
		built = false;

		manageScenes();

		foreach_reverse (r; vec) {
			r.logic();

			if (r.flags & Scene.Flag.Blocker) {
				break;
			}
		}
	}

	override void idle(long time)
	{
		// If we have built at least once this frame and have
		// very little time left don't build again. But we
		// always build one each frame.
		if (built && time < 5 || builders.length == 0) {
			return;
		}

		// Account this time for build instead of idle
/+
		buildTime.start();
+/

		// Need to reset each idle check
		built = false;

		// Do the build
		foreach (b; builders) {
			built = b() || built;
		}

		// Delete unused resources
		//charge.sys.resource.Pool().collect();

		// Switch back to idle
/+
		buildTime.stop();
+/
	}


	/*
	 *
	 * Router functions.
	 *
	 */

	override void push(Scene r)
	{
		assert(r !is null);

		// Remove and then reinsert the scene on top.
		remove(r);
		dirty = true;

		if (r.flags & Scene.Flag.AlwaysOnTop) {
			vec ~= r;
			return;
		}

		int i = cast(int)vec.length;
		for(--i; (i >= 0) && (vec[i].flags & Scene.Flag.AlwaysOnTop); i--) { }
		// should be placed after the first non AlwaysOnTop scene.
		i++;

		// Might be moved, but also covers the case where it is empty.
		vec ~= r;
		for (Scene o, n = r; cast(size_t)i < vec.length; i++, n = o) {
			o = vec[i];
			vec[i] = n;
		}
	}

	override void closeMe(Scene r)
	{
		if (r is null) {
			return;
		}

		// Don't delete a scene already on the list
		foreach (ru; del) {
			if (ru is r) {
				return;
			}
		}

		remove(r);

		del ~= r;
	}

private:
	void closeAll()
	{
		auto d = vec;
		foreach (r; d) {
			closeMe(r);
		}
		dirty = true;
	}

	override void remove(Scene r)
	{
		size_t n;
		foreach (ref s; vec) {
			if (r is s) {
				break;
			}
			n++;
		}
		if (n >= vec.length) {
			return;
		}

		for (;n < vec.length - 1; n++) {
			vec[n] = vec[n + 1];
		}
		vec = vec[0 .. $ - 1];
		dirty = true;
	}

	final void manageScenes()
	{
		if (!dirty) {
			return;
		}
		dirty = false;

		Scene newScene;

		foreach_reverse (r; vec) {
			assert(r !is null);

			if (!(r.flags & Scene.Flag.TakesInput)) {
				continue;
			}

			newScene = r;
			break;
		}

		// If there is nobody to take the input we quit the game.
		if (newScene is null) {
			chargeQuit();
		}

		if (currentInput !is newScene) {
			if (currentInput !is null) {
				currentInput.dropControl();
			}
			currentInput = newScene;
			if (currentInput !is null) {
				currentInput.assumeControl();
			}
		}

		auto tmp = del;
		foreach(r; tmp) {
			r.close();
		}
		del = null;
	}
}
