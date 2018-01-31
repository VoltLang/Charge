// Copyright © 2016-2017, Jakob Bornecrantz.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * A specialiced hashmap and buffer.
 */
module charge.util.hash;

import io = watt.io;
import digest = watt.digest;

import watt.math;
import watt.algorithm;

import sys = charge.sys;
import math = charge.math;

import voxel.svo.buddy : nextHighestPowerOfTwo;


struct HashMapU32BoolFast = mixin HashMapInteger!(u64, bool, SizeBehavoirPow, 0.5);
struct HashMapU32BoolRobust = mixin HashMapInteger!(u64, bool, SizeBehavoirPrime, 0.5);
struct HashMapStringU32 = mixin HashMapArray!(char, u64, SizeBehavoirPow, 0.5, true);


struct HashMapInteger!(K, V, SB, F: f64)
{
public:
	alias Key = K;
	alias Value = V;
	alias HashType = u64;
	alias Distance = u8;
	alias SizeBehavoir = SB;
	enum Factor : f64 = F;


private:
	static assert(typeid(Key).size <= typeid(HashType).size);

	mKeys: Key[];
	mValues: Value[];
	mDistances: Distance[];
	mNumEntries: size_t;
	mGrowAt: size_t;
	mSize: SizeBehavoir;
	mTries: i32;


public:
	/*!
	 * Optionally initialize the hash map with a minimum number of elements.
	 */
	fn setup(size: size_t)
	{
		size = cast(size_t)(size / Factor);
		entries := mSize.setStarting(size);

		allocArrays(entries);
	}

	/*!
	 * Simpler helper for getting values,
	 * returns `Value.init` if the key was not found.
	 */
	fn getOrInit(key: Key) Value
	{
		def: Value;
		find(ref key, out def);
		return def;
	}

	/*!
	 * Find the given key in this hashmap, return true if found and sets
	 * ret to the value at the key.
	 *
	 * @Param[in] key  The key to look for.
	 * @Param[out] ret The value at key or default value for Value.
	 * @Return True if found false otherwise.
	 */
	fn find(key: Key, out ret: Value) bool
	{
		hash := makeHash(ref key);
		index := mSize.getIndex(hash);

		for (distance: i32 = 1; distance < mTries; distance++, index++) {
			distanceForIndex := mDistances.ptr[index];

			if (distanceForIndex == 0) {
				return false;
			}

			if (distanceForIndex == distance &&
			    mKeys.ptr[index] == key) {
				ret = mValues.ptr[index];
				return true;
			}
		}

		return false;
	}

	/*!
	 * Adds the given key value pair to the hashmap, replacing any value
	 * with the same key if it was in the map.
	 *
	 * @Param[in] key   The key for the value.
	 * @Param[in] value The value to add.
	 */
	fn add(key: Key, value: Value)
	{
		// They both start at zero, make sure we grow the hashmap then.
		if (mNumEntries >= mGrowAt) {
			grow();
		}

		hash := makeHash(ref key);
		index := mSize.getIndex(hash);

		for (distance: i32 = 1; distance < mTries; distance++, index++) {
			distanceForIndex := mDistances.ptr[index];

			// If we found a empty slot 
			if (distanceForIndex == 0) {
				mDistances.ptr[index] = cast(Distance)distance;
				mValues.ptr[index] = value;
				mKeys.ptr[index] = key;
				mNumEntries++;
				return;
			}

			// If the distances match compare keys.
			if (distanceForIndex == distance &&
			    mKeys.ptr[index] == key) {
				mValues.ptr[index] = value;
				return;
			}

			// This element doesn't match, and is poorer then us.
			if (distanceForIndex >= distance) {
				continue;
			}

			// This entry is richer then us, replace it.
			tmpKey := mKeys.ptr[index];
			tmpValue := mValues.ptr[index];

			mDistances.ptr[index] = cast(Distance)distance;
			mValues.ptr[index] = value;
			mKeys.ptr[index] = key;

			return add(ref tmpKey, ref tmpValue);
		}

		grow();

		add(ref key, ref value);
	}

