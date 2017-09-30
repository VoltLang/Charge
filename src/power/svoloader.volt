// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.svoloader;

import watt.io.file : isFile, read;

import gfx = charge.gfx;
import tui = charge.game.tui;

import charge.gfx.gl;

import power.app;

import svo = voxel.svo;
import gen = voxel.generators;

import voxel.loaders;
import voxel.viewer;


class SvoLoader : tui.WindowScene
{
public:
	app: App;


protected:
	mHasRendered: bool;
	mFilename: string;


public:
	this(app: App, filename: string)
	{
		this.app = app;
		this.mFilename = filename;
		super(app, 40, 5);
		setHeader(cast(immutable(u8)[])"Loading");
	}

	override fn render(t: gfx.Target)
	{
		mHasRendered = true;
		super.render(t);
	}

	override fn logic()
	{
		if (!mHasRendered) {
			return;
		}

		if (str := svo.checkGraphics()) {
			return doError(str);
		}

		// State to give to the renderers.
		frames: u32[];
		data: void[];
		state: svo.Create;

		// First try a magica voxel level.
		if (!loadFile(mFilename, out state, out frames, out data) &&
		    !doGen(mFilename, out state, out frames, out data)) {
			return doError("Could not load or generate a level");
		}

		d := new svo.Data(ref state, data);
		obj := new svo.Entity(d, frames);

		app.closeMe(this);
		app.push(new RayTracer(app, d, obj));
	}


	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	fn loadFile(filename: string, out c: svo.Create, out frames: u32[], out data: void[]) bool
	{
		if (!isFile(filename)) {
			return false;
		}

		// Load the file.
		fileData := cast(void[])read(filename);

		if (magica.isMagicaFile(fileData)) {
			return loadMagica(fileData, out c, out frames, out data);
		}

		if (chalmers.isChalmersDag(fileData)) {
			return loadChalmers(fileData, out c, out frames, out data);
		}

		return false;
	}

	fn loadMagica(fileData: void[], out c: svo.Create,
	              out frames: u32[], out data: void[]) bool
	{
		// Setup the state.
		c.xShift = svo.XShift;
		c.yShift = svo.YShift;
		c.zShift = svo.ZShift;
		c.numLevels = 11;

		// Create the loader.
		l := new magica.Loader();

		// Load parse the file.
		return l.loadFileFromData(fileData, out frames, out data);
	}

	fn loadChalmers(fileData: void[], out c: svo.Create,
	                out frames: u32[], out data: void[]) bool
	{
		// Create the loader.
		l := new chalmers.Loader();

		// Load parse the file.
		return l.loadFileFromData(fileData, out c, out frames, out data);
	}

	fn doGen(arg: string, out c: svo.Create, out frames: u32[], out data: void[]) bool
	{
		switch (arg) {
		case "--gen-one":
			return genOne(out c, out frames, out data);
		case "--gen-flat", "--gen-flat-y":
			return genFlatY(out c, out frames, out data);
		default:
			return genFlatY(out c, out frames, out data);
		}
	}

	fn genOne(out c: svo.Create, out frames: u32[], out data: void[]) bool
	{
		// Setup the state.
		c.xShift = svo.XShift;
		c.yShift = svo.YShift;
		c.zShift = svo.ZShift;
		c.numLevels = 11;

		// Reserve the first index.
		ib: svo.InputBuffer;
		ib.setup(1);

		// Load parse the file.
		og: gen.OneGen;

		// Only one frame.
		frames = new u32[](1);
		frames[0] = og.gen(ref ib, 11);

		data = ib.getData();
		return true;
	}

	fn genFlatY(out c: svo.Create, out frames: u32[], out data: void[]) bool
	{
		// Setup the state.
		c.xShift = svo.XShift;
		c.yShift = svo.YShift;
		c.zShift = svo.ZShift;
		c.numLevels = 11;

		// Reserve the first index.
		ib: svo.InputBuffer;
		ib.setup(1);

		// Load parse the file.
		fg: gen.FlatGen;

		// Only one frame.
		frames = new u32[](1);
		frames[0] = fg.genYColored(ref ib, c.numLevels);

		data = ib.getData();
		return true;
	}

	fn doError(str: string)
	{
		app.closeMe(this);
		app.push(new tui.MessageScene(app, "ERROR", str));
	}
}
