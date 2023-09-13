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
#define S 0.039716259676045834
#else
#define S 0.00245792863046567
#endif

// Lower numbers blur more when intensity varies more between bands
#ifdef LUMA_raw
#define SI 13.401712932601427
#else
#define SI 10.923402488160853
#endif

// Higher numbers reduce blur for shorter runs
#ifdef LUMA_raw
#define SR 0.003446736773092952
#else
#define SR 0.012925109858034363
#endif

// Starting weight, lower values give less weight to the input image
#ifdef LUMA_raw
#define SW 0.43999145467432316
#else
#define SW 0.009466672829458444
#endif

// Bigger numbers search further, but slower
#ifdef LUMA_raw
#define RADIUS 8
#else
#define RADIUS 8
#endif

// Bigger numbers search further, but less accurate
#ifdef LUMA_raw
#define SPARSITY 0.0
#else
#define SPARSITY 0.0
#endif

// Bigger numbers search in more directions, slower (max 8)
// Only 4 and 8 are symmetrical, everything else blurs directionally
#ifdef LUMA_raw
#define DIRECTIONS 8
#else
#define DIRECTIONS 8
#endif

// A region is considered a run if it varies less than this
#ifdef LUMA_raw
#define TOLERANCE 0.001
#else
#define TOLERANCE 0.001
#endif

// 0 for avg, 1 for min, 2 for max
#ifdef LUMA_raw
#define M 0
#else
#define M 0
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
 *     - If the pixel after a skipped pixel has the same value as the previous unskipped pixel then its weight is doubled
 *     - This works well in big flat banded areas but may result in artifacts elsewhere
 *   - For step 5 and SW, pixels are considered to have the same value if their absolute difference is within a threshold
 *   - The number of directions in step 3 are user configurable
 */

vec4 hook()
{
	val sum = val(poi * SW);
#if M == 1 // min
	val total_weight = val(RADIUS);
#elif M == 2 // max
	val total_weight = val(0);
#else // avg
	val total_weight = val(SW);
#endif

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
		val prev_was_run = val(0);
		val prev_weight = val(1);
		val not_done = val(1);
		val run = val(1);
		val dir_sum = poi * SW;
		val dir_total_weight = val(SW);
		for (int i = 1; i <= RADIUS; i++) {
			float sparsity = floor(i * SPARSITY);
			val px = val_swizz(HOOKED_texOff((i + sparsity) * direction));
			val is_run = step(abs(prev_px - px), val(TOLERANCE));

			// stop blurring after discovering a 1px run
			not_done *= step(val(1), prev_was_run + is_run);

			// consider skipped pixels as runs if their neighbors are both runs
			float sparsity_delta = sparsity - floor((i - 1) * SPARSITY);
			float prev_sparsity = floor((i - 1) * SPARSITY);
			val weight = val(gaussian(length((i + sparsity) * direction) * max(0.0, S)));
			weight = is_run * weight + is_run * prev_weight * sparsity_delta;

			// run's 2nd pixel has weight increased to compensate for 1st pixel's weight of 0
			// XXX doesn't account for sparsity
			weight += prev_weight * NOT(prev_was_run);

			weight *= gaussian(abs(poi - px) * max(0.0, SI));

			weight *= gaussian((run += is_run) * SR);

			dir_sum += prev_px * weight * not_done;
			dir_total_weight += weight * not_done;

			prev_px = TERNARY(is_run, prev_px, px);
			prev_was_run = is_run;
			prev_weight = weight;
		}
#if M == 1
		sum = TERNARY(step(dir_total_weight, total_weight), dir_sum, sum);
		total_weight = min(dir_total_weight, total_weight);
#elif M == 2
		sum = TERNARY(step(total_weight, dir_total_weight), dir_sum, sum);
		total_weight = max(dir_total_weight, total_weight);
#else
		sum += dir_sum;
		total_weight += dir_total_weight;
#endif
	}

	val result = sum / total_weight;
	return unval(result);
}