	/*!
	 * Remove the given key and value associated with that key from the map.
	 *
	 * @Param[in] key The key to remove.
	 * @Returns True if the key was removed.
	 */
	fn remove(key: Key) bool
	{
		hash := makeHash(ref key);
		index := mSize.getIndex(hash);

		for (distance: i32 = 1; distance < mTries; distance++, index++) {
			distanceForIndex := mDistances.ptr[index];

			if (distanceForIndex == distance &&
			    mKeys.ptr[index] == key) {
				removeAt(index);
				return true;
			}
		}

		return false;
	}


public:
	/*!
	 * Grows the internal arrays.
	 */
	fn grow()
	{
		oldNumEntries := mNumEntries;
		oldDistances := mDistances;
		oldValues := mValues;
		oldKeys := mKeys;

		entries := mSize.getNextSize();
		allocArrays(entries);

		foreach (index, distanceForIndex; oldDistances) {
			if (distanceForIndex == 0) {
				continue;
			}

			add(oldKeys[index], oldValues[index]);
		}
	}

	/*!
	 * Allocate new set of arrays, reset all fields that
	 * tracks the contents of the said arrays.
	 */
	fn allocArrays(entries: size_t)
	{
		// Arrays are complete
		mNumEntries = 0;
		mTries = cast(Distance)log2(cast(u32)entries);

		numElements := entries + cast(u32)mTries + 2;

		mGrowAt = cast(size_t)(entries * Factor);
		mKeys = new Key[](numElements);
		mValues = new Value[](numElements);
		mDistances = new Distance[](numElements);
	}


	/*
	 *
	 * Functions for doing operations at indicies.
	 *
	 */

	/*!
	 * Remove the entry at the given index, and move
	 * entries that are poor into the now free slot.
	 */
	fn removeAt(index: size_t)
	{
		next := index + 1;
		while (wantsToGetRicher(next)) {
			mDistances.ptr[index] = cast(Distance)(mDistances.ptr[next] - 1u);
			mValues.ptr[index] = mValues.ptr[next];
			mKeys.ptr[index] = mKeys.ptr[next];
			next++;
			index++;
		}

		// If we don't enter the loop aboce index points at the
		// original index that was supplied to the function, if
		// we have entered the loop above index points to next.
		clearAt(index);
	}

	/*!
	 * This function clears a single entry, does not do any moving.
	 */
	fn clearAt(index: size_t)
	{
		mDistances.ptr[index] = 0;
		mValues.ptr[index] = Value.init;
		mKeys.ptr[index] = Key.init;
	}


	/*
	 *
	 * Helper functions.
	 *
	 */

	/*!
	 * Returns true if the entry at index can be moved
	 * closer to where it wants to reside.
	 */
	fn wantsToGetRicher(index: size_t) bool
	{
		distanceForIndex := mDistances.ptr[index];

		// 0 == empty, so no.
		// 1 == prefered location.
		// 2 >= wants to get richer.
		return distanceForIndex > 1;
	}

	/*!
	 * Helper function to go from a key to a hash value.
	 */
	global fn makeHash(key: Key) u64
	{
		// This is the fastest but only works if key is integer.
		return cast(u64)key;
	}
}

struct HashMapArray!(KE, V, SB, F: f64, CK: bool)
{
public:
	alias KeyElement = KE;
	alias Key = /*static if (CK) {
		*/scope const(KeyElement)[];
		static assert(CopyKey);/*
	} else {
		const(KE)[];
	}*/
	alias Value = V;
	alias Distance = u8;
	alias SizeBehavoir = SB;
	enum Factor : f64 = F;
	enum CopyKey : bool = CK;


private:
	mKeys: Key[];
	mValues: Value[];
	mDistances: Distance[];
	mNumEntries: size_t;
	mGrowAt: size_t;
	mSize: SizeBehavoir;
	mTries: i32;


public:
	/*!
	 * Optionally initialize the hash map with a minimum number of elements.
	 */
	fn setup(size: size_t)
	{
		size = cast(size_t)(size / Factor);
		entries := mSize.setStarting(size);

		allocArrays(entries);
	}

