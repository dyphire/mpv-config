/* vi: ft=c
 *
 * Based on vf_nlmeans.c from FFmpeg.
 *
 * Copyright (c) 2022 an3223 <ethanr2048@gmail.com>
 * Copyright (c) 2016 Clément Bœsch <u pkh me>
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

// Description: HQ/nlmeans.glsl: Slow, but higher quality.

// The following is shader code injected from ./nlmeans_template
/* vi: ft=c
 *
 * Based on vf_nlmeans.c from FFmpeg.
 *
 * Copyright (c) 2022 an3223 <ethanr2048@gmail.com>
 * Copyright (c) 2016 Clément Bœsch <u pkh me>
 *
 * This program is free software: you can redistribute it and/or modify it 
 * under the terms of the GNU Lesser General Public License as published by 
 * the Free Software Foundation, either version 2.1 of the License, or (at 
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY;  without even the implied warranty of MERCHANTABILITY or 
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License 
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License 
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

// Description: nlmeans.glsl: Default profile, general purpose, tuned for low noise

//!HOOK LUMA
//!HOOK CHROMA
//!BIND HOOKED
//!DESC Non-local means (nlmeans.glsl)
//!SAVE G



// User variables

// It is generally preferable to denoise luma and chroma differently, so the 
// user variables for luma and chroma are split.

// Denoising factor (sigma, higher means more blur)
#ifdef LUMA_raw
#define S 3.8070155534513885
#else
#define S 3.8391080491674847
#endif

/* Noise resistant adaptive sharpening
 *
 * AS:
 * 	 - 0: disable
 * 	 - 1: sharpen+denoise
 * 	 - 2: sharpen only
 * ASF: Higher numbers make a sharper image
 * ASA: Anti-ringing, higher numbers increase strength
 * ASP: Power, lower numbers increase sharpening on lower frequency detail
 * ASS: Equivalent to SS but for ASK instead of SK
 * ASI:
 *  - 0: don't sharpen noise
 *  - 1: sharpen noise
 */
#ifdef LUMA_raw
#define AS 0
#define ASF 0.0
#define ASA 0.0
#define ASP 0.0
#define ASS 0.0
#define ASI 0
#else
#define AS 0
#define ASF 0.0
#define ASA 0.0
#define ASP 0.0
#define ASS 0.0
#define ASI 0
#endif

/* Starting weight
 *
 * AKA the center weight, the weight of the pixel-of-interest.
 */
#ifdef LUMA_raw
#define SW 0.31161702146553555
#else
#define SW 0.5455997832190327
#endif

/* Spatial kernel
 *
 * Increasing the spatial sigma (SS) reduces the weight of further 
 * pixels.
 *
 * The intra-patch variants might help with larger patch sizes.
 *
 * SST: enables spatial kernel if R>=PST, 0 fully disables
 * SS: spatial sigma
 * PSS: intra-patch spatial sigma
 * PST: enables intra-patch spatial kernel if P>=PST, 0 fully disables
 */
#ifdef LUMA_raw
#define SST 1
#define SS 1.3426595626243674
#define PST 0
#define PSS 0.0
#else
#define SST 1
#define SS 0.6454412326714503
#define PST 0
#define PSS 0.0
#endif

/* Extremes preserve
 *
 * This setting is dependent on code generation from shader_cfg, so this 
 * setting can only be enabled via shader_cfg.
 *
 * Reduce denoising in very bright/dark areas.
 *
 * The downscaling factor of the EP shader stage affects the size of the area 
 * checked for luminance.
 *
 * This is incompatible with RGB. If you have RGB hooks enabled then you will 
 * have to delete the EP shader stage or specify EP=0 through shader_cfg.
 *
 * EP: 1 to enable, 0 to disable
 * DP: EP strength on dark areas, 0 to fully denoise
 * BP: EP strength on bright areas, 0 to fully denoise
 */
#ifdef LUMA_raw
#define EP 0
#define BP 0.0
#define DP 0.0
#else
#define EP 0
#define BP 0.0
#define DP 0.0
#endif

/* ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS */
/* ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS */
/* ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS */
/* ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS */
/* ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS */

/* textureGather applicable configurations:
 *
 * - PS={0,3,7,8}:P=3:RI={0,1,3,7}:RFI={0,1,2}
 * - PS={0,8}:P=3:RI={0,1,3,7}:RFI={0,1,2}
 * - PS=4:P=3:PST=0:RI=0:RFI=0
 * - PS=6:RI=0:RFI=0
 *   - Currently the only scalable variant
 *
 * Options which always disable textureGather:
 * 	 - NG
 * 	 - SAMPLE
 * 	 - PD
 *
 * Running without textureGather may be much slower.
 */

/* Patch & research sizes
 *
 * P should be an odd number. Higher values are slower and not always better.
 *
 * R should be an odd number greater than or equal to 3. Higher values are 
 * generally better, but slower.
 */
#ifdef LUMA_raw
#define P 3
#define R 5
#else
#define P 3
#define R 5
#endif

/* Patch and research shapes
 *
 * Different shapes have different speed and quality characteristics. Every 
 * shape (besides square) is smaller than square.
 *
 * PS applies applies to patches, RS applies to research zones.
 *
 * 0: square (symmetrical)
 * 1: horizontal line (asymmetric)
 * 2: vertical line (asymmetric)
 * 3: diamond (symmetrical)
 * 4: triangle (asymmetric, pointing upward)
 * 5: truncated triangle (asymmetric on two axis, last row halved)
 * 6: even sized square (asymmetric on two axis)
 * 7: plus (symmetrical)
 * 8: plus X (symmetrical)
 */
#ifdef LUMA_raw
#define RS 3
#define PS 0
#else
#define RS 3
#define PS 4
#endif

/* Weight discard
 *
 * Reduces weights that fall below a fraction of the average weight. This culls 
 * the most dissimilar samples from the blur, which can yield a better result, 
 * especially around edges.
 * 
 * WD:
 * 	 - 2: Mean. Better quality, but slower and requires GLSL 4.0 or later
 * 	 - 1: Moving cumulative average. Fast but inaccurate, blurs directionally.
 * 	 - 0: Disable
 *
 * WDT: Threshold coefficient, higher numbers discard more
 * WDP (only for WD=1): Increasing reduces the threshold for small sample sizes
 * WDS (not for WDK=is_zero): Higher numbers are more eager to reduce weights
 */
#ifdef LUMA_raw
#define WD 2
#define WDT 0.4893345936928189
#define WDP 0.0
#define WDS 1.0
#else
#define WD 0
#define WDT 0.0
#define WDP 0.0
#define WDS 1.0
#endif

/* Connectivity
 *
 * Increases weights that are near high weights, decreases weights that are 
 * near low weights.
 *
 * C: Number of passes to do, more increases the effect, 0 does nothing
 * CD: Distance between each pixel and its furthest neighbor
 * CS: Strength of effect, higher is more
 */
#ifdef LUMA_raw
#define C 0
#define CD 1.0
#define CS 1.0
#else
#define C 0
#define CD 1.0
#define CS 1.0
#endif

/* Rotational/reflectional invariance
 *
 * Number of rotations/reflections to try for each patch comparison. Can be 
 * slow, but may improve feature preservation. More rotations/reflections gives 
 * diminishing returns. The most similar rotation/reflection is used.
 *
 * The angle in degrees of each rotation is 360/(RI+1), so RI=1 will do a 
 * single 180 degree rotation, RI=3 will do three 90 degree rotations, etc.
 *
 * Consider setting SAMPLE=1 if setting RI to a setting that would require 
 * sampling between pixels.
 *
 * RI: Rotational invariance
 * RFI (0 to 2): Reflectional invariance
 */
#ifdef LUMA_raw
#define RI 0
#define RFI 0
#else
#define RI 0
#define RFI 0
#endif

/* Temporal denoising
 *
 * This setting is dependent on code generation from shader_cfg, so this 
 * setting can only be enabled via shader_cfg.
 *
 * Caveats:
 * 	 - Slower:
 * 	 	 - Gather optimizations only apply to the current frame
 * 	 - Requires vo=gpu-next
 * 	 - Luma-only (this is a bug)
 * 	 - Buggy
 *
 * May cause motion blur and may struggle more with noise that persists across 
 * multiple frames (e.g., from compression or duplicate frames).
 *
 * Motion estimation (ME) should improve quality without impacting speed.
 *
 * Increasing temporal distortion (TD) can reduce motion blur.
 *
 * T: number of frames used
 * ME: motion estimation, 0 for none, 1 for max weight, 2 for weighted avg
 * MEF: estimate factor, compensates for ME being one frame behind
 * TRF: compare against the denoised frames
 * TD: temporal distortion, higher numbers give less weight to previous frames
 */
#ifdef LUMA_raw
#define T 0
#define ME 1
#define MEF 2
#define TRF 0
#define TD 1.0
#else
#define T 0
#define ME 0
#define MEF 2
#define TRF 0
#define TD 1.0
#endif

/* Kernels
 *
 * SK: spatial kernel
 * RK: range kernel (takes patch differences)
 * ASK: adaptive sharpening kernel
 * PSK: intra-patch spatial kernel
 * WDK: weight discard kernel
 * WD1TK (WD=1 only): weight discard tolerance kernel
 *
 * List of available kernels:
 *
 * bicubic
 * cosine
 * cosine_
 * ffexp
 * gaussian
 * ginseng
 * ginseng_ (unclamped)
 * jinc
 * jinc3
 * jinc_ (unclamped)
 * jincjinc
 * jincjinc3
 * jincjinc3_ (unclamped)
 * jincjinc_ (unclamped)
 * lanczos
 * quadratic
 * quadratic_ (unclamped)
 * sinc
 * sinc3
 * sinc_ (unclamped)
 * sphinx
 * sphinx_ (unclamped)
 * triangle
 * triangle_ (unclamped)
 */
#ifdef LUMA_raw
#define SK gaussian
#define RK gaussian
#define ASK sinc
#define ASAK gaussian
#define PSK gaussian
#define WDK is_zero
#define WD1TK gaussian
#else
#define SK gaussian
#define RK gaussian
#define ASK sphinx_
#define ASAK gaussian
#define PSK gaussian
#define WDK is_zero
#define WD1TK gaussian
#endif

/* Kernel parameters
 *
 * The following kernels take these parameters:
 *
 * ffexp: K0
 * ginseng: KWS
 * jincjinc3: KWS
 * jincjinc: KWS
 * lanczos: KWS
 */
#ifdef LUMA_raw
#define K0 1.0
#define K1 1.0
#define KWS 1.0
#else
#define K0 1.0
#define K1 1.0
#define KWS 1.0
#endif

/* Negative kernel parameter offsets
 *
 * Usually kernels go high -> low. These parameters allow for a kernel to go 
 * low -> high -> low.
 *
 * Values of 0.0 mean no effect, higher values increase the effect.
 *
 * RO: range kernel (takes patch differences)
 */
#ifdef LUMA_raw
#define RO 0.00014746957936752556
#else
#define RO 9.773746446023492e-05
#endif

/* Sampling method
 *
 * In most cases this shouldn't make any difference, only set to bilinear if 
 * it's necessary to sample between pixels (e.g., RI=2).
 *
 * 0: nearest neighbor
 * 1: bilinear
 */
#ifdef LUMA_raw
#define SAMPLE 0
#else
#define SAMPLE 0
#endif

/* Research scaling factor
 *
 * Higher numbers sample more sparsely as the distance from the POI grows.
 */
#ifdef LUMA_raw
#define RSF 0.0
#else
#define RSF 0.0
#endif

// Scaling factor (should match WIDTH/HEIGHT)
#ifdef LUMA_raw
#define SF 1
#else
#define SF 1
#endif

// Use the guide image as the input image
#ifdef LUMA_raw
#define GI 0
#else
#define GI 0
#endif

/* Visualization
 *
 * 0: off
 * 1: absolute difference between input/output to the power of 0.25
 * 2: difference between input/output centered on 0.5
 * 3: post-WD average weight map
 * 4: pre-WD average weight map
 * 5: unsharp mask
 * 6: EP
 * 7: celled weight map (incompatible with temporal)
 */
#ifdef LUMA_raw
#define V 0
#else
#define V 0
#endif

// Fast approximate division
#ifdef LUMA_raw
#define FAST_DIV 0
#else
#define FAST_DIV 0
#endif

