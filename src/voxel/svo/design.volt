// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.design;

import math = charge.math;


/*!
 * Some constants used troughout the code.
 * @{
 */
enum NumDim = 3;

enum XShift = 0;
enum YShift = 1;
enum ZShift = 2;
/*!
 * @}
 */

/*!
 * Constants used in the rendering pipeline.
 * @{
 */
enum BufferNum = 6;
enum u32 BufferCommandId = BufferNum; // Buffer ids start at zero.
/*!
 * @}
 */

/*!
 * Information about a single SVO, used by loaders and the pipeline.
 */
struct Create
{
	xShift, yShift, zShift: u32;
	numLevels: u32;
}