	/*!
	 * Simpler helper for getting values,
	 * returns `Value.init` if the key was not found.
	 */
	fn getOrInit(key: Key) Value
	{
		def: Value;
		find(ref key, out def);
		return def;
	}

	/*!
	 * Find the given key in this hashmap, return true if found and sets
	 * ret to the value at the key.
	 *
	 * @Param[in] key  The key to look for.
	 * @Param[out] ret The value at key or default value for Value.
	 * @Return True if found false otherwise.
	 */
	fn find(key: Key, out ret: Value) bool
	{
		hash := makeHash(key);
		index := mSize.getIndex(hash);

		for (distance: i32 = 1; distance < mTries; distance++, index++) {
			distanceForIndex := mDistances.ptr[index];

			if (distanceForIndex == 0) {
				return false;
			}

			if (distanceForIndex == distance &&
			    mKeys.ptr[index] == key) {
				ret = mValues.ptr[index];
				return true;
			}
		}

		return false;
	}

	/*!
	 * Adds the given key value pair to the hashmap, replacing any value
	 * with the same key if it was in the map.
	 *
	 * @Param[in] key   The key for the value.
	 * @Param[in] value The value to add.
	 */
	fn add(key: Key, value: Value)
	{
		// They both start at zero, make sure we grow the hashmap then.
		if (mNumEntries >= mGrowAt) {
			grow();
		}

		hash := makeHash(key);
		index := mSize.getIndex(hash);

		for (distance: i32 = 1; distance < mTries; distance++, index++) {
			distanceForIndex := mDistances.ptr[index];

			// If we found a empty slot 
			if (distanceForIndex == 0) {
				mDistances.ptr[index] = cast(Distance)distance;
				mValues.ptr[index] = value;
				if (CopyKey) {
					mKeys.ptr[index] = new key[..];
				} else {
					mKeys.ptr[index] = key;
				}
				mNumEntries++;
				return;
			}

			// If the distances match compare keys.
			if (distanceForIndex == distance &&
			    mKeys.ptr[index] == key) {
				mValues.ptr[index] = value;
				return;
			}

			// This element doesn't match, and is poorer then us.
			if (distanceForIndex >= distance) {
				continue;
			}

			// This entry is richer then us, replace it.
			tmpKey := mKeys.ptr[index];
			tmpValue := mValues.ptr[index];

			mDistances.ptr[index] = cast(Distance)distance;
			mValues.ptr[index] = value;
			if (CopyKey) {
				mKeys.ptr[index] = new key[..];
			} else {
				mKeys.ptr[index] = key;
			}

			return add(ref tmpKey, ref tmpValue);
		}

		grow();

		add(ref key, ref value);
	}

	/*!
	 * Remove the given key and value associated with that key from the map.
	 *
	 * @Param[in] key The key to remove.
	 * @Returns True if the key was removed.
	 */
	fn remove(key: Key) bool
	{
		hash := makeHash(key);
		index := mSize.getIndex(hash);

		for (distance: i32 = 1; distance < mTries; distance++, index++) {
			distanceForIndex := mDistances.ptr[index];

			if (distanceForIndex == distance &&
			    mKeys.ptr[index] == key) {
				removeAt(index);
				return true;
			}
		}

		return false;
	}


public:
	/*!
	 * Grows the internal arrays.
	 */
	fn grow()
	{
		oldDistances := mDistances;
		oldValues := mValues;
		oldKeys := mKeys;

		entries := mSize.getNextSize();
		allocArrays(entries);

		foreach (index, distanceForIndex; oldDistances) {
			if (distanceForIndex == 0) {
				continue;
			}

			add(oldKeys[index], oldValues[index]);
		}
	}