// Force disable textureGather
#ifdef LUMA_raw
#define NG 0
#else
#define NG 0
#endif

// Patch donut (probably useless)
#ifdef LUMA_raw
#define PD 0
#else
#define PD 0
#endif

// Duplicate 1st weight (for luma-guided-chroma)
#ifdef LUMA_raw
#define D1W 0
#else
#define D1W 0
#endif

// Skip patch comparison
#ifdef LUMA_raw
#define SKIP_PATCH 0
#else
#define SKIP_PATCH 0
#endif

// Shader code

#define EPSILON 1.2e-38
#define FLT_EPSILON 1.19209290E-07
#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define M_PI_4 0.78539816339744830962
#define M_1_PI 0.31830988618379067154
#define M_2_PI 0.63661977236758134308
#define POW2(x) ((x)*(x))
#define POW3(x) ((x)*(x)*(x))
#define POW4(x) ((x)*(x)*(x)*(x))
#define POW5(x) ((x)*(x)*(x)*(x)*(x))
#define POW6(x) ((x)*(x)*(x)*(x)*(x)*(x))
#define POW7(x) ((x)*(x)*(x)*(x)*(x)*(x)*(x))

// pow() implementation that gives -pow() when x<0
// avoids actually calling pow() since apparently it's buggy on nvidia
#define POW(x,y) (exp(log(abs(x)) * y) * sign(x))

// boolean logic w/ vectors
// from hdeband
#define NOT(x) (1 - (x))
#define AND *
#define TERNARY(cond, x, y) ((x)*(cond) + (y)*NOT(cond))

// from FSR
#if FAST_DIV
#define RECIPROCAL(x) uintBitsToFloat(uint(0x7ef07ebb) - floatBitsToUint(x))
#define DIV(x,y) ((x) * RECIPROCAL(y))
#define MED_RCP_B(x) uintBitsToFloat(uint(0x7ef19fff) - floatBitsToUint(x))
#define MED_RECIPROCAL(x) (MED_RCP_B(x) * (-MED_RCP_B(x) * x + 2))
#define MED_DIV(x,y) ((x) * MED_RECIPROCAL(y))
#else
#define RECIPROCAL(x) (1.0/(x))
#define MED_RECIPROCAL(x) (1.0/(x))
#define DIV(x,y) ((x)/(y))
#define MED_DIV(x,y) ((x)/(y))
#endif

// adapted from https://github.com/garamond13/Jinc
#define j1(x) TERNARY(step((x), 2.2931157), ((x) * 0.5) - (POW3(x) * 0.0625) + (POW5(x) * 0.00260416666666666666) - (POW7(x) * 0.00005425347222222222), sqrt(DIV(M_2_PI, (x))) * (1.0 + DIV(0.1875, POW2(x)) - DIV(0.1933594, POW4(x))) * cos((x) - 3.0 * M_PI_4 + DIV(0.375, (x)) - DIV(0.1640625, POW3(x))))

// XXX make kernel params capable of being set per-kernel, e.g., RK0, SK0...

// kernels, most of these are from libplacebo
// XXX sinc/jinc/sphinx: 1e-3 was selected tentatively;  not sure what the correct value should be (1e-8 is too low, x is never considered to be lower than it for some reason)
#define bicubic(x) bicubic_(clamp(x, 0.0, 2.0))
#define bicubic_(x) ((1.0/6.0) * (POW3((x)+2) - 4 * POW3((x)+1) + 6 * POW3(x) - 4 * POW3(max((x)-1, 0))))
#define cosine(x) cos(clamp(x, 0, M_PI_2))
#define cosine_ cos
#define ffexp(x) (POW(cos(max(EPSILON, clamp(x, 0.0, 1.0) * M_PI)), K0) * 0.5 + 0.5) // "experimental" scaler from ffmpeg
#define gaussian(x) exp(-1 * POW2(x))
#define ginseng(x) ginseng_(clamp(x, 0.0, 3.0))
#define ginseng_(x) (jinc(x) * sinc(x*KWS))
#define is_zero(x) int((x) == 0)
#define jinc(x) jinc_(clamp(x, 0.0, 1.2196698912665045))
#define jinc3(x) jinc_(clamp(x, 0.0, 3.2383154841662362))
#define jinc_(x) TERNARY(step(x, 1e-3), 1.0, DIV(2 * j1((x)*M_PI), (x)*M_PI))
#define jincjinc(x) jincjinc_(clamp(x, 0.0, 3.2383154841662362))
#define jincjinc3(x) jincjinc3_(clamp(x, 0.0, 3.2383154841662362))
#define jincjinc3_(x) (jinc(x) * jinc3(x*KWS))
#define jincjinc_(x) (jinc(x) * jinc(x*KWS))
#define lanczos(x) lanczos_(clamp(x, 0.0, 3.0))
#define lanczos_(x) (sinc3(x) * sinc(x*KWS))
#define quadratic(x) quadratic_(clamp(x, 0.0, 1.5))
#define quadratic_(x) TERNARY(step(x, 0.5), 0.75 - POW2(x), 0.5 * POW2((x) - 1.5))
#define sinc(x) sinc_(clamp(x, 0.0, 1.0))
#define sinc3(x) sinc_(clamp(x, 0.0, 3.0))
#define sinc_(x) TERNARY(step(x, 1e-3), 1.0, DIV(sin((x)*M_PI), ((x)*M_PI)))
#define sphinx(x) sphinx_(clamp(x, 0.0, 1.4302966531242027))
#define sphinx_(x) TERNARY(step(x, 1e-3), 1.0, DIV(3.0 * (sin((x)*M_PI) - (x)*M_PI * cos((x)*M_PI)), POW3((x)*M_PI)))
#define triangle(x) triangle_(clamp(x, 0.0, 1.0))
#define triangle_(x) (1 - (x))

#define MAP1(f,param) f(param)
#define MAP2(f,param) vec2(f(param.x), f(param.y))
#define MAP3(f,param) vec3(f(param.x), f(param.y), f(param.z))

#if defined(LUMA_raw)
#define val float
#define val_swizz(v) (v.x)
#define unval(v) vec4(v, 0, 0, poi_.a)
#define val_packed val
#define val_pack(v) (v)
#define val_unpack(v) (v)
#define MAP MAP1
#elif defined(CHROMA_raw)
#define val vec2
#define val_swizz(v) (v.xy)
#define unval(v) vec4(v.x, v.y, 0, poi_.a)
#define val_packed uint
#define val_pack(v) packUnorm2x16(v)
#define val_unpack(v) unpackUnorm2x16(v)
#define MAP MAP2
#else
#define val vec3
#define val_swizz(v) (v.xyz)
#define unval(v) vec4(v.x, v.y, v.z, poi_.a)
#define val_packed val
#define val_pack(v) (v)
#define val_unpack(v) (v)
#define MAP MAP3
#endif

#if D1W // float guide
#define val_guide float
#define val_guide_swizz(v) (v.x)
#define val_guide_packed float
#define val_guide_pack(v) (v)
#define val_guide_unpack(v) (v)
#define MAP_GUIDE MAP1
#define unval_guide(v) vec4(v, 0, 0, poi2_.a)
#else // val guide
#define val_guide val
#define val_guide_swizz val_swizz
#define val_guide_packed val_packed
#define val_guide_pack val_pack
#define val_guide_unpack val_unpack
#define MAP_GUIDE MAP
#if defined(LUMA_raw)
#define unval_guide(v) vec4(v, 0, 0, poi2_.a)
#elif defined(CHROMA_raw)
#define unval_guide(v) vec4(v.x, v.y, 0, poi2_.a)
#else
#define unval_guide(v) vec4(v.x, v.y, v.z, poi2_.a)
#endif
#endif

#if PS == 6
const int hp = P/2; 
#else
const float hp = int(P/2) - 0.5*(1-(P%2));  // sample between pixels for even patch sizes
#endif

#if RS == 6
const int hr = R/2; 
#else
const float hr = int(R/2) - 0.5*(1-(R%2));  // sample between pixels for even research sizes
#endif

// patch/research shapes
// each shape is depicted in a comment, where Z=5 (Z corresponds to P or R)
// dots (.) represent samples (pixels) and X represents the pixel-of-interest

// Z    .....
// Z    .....
// Z    ..X..
// Z    .....
// Z    .....
#define S_SQUARE(z,hz,incr) for (z.x = -hz;  z.x <= hz;  z.x++) for (z.y = -hz;  z.y <= hz;  incr)

// (in this instance Z=4)
// Z    ....
// Z    ....
// Z    ..X.
// Z    ....
#define S_SQUARE_EVEN(z,hz,incr) for (z.x = -hz;  z.x < hz;  z.x++) for (z.y = -hz;  z.y < hz;  incr)

// Z-4    .
// Z-2   ...
// Z    ..X..
#define S_TRIANGLE(z,hz,incr) for (z.y = -hz;  z.y <= 0;  z.y++) for (z.x = -abs(abs(z.y) - hz);  z.x <= abs(abs(z.y) - hz);  incr)

// Z-4    .
// Z-2   ...
// hz+1 ..X
#define S_TRUNC_TRIANGLE(z,hz,incr) for (z.y = -hz;  z.y <= 0;  z.y++) for (z.x = -abs(abs(z.y) - hz);  z.x <= abs(abs(z.y) - hz)*int(z.y!=0);  incr)
#define S_TRIANGLE_A(hz,Z) int(hz*hz+Z)

// Z-4    .
// Z-2   ...
// Z    ..X..
// Z-2   ...
// Z-4    .
#define S_DIAMOND(z,hz,incr) for (z.x = -hz;  z.x <= hz;  z.x++) for (z.y = -abs(abs(z.x) - hz);  z.y <= abs(abs(z.x) - hz);  incr)
#define S_DIAMOND_A(hz,Z) int(hz*hz*2+Z)

//
// Z    ..X..
//
#define S_HORIZONTAL(z,hz,incr) for (z.y = 0;  z.y <= 0;  z.y++) for (z.x = -hz;  z.x <= hz;  incr)

// 90 degree rotation of S_HORIZONTAL
#define S_VERTICAL(z,hz,incr) for (z.x = 0;  z.x <= 0;  z.x++) for (z.y = -hz;  z.y <= hz;  incr)

// 1      .
// 1      . 
// Z    ..X..
// 1      . 
// 1      .
#define S_PLUS(z,hz,incr) for (z.x = -hz;  z.x <= hz;  z.x++) for (z.y = -hz * int(z.x == 0);  z.y <= hz * int(z.x == 0);  incr)
#define S_PLUS_A(hz,Z) (Z*2 - 1)

// 3    . . .
// 3     ...
// Z    ..X..
// 3     ...
// 3    . . .
#define S_PLUS_X(z,hz,incr) for (z.x = -hz;  z.x <= hz;  z.x++) for (z.y = -abs(z.x) + -hz * int(z.x == 0);  z.y <= abs(z.x) + hz * int(z.x == 0);  incr)
#define S_PLUS_X_A(hz,Z) (Z*4 - 3)

// 1x1 square
#define S_1X1(z) for (z = vec3(0);  z.x <= 0;  z.x++)

#define T1 (T+1)
#define FOR_FRAME(r) for (r.z = 0;  r.z < T1;  r.z++)

// donut increment, increments without landing on (0,0,0)
// much faster than a continue statement
#define DINCR(z,c,a) ((z.c += a),(z.c += int(z == vec3(0))))

#define R_AREA(a) (a * T1 - 1)

