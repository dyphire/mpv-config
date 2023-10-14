/* vi: ft=c
 *
 * Copyright (c) 2023 an3223 <ethanr2048@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify it 
 * under the terms of the GNU Lesser General Public License as published by 
 * the Free Software Foundation, either version 2.1 of the License, or (at 
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License 
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License 
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

/* This is an implementation of a debanding algorithm where homogeneous regions 
 * are blurred with neighboring homogeneous regions.
 *
 * This should run prior to any other shaders and mpv's built in debanding 
 * should be disabled by setting deband=no in mpv.conf
 */

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!BIND HOOKED
//!DESC hdeband

// User variables

// Lower numbers increase blur over longer distances
#ifdef LUMA_raw
#define S 0.0
#else
#define S 0.0
#endif

// Lower numbers blur more when intensity varies more between bands
#ifdef LUMA_raw
#define SI 50.0
#else
#define SI 50.0
#endif

// Higher numbers reduce penalty for 1px runs, 1.0 fully ignores homogeneity
#ifdef LUMA_raw
#define SR 0.0
#else
#define SR 0.0
#endif

// Starting weight, lower values give less weight to the input image
#ifdef LUMA_raw
#define SW 4.0
#else
#define SW 4.0
#endif

// Bigger numbers search further, but slower
#ifdef LUMA_raw
#define RADIUS 8
#else
#define RADIUS 8
#endif

// Bigger numbers search further, but less accurate
#ifdef LUMA_raw
#define SPARSITY 2.0
#else
#define SPARSITY 2.0
#endif

// Bigger numbers search in more directions, slower (max 8)
// Only 4 and 8 are symmetrical, everything else blurs directionally
#ifdef LUMA_raw
#define DIRECTIONS 8
#else
#define DIRECTIONS 8
#endif

// If 0: Stop blur at POI if a run isn't found
// If 1: Always blur with POI-adjacent pixels
#ifdef LUMA_raw
#define RUN_START 1
#else
#define RUN_START 1
#endif

// A region is considered a run if it varies less than this
#ifdef LUMA_raw
#define TOLERANCE 0.0
#else
#define TOLERANCE 0.0
#endif

// Shader code

#define gaussian(x) exp(-1 * (x) * (x))

// boolean logic w/ vectors
#define NOT(x) (1 - (x))
#define AND *
#define TERNARY(cond, x, y) ((x)*(cond) + (y)*NOT(cond))
#ifdef LUMA_raw
#define EQ(x,y) val(val(x) == val(y))
#else
#define EQ(x,y) val(equal(val(x),val(y)))
#endif

// from NLM
#if defined(LUMA_raw)
#define val float
#define val_swizz(v) (v.x)
#define unval(v) vec4(v.x, 0, 0, poi_.a)
#define val_packed val
#define val_pack(v) (v)
#define val_unpack(v) (v)
#define MAP(f,param) f(param)
#elif defined(CHROMA_raw)
#define val vec2
#define val_swizz(v) (v.xy)
#define unval(v) vec4(v.x, v.y, 0, poi_.a)
#define val_packed uint
#define val_pack(v) packUnorm2x16(v)
#define val_unpack(v) unpackUnorm2x16(v)
#define MAP(f,param) vec2(f(param.x), f(param.y))
#else
#define val vec3
#define val_swizz(v) (v.xyz)
#define unval(v) vec4(v.x, v.y, v.z, poi_.a)
#define val_packed val
#define val_pack(v) (v)
#define val_unpack(v) (v)
#define MAP(f,param) vec3(f(param.x), f(param.y), f(param.z))
#endif

vec4 poi_ = HOOKED_texOff(0);
val poi = val_swizz(poi_);

/* Description of the algorithm:
 *
 * 1. For each pixel in the image (pixel-of-interest, POI):
 *   2. Accumulate its value with a weight of 1
 *   3. For each direction (adjacent/diagonal):
 *     4. For each pixel in that direction, originating from the POI and ending at an arbitrary limit, excluding the POI itself:
 *       5. If this pixel has the same value as the previous pixel (including POI) or the next pixel:
 *         5a. Accumulate its value with a weight of 1
 *       5b. Otherwise, stop accumulating in this direction
 *   6. Return the sum of the accumulated weighted pixel values divided by the sum of their weights
 *
 * Things this implementation does to make this algorithm more useful:
 *   - For steps 2 and 5, better weights should be used:
 *     - For step 5, multiply the weight by the gaussian of the absolute difference between the pixel's value and the POI value
 *       - This decreases blur for large shifts in intensity
 *       - The difference is scaled with a user parameter (SI)
 *     - For steps 2 and 5, multiply the weight of any pixels with values identical to the POI value by a user-specified value (SW)
 *       - Decreasing SW increases the amount of blur
 *     - For step 5, multiply the weight by the gaussian of the Euclidean norm of the pixel coordinates
 *   - For step 4, a parameter (SPARSITY) is taken which directs pixels to be skipped at a specified interval
 *     - This works well in big flat banded areas but may result in artifacts elsewhere
 *   - For step 5 and SW, pixels are considered to have the same value if their absolute difference is within a threshold
 *   - The number of directions in step 3 are user configurable
 */

vec4 hook()
{
	val sum = val(poi * SW);
	val total_weight = val(SW);

	for (int dir = 0; dir < DIRECTIONS; dir++) {
		vec2 direction;
		switch (dir) {
		case 0: direction = vec2( 1, 0); break;
		case 1: direction = vec2(-1, 0); break;
		case 2: direction = vec2( 0, 1); break;
		case 3: direction = vec2( 0,-1); break;
		case 4: direction = vec2( 1, 1); break;
		case 5: direction = vec2(-1,-1); break;
		case 6: direction = vec2( 1,-1); break;
		case 7: direction = vec2(-1, 1); break;
		}

		val prev_px = poi;
		val prev_is_run = val(RUN_START);
		val prev_weight = val(0);
		val not_done = val(1);
		for (int i = 1; i <= RADIUS; i++) {
			vec2 coord = (i + floor(i * SPARSITY)) * direction;
			val px = val_swizz(HOOKED_texOff(coord));
			val is_run = step(abs(prev_px - px), val(TOLERANCE));
			val weight = val(gaussian(length(coord) * max(0.0,S)));

			// reduce blur after discovering 1px runs
			not_done *= max(val(clamp(SR, 0.0, 1.0)),
			            clamp(prev_is_run + is_run, 0.0, 1.0));

			weight *= gaussian(abs(poi - px) * max(0.0,SI));

			// for compensating for skipping the first pixel of each run
			val prev_weight_compensate = NOT(prev_is_run) * prev_weight;
			// update previous state
			prev_px = px;
			prev_is_run = is_run;
			prev_weight = weight;
			// finally compensate
			weight += prev_weight_compensate;
			weight *= is_run;

			sum += px * weight * not_done;
			total_weight += weight * not_done;
		}
	}

	val result = sum / total_weight;
	return unval(result);
}