	/*!
	 * Allocate new set of arrays, reset all fields that
	 * tracks the contents of the said arrays.
	 */
	fn allocArrays(entries: size_t)
	{
		mTries = cast(Distance)log2(cast(u32)entries);

		numElements := entries + cast(u32)mTries + 2;

		mGrowAt = cast(size_t)(entries * Factor);
		mKeys = new Key[](numElements);
		mValues = new Value[](numElements);
		mDistances = new Distance[](numElements);
	}


	/*
	 *
	 * Functions for doing operations at indicies.
	 *
	 */

	/*!
	 * Remove the entry at the given index, and move
	 * entries that are poor into the now free slot.
	 */
	fn removeAt(index: size_t)
	{
		next := index + 1;
		while (wantsToGetRicher(next)) {
			mDistances.ptr[index] = cast(Distance)(mDistances.ptr[next] - 1u);
			mValues.ptr[index] = mValues.ptr[next];
			// This is okay, we already own mKeys.ptr[next].
			mKeys.ptr[index] = mKeys.ptr[next];
			next++;
			index++;
		}

		// If we don't enter the loop aboce index points at the
		// original index that was supplied to the function, if
		// we have entered the loop above index points to next.
		clearAt(index);
	}

	/*!
	 * This function clears a single entry, does not do any moving.
	 */
	fn clearAt(index: size_t)
	{
		mDistances.ptr[index] = 0;
		mValues.ptr[index] = Value.init;
		mKeys.ptr[index] = null; // @todo Key.init;
	}


	/*
	 *
	 * Helper functions.
	 *
	 */

	/*!
	 * Returns true if the entry at index can be moved
	 * closer to where it wants to reside.
	 */
	fn wantsToGetRicher(index: size_t) bool
	{
		distanceForIndex := mDistances.ptr[index];

		// 0 == empty, so no.
		// 1 == prefered location.
		// 2 >= wants to get richer.
		return distanceForIndex > 1;
	}

	/*!
	 * Helper function to go from a key to a hash value.
	 */
	global fn makeHash(key: Key) u64
	{
		// vrt_hash has a lot of collisions.
		//return vrt_hash(cast(void*)&key, typeid(Key).size);

		// hashFNV1A has far fewer
		return digest.hashFNV1A_64(cast(scope const(void)[])key);

		// This is the fastest but only works if key is integer.
		//return key;
	}
}

struct SizeBehavoirPow
{
private:
	mEntriesMinesOne: size_t;


public:
	fn setStarting(inital: size_t) size_t
	{
		ret := nextHighestPowerOfTwo(max(inital, 16));
		mEntriesMinesOne = ret - 1;
		return ret;
	}

	fn getNextSize() size_t
	{
		ret := nextHighestPowerOfTwo(mEntriesMinesOne + 2);
		mEntriesMinesOne = ret - 1;
		return mEntriesMinesOne;
	}

	fn getIndex(hash: size_t) size_t
	{
		return cast(u32)(hash & mEntriesMinesOne);
	}
}

struct SizeBehavoirPrime
{
private:
	mIndex: u8;


public:
	fn setStarting(min: size_t) size_t
	{
		min = max(16, min);
		while (getPrimeSize(mIndex) < min) {
			mIndex++;
		}
		return cast(size_t)getPrimeSize(mIndex);
	}

	fn getNextSize() size_t
	{
		return cast(size_t)getPrimeSize(++mIndex);
	}

	fn getIndex(hash: size_t) size_t
	{
		return cast(size_t)fastPrimeHashToIndex(mIndex, hash);
	}
}


private:

fn getPrimeSize(index: u32) u64
{
	switch (index) {
	case   0: return 2UL;
	case   1: return 3UL;
	case   2: return 5UL;
	case   3: return 7UL;
	case   4: return 11UL;
	case   5: return 13UL;
	case   6: return 17UL;
	case   7: return 23UL;
	case   8: return 29UL;
	case   9: return 37UL;
	case  10: return 47UL;
	case  11: return 59UL;
	case  12: return 73UL;
	case  13: return 97UL;
	case  14: return 127UL;
	case  15: return 151UL;
	case  16: return 197UL;
	case  17: return 251UL;
	case  18: return 313UL;
	case  19: return 397UL;
	case  20: return 499UL;
	case  21: return 631UL;
	case  22: return 797UL;
	case  23: return 1009UL;
	case  24: return 1259UL;
	case  25: return 1597UL;
	case  26: return 2011UL;
	case  27: return 2539UL;
	case  28: return 3203UL;
	case  29: return 4027UL;
	case  30: return 5087UL;
	case  31: return 6421UL;
	case  32: return 8089UL;
	case  33: return 10193UL;
	case  34: return 12853UL;
	case  35: return 16193UL;
	case  36: return 20399UL;
	case  37: return 25717UL;
	case  38: return 32401UL;
	case  39: return 40823UL;
	case  40: return 51437UL;
	case  41: return 64811UL;
	case  42: return 81649UL;
	case  43: return 102877UL;
	case  44: return 129607UL;
	case  45: return 163307UL;
	case  46: return 205759UL;
	case  47: return 259229UL;
	case  48: return 326617UL;
	case  49: return 411527UL;
	case  50: return 518509UL;
	case  51: return 653267UL;
	case  52: return 823117UL;
	case  53: return 1037059UL;
	case  54: return 1306601UL;
	case  55: return 1646237UL;
	case  56: return 2074129UL;
	case  57: return 2613229UL;
	case  58: return 3292489UL;
	case  59: return 4148279UL;
	case  60: return 5226491UL;
	case  61: return 6584983UL;
	case  62: return 8296553UL;
	case  63: return 10453007UL;
	case  64: return 13169977UL;
	case  65: return 16593127UL;
	case  66: return 20906033UL;
	case  67: return 26339969UL;
	case  68: return 33186281UL;
	case  69: return 41812097UL;
	case  70: return 52679969UL;
	case  71: return 66372617UL;
	case  72: return 83624237UL;
	case  73: return 105359939UL;
	case  74: return 132745199UL;
	case  75: return 167248483UL;
	case  76: return 210719881UL;
	case  77: return 265490441UL;
	case  78: return 334496971UL;
	case  79: return 421439783UL;
	case  80: return 530980861UL;
	case  81: return 668993977UL;
	case  82: return 842879579UL;
	case  83: return 1061961721UL;
	case  84: return 1337987929UL;
	case  85: return 1685759167UL;
	case  86: return 2123923447UL;
	case  87: return 2675975881UL;
	case  88: return 3371518343UL;
	case  89: return 4247846927UL;
	case  90: return 5351951779UL;
	case  91: return 6743036717UL;
	case  92: return 8495693897UL;
	case  93: return 10703903591UL;
	case  94: return 13486073473UL;
	case  95: return 16991387857UL;
	case  96: return 21407807219UL;
	case  97: return 26972146961UL;
	case  98: return 33982775741UL;
	case  99: return 42815614441UL;
	case 100: return 53944293929UL;
	case 101: return 67965551447UL;
	case 102: return 85631228929UL;
	case 103: return 107888587883UL;
	case 104: return 135931102921UL;
	case 105: return 171262457903UL;
	case 106: return 215777175787UL;
	case 107: return 271862205833UL;
	case 108: return 342524915839UL;
	case 109: return 431554351609UL;
	case 110: return 543724411781UL;
	case 111: return 685049831731UL;
	case 112: return 863108703229UL;
	case 113: return 1087448823553UL;
	case 114: return 1370099663459UL;
	case 115: return 1726217406467UL;
	case 116: return 2174897647073UL;
	case 117: return 2740199326961UL;
	case 118: return 3452434812973UL;
	case 119: return 4349795294267UL;
	case 120: return 5480398654009UL;
	case 121: return 6904869625999UL;
	case 122: return 8699590588571UL;
	case 123: return 10960797308051UL;
	case 124: return 13809739252051UL;
	case 125: return 17399181177241UL;
	case 126: return 21921594616111UL;
	case 127: return 27619478504183UL;
	case 128: return 34798362354533UL;
	case 129: return 43843189232363UL;
	case 130: return 55238957008387UL;
	case 131: return 69596724709081UL;
	case 132: return 87686378464759UL;
	case 133: return 110477914016779UL;
	case 134: return 139193449418173UL;
	case 135: return 175372756929481UL;
	case 136: return 220955828033581UL;
	case 137: return 278386898836457UL;
	case 138: return 350745513859007UL;
	case 139: return 441911656067171UL;
	case 140: return 556773797672909UL;
	case 141: return 701491027718027UL;
	case 142: return 883823312134381UL;
	case 143: return 1113547595345903UL;
	case 144: return 1402982055436147UL;
	case 145: return 1767646624268779UL;
	case 146: return 2227095190691797UL;
	case 147: return 2805964110872297UL;
	case 148: return 3535293248537579UL;
	case 149: return 4454190381383713UL;
	case 150: return 5611928221744609UL;
	case 151: return 7070586497075177UL;
	case 152: return 8908380762767489UL;
	case 153: return 11223856443489329UL;
	case 154: return 14141172994150357UL;
	case 155: return 17816761525534927UL;
	case 156: return 22447712886978529UL;
	case 157: return 28282345988300791UL;
	case 158: return 35633523051069991UL;
	case 159: return 44895425773957261UL;
	case 160: return 56564691976601587UL;
	case 161: return 71267046102139967UL;
	case 162: return 89790851547914507UL;
	case 163: return 113129383953203213UL;
	case 164: return 142534092204280003UL;
	case 165: return 179581703095829107UL;
	case 166: return 226258767906406483UL;
	case 167: return 285068184408560057UL;
	case 168: return 359163406191658253UL;
	case 169: return 452517535812813007UL;
	case 170: return 570136368817120201UL;
	case 171: return 718326812383316683UL;
	case 172: return 905035071625626043UL;
	case 173: return 1140272737634240411UL;
	case 174: return 1436653624766633509UL;
	case 175: return 1810070143251252131UL;
	case 176: return 2280545475268481167UL;
	case 177: return 2873307249533267101UL;
	case 178: return 3620140286502504283UL;
	case 179: return 4561090950536962147UL;
	case 180: return 5746614499066534157UL;
	case 181: return 7240280573005008577UL;
	case 182: return 9122181901073924329UL;
	case 183: return 11493228998133068689UL;
	case 184: return 14480561146010017169UL;
	case 185: return 18446744073709551557UL;
	default: assert(false);
	}
}