// research shapes
// XXX would be nice to have the option of temporally-varying research sizes
#if R == 0 || R == 1
#define FOR_RESEARCH(r) S_1X1(r)
const int r_area = R_AREA(1); 
#elif RS == 8
#define FOR_RESEARCH(r) S_PLUS_X(r,hr,DINCR(r,y,max(1,abs(r.x))))
const int r_area = R_AREA(S_PLUS_X_A(hr,R)); 
#elif RS == 7
#define FOR_RESEARCH(r) S_PLUS(r,hr,DINCR(r,y,1))
const int r_area = R_AREA(S_PLUS_A(hr,R)); 
#elif RS == 6
#define FOR_RESEARCH(r) S_SQUARE_EVEN(r,hr,DINCR(r,y,1))
const int r_area = R_AREA(R*R); 
#elif RS == 5
#define FOR_RESEARCH(r) S_TRUNC_TRIANGLE(r,hr,DINCR(r,x,1))
const int r_area = R_AREA(S_TRIANGLE_A(hr,hr)); 
#elif RS == 4
#define FOR_RESEARCH(r) S_TRIANGLE(r,hr,DINCR(r,x,1))
const int r_area = R_AREA(S_TRIANGLE_A(hr,R)); 
#elif RS == 3
#define FOR_RESEARCH(r) S_DIAMOND(r,hr,DINCR(r,y,1))
const int r_area = R_AREA(S_DIAMOND_A(hr,R)); 
#elif RS == 2
#define FOR_RESEARCH(r) S_VERTICAL(r,hr,DINCR(r,y,1))
const int r_area = R_AREA(R); 
#elif RS == 1
#define FOR_RESEARCH(r) S_HORIZONTAL(r,hr,DINCR(r,x,1))
const int r_area = R_AREA(R); 
#elif RS == 0
#define FOR_RESEARCH(r) S_SQUARE(r,hr,DINCR(r,y,1))
const int r_area = R_AREA(R*R); 
#endif

#define RI1 (RI+1)
#define RFI1 (RFI+1)

#if RI
#define FOR_ROTATION for (float ri = 0;  ri < 360;  ri += DIV(360.0, RI1))
#else
#define FOR_ROTATION
#endif

#if RFI
#define FOR_REFLECTION for (int rfi = 0;  rfi < RFI1;  rfi++)
#else
#define FOR_REFLECTION
#endif

#if PD
#define PINCR DINCR
#else
#define PINCR(z,c,a) (z.c += a)
#endif

#define P_AREA(a) (a - PD)

// patch shapes
#if P == 0 || P == 1
#define FOR_PATCH(p) S_1X1(p)
const int p_area = P_AREA(1); 
#elif PS == 8
#define FOR_PATCH(p) S_PLUS_X(p,hp,PINCR(p,y,max(1,abs(p.x))))
const int p_area = P_AREA(S_PLUS_X_A(hp,P)); 
#elif PS == 7
#define FOR_PATCH(p) S_PLUS(p,hp,PINCR(p,y,1))
const int p_area = P_AREA(S_PLUS_A(hp,P)); 
#elif PS == 6
#define FOR_PATCH(p) S_SQUARE_EVEN(p,hp,PINCR(p,y,1))
const int p_area = P_AREA(P*P); 
#elif PS == 5
#define FOR_PATCH(p) S_TRUNC_TRIANGLE(p,hp,PINCR(p,x,1))
const int p_area = P_AREA(S_TRIANGLE_A(hp,hp)); 
#elif PS == 4
#define FOR_PATCH(p) S_TRIANGLE(p,hp,PINCR(p,x,1))
const int p_area = P_AREA(S_TRIANGLE_A(hp,P)); 
#elif PS == 3
#define FOR_PATCH(p) S_DIAMOND(p,hp,PINCR(p,y,1))
const int p_area = P_AREA(S_DIAMOND_A(hp,P)); 
#elif PS == 2
#define FOR_PATCH(p) S_VERTICAL(p,hp,PINCR(p,y,1))
const int p_area = P_AREA(P); 
#elif PS == 1
#define FOR_PATCH(p) S_HORIZONTAL(p,hp,PINCR(p,x,1))
const int p_area = P_AREA(P); 
#elif PS == 0
#define FOR_PATCH(p) S_SQUARE(p,hp,PINCR(p,y,1))
const int p_area = P_AREA(P*P); 
#endif

const float r_scale = 1.0/r_area; 
const float r1_scale = 1.0/(r_area+1); 
const float p_scale = 1.0/p_area; 
const float hr_scale = 1.0/hr; 

#if SAMPLE == 0
#define sample(tex, pos, size, pt, off) tex((pos) + (pt) * (vec2(off) + 0.5 - fract((pos) * (size))))
#else
#define sample(tex, pos, size, pt, off) tex((pos) + (pt) * vec2(off))
#endif

/* Guide images are bound through the G (luma) GC (chroma, or non-luma) 
 * textures. When bound, these are where the weights are computed. Otherwise 
 * the weights are computed on the hooked texture.
 */

#if GI && defined(LUMA_raw)
#define GET_(off) sample(G_tex, G_pos, G_size, G_pt, off)
#elif GI
#define GET_(off) sample(GC_tex, GC_pos, GC_size, GC_pt, off)
#else
#define GET_(off) sample(HOOKED_tex, HOOKED_pos, HOOKED_size, HOOKED_pt, off)
#endif

#if defined(G_raw) && (defined(LUMA_raw) || D1W)
#define GET_GUIDE_(off) sample(G_tex, G_pos, G_size, G_pt, off)
#define gather_offs(off, off_arr) (G_mul * vec4(textureGatherOffsets(G_raw, G_pos + vec2(off) * G_pt, off_arr)))
#define gather(off) G_gather(G_pos + (off) * G_pt, 0)
#elif defined(GC_raw)
#define GET_GUIDE_(off) sample(GC_tex, GC_pos, GC_size, GC_pt, off)
#else
#define GET_GUIDE_(off) GET_(off)
#define gather_offs(off, off_arr) (HOOKED_mul * vec4(textureGatherOffsets(HOOKED_raw, HOOKED_pos + vec2(off) * HOOKED_pt, off_arr)))
#define gather(off) HOOKED_gather(HOOKED_pos + (off)*HOOKED_pt, 0)
#endif

#if T
val GET(vec3 off)
{
	 switch (min(int(off.z), frame)) {
	 case 0: return val_swizz(GET_(off)); 

	 }
}
val GET_GUIDE(vec3 off)
{
	 return off.z == 0 ? val_guide_swizz(GET_GUIDE_(off)) : GET(off); 
}
#else
#define GET(off) val_swizz(GET_(off))
#define GET_GUIDE(off) val_guide_swizz(GET_GUIDE_(off))
#endif

vec4 poi_ = GET_(vec3(0)); 
vec4 poi2_ = GET_GUIDE_(vec3(0)); 
val poi = val_swizz(poi_);  // pixel-of-interest
val_guide poi2 = val_guide_swizz(poi2_);  // guide pixel-of-interest

#if RI // rotation
vec2 rot(vec2 p, float d)
{
	 return vec2(
	 	 p.x * cos(radians(d)) - p.y * sin(radians(d)),
	 	 p.y * sin(radians(d)) + p.x * cos(radians(d))
	 ); 
}
#else
#define rot(p, d) (p)
#endif

#if RFI // reflection
vec2 ref(vec2 p, int d)
{
	 switch (d) {
	 case 0: return p; 
	 case 1: return p * vec2(1, -1); 
	 case 2: return p * vec2(-1, 1); 
	 }
}
#else
#define ref(p, d) (p)
#endif

#if SST && R >= SST
float spatial_r(vec3 v)
{
	 v.xy += 0.5 - fract(HOOKED_pos*HOOKED_size); 
	 v.z *= TD; 
	 return SK(length(v)*SS); 
}
#else
#define spatial_r(v) (1)
#endif

// 2D blur for sharpening
#if AS
float spatial_as(vec3 v)
{
	 v.xy += 0.5 - fract(HOOKED_pos*HOOKED_size); 
	 return ASK(length(v)*ASS) * int(v.z == 0); 
}
#endif

#if PST && P >= PST
#define spatial_p(v) PSK(length(v)*PSS)
#define normalize_p(x,expr) DIV((x), (expr))
#else
#define spatial_p(v) (1)
#define normalize_p(x,expr) ((x) * p_scale)
#endif

const float pdiff_scale = 1.0/max(EPSILON,POW2(S*0.013)); 
val_guide range(val_guide pdiff_sq)
{
	 pdiff_sq = sqrt(abs(pdiff_sq - max(EPSILON, RO)) * pdiff_scale); 
	 return RK(pdiff_sq); 
}

#define GATHER (PD == 0 && NG == 0 && SAMPLE == 0) // never textureGather if any of these conditions are false
#define REGULAR_ROTATIONS (RI == 0 || RI == 1 || RI == 3 || RI == 7)

#if (defined(LUMA_gather) || D1W) && ((PS == 0 || ((PS == 3 || PS == 7) && RI != 7) || PS == 8) && P == 3) && REGULAR_ROTATIONS && GATHER
// 3x3 diamond/plus or square patch_comparison_gather
const ivec2 offsets_adj[4] = { ivec2(0,-1), ivec2(1,0), ivec2(0,1), ivec2(-1,0) }; 
const ivec2 offsets_adj_sf[4] = { ivec2(0,-1) * SF, ivec2(1,0) * SF, ivec2(0,1) * SF, ivec2(-1,0) * SF }; 
vec4 poi_patch_adj = gather_offs(0, offsets_adj); 
#if PS == 0 || PS == 8
const ivec2 offsets_diag[4] = { ivec2(-1,-1), ivec2(1,-1), ivec2(1,1), ivec2(-1,1) }; 
const ivec2 offsets_diag_sf[4] = { ivec2(-1,-1) * SF, ivec2(1,-1) * SF, ivec2(1,1) * SF, ivec2(-1,1) * SF }; 
vec4 poi_patch_diag = gather_offs(0, offsets_diag); 
#endif
float patch_comparison_gather(vec3 r)
{
	 float min_rot = p_area - 1; 
	 vec4 transformer_adj = gather_offs(r, offsets_adj_sf); 
#if PS == 0 || PS == 8
	 vec4 transformer_diag = gather_offs(r, offsets_diag_sf); 
#endif
	 FOR_ROTATION {
	 	 FOR_REFLECTION {
#if RFI
	 	 	 /* xxy
	 	 	  * w y
	 	 	  * wzz
	 	 	  */
	 	 	 switch(rfi) {
	 	 	 case 1:
	 	 	 	 transformer_adj = transformer_adj.zyxw; 
#if PS == 0 || PS == 8
	 	 	 	 transformer_diag = transformer_diag.zyxw; 
#endif
	 	 	 	 break; 
	 	 	 case 2:
	 	 	 	 transformer_adj = transformer_adj.xwzy; 
#if PS == 0 || PS == 8
	 	 	 	 transformer_diag = transformer_diag.xwzy; 
#endif
	 	 	 	 break; 
	 	 	 }
#endif

	 	 	 vec4 pdiff_sq = POW2(poi_patch_adj - transformer_adj) * spatial_p(vec2(1,0)); 
#if PS == 0 || PS == 8
	 	 	 pdiff_sq += POW2(poi_patch_diag - transformer_diag) * spatial_p(vec2(1,1)); 
#endif
	 	 	 min_rot = min(dot(pdiff_sq, vec4(1)), min_rot); 

// un-reflect
#if RFI
	 	 	 switch(rfi) {
	 	 	 case 1:
	 	 	 	 transformer_adj = transformer_adj.zyxw; 
#if PS == 0 || PS == 8
	 	 	 	 transformer_diag = transformer_diag.zyxw; 
#endif
	 	 	 	 break; 
	 	 	 case 2:
	 	 	 	 transformer_adj = transformer_adj.xwzy; 
#if PS == 0 || PS == 8
	 	 	 	 transformer_diag = transformer_diag.xwzy; 
#endif
	 	 	 	 break; 
	 	 	 }
#endif
	 	 } // FOR_REFLECTION
#if RI == 7
	 	 transformer_adj = transformer_adj.wxyz; 
	 	 // swap adjacents for diagonals
	 	 transformer_adj += transformer_diag; 
	 	 transformer_diag = transformer_adj - transformer_diag; 
	 	 transformer_adj -= transformer_diag; 
#elif RI == 3
	 	 transformer_adj = transformer_adj.wxyz; 
#elif RI == 1
	 	 transformer_adj = transformer_adj.zwxy; 
#endif
#if RI == 3 && (PS == 0 || PS == 8)
	 	 transformer_diag = transformer_diag.wxyz; 
#elif RI == 1 && (PS == 0 || PS == 8)
	 	 transformer_diag = transformer_diag.zwxy; 
#endif
	 } // FOR_ROTATION
	 
#if PS == 0 || PS == 8
	 float total_weight = spatial_p(vec2(0,0)) + 4 * spatial_p(vec2(0,1)) + 4 * spatial_p(vec2(1,1)); 
#else
	 float total_weight = spatial_p(vec2(0,0)) + 4 * spatial_p(vec2(0,1)); 
#endif

	 float center_diff = poi2.x - GET_GUIDE(r).x; 
	 return normalize_p(POW2(center_diff) + min_rot, max(EPSILON,total_weight)); 
}
#elif (defined(LUMA_gather) || D1W) && PS == 4 && P == 3 && RI == 0 && RFI == 0 && GATHER
const ivec2 offsets[4] = { ivec2(0,-1), ivec2(-1,0), ivec2(0,0), ivec2(1,0) }; 
const ivec2 offsets_sf[4] = { ivec2(0,-1) * SF, ivec2(-1,0) * SF, ivec2(0,0) * SF, ivec2(1,0) * SF }; 
vec4 poi_patch = gather_offs(0, offsets); 
vec4 spatial_p_weights = vec4(spatial_p(vec2(0,-1)), spatial_p(vec2(-1,0)), spatial_p(vec2(0,0)), spatial_p(vec2(1,0))); 
float patch_comparison_gather(vec3 r)
{
	 vec4 pdiff = poi_patch - gather_offs(r, offsets_sf); 
	 return normalize_p(
	 	 dot(POW2(pdiff) * spatial_p_weights, vec4(1)),
	 	 dot(spatial_p_weights, vec4(1))
	 ); 
}
#elif (defined(LUMA_gather) || D1W) && PS == 6 && RI == 0 && RFI == 0 && GATHER
// tiled even square patch_comparison_gather
// XXX extend to support odd square?
float patch_comparison_gather(vec3 r)
{
	 /* gather order:
	  * w z
	  * x y
	  */
	 vec2 tile; 
	 float pdiff_sq = 0; 
	 float total_weight = 0; 
	 for (tile.x = -hp;  tile.x < hp;  tile.x+=2) for (tile.y = -hp;  tile.y < hp;  tile.y+=2) {
	 	 vec4 diff = gather(tile + r.xy) - gather(tile); 
	 	 vec4 weights = vec4(spatial_p(tile+vec2(0,1)), spatial_p(tile+vec2(1,1)), spatial_p(tile+vec2(1,0)), spatial_p(tile+vec2(0,0))); 
	 	 pdiff_sq += dot(POW2(diff) * weights, vec4(1)); 
	 	 total_weight += dot(weights, vec4(1)); 
	 }

	 return normalize_p(pdiff_sq, max(EPSILON,total_weight)); 
}
#else
#define patch_comparison_gather patch_comparison
#define STORE_POI_PATCH 1
val_guide poi_patch[p_area]; 
#endif

val_guide patch_comparison(vec3 r)
{
	 vec3 p; 
	 val_guide min_rot = val_guide(p_area); 

	 FOR_ROTATION FOR_REFLECTION {
	 	 val_guide pdiff_sq = val_guide(0); 
	 	 float total_weight = 0; 

	 	 int p_index = 0; 
	 	 FOR_PATCH(p) {
#ifdef STORE_POI_PATCH
	 	 	 val_guide poi_p = poi_patch[p_index++]; 
#else
	 	 	 val_guide poi_p = GET_GUIDE(p); 
#endif
	 	 	 vec3 transformed_p = SF * vec3(ref(rot(p.xy, ri), rfi), p.z); 
	 	 	 val_guide diff_sq = poi_p - GET_GUIDE(transformed_p + r); 
	 	 	 diff_sq *= diff_sq; 

	 	 	 float weight = spatial_p(p.xy); 
	 	 	 pdiff_sq += diff_sq * weight; 
	 	 	 total_weight += weight; 
	 	 }

	 	 min_rot = min(min_rot, normalize_p(pdiff_sq, max(EPSILON,total_weight))); 
	 }

	 return min_rot; 
}

vec4 hook()
{
	 val_guide total_weight = val_guide(0); 
	 val sum = val(0); 
	 val result = val(0); 

	 vec3 r = vec3(0); 
	 vec3 me = vec3(0); 

	 float sw = SW * spatial_r(vec3(0)); 

#if T && ME == 1 // temporal & motion estimation
	 vec3 me_tmp = vec3(0); 
	 float maxweight = 0; 
#elif T && ME == 2 // temporal & motion estimation
	 vec3 me_sum = vec3(0); 
	 float me_weight = 0; 
#endif

#if AS
	 float total_weight_as = 0; 
	 val sum_as = val(0); 
#endif

#if WD == 2 || V == 7 || C
#define STORE_WEIGHTS 1
#else
#define STORE_WEIGHTS 0
#endif

#if STORE_WEIGHTS
	 int r_index = 0; 
	 val_guide_packed all_weights[r_area]; 
	 val_packed all_pixels[r_area]; 
#endif

#ifdef STORE_POI_PATCH
	 vec3 p; 
	 int p_index = 0; 
	 FOR_PATCH(p)
	 	 poi_patch[p_index++] = GET_GUIDE(p); 
#endif
	 
#if WD == 1 // weight discard (moving cumulative average)
	 int r_iter = 1; 
	 val_guide wd_total_weight = val_guide(0); 
	 val wd_sum = val(0); 
#endif

#if V == 7
	 vec2 v7cell = floor(HOOKED_size/R * HOOKED_pos) * R + hr; 
	 vec2 v7cell_off = floor(HOOKED_pos * HOOKED_size) - floor(v7cell); 
#endif

	 FOR_FRAME(r) {
	 // XXX ME is always a frame behind, should have the option to re-research after applying ME (could do it an arbitrary number of times per frame if desired)
#if T && ME == 1 // temporal & motion estimation max weight
	 if (r.z > 0) {
	 	 me += me_tmp * MEF; 
	 	 me_tmp = vec3(0); 
	 	 maxweight = 0; 
	 }
#elif T && ME == 2 // temporal & motion estimation weighted average
	 if (r.z > 0) {
	 	 me += round(DIV(me_sum, me_weight) * MEF); 
	 	 me_sum = vec3(0); 
	 	 me_weight = 0; 
	 }
#endif
	 FOR_RESEARCH(r) {
#if V == 7
	 	 r.xy += v7cell_off; 
#endif

	 	 // r coords with appropriate transformations applied
	 	 vec3 tr = vec3(r.xy + floor(r.xy * RSF), r.z); 
	 	 tr.xy += me.xy; 

	 	 val px = GET(tr); 

#if SKIP_PATCH
	 	 val weight = val(1); 
#else
	 	 val_guide pdiff_sq = (r.z == 0) ? patch_comparison_gather(tr) : patch_comparison(tr); 
	 	 val_guide weight = range(pdiff_sq); 
#endif

#if T && ME == 1 // temporal & motion estimation max weight
	 	 me_tmp = vec3(tr.xy,0) * step(maxweight, weight.x) + me_tmp * (1 - step(maxweight, weight.x)); 
	 	 maxweight = max(maxweight, weight.x); 
#elif T && ME == 2 // temporal & motion estimation weighted average
	 	 me_sum += vec3(tr.xy,0) * weight.x; 
	 	 me_weight += weight.x; 
#endif

	 	 weight *= spatial_r(r); 

#if AS
	 	 float spatial_as_weight = spatial_as(tr); 
	 	 sum_as += px * spatial_as_weight; 
	 	 total_weight_as += spatial_as_weight; 
#endif

#if WD == 1 // weight discard (moving cumulative average)
	 	 float wd_scale = RECIPROCAL(r_iter); 

	 	 val_guide below_threshold = WDS * abs(min(val_guide(0.0), weight - (total_weight * wd_scale * WDT * WD1TK(sqrt(wd_scale*WDP))))); 
	 	 val_guide wdkf = MAP_GUIDE(WDK, below_threshold); 

	 	 wd_sum += px * weight * wdkf; 
	 	 wd_total_weight += weight * wdkf; 
	 	 r_iter++; 
#if STORE_WEIGHTS
	 	 all_weights[r_index] = val_guide_pack(weight * wdkf); 
	 	 all_pixels[r_index] = val_pack(px); 
	 	 r_index++; 
#endif
#elif STORE_WEIGHTS
	 	 all_weights[r_index] = val_guide_pack(weight); 
	 	 all_pixels[r_index] = val_pack(px); 
	 	 r_index++; 
#endif

#if V == 7
	 	 r.xy -= v7cell_off; 
#endif

	 	 sum += px * weight; 
	 	 total_weight += weight; 
	 } // FOR_RESEARCH
	 } // FOR_FRAME

	 val_guide avg_weight = total_weight * r_scale; 

#if defined(LUMA_raw) && V == 4
	 return unval_guide(avg_weight); 
#elif defined(CHROMA_raw) && V == 4
	 return vec4(0.5);  // XXX visualize for chroma
#endif

#if C
	 total_weight = val_guide(0); 
	 sum = val(0); 

	 for (int c = 0;  c <= C;  c++) {
	 	 val_guide_packed all_weights_update[r_area]; 

	 	 r_index = 0; 
	 	 FOR_FRAME(r) FOR_RESEARCH(r) {
	 	 	 val_guide c_sum = val_guide(0); 
	 	 	 vec3 r2 = vec3(0); 
	 	 	 int r2_index = 0; 
	 	 	 FOR_FRAME(r2) FOR_RESEARCH(r2)
	 	 	 	 if (distance(r, r2) - sqrt(CD) <= FLT_EPSILON)
	 	 	 	 	 c_sum += val_guide_unpack(all_weights[r2_index++]); 
	 	 	 if (length(r) - sqrt(CD) <= FLT_EPSILON)
	 	 	 	 c_sum += sw; 
	 	 	 all_weights_update[r_index++] = val_guide_pack(c_sum); 
	 	 }

	 	 r_index = 0; 
	 	 FOR_FRAME(r) FOR_RESEARCH(r) {
	 	 	 val_guide old_weight = val_guide_unpack(all_weights[r_index]); 
	 	 	 val_guide update = val_guide_unpack(all_weights_update[r_index]); 
	 	 	 val_guide weight = old_weight * RECIPROCAL(max(EPSILON,CS))
	 	 	                  + old_weight * update * r1_scale * CS; 
	 	 	 all_weights[r_index] = val_guide_pack(weight); 
	 	 	 if (c == C) { // only need to update this stuff on the final C iteration
	 	 	 	 val px = val_unpack(all_pixels[r_index]); 
	 	 	 	 sum += px * weight; 
	 	 	 	 total_weight += weight; 
	 	 	 	 all_pixels[r_index] = val_pack(px); 
	 	 	 }
	 	 	 r_index++; 
	 	 }
	 } // for C
#endif

#if WD == 2 // weight discard (mean)
	 total_weight = val_guide(0); 
	 sum = val(0); 

	 r_index = 0; 
	 FOR_FRAME(r) FOR_RESEARCH(r) {
	 	 val px = val_unpack(all_pixels[r_index]); 
	 	 val_guide weight = val_guide_unpack(all_weights[r_index]); 

	 	 val_guide below_threshold = WDS * abs(min(val_guide(0.0), weight - (avg_weight * WDT))); 
	 	 weight *= MAP_GUIDE(WDK, below_threshold); 

	 	 sum += px * weight; 
	 	 total_weight += weight; 
#if V == 7
	 	 all_pixels[r_index] = val_pack(px); 
	 	 all_weights[r_index] = val_guide_pack(weight); 
#endif
	 	 r_index++; 
	 } // FOR_FRAME FOR_RESEARCH
#endif

#if WD == 1 // weight discard (moving cumulative average)
	 total_weight = wd_total_weight; 
	 sum = wd_sum; 
#endif

#if WD // weight discard
	 avg_weight = total_weight * r_scale; 
#endif

	 total_weight += sw; 
	 sum += poi * sw; 
	 result = MED_DIV(sum, max(val(EPSILON),val(total_weight))); 

	 // store frames for temporal
#if T > 1

#endif
#if T && TRF
	 imageStore(PREV1, ivec2(HOOKED_pos*HOOKED_size), unval(result)); 
#elif T
	 imageStore(PREV1, ivec2(HOOKED_pos*HOOKED_size), unval_guide(poi2)); 
#endif

#if AS == 1 // sharpen+denoise
#define AS_base result
#elif AS == 2 // sharpen only
#define AS_base poi
#endif

#if ASI == 0
#define AS_input result
#elif ASI == 1
#define AS_input poi
#endif

#if AS // sharpening
	 val usm = AS_input - MED_DIV(sum_as, max(EPSILON,total_weight_as)); 
	 usm = POW(usm, ASP); 
	 const float as_scale_15 = 1.0/1.5; 
	 usm *= ASAK(abs((AS_base + usm - 0.5) * as_scale_15) * ASA); 
	 usm *= ASF; 
	 result = AS_base + usm; 
#endif

#if EP // extremes preserve
	 float luminance = EP_texOff(0).x; 
	 float ep_weight = POW(max(EPSILON, min(1-luminance, luminance)*2), (luminance < 0.5 ? DP : BP)); 
	 result = mix(poi, result, ep_weight); 
#else
	 float ep_weight = 0; 
#endif

#if V == 1
	 result = clamp(pow(abs(poi - result), val(0.25)), 0.0, 1.0); 
#elif V == 2
	 result = (poi - result) * 0.5 + 0.5; 
#elif V == 3
	 result = val(avg_weight); 
#elif V == 5
	 result = 0.5 + usm; 
#elif V == 6
	 result = val(1 - ep_weight); 
#elif V == 7
	 result = val(0); 
	 r_index = 0; 
	 FOR_FRAME(r) FOR_RESEARCH(r) {
	 	 if (v7cell_off == r.xy)
	 	 	 result = val_guide_unpack(all_weights[r_index]); 
	 	 r_index++; 
	 }

	 if (v7cell_off == vec2(0,0))
	 	 result = val(SW * spatial_r(vec3(0))); 
#endif

// XXX visualize chroma for these
#if defined(CHROMA_raw) && (V == 3 || V == 4 || V == 6 || V == 7)
	 return vec4(0.5); 
#endif

	 return unval(result); 
}