fn fastPrimeHashToIndex(index: u8, hash: size_t) u64
{
	switch (index) {
	case   0: return hash % 2UL;
	case   1: return hash % 3UL;
	case   2: return hash % 5UL;
	case   3: return hash % 7UL;
	case   4: return hash % 11UL;
	case   5: return hash % 13UL;
	case   6: return hash % 17UL;
	case   7: return hash % 23UL;
	case   8: return hash % 29UL;
	case   9: return hash % 37UL;
	case  10: return hash % 47UL;
	case  11: return hash % 59UL;
	case  12: return hash % 73UL;
	case  13: return hash % 97UL;
	case  14: return hash % 127UL;
	case  15: return hash % 151UL;
	case  16: return hash % 197UL;
	case  17: return hash % 251UL;
	case  18: return hash % 313UL;
	case  19: return hash % 397UL;
	case  20: return hash % 499UL;
	case  21: return hash % 631UL;
	case  22: return hash % 797UL;
	case  23: return hash % 1009UL;
	case  24: return hash % 1259UL;
	case  25: return hash % 1597UL;
	case  26: return hash % 2011UL;
	case  27: return hash % 2539UL;
	case  28: return hash % 3203UL;
	case  29: return hash % 4027UL;
	case  30: return hash % 5087UL;
	case  31: return hash % 6421UL;
	case  32: return hash % 8089UL;
	case  33: return hash % 10193UL;
	case  34: return hash % 12853UL;
	case  35: return hash % 16193UL;
	case  36: return hash % 20399UL;
	case  37: return hash % 25717UL;
	case  38: return hash % 32401UL;
	case  39: return hash % 40823UL;
	case  40: return hash % 51437UL;
	case  41: return hash % 64811UL;
	case  42: return hash % 81649UL;
	case  43: return hash % 102877UL;
	case  44: return hash % 129607UL;
	case  45: return hash % 163307UL;
	case  46: return hash % 205759UL;
	case  47: return hash % 259229UL;
	case  48: return hash % 326617UL;
	case  49: return hash % 411527UL;
	case  50: return hash % 518509UL;
	case  51: return hash % 653267UL;
	case  52: return hash % 823117UL;
	case  53: return hash % 1037059UL;
	case  54: return hash % 1306601UL;
	case  55: return hash % 1646237UL;
	case  56: return hash % 2074129UL;
	case  57: return hash % 2613229UL;
	case  58: return hash % 3292489UL;
	case  59: return hash % 4148279UL;
	case  60: return hash % 5226491UL;
	case  61: return hash % 6584983UL;
	case  62: return hash % 8296553UL;
	case  63: return hash % 10453007UL;
	case  64: return hash % 13169977UL;
	case  65: return hash % 16593127UL;
	case  66: return hash % 20906033UL;
	case  67: return hash % 26339969UL;
	case  68: return hash % 33186281UL;
	case  69: return hash % 41812097UL;
	case  70: return hash % 52679969UL;
	case  71: return hash % 66372617UL;
	case  72: return hash % 83624237UL;
	case  73: return hash % 105359939UL;
	case  74: return hash % 132745199UL;
	case  75: return hash % 167248483UL;
	case  76: return hash % 210719881UL;
	case  77: return hash % 265490441UL;
	case  78: return hash % 334496971UL;
	case  79: return hash % 421439783UL;
	case  80: return hash % 530980861UL;
	case  81: return hash % 668993977UL;
	case  82: return hash % 842879579UL;
	case  83: return hash % 1061961721UL;
	case  84: return hash % 1337987929UL;
	case  85: return hash % 1685759167UL;
	case  86: return hash % 2123923447UL;
	case  87: return hash % 2675975881UL;
	case  88: return hash % 3371518343UL;
	case  89: return hash % 4247846927UL;
	case  90: return hash % 5351951779UL;
	case  91: return hash % 6743036717UL;
	case  92: return hash % 8495693897UL;
	case  93: return hash % 10703903591UL;
	case  94: return hash % 13486073473UL;
	case  95: return hash % 16991387857UL;
	case  96: return hash % 21407807219UL;
	case  97: return hash % 26972146961UL;
	case  98: return hash % 33982775741UL;
	case  99: return hash % 42815614441UL;
	case 100: return hash % 53944293929UL;
	case 101: return hash % 67965551447UL;
	case 102: return hash % 85631228929UL;
	case 103: return hash % 107888587883UL;
	case 104: return hash % 135931102921UL;
	case 105: return hash % 171262457903UL;
	case 106: return hash % 215777175787UL;
	case 107: return hash % 271862205833UL;
	case 108: return hash % 342524915839UL;
	case 109: return hash % 431554351609UL;
	case 110: return hash % 543724411781UL;
	case 111: return hash % 685049831731UL;
	case 112: return hash % 863108703229UL;
	case 113: return hash % 1087448823553UL;
	case 114: return hash % 1370099663459UL;
	case 115: return hash % 1726217406467UL;
	case 116: return hash % 2174897647073UL;
	case 117: return hash % 2740199326961UL;
	case 118: return hash % 3452434812973UL;
	case 119: return hash % 4349795294267UL;
	case 120: return hash % 5480398654009UL;
	case 121: return hash % 6904869625999UL;
	case 122: return hash % 8699590588571UL;
	case 123: return hash % 10960797308051UL;
	case 124: return hash % 13809739252051UL;
	case 125: return hash % 17399181177241UL;
	case 126: return hash % 21921594616111UL;
	case 127: return hash % 27619478504183UL;
	case 128: return hash % 34798362354533UL;
	case 129: return hash % 43843189232363UL;
	case 130: return hash % 55238957008387UL;
	case 131: return hash % 69596724709081UL;
	case 132: return hash % 87686378464759UL;
	case 133: return hash % 110477914016779UL;
	case 134: return hash % 139193449418173UL;
	case 135: return hash % 175372756929481UL;
	case 136: return hash % 220955828033581UL;
	case 137: return hash % 278386898836457UL;
	case 138: return hash % 350745513859007UL;
	case 139: return hash % 441911656067171UL;
	case 140: return hash % 556773797672909UL;
	case 141: return hash % 701491027718027UL;
	case 142: return hash % 883823312134381UL;
	case 143: return hash % 1113547595345903UL;
	case 144: return hash % 1402982055436147UL;
	case 145: return hash % 1767646624268779UL;
	case 146: return hash % 2227095190691797UL;
	case 147: return hash % 2805964110872297UL;
	case 148: return hash % 3535293248537579UL;
	case 149: return hash % 4454190381383713UL;
	case 150: return hash % 5611928221744609UL;
	case 151: return hash % 7070586497075177UL;
	case 152: return hash % 8908380762767489UL;
	case 153: return hash % 11223856443489329UL;
	case 154: return hash % 14141172994150357UL;
	case 155: return hash % 17816761525534927UL;
	case 156: return hash % 22447712886978529UL;
	case 157: return hash % 28282345988300791UL;
	case 158: return hash % 35633523051069991UL;
	case 159: return hash % 44895425773957261UL;
	case 160: return hash % 56564691976601587UL;
	case 161: return hash % 71267046102139967UL;
	case 162: return hash % 89790851547914507UL;
	case 163: return hash % 113129383953203213UL;
	case 164: return hash % 142534092204280003UL;
	case 165: return hash % 179581703095829107UL;
	case 166: return hash % 226258767906406483UL;
	case 167: return hash % 285068184408560057UL;
	case 168: return hash % 359163406191658253UL;
	case 169: return hash % 452517535812813007UL;
	case 170: return hash % 570136368817120201UL;
	case 171: return hash % 718326812383316683UL;
	case 172: return hash % 905035071625626043UL;
	case 173: return hash % 1140272737634240411UL;
	case 174: return hash % 1436653624766633509UL;
	case 175: return hash % 1810070143251252131UL;
	case 176: return hash % 2280545475268481167UL;
	case 177: return hash % 2873307249533267101UL;
	case 178: return hash % 3620140286502504283UL;
	case 179: return hash % 4561090950536962147UL;
	case 180: return hash % 5746614499066534157UL;
	case 181: return hash % 7240280573005008577UL;
	case 182: return hash % 9122181901073924329UL;
	case 183: return hash % 11493228998133068689UL;
	case 184: return hash % 14480561146010017169UL;
	case 185: return hash % 18446744073709551557UL;
	default: assert(false);
	}
}