// End of source code injected from ./nlmeans_template 

//!HOOK LUMA
//!HOOK CHROMA
//!BIND G
//!WIDTH G.w
//!HEIGHT G.h
//!DESC Non-local means (Guide, share)
//!SAVE GC

vec4 hook()
{
	return G_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!BIND HOOKED
//!BIND G
//!BIND GC
//!DESC Non-local means (HQ/nlmeans.glsl)



// User variables

// It is generally preferable to denoise luma and chroma differently, so the 
// user variables for luma and chroma are split.

// Denoising factor (sigma, higher means more blur)
#ifdef LUMA_raw
#define S 1.0891793821856746
#else
#define S 0.9261970284633889
#endif

/* Noise resistant adaptive sharpening
 *
 * AS:
 * 	- 0: disable
 * 	- 1: sharpen+denoise
 * 	- 2: sharpen only
 * ASF: Higher numbers make a sharper image
 * ASA: Anti-ringing, higher numbers increase strength
 * ASP: Power, lower numbers increase sharpening on lower frequency detail
 * ASS: Equivalent to SS but for ASK instead of SK
 * ASI:
 *  - 0: don't sharpen noise
 *  - 1: sharpen noise
 */
#ifdef LUMA_raw
#define AS 0
#define ASF 0.0
#define ASA 0.0
#define ASP 0.0
#define ASS 0.0
#define ASI 0
#else
#define AS 0
#define ASF 0.0
#define ASA 0.0
#define ASP 0.0
#define ASS 0.0
#define ASI 0
#endif

/* Starting weight
 *
 * AKA the center weight, the weight of the pixel-of-interest.
 */
#ifdef LUMA_raw
#define SW 1.4918935240131503
#else
#define SW 3.3672059070451072
#endif

/* Spatial kernel
 *
 * Increasing the spatial sigma (SS) reduces the weight of further 
 * pixels.
 *
 * The intra-patch variants might help with larger patch sizes.
 *
 * SST: enables spatial kernel if R>=PST, 0 fully disables
 * SS: spatial sigma
 * PSS: intra-patch spatial sigma
 * PST: enables intra-patch spatial kernel if P>=PST, 0 fully disables
 */
#ifdef LUMA_raw
#define SST 1
#define SS 0.12303243413917926
#define PST 0
#define PSS 0.0
#else
#define SST 1
#define SS 0.04608821797323175
#define PST 0
#define PSS 0.0
#endif

/* Extremes preserve
 *
 * This setting is dependent on code generation from shader_cfg, so this 
 * setting can only be enabled via shader_cfg.
 *
 * Reduce denoising in very bright/dark areas.
 *
 * The downscaling factor of the EP shader stage affects the size of the area 
 * checked for luminance.
 *
 * This is incompatible with RGB. If you have RGB hooks enabled then you will 
 * have to delete the EP shader stage or specify EP=0 through shader_cfg.
 *
 * EP: 1 to enable, 0 to disable
 * DP: EP strength on dark areas, 0 to fully denoise
 * BP: EP strength on bright areas, 0 to fully denoise
 */
#ifdef LUMA_raw
#define EP 0
#define BP 0.0
#define DP 0.0
#else
#define EP 0
#define BP 0.0
#define DP 0.0
#endif

/* ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS */
/* ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS */
/* ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS */
/* ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS */
/* ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS * ADVANCED OPTIONS */

/* textureGather applicable configurations:
 *
 * - PS={0,3,7,8}:P=3:RI={0,1,3,7}:RFI={0,1,2}
 * - PS={0,8}:P=3:RI={0,1,3,7}:RFI={0,1,2}
 * - PS=4:P=3:PST=0:RI=0:RFI=0
 * - PS=6:RI=0:RFI=0
 *   - Currently the only scalable variant
 *
 * Options which always disable textureGather:
 * 	- NG
 * 	- SAMPLE
 * 	- PD
 *
 * Running without textureGather may be much slower.
 */

/* Patch & research sizes
 *
 * P should be an odd number. Higher values are slower and not always better.
 *
 * R should be an odd number greater than or equal to 3. Higher values are 
 * generally better, but slower.
 */
#ifdef LUMA_raw
#define P 3
#define R 9
#else
#define P 3
#define R 9
#endif

/* Patch and research shapes
 *
 * Different shapes have different speed and quality characteristics. Every 
 * shape (besides square) is smaller than square.
 *
 * PS applies applies to patches, RS applies to research zones.
 *
 * 0: square (symmetrical)
 * 1: horizontal line (asymmetric)
 * 2: vertical line (asymmetric)
 * 3: diamond (symmetrical)
 * 4: triangle (asymmetric, pointing upward)
 * 5: truncated triangle (asymmetric on two axis, last row halved)
 * 6: even sized square (asymmetric on two axis)
 * 7: plus (symmetrical)
 * 8: plus X (symmetrical)
 */
#ifdef LUMA_raw
#define RS 3
#define PS 0
#else
#define RS 3
#define PS 3
#endif

/* Weight discard
 *
 * Reduces weights that fall below a fraction of the average weight. This culls 
 * the most dissimilar samples from the blur, which can yield a better result, 
 * especially around edges.
 * 
 * WD:
 * 	- 2: Mean. Better quality, but slower and requires GLSL 4.0 or later
 * 	- 1: Moving cumulative average. Fast but inaccurate, blurs directionally.
 * 	- 0: Disable
 *
 * WDT: Threshold coefficient, higher numbers discard more
 * WDP (only for WD=1): Increasing reduces the threshold for small sample sizes
 * WDS (not for WDK=is_zero): Higher numbers are more eager to reduce weights
 */
#ifdef LUMA_raw
#define WD 1
#define WDT 0.0882286053470455
#define WDP 1.060997583415308
#define WDS 1.0
#else
#define WD 0
#define WDT 0.0
#define WDP 0.0
#define WDS 1.0
#endif

/* Connectivity
 *
 * Increases weights that are near high weights, decreases weights that are 
 * near low weights.
 *
 * C: Number of passes to do, more increases the effect, 0 does nothing
 * CD: Distance between each pixel and its furthest neighbor
 * CS: Strength of effect, higher is more
 */
#ifdef LUMA_raw
#define C 0
#define CD 1.0
#define CS 1.0
#else
#define C 0
#define CD 1.0
#define CS 1.0
#endif

/* Rotational/reflectional invariance
 *
 * Number of rotations/reflections to try for each patch comparison. Can be 
 * slow, but may improve feature preservation. More rotations/reflections gives 
 * diminishing returns. The most similar rotation/reflection is used.
 *
 * The angle in degrees of each rotation is 360/(RI+1), so RI=1 will do a 
 * single 180 degree rotation, RI=3 will do three 90 degree rotations, etc.
 *
 * Consider setting SAMPLE=1 if setting RI to a setting that would require 
 * sampling between pixels.
 *
 * RI: Rotational invariance
 * RFI (0 to 2): Reflectional invariance
 */
#ifdef LUMA_raw
#define RI 0
#define RFI 0
#else
#define RI 0
#define RFI 0
#endif

/* Temporal denoising
 *
 * This setting is dependent on code generation from shader_cfg, so this 
 * setting can only be enabled via shader_cfg.
 *
 * Caveats:
 * 	- Slower:
 * 		- Gather optimizations only apply to the current frame
 * 	- Requires vo=gpu-next
 * 	- Luma-only (this is a bug)
 * 	- Buggy
 *
 * May cause motion blur and may struggle more with noise that persists across 
 * multiple frames (e.g., from compression or duplicate frames).
 *
 * Motion estimation (ME) should improve quality without impacting speed.
 *
 * Increasing temporal distortion (TD) can reduce motion blur.
 *
 * T: number of frames used
 * ME: motion estimation, 0 for none, 1 for max weight, 2 for weighted avg
 * MEF: estimate factor, compensates for ME being one frame behind
 * TRF: compare against the denoised frames
 * TD: temporal distortion, higher numbers give less weight to previous frames
 */
#ifdef LUMA_raw
#define T 0
#define ME 1
#define MEF 2
#define TRF 0
#define TD 1.0
#else
#define T 0
#define ME 0
#define MEF 2
#define TRF 0
#define TD 1.0
#endif

/* Kernels
 *
 * SK: spatial kernel
 * RK: range kernel (takes patch differences)
 * ASK: adaptive sharpening kernel
 * PSK: intra-patch spatial kernel
 * WDK: weight discard kernel
 * WD1TK (WD=1 only): weight discard tolerance kernel
 *
 * List of available kernels:
 *
 * bicubic
 * cosine
 * cosine_
 * ffexp
 * gaussian
 * ginseng
 * ginseng_ (unclamped)
 * jinc
 * jinc3
 * jinc_ (unclamped)
 * jincjinc
 * jincjinc3
 * jincjinc3_ (unclamped)
 * jincjinc_ (unclamped)
 * lanczos
 * quadratic
 * quadratic_ (unclamped)
 * sinc
 * sinc3
 * sinc_ (unclamped)
 * sphinx
 * sphinx_ (unclamped)
 * triangle
 * triangle_ (unclamped)
 */
#ifdef LUMA_raw
#define SK gaussian
#define RK gaussian
#define ASK sinc
#define ASAK gaussian
#define PSK gaussian
#define WDK is_zero
#define WD1TK gaussian
#else
#define SK gaussian
#define RK gaussian
#define ASK sphinx_
#define ASAK gaussian
#define PSK gaussian
#define WDK is_zero
#define WD1TK gaussian
#endif

/* Kernel parameters
 *
 * The following kernels take these parameters:
 *
 * ffexp: K0
 * ginseng: KWS
 * jincjinc3: KWS
 * jincjinc: KWS
 * lanczos: KWS
 */
#ifdef LUMA_raw
#define K0 1.0
#define K1 1.0
#define KWS 1.0
#else
#define K0 1.0
#define K1 1.0
#define KWS 1.0
#endif

/* Negative kernel parameter offsets
 *
 * Usually kernels go high -> low. These parameters allow for a kernel to go 
 * low -> high -> low.
 *
 * Values of 0.0 mean no effect, higher values increase the effect.
 *
 * RO: range kernel (takes patch differences)
 */
#ifdef LUMA_raw
#define RO 2.603846182420303e-05
#else
#define RO 0.00012555521925975498
#endif

/* Sampling method
 *
 * In most cases this shouldn't make any difference, only set to bilinear if 
 * it's necessary to sample between pixels (e.g., RI=2).
 *
 * 0: nearest neighbor
 * 1: bilinear
 */
#ifdef LUMA_raw
#define SAMPLE 0
#else
#define SAMPLE 0
#endif

/* Research scaling factor
 *
 * Higher numbers sample more sparsely as the distance from the POI grows.
 */
#ifdef LUMA_raw
#define RSF 0.0
#else
#define RSF 0.0
#endif

// Scaling factor (should match WIDTH/HEIGHT)
#ifdef LUMA_raw
#define SF 1
#else
#define SF 1
#endif

// Use the guide image as the input image
#ifdef LUMA_raw
#define GI 1
#else
#define GI 1
#endif

/* Visualization
 *
 * 0: off
 * 1: absolute difference between input/output to the power of 0.25
 * 2: difference between input/output centered on 0.5
 * 3: post-WD average weight map
 * 4: pre-WD average weight map
 * 5: unsharp mask
 * 6: EP
 * 7: celled weight map (incompatible with temporal)
 */
#ifdef LUMA_raw
#define V 0
#else
#define V 0
#endif

// Fast approximate division
#ifdef LUMA_raw
#define FAST_DIV 0
#else
#define FAST_DIV 0
#endif

// Force disable textureGather
#ifdef LUMA_raw
#define NG 0
#else
#define NG 0
#endif

// Patch donut (probably useless)
#ifdef LUMA_raw
#define PD 0
#else
#define PD 0
#endif

// Duplicate 1st weight (for luma-guided-chroma)
#ifdef LUMA_raw
#define D1W 0
#else
#define D1W 0
#endif

// Skip patch comparison
#ifdef LUMA_raw
#define SKIP_PATCH 0
#else
#define SKIP_PATCH 0
#endif

// Shader code

#define EPSILON 1.2e-38
#define FLT_EPSILON 1.19209290E-07
#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define M_PI_4 0.78539816339744830962
#define M_1_PI 0.31830988618379067154
#define M_2_PI 0.63661977236758134308
#define POW2(x) ((x)*(x))
#define POW3(x) ((x)*(x)*(x))
#define POW4(x) ((x)*(x)*(x)*(x))
#define POW5(x) ((x)*(x)*(x)*(x)*(x))
#define POW6(x) ((x)*(x)*(x)*(x)*(x)*(x))
#define POW7(x) ((x)*(x)*(x)*(x)*(x)*(x)*(x))

// pow() implementation that gives -pow() when x<0
// avoids actually calling pow() since apparently it's buggy on nvidia
#define POW(x,y) (exp(log(abs(x)) * y) * sign(x))

// boolean logic w/ vectors
// from hdeband
#define NOT(x) (1 - (x))
#define AND *
#define TERNARY(cond, x, y) ((x)*(cond) + (y)*NOT(cond))

// from FSR
#if FAST_DIV
#define RECIPROCAL(x) uintBitsToFloat(uint(0x7ef07ebb) - floatBitsToUint(x))
#define DIV(x,y) ((x) * RECIPROCAL(y))
#define MED_RCP_B(x) uintBitsToFloat(uint(0x7ef19fff) - floatBitsToUint(x))
#define MED_RECIPROCAL(x) (MED_RCP_B(x) * (-MED_RCP_B(x) * x + 2))
#define MED_DIV(x,y) ((x) * MED_RECIPROCAL(y))
#else
#define RECIPROCAL(x) (1.0/(x))
#define MED_RECIPROCAL(x) (1.0/(x))
#define DIV(x,y) ((x)/(y))
#define MED_DIV(x,y) ((x)/(y))
#endif

// adapted from https://github.com/garamond13/Jinc
#define j1(x) TERNARY(step((x), 2.2931157), ((x) * 0.5) - (POW3(x) * 0.0625) + (POW5(x) * 0.00260416666666666666) - (POW7(x) * 0.00005425347222222222), sqrt(DIV(M_2_PI, (x))) * (1.0 + DIV(0.1875, POW2(x)) - DIV(0.1933594, POW4(x))) * cos((x) - 3.0 * M_PI_4 + DIV(0.375, (x)) - DIV(0.1640625, POW3(x))))

// XXX make kernel params capable of being set per-kernel, e.g., RK0, SK0...

// kernels, most of these are from libplacebo
// XXX sinc/jinc/sphinx: 1e-3 was selected tentatively; not sure what the correct value should be (1e-8 is too low, x is never considered to be lower than it for some reason)
#define bicubic(x) bicubic_(clamp(x, 0.0, 2.0))
#define bicubic_(x) ((1.0/6.0) * (POW3((x)+2) - 4 * POW3((x)+1) + 6 * POW3(x) - 4 * POW3(max((x)-1, 0))))
#define cosine(x) cos(clamp(x, 0, M_PI_2))
#define cosine_ cos
#define ffexp(x) (POW(cos(max(EPSILON, clamp(x, 0.0, 1.0) * M_PI)), K0) * 0.5 + 0.5) // "experimental" scaler from ffmpeg
#define gaussian(x) exp(-1 * POW2(x))
#define ginseng(x) ginseng_(clamp(x, 0.0, 3.0))
#define ginseng_(x) (jinc(x) * sinc(x*KWS))
#define is_zero(x) int((x) == 0)
#define jinc(x) jinc_(clamp(x, 0.0, 1.2196698912665045))
#define jinc3(x) jinc_(clamp(x, 0.0, 3.2383154841662362))
#define jinc_(x) TERNARY(step(x, 1e-3), 1.0, DIV(2 * j1((x)*M_PI), (x)*M_PI))
#define jincjinc(x) jincjinc_(clamp(x, 0.0, 3.2383154841662362))
#define jincjinc3(x) jincjinc3_(clamp(x, 0.0, 3.2383154841662362))
#define jincjinc3_(x) (jinc(x) * jinc3(x*KWS))
#define jincjinc_(x) (jinc(x) * jinc(x*KWS))
#define lanczos(x) lanczos_(clamp(x, 0.0, 3.0))
#define lanczos_(x) (sinc3(x) * sinc(x*KWS))
#define quadratic(x) quadratic_(clamp(x, 0.0, 1.5))
#define quadratic_(x) TERNARY(step(x, 0.5), 0.75 - POW2(x), 0.5 * POW2((x) - 1.5))
#define sinc(x) sinc_(clamp(x, 0.0, 1.0))
#define sinc3(x) sinc_(clamp(x, 0.0, 3.0))
#define sinc_(x) TERNARY(step(x, 1e-3), 1.0, DIV(sin((x)*M_PI), ((x)*M_PI)))
#define sphinx(x) sphinx_(clamp(x, 0.0, 1.4302966531242027))
#define sphinx_(x) TERNARY(step(x, 1e-3), 1.0, DIV(3.0 * (sin((x)*M_PI) - (x)*M_PI * cos((x)*M_PI)), POW3((x)*M_PI)))
#define triangle(x) triangle_(clamp(x, 0.0, 1.0))
#define triangle_(x) (1 - (x))

#define MAP1(f,param) f(param)
#define MAP2(f,param) vec2(f(param.x), f(param.y))
#define MAP3(f,param) vec3(f(param.x), f(param.y), f(param.z))

#if defined(LUMA_raw)
#define val float
#define val_swizz(v) (v.x)
#define unval(v) vec4(v, 0, 0, poi_.a)
#define val_packed val
#define val_pack(v) (v)
#define val_unpack(v) (v)
#define MAP MAP1
#elif defined(CHROMA_raw)
#define val vec2
#define val_swizz(v) (v.xy)
#define unval(v) vec4(v.x, v.y, 0, poi_.a)
#define val_packed uint
#define val_pack(v) packUnorm2x16(v)
#define val_unpack(v) unpackUnorm2x16(v)
#define MAP MAP2
#else
#define val vec3
#define val_swizz(v) (v.xyz)
#define unval(v) vec4(v.x, v.y, v.z, poi_.a)
#define val_packed val
#define val_pack(v) (v)
#define val_unpack(v) (v)
#define MAP MAP3
#endif

#if D1W // float guide
#define val_guide float
#define val_guide_swizz(v) (v.x)
#define val_guide_packed float
#define val_guide_pack(v) (v)
#define val_guide_unpack(v) (v)
#define MAP_GUIDE MAP1
#define unval_guide(v) vec4(v, 0, 0, poi2_.a)
#else // val guide
#define val_guide val
#define val_guide_swizz val_swizz
#define val_guide_packed val_packed
#define val_guide_pack val_pack
#define val_guide_unpack val_unpack
#define MAP_GUIDE MAP
#if defined(LUMA_raw)
#define unval_guide(v) vec4(v, 0, 0, poi2_.a)
#elif defined(CHROMA_raw)
#define unval_guide(v) vec4(v.x, v.y, 0, poi2_.a)
#else
#define unval_guide(v) vec4(v.x, v.y, v.z, poi2_.a)
#endif
#endif

#if PS == 6
const int hp = P/2;
#else
const float hp = int(P/2) - 0.5*(1-(P%2)); // sample between pixels for even patch sizes
#endif

#if RS == 6
const int hr = R/2;
#else
const float hr = int(R/2) - 0.5*(1-(R%2)); // sample between pixels for even research sizes
#endif

// patch/research shapes
// each shape is depicted in a comment, where Z=5 (Z corresponds to P or R)
// dots (.) represent samples (pixels) and X represents the pixel-of-interest

// Z    .....
// Z    .....
// Z    ..X..
// Z    .....
// Z    .....
#define S_SQUARE(z,hz,incr) for (z.x = -hz; z.x <= hz; z.x++) for (z.y = -hz; z.y <= hz; incr)

// (in this instance Z=4)
// Z    ....
// Z    ....
// Z    ..X.
// Z    ....
#define S_SQUARE_EVEN(z,hz,incr) for (z.x = -hz; z.x < hz; z.x++) for (z.y = -hz; z.y < hz; incr)

// Z-4    .
// Z-2   ...
// Z    ..X..
#define S_TRIANGLE(z,hz,incr) for (z.y = -hz; z.y <= 0; z.y++) for (z.x = -abs(abs(z.y) - hz); z.x <= abs(abs(z.y) - hz); incr)

// Z-4    .
// Z-2   ...
// hz+1 ..X
#define S_TRUNC_TRIANGLE(z,hz,incr) for (z.y = -hz; z.y <= 0; z.y++) for (z.x = -abs(abs(z.y) - hz); z.x <= abs(abs(z.y) - hz)*int(z.y!=0); incr)
#define S_TRIANGLE_A(hz,Z) int(hz*hz+Z)

// Z-4    .
// Z-2   ...
// Z    ..X..
// Z-2   ...
// Z-4    .
#define S_DIAMOND(z,hz,incr) for (z.x = -hz; z.x <= hz; z.x++) for (z.y = -abs(abs(z.x) - hz); z.y <= abs(abs(z.x) - hz); incr)
#define S_DIAMOND_A(hz,Z) int(hz*hz*2+Z)

//
// Z    ..X..
//
#define S_HORIZONTAL(z,hz,incr) for (z.y = 0; z.y <= 0; z.y++) for (z.x = -hz; z.x <= hz; incr)

// 90 degree rotation of S_HORIZONTAL
#define S_VERTICAL(z,hz,incr) for (z.x = 0; z.x <= 0; z.x++) for (z.y = -hz; z.y <= hz; incr)

// 1      .
// 1      . 
// Z    ..X..
// 1      . 
// 1      .
#define S_PLUS(z,hz,incr) for (z.x = -hz; z.x <= hz; z.x++) for (z.y = -hz * int(z.x == 0); z.y <= hz * int(z.x == 0); incr)
#define S_PLUS_A(hz,Z) (Z*2 - 1)

// 3    . . .
// 3     ...
// Z    ..X..
// 3     ...
// 3    . . .
#define S_PLUS_X(z,hz,incr) for (z.x = -hz; z.x <= hz; z.x++) for (z.y = -abs(z.x) + -hz * int(z.x == 0); z.y <= abs(z.x) + hz * int(z.x == 0); incr)
#define S_PLUS_X_A(hz,Z) (Z*4 - 3)

// 1x1 square
#define S_1X1(z) for (z = vec3(0); z.x <= 0; z.x++)

#define T1 (T+1)
#define FOR_FRAME(r) for (r.z = 0; r.z < T1; r.z++)

// donut increment, increments without landing on (0,0,0)
// much faster than a continue statement
#define DINCR(z,c,a) ((z.c += a),(z.c += int(z == vec3(0))))

#define R_AREA(a) (a * T1 - 1)

// research shapes
// XXX would be nice to have the option of temporally-varying research sizes
#if R == 0 || R == 1
#define FOR_RESEARCH(r) S_1X1(r)
const int r_area = R_AREA(1);
#elif RS == 8
#define FOR_RESEARCH(r) S_PLUS_X(r,hr,DINCR(r,y,max(1,abs(r.x))))
const int r_area = R_AREA(S_PLUS_X_A(hr,R));
#elif RS == 7
#define FOR_RESEARCH(r) S_PLUS(r,hr,DINCR(r,y,1))
const int r_area = R_AREA(S_PLUS_A(hr,R));
#elif RS == 6
#define FOR_RESEARCH(r) S_SQUARE_EVEN(r,hr,DINCR(r,y,1))
const int r_area = R_AREA(R*R);
#elif RS == 5
#define FOR_RESEARCH(r) S_TRUNC_TRIANGLE(r,hr,DINCR(r,x,1))
const int r_area = R_AREA(S_TRIANGLE_A(hr,hr));
#elif RS == 4
#define FOR_RESEARCH(r) S_TRIANGLE(r,hr,DINCR(r,x,1))
const int r_area = R_AREA(S_TRIANGLE_A(hr,R));
#elif RS == 3
#define FOR_RESEARCH(r) S_DIAMOND(r,hr,DINCR(r,y,1))
const int r_area = R_AREA(S_DIAMOND_A(hr,R));
#elif RS == 2
#define FOR_RESEARCH(r) S_VERTICAL(r,hr,DINCR(r,y,1))
const int r_area = R_AREA(R);
#elif RS == 1
#define FOR_RESEARCH(r) S_HORIZONTAL(r,hr,DINCR(r,x,1))
const int r_area = R_AREA(R);
#elif RS == 0
#define FOR_RESEARCH(r) S_SQUARE(r,hr,DINCR(r,y,1))
const int r_area = R_AREA(R*R);
#endif

#define RI1 (RI+1)
#define RFI1 (RFI+1)

#if RI
#define FOR_ROTATION for (float ri = 0; ri < 360; ri += DIV(360.0, RI1))
#else
#define FOR_ROTATION
#endif

#if RFI
#define FOR_REFLECTION for (int rfi = 0; rfi < RFI1; rfi++)
#else
#define FOR_REFLECTION
#endif

#if PD
#define PINCR DINCR
#else
#define PINCR(z,c,a) (z.c += a)
#endif

#define P_AREA(a) (a - PD)

// patch shapes
#if P == 0 || P == 1
#define FOR_PATCH(p) S_1X1(p)
const int p_area = P_AREA(1);
#elif PS == 8
#define FOR_PATCH(p) S_PLUS_X(p,hp,PINCR(p,y,max(1,abs(p.x))))
const int p_area = P_AREA(S_PLUS_X_A(hp,P));
#elif PS == 7
#define FOR_PATCH(p) S_PLUS(p,hp,PINCR(p,y,1))
const int p_area = P_AREA(S_PLUS_A(hp,P));
#elif PS == 6
#define FOR_PATCH(p) S_SQUARE_EVEN(p,hp,PINCR(p,y,1))
const int p_area = P_AREA(P*P);
#elif PS == 5
#define FOR_PATCH(p) S_TRUNC_TRIANGLE(p,hp,PINCR(p,x,1))
const int p_area = P_AREA(S_TRIANGLE_A(hp,hp));
#elif PS == 4
#define FOR_PATCH(p) S_TRIANGLE(p,hp,PINCR(p,x,1))
const int p_area = P_AREA(S_TRIANGLE_A(hp,P));
#elif PS == 3
#define FOR_PATCH(p) S_DIAMOND(p,hp,PINCR(p,y,1))
const int p_area = P_AREA(S_DIAMOND_A(hp,P));
#elif PS == 2
#define FOR_PATCH(p) S_VERTICAL(p,hp,PINCR(p,y,1))
const int p_area = P_AREA(P);
#elif PS == 1
#define FOR_PATCH(p) S_HORIZONTAL(p,hp,PINCR(p,x,1))
const int p_area = P_AREA(P);
#elif PS == 0
#define FOR_PATCH(p) S_SQUARE(p,hp,PINCR(p,y,1))
const int p_area = P_AREA(P*P);
#endif

const float r_scale = 1.0/r_area;
const float r1_scale = 1.0/(r_area+1);
const float p_scale = 1.0/p_area;
const float hr_scale = 1.0/hr;

#if SAMPLE == 0
#define sample(tex, pos, size, pt, off) tex((pos) + (pt) * (vec2(off) + 0.5 - fract((pos) * (size))))
#else
#define sample(tex, pos, size, pt, off) tex((pos) + (pt) * vec2(off))
#endif

/* Guide images are bound through the G (luma) GC (chroma, or non-luma) 
 * textures. When bound, these are where the weights are computed. Otherwise 
 * the weights are computed on the hooked texture.
 */

#if GI && defined(LUMA_raw)
#define GET_(off) sample(G_tex, G_pos, G_size, G_pt, off)
#elif GI
#define GET_(off) sample(GC_tex, GC_pos, GC_size, GC_pt, off)
#else
#define GET_(off) sample(HOOKED_tex, HOOKED_pos, HOOKED_size, HOOKED_pt, off)
#endif

#if defined(G_raw) && (defined(LUMA_raw) || D1W)
#define GET_GUIDE_(off) sample(G_tex, G_pos, G_size, G_pt, off)
#define gather_offs(off, off_arr) (G_mul * vec4(textureGatherOffsets(G_raw, G_pos + vec2(off) * G_pt, off_arr)))
#define gather(off) G_gather(G_pos + (off) * G_pt, 0)
#elif defined(GC_raw)
#define GET_GUIDE_(off) sample(GC_tex, GC_pos, GC_size, GC_pt, off)
#else
#define GET_GUIDE_(off) GET_(off)
#define gather_offs(off, off_arr) (HOOKED_mul * vec4(textureGatherOffsets(HOOKED_raw, HOOKED_pos + vec2(off) * HOOKED_pt, off_arr)))
#define gather(off) HOOKED_gather(HOOKED_pos + (off)*HOOKED_pt, 0)
#endif

#if T
val GET(vec3 off)
{
	switch (min(int(off.z), frame)) {
	case 0: return val_swizz(GET_(off));

	}
}
val GET_GUIDE(vec3 off)
{
	return off.z == 0 ? val_guide_swizz(GET_GUIDE_(off)) : GET(off);
}
#else
#define GET(off) val_swizz(GET_(off))
#define GET_GUIDE(off) val_guide_swizz(GET_GUIDE_(off))
#endif

vec4 poi_ = GET_(vec3(0));
vec4 poi2_ = GET_GUIDE_(vec3(0));
val poi = val_swizz(poi_); // pixel-of-interest
val_guide poi2 = val_guide_swizz(poi2_); // guide pixel-of-interest

#if RI // rotation
vec2 rot(vec2 p, float d)
{
	return vec2(
		p.x * cos(radians(d)) - p.y * sin(radians(d)),
		p.y * sin(radians(d)) + p.x * cos(radians(d))
	);
}
#else
#define rot(p, d) (p)
#endif

#if RFI // reflection
vec2 ref(vec2 p, int d)
{
	switch (d) {
	case 0: return p;
	case 1: return p * vec2(1, -1);
	case 2: return p * vec2(-1, 1);
	}
}
#else
#define ref(p, d) (p)
#endif

#if SST && R >= SST
float spatial_r(vec3 v)
{
	v.xy += 0.5 - fract(HOOKED_pos*HOOKED_size);
	v.z *= TD;
	return SK(length(v)*SS);
}
#else
#define spatial_r(v) (1)
#endif

// 2D blur for sharpening
#if AS
float spatial_as(vec3 v)
{
	v.xy += 0.5 - fract(HOOKED_pos*HOOKED_size);
	return ASK(length(v)*ASS) * int(v.z == 0);
}
#endif

#if PST && P >= PST
#define spatial_p(v) PSK(length(v)*PSS)
#define normalize_p(x,expr) DIV((x), (expr))
#else
#define spatial_p(v) (1)
#define normalize_p(x,expr) ((x) * p_scale)
#endif

const float pdiff_scale = 1.0/max(EPSILON,POW2(S*0.013));
val_guide range(val_guide pdiff_sq)
{
	pdiff_sq = sqrt(abs(pdiff_sq - max(EPSILON, RO)) * pdiff_scale);
	return RK(pdiff_sq);
}

#define GATHER (PD == 0 && NG == 0 && SAMPLE == 0) // never textureGather if any of these conditions are false
#define REGULAR_ROTATIONS (RI == 0 || RI == 1 || RI == 3 || RI == 7)

#if (defined(LUMA_gather) || D1W) && ((PS == 0 || ((PS == 3 || PS == 7) && RI != 7) || PS == 8) && P == 3) && REGULAR_ROTATIONS && GATHER
// 3x3 diamond/plus or square patch_comparison_gather
const ivec2 offsets_adj[4] = { ivec2(0,-1), ivec2(1,0), ivec2(0,1), ivec2(-1,0) };
const ivec2 offsets_adj_sf[4] = { ivec2(0,-1) * SF, ivec2(1,0) * SF, ivec2(0,1) * SF, ivec2(-1,0) * SF };
vec4 poi_patch_adj = gather_offs(0, offsets_adj);
#if PS == 0 || PS == 8
const ivec2 offsets_diag[4] = { ivec2(-1,-1), ivec2(1,-1), ivec2(1,1), ivec2(-1,1) };
const ivec2 offsets_diag_sf[4] = { ivec2(-1,-1) * SF, ivec2(1,-1) * SF, ivec2(1,1) * SF, ivec2(-1,1) * SF };
vec4 poi_patch_diag = gather_offs(0, offsets_diag);
#endif
float patch_comparison_gather(vec3 r)
{
	float min_rot = p_area - 1;
	vec4 transformer_adj = gather_offs(r, offsets_adj_sf);
#if PS == 0 || PS == 8
	vec4 transformer_diag = gather_offs(r, offsets_diag_sf);
#endif
	FOR_ROTATION {
		FOR_REFLECTION {
#if RFI
			/* xxy
			 * w y
			 * wzz
			 */
			switch(rfi) {
			case 1:
				transformer_adj = transformer_adj.zyxw;
#if PS == 0 || PS == 8
				transformer_diag = transformer_diag.zyxw;
#endif
				break;
			case 2:
				transformer_adj = transformer_adj.xwzy;
#if PS == 0 || PS == 8
				transformer_diag = transformer_diag.xwzy;
#endif
				break;
			}
#endif

			vec4 pdiff_sq = POW2(poi_patch_adj - transformer_adj) * spatial_p(vec2(1,0));
#if PS == 0 || PS == 8
			pdiff_sq += POW2(poi_patch_diag - transformer_diag) * spatial_p(vec2(1,1));
#endif
			min_rot = min(dot(pdiff_sq, vec4(1)), min_rot);

// un-reflect
#if RFI
			switch(rfi) {
			case 1:
				transformer_adj = transformer_adj.zyxw;
#if PS == 0 || PS == 8
				transformer_diag = transformer_diag.zyxw;
#endif
				break;
			case 2:
				transformer_adj = transformer_adj.xwzy;
#if PS == 0 || PS == 8
				transformer_diag = transformer_diag.xwzy;
#endif
				break;
			}
#endif
		} // FOR_REFLECTION
#if RI == 7
		transformer_adj = transformer_adj.wxyz;
		// swap adjacents for diagonals
		transformer_adj += transformer_diag;
		transformer_diag = transformer_adj - transformer_diag;
		transformer_adj -= transformer_diag;
#elif RI == 3
		transformer_adj = transformer_adj.wxyz;
#elif RI == 1
		transformer_adj = transformer_adj.zwxy;
#endif
#if RI == 3 && (PS == 0 || PS == 8)
		transformer_diag = transformer_diag.wxyz;
#elif RI == 1 && (PS == 0 || PS == 8)
		transformer_diag = transformer_diag.zwxy;
#endif
	} // FOR_ROTATION
	
#if PS == 0 || PS == 8
	float total_weight = spatial_p(vec2(0,0)) + 4 * spatial_p(vec2(0,1)) + 4 * spatial_p(vec2(1,1));
#else
	float total_weight = spatial_p(vec2(0,0)) + 4 * spatial_p(vec2(0,1));
#endif

	float center_diff = poi2.x - GET_GUIDE(r).x;
	return normalize_p(POW2(center_diff) + min_rot, max(EPSILON,total_weight));
}
#elif (defined(LUMA_gather) || D1W) && PS == 4 && P == 3 && RI == 0 && RFI == 0 && GATHER
const ivec2 offsets[4] = { ivec2(0,-1), ivec2(-1,0), ivec2(0,0), ivec2(1,0) };
const ivec2 offsets_sf[4] = { ivec2(0,-1) * SF, ivec2(-1,0) * SF, ivec2(0,0) * SF, ivec2(1,0) * SF };
vec4 poi_patch = gather_offs(0, offsets);
vec4 spatial_p_weights = vec4(spatial_p(vec2(0,-1)), spatial_p(vec2(-1,0)), spatial_p(vec2(0,0)), spatial_p(vec2(1,0)));
float patch_comparison_gather(vec3 r)
{
	vec4 pdiff = poi_patch - gather_offs(r, offsets_sf);
	return normalize_p(
		dot(POW2(pdiff) * spatial_p_weights, vec4(1)),
		dot(spatial_p_weights, vec4(1))
	);
}
#elif (defined(LUMA_gather) || D1W) && PS == 6 && RI == 0 && RFI == 0 && GATHER
// tiled even square patch_comparison_gather
// XXX extend to support odd square?
float patch_comparison_gather(vec3 r)
{
	/* gather order:
	 * w z
	 * x y
	 */
	vec2 tile;
	float pdiff_sq = 0;
	float total_weight = 0;
	for (tile.x = -hp; tile.x < hp; tile.x+=2) for (tile.y = -hp; tile.y < hp; tile.y+=2) {
		vec4 diff = gather(tile + r.xy) - gather(tile);
		vec4 weights = vec4(spatial_p(tile+vec2(0,1)), spatial_p(tile+vec2(1,1)), spatial_p(tile+vec2(1,0)), spatial_p(tile+vec2(0,0)));
		pdiff_sq += dot(POW2(diff) * weights, vec4(1));
		total_weight += dot(weights, vec4(1));
	}

	return normalize_p(pdiff_sq, max(EPSILON,total_weight));
}
#else
#define patch_comparison_gather patch_comparison
#define STORE_POI_PATCH 1
val_guide poi_patch[p_area];
#endif

val_guide patch_comparison(vec3 r)
{
	vec3 p;
	val_guide min_rot = val_guide(p_area);

	FOR_ROTATION FOR_REFLECTION {
		val_guide pdiff_sq = val_guide(0);
		float total_weight = 0;

		int p_index = 0;
		FOR_PATCH(p) {
#ifdef STORE_POI_PATCH
			val_guide poi_p = poi_patch[p_index++];
#else
			val_guide poi_p = GET_GUIDE(p);
#endif
			vec3 transformed_p = SF * vec3(ref(rot(p.xy, ri), rfi), p.z);
			val_guide diff_sq = poi_p - GET_GUIDE(transformed_p + r);
			diff_sq *= diff_sq;

			float weight = spatial_p(p.xy);
			pdiff_sq += diff_sq * weight;
			total_weight += weight;
		}

		min_rot = min(min_rot, normalize_p(pdiff_sq, max(EPSILON,total_weight)));
	}

	return min_rot;
}

vec4 hook()
{
	val_guide total_weight = val_guide(0);
	val sum = val(0);
	val result = val(0);

	vec3 r = vec3(0);
	vec3 me = vec3(0);

	float sw = SW * spatial_r(vec3(0));

#if T && ME == 1 // temporal & motion estimation
	vec3 me_tmp = vec3(0);
	float maxweight = 0;
#elif T && ME == 2 // temporal & motion estimation
	vec3 me_sum = vec3(0);
	float me_weight = 0;
#endif

#if AS
	float total_weight_as = 0;
	val sum_as = val(0);
#endif

#if WD == 2 || V == 7 || C
#define STORE_WEIGHTS 1
#else
#define STORE_WEIGHTS 0
#endif

#if STORE_WEIGHTS
	int r_index = 0;
	val_guide_packed all_weights[r_area];
	val_packed all_pixels[r_area];
#endif

#ifdef STORE_POI_PATCH
	vec3 p;
	int p_index = 0;
	FOR_PATCH(p)
		poi_patch[p_index++] = GET_GUIDE(p);
#endif
	
#if WD == 1 // weight discard (moving cumulative average)
	int r_iter = 1;
	val_guide wd_total_weight = val_guide(0);
	val wd_sum = val(0);
#endif

#if V == 7
	vec2 v7cell = floor(HOOKED_size/R * HOOKED_pos) * R + hr;
	vec2 v7cell_off = floor(HOOKED_pos * HOOKED_size) - floor(v7cell);
#endif

	FOR_FRAME(r) {
	// XXX ME is always a frame behind, should have the option to re-research after applying ME (could do it an arbitrary number of times per frame if desired)
#if T && ME == 1 // temporal & motion estimation max weight
	if (r.z > 0) {
		me += me_tmp * MEF;
		me_tmp = vec3(0);
		maxweight = 0;
	}
#elif T && ME == 2 // temporal & motion estimation weighted average
	if (r.z > 0) {
		me += round(DIV(me_sum, me_weight) * MEF);
		me_sum = vec3(0);
		me_weight = 0;
	}
#endif
	FOR_RESEARCH(r) {
#if V == 7
		r.xy += v7cell_off;
#endif

		// r coords with appropriate transformations applied
		vec3 tr = vec3(r.xy + floor(r.xy * RSF), r.z);
		tr.xy += me.xy;

		val px = GET(tr);

#if SKIP_PATCH
		val weight = val(1);
#else
		val_guide pdiff_sq = (r.z == 0) ? patch_comparison_gather(tr) : patch_comparison(tr);
		val_guide weight = range(pdiff_sq);
#endif

#if T && ME == 1 // temporal & motion estimation max weight
		me_tmp = vec3(tr.xy,0) * step(maxweight, weight.x) + me_tmp * (1 - step(maxweight, weight.x));
		maxweight = max(maxweight, weight.x);
#elif T && ME == 2 // temporal & motion estimation weighted average
		me_sum += vec3(tr.xy,0) * weight.x;
		me_weight += weight.x;
#endif

		weight *= spatial_r(r);

#if AS
		float spatial_as_weight = spatial_as(tr);
		sum_as += px * spatial_as_weight;
		total_weight_as += spatial_as_weight;
#endif

#if WD == 1 // weight discard (moving cumulative average)
		float wd_scale = RECIPROCAL(r_iter);

		val_guide below_threshold = WDS * abs(min(val_guide(0.0), weight - (total_weight * wd_scale * WDT * WD1TK(sqrt(wd_scale*WDP)))));
		val_guide wdkf = MAP_GUIDE(WDK, below_threshold);

		wd_sum += px * weight * wdkf;
		wd_total_weight += weight * wdkf;
		r_iter++;
#if STORE_WEIGHTS
		all_weights[r_index] = val_guide_pack(weight * wdkf);
		all_pixels[r_index] = val_pack(px);
		r_index++;
#endif
#elif STORE_WEIGHTS
		all_weights[r_index] = val_guide_pack(weight);
		all_pixels[r_index] = val_pack(px);
		r_index++;
#endif

#if V == 7
		r.xy -= v7cell_off;
#endif

		sum += px * weight;
		total_weight += weight;
	} // FOR_RESEARCH
	} // FOR_FRAME

	val_guide avg_weight = total_weight * r_scale;

#if defined(LUMA_raw) && V == 4
	return unval_guide(avg_weight);
#elif defined(CHROMA_raw) && V == 4
	return vec4(0.5); // XXX visualize for chroma
#endif

#if C
	total_weight = val_guide(0);
	sum = val(0);

	for (int c = 0; c <= C; c++) {
		val_guide_packed all_weights_update[r_area];

		r_index = 0;
		FOR_FRAME(r) FOR_RESEARCH(r) {
			val_guide c_sum = val_guide(0);
			vec3 r2 = vec3(0);
			int r2_index = 0;
			FOR_FRAME(r2) FOR_RESEARCH(r2)
				if (distance(r, r2) - sqrt(CD) <= FLT_EPSILON)
					c_sum += val_guide_unpack(all_weights[r2_index++]);
			if (length(r) - sqrt(CD) <= FLT_EPSILON)
				c_sum += sw;
			all_weights_update[r_index++] = val_guide_pack(c_sum);
		}

		r_index = 0;
		FOR_FRAME(r) FOR_RESEARCH(r) {
			val_guide old_weight = val_guide_unpack(all_weights[r_index]);
			val_guide update = val_guide_unpack(all_weights_update[r_index]);
			val_guide weight = old_weight * RECIPROCAL(max(EPSILON,CS))
			                 + old_weight * update * r1_scale * CS;
			all_weights[r_index] = val_guide_pack(weight);
			if (c == C) { // only need to update this stuff on the final C iteration
				val px = val_unpack(all_pixels[r_index]);
				sum += px * weight;
				total_weight += weight;
				all_pixels[r_index] = val_pack(px);
			}
			r_index++;
		}
	} // for C
#endif

#if WD == 2 // weight discard (mean)
	total_weight = val_guide(0);
	sum = val(0);

	r_index = 0;
	FOR_FRAME(r) FOR_RESEARCH(r) {
		val px = val_unpack(all_pixels[r_index]);
		val_guide weight = val_guide_unpack(all_weights[r_index]);

		val_guide below_threshold = WDS * abs(min(val_guide(0.0), weight - (avg_weight * WDT)));
		weight *= MAP_GUIDE(WDK, below_threshold);

		sum += px * weight;
		total_weight += weight;
#if V == 7
		all_pixels[r_index] = val_pack(px);
		all_weights[r_index] = val_guide_pack(weight);
#endif
		r_index++;
	} // FOR_FRAME FOR_RESEARCH
#endif

#if WD == 1 // weight discard (moving cumulative average)
	total_weight = wd_total_weight;
	sum = wd_sum;
#endif

#if WD // weight discard
	avg_weight = total_weight * r_scale;
#endif

	total_weight += sw;
	sum += poi * sw;
	result = MED_DIV(sum, max(val(EPSILON),val(total_weight)));

	// store frames for temporal
#if T > 1

#endif
#if T && TRF
	imageStore(PREV1, ivec2(HOOKED_pos*HOOKED_size), unval(result));
#elif T
	imageStore(PREV1, ivec2(HOOKED_pos*HOOKED_size), unval_guide(poi2));
#endif

#if AS == 1 // sharpen+denoise
#define AS_base result
#elif AS == 2 // sharpen only
#define AS_base poi
#endif

#if ASI == 0
#define AS_input result
#elif ASI == 1
#define AS_input poi
#endif

#if AS // sharpening
	val usm = AS_input - MED_DIV(sum_as, max(EPSILON,total_weight_as));
	usm = POW(usm, ASP);
	const float as_scale_15 = 1.0/1.5;
	usm *= ASAK(abs((AS_base + usm - 0.5) * as_scale_15) * ASA);
	usm *= ASF;
	result = AS_base + usm;
#endif

#if EP // extremes preserve
	float luminance = EP_texOff(0).x;
	float ep_weight = POW(max(EPSILON, min(1-luminance, luminance)*2), (luminance < 0.5 ? DP : BP));
	result = mix(poi, result, ep_weight);
#else
	float ep_weight = 0;
#endif

#if V == 1
	result = clamp(pow(abs(poi - result), val(0.25)), 0.0, 1.0);
#elif V == 2
	result = (poi - result) * 0.5 + 0.5;
#elif V == 3
	result = val(avg_weight);
#elif V == 5
	result = 0.5 + usm;
#elif V == 6
	result = val(1 - ep_weight);
#elif V == 7
	result = val(0);
	r_index = 0;
	FOR_FRAME(r) FOR_RESEARCH(r) {
		if (v7cell_off == r.xy)
			result = val_guide_unpack(all_weights[r_index]);
		r_index++;
	}

	if (v7cell_off == vec2(0,0))
		result = val(SW * spatial_r(vec3(0)));
#endif

// XXX visualize chroma for these
#if defined(CHROMA_raw) && (V == 3 || V == 4 || V == 6 || V == 7)
	return vec4(0.5);
#endif

	return unval(result);
}

