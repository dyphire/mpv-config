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

// Description: nlmeans.glsl: Default profile, general purpose, tuned for low noise

/* This shader is highly configurable via user variables below. Although the 
 * default settings should offer good quality at a reasonable speed, you are 
 * encouraged to tweak them to your preferences.
 */

// The following is shader code injected from ../LQ/nlmeans.glsl
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

// Description: LQ/nlmeans.glsl: Faster, but lower quality.

/* This shader is highly configurable via user variables below. Although the 
 * default settings should offer good quality at a reasonable speed, you are 
 * encouraged to tweak them to your preferences.
 */

//!HOOK LUMA
//!HOOK CHROMA
//!BIND HOOKED
//!DESC Non-local means (LQ/nlmeans.glsl)
//!SAVE RF_LUMA

// User variables

// It is generally preferable to denoise luma and chroma differently, so the 
// user variables for luma and chroma are split.

// Denoising factor (sigma, higher means more blur)
#ifdef LUMA_raw
#define S 3.6280599151151334
#else
#define S 5.100920322105462
#endif

/* Adaptive sharpening
 *
 * Performs an unsharp mask by subtracting the spatial kernel's blur from the 
 * NLM blur. For sharpen+denoise the sharpening is limited to edge areas and 
 * denoising is done everywhere else.
 *
 * Use V=4 to visualize which areas are sharpened (black means sharpen).
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
#define ASF 0.3210768548589939
#define ASA 0.9397860227779741
#define ASP 0.7654083023321232
#define ASS 0.4031301466402857
#define ASI 0
#else
#define AS 0
#define ASF 0.6267063361944475
#define ASA 1.9701543289754333
#define ASP 1.0024630095639717
#define ASS 0.05977279329812535
#define ASI 0
#endif

/* Starting weight
 *
 * Also known as the center weight. This represents the weight of the 
 * pixel-of-interest. Lower numbers may help handle heavy noise.
 */
#ifdef LUMA_raw
#define SW 0.717967659498257
#else
#define SW 0.6429313578248627
#endif

/* Spatial kernel
 *
 * Increasing the spatial sigma (SS) reduces the weight of further 
 * pixels.
 *
 * The intra-patch variants are supposed to help with larger patch sizes.
 *
 * SST: enables spatial kernel if R>=PST, 0 fully disables
 * SS: spatial sigma
 * PSS: intra-patch spatial sigma
 * PST: enables intra-patch spatial kernel if P>=PST, 0 fully disables
 */
#ifdef LUMA_raw
#define SST 1
#define SS 0.5072938692870894
#define PST 0
#define PSS 0.0
#else
#define SST 1
#define SS 0.31580805565941705
#define PST 0
#define PSS 0.0
#endif

/* Extremes preserve
 *
 * Reduce denoising in very bright/dark areas.
 *
 * Disabled by default now. If you want to reenable this, set EP=3/ in 
 * Makefile.nlm and rebuild.
 *
 * The downscaling factor of the EP shader stage affects what is considered a 
 * bright/dark area.
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
#define BP 0.75
#define DP 0.25
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
 * generally better, but slower, blurrier, and gives diminishing returns.
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
#define PS 4
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
 * 	 - 2: Mean. Better quality, but slower and requires GLSL 4.0 or later
 * 	 - 1: Moving cumulative average. Fast but inaccurate, blurs directionally.
 * 	 - 0: Disable
 *
 * WDT: Threshold coefficient, higher numbers discard more
 * WDP (only for WD=1): Increasing reduces the threshold for small sample sizes
 * WDS (not for WDK=is_zero): Higher numbers are more eager to reduce weights
 */
#ifdef LUMA_raw
#define WD 1
#define WDT 0.5509878334105431
#define WDP 5.402102275251726
#define WDS 1.0
#else
#define WD 1
#define WDT 0.9385150042004405
#define WDP 5.692202343435388
#define WDS 1.0
#endif

/* Spatial correlation
 *
 * May have some impact on speed due to the need to store all of the 
 * pixels+weights and loop over them twice. This is shared with WD=2, the 
 * C=1:WD=2 should behave similar to WD=2 on its own.
 *
 * C: 0 for disabled, 1 for enabled
 * CS: higher numbers reduce outlier weights
 */
#ifdef LUMA_raw
#define C 0
#define CS 0.11643442361134813
#else
#define C 0
#define CS 0.11643442361134813
#endif

/* Robust filtering
 *
 * This setting is dependent on code generation from shader_cfg, so this 
 * setting can only be enabled via shader_cfg.
 *
 * Computes weights on a guide, which could be a downscaled image or the output 
 * of another shader, and applies the weights to the original image
 */
#define RF_LUMA 0
#define RF 0

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
 * CK: spatial correlation kernel
 *
 * List of available kernels:
 *
 * bicubic
 * cos
 * gaussian
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
#define PSK gaussian
#define WDK is_zero
#define WD1TK gaussian
#define CK gaussian
#else
#define SK gaussian
#define RK gaussian
#define ASK sphinx_
#define PSK gaussian
#define WDK is_zero
#define WD1TK gaussian
#define CK gaussian
#endif

/* Negative kernel parameter offsets
 *
 * Usually kernels go high -> low. These parameters allow for a kernel to go 
 * low -> high -> low.
 *
 * Values of 0.0 mean no effect, higher values increase the effect.
 *
 * SO: spatial kernel
 * RO: range kernel (takes patch differences)
 * ASO: adaptive sharpening kernel
 * PSO: intra-patch spatial kernel
 */
#ifdef LUMA_raw
#define SO 0.0
#define RO 0.0
#define PSO 0.0
#define ASO 0.0
#else
#define SO 0.0
#define RO 0.0
#define PSO 0.0
#define ASO 0.0
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
#define GUIDE_INPUT 0
#else
#define GUIDE_INPUT 0
#endif

/* Visualization
 *
 * 0: off
 * 1: absolute difference between input/output to the power of 0.25
 * 2: difference between input/output centered on 0.5
 * 3: post-WD/post-C weight map
 * 4: pre-WD/pre-C weight map
 * 5: unsharp mask
 * 6: EP
 */
#ifdef LUMA_raw
#define V 0
#else
#define V 0
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
#define M_PI 3.14159265358979323846
#define POW2(x) ((x)*(x))
#define POW3(x) ((x)*(x)*(x))
#define bicubic_(x) ((1.0/6.0) * (POW3((x)+2) - 4 * POW3((x)+1) + 6 * POW3(x) - 4 * POW3(max((x)-1, 0))))
#define bicubic(x) bicubic_(clamp((x), 0.0, 2.0))
#define gaussian(x) exp(-1 * POW2(x))
#define quadratic_(x) ((x) < 0.5 ? 0.75 - POW2(x) : 0.5 * POW2((x) - 1.5))
#define quadratic(x) quadratic_(clamp((x), 0.0, 1.5))
#define sinc_(x) ((x) < 1e-8 ? 1.0 : sin((x)*M_PI) / ((x)*M_PI))
#define sinc(x) sinc_(clamp((x), 0.0, 1.0))
#define sinc3(x) sinc_(clamp((x), 0.0, 3.0))
#define lanczos(x) (sinc3(x) * sinc(x))
#define sphinx_(x) ((x) < 1e-8 ? 1.0 : 3.0 * (sin((x)*M_PI) - (x)*M_PI * cos((x)*M_PI)) / POW3((x)*M_PI))
#define sphinx(x) sphinx_(clamp((x), 0.0, 1.4302966531242027))
#define triangle_(x) (1 - (x))
#define triangle(x) triangle_(clamp((x), 0.0, 1.0))
#define is_zero(x) int(x == 0)

// XXX could maybe be better optimized on LGC
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

#ifdef LUMA_raw
#define RF_ RF_LUMA
#else
#define RF_ RF
#endif

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
#define FOR_ROTATION for (float ri = 0;  ri < 360;  ri+=360.0/RI1)
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
const float p_scale = 1.0/p_area; 
const float hr_scale = 1.0/hr; 

#if SAMPLE == 0
#define sample(tex, pos, size, pt, off) tex((pos) + (pt) * (vec2(off) + 0.5 - fract((pos) * (size))))
#else
#define sample(tex, pos, size, pt, off) tex((pos) + (pt) * vec2(off))
#endif

#define GET_(off) sample(HOOKED_tex, HOOKED_pos, HOOKED_size, HOOKED_pt, off)

#if RF_ && defined(LUMA_raw)
#define GET_RF_(off) sample(RF_LUMA_tex, RF_LUMA_pos, RF_LUMA_size, RF_LUMA_pt, off)
#define gather_offs(off, off_arr) (RF_LUMA_mul * vec4(textureGatherOffsets(RF_LUMA_raw, RF_LUMA_pos + vec2(off) * RF_LUMA_pt, off_arr)))
#define gather(off) RF_LUMA_gather(RF_LUMA_pos + (off) * RF_LUMA_pt, 0)
#elif RF_ && D1W
#define GET_RF_(off) sample(RF_tex, RF_pos, RF_size, RF_pt, off)
#define gather_offs(off, off_arr) (RF_mul * vec4(textureGatherOffsets(RF_raw, RF_pos + vec2(off) * RF_pt, off_arr)))
#define gather(off) RF_gather(RF_pos + (off) * RF_pt, 0)
#elif RF_
#define GET_RF_(off) sample(RF_tex, RF_pos, RF_size, RF_pt, off)
#else
#define GET_RF_(off) GET_(off)
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
val GET_RF(vec3 off)
{
	 return off.z == 0 ? val_swizz(GET_RF_(off)) : GET(off); 
}
#else
#define GET(off) val_swizz(GET_(off))
#define GET_RF(off) val_swizz(GET_RF_(off))
#endif

val poi2 = GET_RF(vec3(0));  // guide pixel-of-interest
#if GUIDE_INPUT
#define poi poi2
#else
vec4 poi_ = GET_(vec3(0)); 
val poi = val_swizz(poi_);  // pixel-of-interest
#endif

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
	 return SK(abs(length(v) - max(0.0, SO))*SS); 
}
#else
#define spatial_r(v) (1)
#endif

// 2D blur for sharpening
#if AS
float spatial_as(vec3 v)
{
	 v.xy += 0.5 - fract(HOOKED_pos*HOOKED_size); 
	 return ASK(abs(length(v) - max(0.0, ASO))*ASS) * int(v.z == 0); 
}
#endif

#if PST && P >= PST
#define spatial_p(v) PSK(abs(length(v) - max(0.0, PSO))*PSS)
#else
#define spatial_p(v) (1)
#endif

val range(val pdiff_sq)
{
	 const float h = max(EPSILON, S) * 0.013; 
	 const float pdiff_scale = 1.0/(h*h); 
	 pdiff_sq = sqrt(abs(pdiff_sq - max(0.0, RO)) * pdiff_scale); 
	 return MAP(RK, pdiff_sq); 
}

val patch_comparison(vec3 r)
{
	 vec3 p; 
	 val min_rot = val(p_area); 

	 FOR_ROTATION FOR_REFLECTION {
	 	 val pdiff_sq = val(0); 
	 	 val total_weight = val(0); 

	 	 FOR_PATCH(p) {
	 	 	 vec3 transformed_p = SF * vec3(ref(rot(p.xy, ri), rfi), p.z); 
	 	 	 val diff_sq = GET_RF(p) - GET_RF(transformed_p + r); 
	 	 	 diff_sq *= diff_sq; 

	 	 	 float weight = spatial_p(p.xy); 
	 	 	 pdiff_sq += diff_sq * weight; 
	 	 	 total_weight += weight; 
	 	 }

	 	 min_rot = min(min_rot, pdiff_sq / max(val(EPSILON),total_weight)); 
	 }

	 return min_rot; 
}

#define NO_GATHER (PD == 0 && NG == 0 && SAMPLE == 0) // never textureGather if any of these conditions are false
#define REGULAR_ROTATIONS (RI == 0 || RI == 1 || RI == 3 || RI == 7)

#if (defined(LUMA_gather) || D1W) && ((PS == 0 || ((PS == 3 || PS == 7) && RI != 7) || PS == 8) && P == 3) && REGULAR_ROTATIONS && NO_GATHER
// 3x3 diamond/plus patch_comparison_gather
// XXX extend to support arbitrary sizes (probably requires code generation)
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

	 float center_diff = poi2.x - GET_RF(r).x; 
	 return (POW2(center_diff) + min_rot) / max(EPSILON,total_weight); 
}
#elif (defined(LUMA_gather) || D1W) && PS == 4 && P == 3 && RI == 0 && RFI == 0 && NO_GATHER
const ivec2 offsets[4] = { ivec2(0,-1), ivec2(-1,0), ivec2(0,0), ivec2(1,0) }; 
const ivec2 offsets_sf[4] = { ivec2(0,-1) * SF, ivec2(-1,0) * SF, ivec2(0,0) * SF, ivec2(1,0) * SF }; 
vec4 poi_patch = gather_offs(0, offsets); 
vec4 spatial_p_weights = vec4(spatial_p(vec2(0,-1)), spatial_p(vec2(-1,0)), spatial_p(vec2(0,0)), spatial_p(vec2(1,0))); 
float patch_comparison_gather(vec3 r)
{
	 vec4 pdiff = poi_patch - gather_offs(r, offsets_sf); 
	 return dot(POW2(pdiff) * spatial_p_weights, vec4(1)) / dot(spatial_p_weights, vec4(1)); 
}
#elif (defined(LUMA_gather) || D1W) && PS == 6 && RI == 0 && RFI == 0 && NO_GATHER
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

	 return pdiff_sq / max(EPSILON,total_weight); 
}
#else
#define patch_comparison_gather patch_comparison
#endif

vec4 hook()
{
	 val total_weight = val(0); 
	 val sum = val(0); 
	 val result = val(0); 

	 vec3 r = vec3(0); 
	 vec3 me = vec3(0); 

#if T && ME == 1 // temporal & motion estimation
	 vec3 me_tmp = vec3(0); 
	 float maxweight = 0; 
#elif T && ME == 2 // temporal & motion estimation
	 vec3 me_sum = vec3(0); 
	 float me_weight = 0; 
#endif

#if AS
	 val total_weight_as = val(0); 
	 val sum_as = val(0); 
#endif

#if WD == 2 || C == 1 // weight discard (mean), spatial correlation
	 int r_index = 0; 
	 val_packed all_weights[r_area]; 
	 val_packed all_pixels[r_area]; 
#endif
#if WD == 1 // weight discard (moving cumulative average)
	 int r_iter = 1; 
	 val wd_total_weight = val(0); 
	 val wd_sum = val(0); 
#endif
#if C == 1 // spatial correlation
	 vec3 avg_coord = vec3(0); 
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
	 	 me += round(me_sum / me_weight * MEF); 
	 	 me_sum = vec3(0); 
	 	 me_weight = 0; 
	 }
#endif
	 FOR_RESEARCH(r) {
	 	 // r coords with appropriate transformations applied
	 	 vec3 tr = vec3(r.xy + floor(r.xy * RSF), r.z); 
	 	 tr.xy += me.xy; 

	 	 val px = GET(tr); 

#if SKIP_PATCH
	 	 val weight = val(1); 
#else
	 	 val pdiff_sq = (r.z == 0) ? val(patch_comparison_gather(tr)) : patch_comparison(tr); 
	 	 val weight = range(pdiff_sq); 
#endif

#if T && ME == 1 // temporal & motion estimation max weight
	 	 me_tmp = vec3(tr.xy,0) * step(maxweight, weight.x) + me_tmp * (1 - step(maxweight, weight.x)); 
	 	 maxweight = max(maxweight, weight.x); 
#elif T && ME == 2 // temporal & motion estimation weighted average
	 	 me_sum += vec3(tr.xy,0) * weight.x; 
	 	 me_weight += weight.x; 
#endif

#if D1W
	 	 weight = val(weight.x); 
#endif

	 	 weight *= spatial_r(r); 

#if AS
	 	 float spatial_as_weight = spatial_as(tr); 
	 	 sum_as += px * spatial_as_weight; 
	 	 total_weight_as += spatial_as_weight; 
#endif

#if WD == 2 || C == 1 // weight discard (mean), spatial correlation
	 	 all_weights[r_index] = val_pack(weight); 
	 	 all_pixels[r_index] = val_pack(px); 
	 	 r_index++; 
#elif WD == 1 // weight discard (moving cumulative average)
	 	 val wd_scale = val(1.0/r_iter); 

	 	 val below_threshold = WDS * abs(min(val(0.0), weight - (total_weight * wd_scale * WDT * WD1TK(sqrt(wd_scale*WDP))))); 
	 	 val wdkf = MAP(WDK, below_threshold); 

	 	 wd_sum += px * weight * wdkf; 
	 	 wd_total_weight += weight * wdkf; 
	 	 r_iter++; 
#endif
#if C == 1 // spatial correlation
	 	 avg_coord += r * r_scale; 
#endif

	 	 sum += px * weight; 
	 	 total_weight += weight; 
	 } // FOR_RESEARCH
	 } // FOR_FRAME

	 val avg_weight = total_weight * r_scale; 

#if defined(LUMA_raw) && V == 4
	 return unval(avg_weight); 
#elif defined(CHROMA_raw) && V == 4
	 return vec4(0.5);  // XXX visualize for chroma
#endif

#if WD == 2 || C == 1 // weight discard (mean), spatial correlation
#if WD == 2 // weight discard (mean)
	 total_weight = val(0); 
	 sum = val(0); 
#endif

#if C == 1 // spatial correlation
	 val cov_rx = val(0);  val cov_ry = val(0);  val cov_rz = val(0); 
	 vec3 var_coord = vec3(0); 
	 val var_weight = val(0); 
#endif

	 r_index = 0; 
	 FOR_FRAME(r) FOR_RESEARCH(r) {
	 	 val px = val_unpack(all_pixels[r_index]); 
	 	 val weight = val_unpack(all_weights[r_index]); 

#if WD == 2 // weight discard (mean)
	 	 val below_threshold = WDS * abs(min(val(0.0), weight - (avg_weight * WDT))); 
	 	 weight *= MAP(WDK, below_threshold); 
#endif

#if C == 1 // spatial correlation
	 	 cov_rx += (r.x - avg_coord.x) * (weight - avg_weight); 
	 	 cov_ry += (r.y - avg_coord.y) * (weight - avg_weight); 
	 	 cov_rz += (r.z - avg_coord.z) * (weight - avg_weight); 
	 	 var_coord += POW2(r - avg_coord); 
	 	 var_weight += POW2(weight - avg_weight); 
#endif

#if WD == 2 // weight discard (mean)
	 	 sum += px * weight; 
	 	 total_weight += weight; 
#endif
#if WD == 2 && C == 1 // weight discard (mean) AND spatial correlation
	 	 all_weights[r_index] = val_pack(weight); 
	 	 all_pixels[r_index] = val_pack(px); 
#endif

	 	 r_index++; 
	 } // FOR_FRAME FOR_RESEARCH
#endif

#if WD == 1 // weight discard (moving cumulative average)
	 total_weight = wd_total_weight; 
	 sum = wd_sum; 
#endif

#if C == 1 // spatial correlation
	 total_weight = val(0); 
	 sum = val(0); 

	 cov_rx *= r_scale;  cov_ry *= r_scale;  cov_rz *= r_scale;  var_coord *= r_scale;  var_weight *= r_scale; 

	 val corr_rx = cov_rx / max(val(EPSILON), sqrt(var_coord.x) * sqrt(var_weight)); 
	 val corr_ry = cov_ry / max(val(EPSILON), sqrt(var_coord.y) * sqrt(var_weight)); 
	 val corr_rz = cov_rz / max(val(EPSILON), sqrt(var_coord.z) * sqrt(var_weight)); 

	 r_index = 0; 
	 FOR_FRAME(r) FOR_RESEARCH(r) {
	 	 val px = val_unpack(all_pixels[r_index]); 
	 	 val weight = val_unpack(all_weights[r_index]); 

	 	 weight *= CK(abs(corr_rx - r.x * hr_scale) * abs(corr_rx) * CS); 
	 	 weight *= CK(abs(corr_ry - r.y * hr_scale) * abs(corr_ry) * CS); 
	 	 weight *= CK(abs(corr_rz - r.z * hr_scale) * abs(corr_rz) * CS); 

	 	 sum += px * weight; 
	 	 total_weight += weight; 

	 	 r_index++; 
	 }
#endif

#if WD || C // weight discard, spatial correlation
	 avg_weight = total_weight * r_scale; 
#endif

	 total_weight += SW * spatial_r(vec3(0)); 
	 sum += poi * SW * spatial_r(vec3(0)); 
	 result = val(sum / max(val(EPSILON),total_weight)); 

	 // store frames for temporal
#if T > 1

#endif
#if T && TRF
	 imageStore(PREV1, ivec2(HOOKED_pos*HOOKED_size), unval(result)); 
#elif T
	 imageStore(PREV1, ivec2(HOOKED_pos*HOOKED_size), unval(poi2)); 
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
	 val usm = AS_input - sum_as/max(val(EPSILON),total_weight_as); 
	 usm = exp(log(abs(usm))*ASP) * sign(usm);  // avoiding pow() since it's buggy on nvidia
	 usm *= gaussian(abs((AS_base + usm - 0.5) / 1.5) * ASA); 
	 usm *= ASF; 
	 result = AS_base + usm; 
#endif

#if EP // extremes preserve
	 float luminance = EP_texOff(0).x; 
	 // EPSILON is needed since pow(0,0) is undefined
	 float ep_weight = pow(EPSILON,max(min(1-luminance, luminance)*2), (luminance < 0.5 ? DP : BP)); 
	 result = mix(poi, result, ep_weight); 
#else
	 float ep_weight = 0; 
#endif

#if V == 1
	 result = clamp(pow(abs(poi - result), val(0.25)), 0.0, 1.0); 
#elif V == 2
	 result = (poi - result) * 0.5 + 0.5; 
#elif V == 3
	 result = avg_weight; 
#elif V == 5
	 result = 0.5 + usm; 
#elif V == 6
	 result = val(1 - ep_weight); 
#endif

// XXX visualize chroma for these
#if defined(CHROMA_raw) && (V == 3 || V == 4 || V == 6)
	 return vec4(0.5); 
#endif

	 return unval(result); 
}

// End of source code injected from ../LQ/nlmeans.glsl 

//!HOOK LUMA
//!HOOK CHROMA
//!BIND RF_LUMA
//!WIDTH RF_LUMA.w
//!HEIGHT RF_LUMA.h
//!DESC Non-local means (RF, share)
//!SAVE RF

vec4 hook()
{
	return RF_LUMA_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!BIND HOOKED
//!BIND RF_LUMA
//!BIND RF
//!DESC Non-local means (nlmeans.glsl)

// User variables

// It is generally preferable to denoise luma and chroma differently, so the 
// user variables for luma and chroma are split.

// Denoising factor (sigma, higher means more blur)
#ifdef LUMA_raw
#define S 2.0262062762852167
#else
#define S 2.356425745363608
#endif

/* Adaptive sharpening
 *
 * Performs an unsharp mask by subtracting the spatial kernel's blur from the 
 * NLM blur. For sharpen+denoise the sharpening is limited to edge areas and 
 * denoising is done everywhere else.
 *
 * Use V=4 to visualize which areas are sharpened (black means sharpen).
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
#define ASF 0.3210768548589939
#define ASA 0.9397860227779741
#define ASP 0.7654083023321232
#define ASS 0.4031301466402857
#define ASI 0
#else
#define AS 0
#define ASF 0.6267063361944475
#define ASA 1.9701543289754333
#define ASP 1.0024630095639717
#define ASS 0.05977279329812535
#define ASI 0
#endif

/* Starting weight
 *
 * Also known as the center weight. This represents the weight of the 
 * pixel-of-interest. Lower numbers may help handle heavy noise.
 */
#ifdef LUMA_raw
#define SW 1.3322924870317203
#else
#define SW 1.2033038941856653
#endif

/* Spatial kernel
 *
 * Increasing the spatial sigma (SS) reduces the weight of further 
 * pixels.
 *
 * The intra-patch variants are supposed to help with larger patch sizes.
 *
 * SST: enables spatial kernel if R>=PST, 0 fully disables
 * SS: spatial sigma
 * PSS: intra-patch spatial sigma
 * PST: enables intra-patch spatial kernel if P>=PST, 0 fully disables
 */
#ifdef LUMA_raw
#define SST 1
#define SS 0.5045657681048714
#define PST 0
#define PSS 0.0
#else
#define SST 1
#define SS 0.2660216669677905
#define PST 0
#define PSS 0.0
#endif

/* Extremes preserve
 *
 * Reduce denoising in very bright/dark areas.
 *
 * Disabled by default now. If you want to reenable this, set EP=3/ in 
 * Makefile.nlm and rebuild.
 *
 * The downscaling factor of the EP shader stage affects what is considered a 
 * bright/dark area.
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
#define BP 0.75
#define DP 0.25
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
 * generally better, but slower, blurrier, and gives diminishing returns.
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
#define PS 3
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
#define WD 2
#define WDT 0.11832010376003192
#define WDP 5.402102275251726
#define WDS 1.0
#else
#define WD 0
#define WDT 0.002713346103131793
#define WDP 5.692202343435388
#define WDS 1.0
#endif

/* Spatial correlation
 *
 * May have some impact on speed due to the need to store all of the 
 * pixels+weights and loop over them twice. This is shared with WD=2, the 
 * C=1:WD=2 should behave similar to WD=2 on its own.
 *
 * C: 0 for disabled, 1 for enabled
 * CS: higher numbers reduce outlier weights
 */
#ifdef LUMA_raw
#define C 1
#define CS 0.11643442361134813
#else
#define C 0
#define CS 0.11643442361134813
#endif

/* Robust filtering
 *
 * This setting is dependent on code generation from shader_cfg, so this 
 * setting can only be enabled via shader_cfg.
 *
 * Computes weights on a guide, which could be a downscaled image or the output 
 * of another shader, and applies the weights to the original image
 */
#define RF_LUMA 1
#define RF 1

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
 * CK: spatial correlation kernel
 *
 * List of available kernels:
 *
 * bicubic
 * cos
 * gaussian
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
#define PSK gaussian
#define WDK is_zero
#define WD1TK gaussian
#define CK gaussian
#else
#define SK gaussian
#define RK gaussian
#define ASK sphinx_
#define PSK gaussian
#define WDK is_zero
#define WD1TK gaussian
#define CK gaussian
#endif

/* Negative kernel parameter offsets
 *
 * Usually kernels go high -> low. These parameters allow for a kernel to go 
 * low -> high -> low.
 *
 * Values of 0.0 mean no effect, higher values increase the effect.
 *
 * SO: spatial kernel
 * RO: range kernel (takes patch differences)
 * ASO: adaptive sharpening kernel
 * PSO: intra-patch spatial kernel
 */
#ifdef LUMA_raw
#define SO 0.0
#define RO 0.0
#define PSO 0.0
#define ASO 0.0
#else
#define SO 0.0
#define RO 0.0
#define PSO 0.0
#define ASO 0.0
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
#define GUIDE_INPUT 0
#else
#define GUIDE_INPUT 0
#endif

/* Visualization
 *
 * 0: off
 * 1: absolute difference between input/output to the power of 0.25
 * 2: difference between input/output centered on 0.5
 * 3: post-WD/post-C weight map
 * 4: pre-WD/pre-C weight map
 * 5: unsharp mask
 * 6: EP
 */
#ifdef LUMA_raw
#define V 0
#else
#define V 0
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
#define M_PI 3.14159265358979323846
#define POW2(x) ((x)*(x))
#define POW3(x) ((x)*(x)*(x))
#define bicubic_(x) ((1.0/6.0) * (POW3((x)+2) - 4 * POW3((x)+1) + 6 * POW3(x) - 4 * POW3(max((x)-1, 0))))
#define bicubic(x) bicubic_(clamp((x), 0.0, 2.0))
#define gaussian(x) exp(-1 * POW2(x))
#define quadratic_(x) ((x) < 0.5 ? 0.75 - POW2(x) : 0.5 * POW2((x) - 1.5))
#define quadratic(x) quadratic_(clamp((x), 0.0, 1.5))
#define sinc_(x) ((x) < 1e-8 ? 1.0 : sin((x)*M_PI) / ((x)*M_PI))
#define sinc(x) sinc_(clamp((x), 0.0, 1.0))
#define sinc3(x) sinc_(clamp((x), 0.0, 3.0))
#define lanczos(x) (sinc3(x) * sinc(x))
#define sphinx_(x) ((x) < 1e-8 ? 1.0 : 3.0 * (sin((x)*M_PI) - (x)*M_PI * cos((x)*M_PI)) / POW3((x)*M_PI))
#define sphinx(x) sphinx_(clamp((x), 0.0, 1.4302966531242027))
#define triangle_(x) (1 - (x))
#define triangle(x) triangle_(clamp((x), 0.0, 1.0))
#define is_zero(x) int(x == 0)

// XXX could maybe be better optimized on LGC
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

#ifdef LUMA_raw
#define RF_ RF_LUMA
#else
#define RF_ RF
#endif

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
#define FOR_ROTATION for (float ri = 0; ri < 360; ri+=360.0/RI1)
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
const float p_scale = 1.0/p_area;
const float hr_scale = 1.0/hr;

#if SAMPLE == 0
#define sample(tex, pos, size, pt, off) tex((pos) + (pt) * (vec2(off) + 0.5 - fract((pos) * (size))))
#else
#define sample(tex, pos, size, pt, off) tex((pos) + (pt) * vec2(off))
#endif

#define GET_(off) sample(HOOKED_tex, HOOKED_pos, HOOKED_size, HOOKED_pt, off)

#if RF_ && defined(LUMA_raw)
#define GET_RF_(off) sample(RF_LUMA_tex, RF_LUMA_pos, RF_LUMA_size, RF_LUMA_pt, off)
#define gather_offs(off, off_arr) (RF_LUMA_mul * vec4(textureGatherOffsets(RF_LUMA_raw, RF_LUMA_pos + vec2(off) * RF_LUMA_pt, off_arr)))
#define gather(off) RF_LUMA_gather(RF_LUMA_pos + (off) * RF_LUMA_pt, 0)
#elif RF_ && D1W
#define GET_RF_(off) sample(RF_tex, RF_pos, RF_size, RF_pt, off)
#define gather_offs(off, off_arr) (RF_mul * vec4(textureGatherOffsets(RF_raw, RF_pos + vec2(off) * RF_pt, off_arr)))
#define gather(off) RF_gather(RF_pos + (off) * RF_pt, 0)
#elif RF_
#define GET_RF_(off) sample(RF_tex, RF_pos, RF_size, RF_pt, off)
#else
#define GET_RF_(off) GET_(off)
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
val GET_RF(vec3 off)
{
	return off.z == 0 ? val_swizz(GET_RF_(off)) : GET(off);
}
#else
#define GET(off) val_swizz(GET_(off))
#define GET_RF(off) val_swizz(GET_RF_(off))
#endif

val poi2 = GET_RF(vec3(0)); // guide pixel-of-interest
#if GUIDE_INPUT
#define poi poi2
#else
vec4 poi_ = GET_(vec3(0));
val poi = val_swizz(poi_); // pixel-of-interest
#endif

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
	return SK(abs(length(v) - max(0.0, SO))*SS);
}
#else
#define spatial_r(v) (1)
#endif

// 2D blur for sharpening
#if AS
float spatial_as(vec3 v)
{
	v.xy += 0.5 - fract(HOOKED_pos*HOOKED_size);
	return ASK(abs(length(v) - max(0.0, ASO))*ASS) * int(v.z == 0);
}
#endif

#if PST && P >= PST
#define spatial_p(v) PSK(abs(length(v) - max(0.0, PSO))*PSS)
#else
#define spatial_p(v) (1)
#endif

val range(val pdiff_sq)
{
	const float h = max(EPSILON, S) * 0.013;
	const float pdiff_scale = 1.0/(h*h);
	pdiff_sq = sqrt(abs(pdiff_sq - max(0.0, RO)) * pdiff_scale);
	return MAP(RK, pdiff_sq);
}

val patch_comparison(vec3 r)
{
	vec3 p;
	val min_rot = val(p_area);

	FOR_ROTATION FOR_REFLECTION {
		val pdiff_sq = val(0);
		val total_weight = val(0);

		FOR_PATCH(p) {
			vec3 transformed_p = SF * vec3(ref(rot(p.xy, ri), rfi), p.z);
			val diff_sq = GET_RF(p) - GET_RF(transformed_p + r);
			diff_sq *= diff_sq;

			float weight = spatial_p(p.xy);
			pdiff_sq += diff_sq * weight;
			total_weight += weight;
		}

		min_rot = min(min_rot, pdiff_sq / max(val(EPSILON),total_weight));
	}

	return min_rot;
}

#define NO_GATHER (PD == 0 && NG == 0 && SAMPLE == 0) // never textureGather if any of these conditions are false
#define REGULAR_ROTATIONS (RI == 0 || RI == 1 || RI == 3 || RI == 7)

#if (defined(LUMA_gather) || D1W) && ((PS == 0 || ((PS == 3 || PS == 7) && RI != 7) || PS == 8) && P == 3) && REGULAR_ROTATIONS && NO_GATHER
// 3x3 diamond/plus patch_comparison_gather
// XXX extend to support arbitrary sizes (probably requires code generation)
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

	float center_diff = poi2.x - GET_RF(r).x;
	return (POW2(center_diff) + min_rot) / max(EPSILON,total_weight);
}
#elif (defined(LUMA_gather) || D1W) && PS == 4 && P == 3 && RI == 0 && RFI == 0 && NO_GATHER
const ivec2 offsets[4] = { ivec2(0,-1), ivec2(-1,0), ivec2(0,0), ivec2(1,0) };
const ivec2 offsets_sf[4] = { ivec2(0,-1) * SF, ivec2(-1,0) * SF, ivec2(0,0) * SF, ivec2(1,0) * SF };
vec4 poi_patch = gather_offs(0, offsets);
vec4 spatial_p_weights = vec4(spatial_p(vec2(0,-1)), spatial_p(vec2(-1,0)), spatial_p(vec2(0,0)), spatial_p(vec2(1,0)));
float patch_comparison_gather(vec3 r)
{
	vec4 pdiff = poi_patch - gather_offs(r, offsets_sf);
	return dot(POW2(pdiff) * spatial_p_weights, vec4(1)) / dot(spatial_p_weights, vec4(1));
}
#elif (defined(LUMA_gather) || D1W) && PS == 6 && RI == 0 && RFI == 0 && NO_GATHER
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

	return pdiff_sq / max(EPSILON,total_weight);
}
#else
#define patch_comparison_gather patch_comparison
#endif

vec4 hook()
{
	val total_weight = val(0);
	val sum = val(0);
	val result = val(0);

	vec3 r = vec3(0);
	vec3 me = vec3(0);

#if T && ME == 1 // temporal & motion estimation
	vec3 me_tmp = vec3(0);
	float maxweight = 0;
#elif T && ME == 2 // temporal & motion estimation
	vec3 me_sum = vec3(0);
	float me_weight = 0;
#endif

#if AS
	val total_weight_as = val(0);
	val sum_as = val(0);
#endif

#if WD == 2 || C == 1 // weight discard (mean), spatial correlation
	int r_index = 0;
	val_packed all_weights[r_area];
	val_packed all_pixels[r_area];
#endif
#if WD == 1 // weight discard (moving cumulative average)
	int r_iter = 1;
	val wd_total_weight = val(0);
	val wd_sum = val(0);
#endif
#if C == 1 // spatial correlation
	vec3 avg_coord = vec3(0);
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
		me += round(me_sum / me_weight * MEF);
		me_sum = vec3(0);
		me_weight = 0;
	}
#endif
	FOR_RESEARCH(r) {
		// r coords with appropriate transformations applied
		vec3 tr = vec3(r.xy + floor(r.xy * RSF), r.z);
		tr.xy += me.xy;

		val px = GET(tr);

#if SKIP_PATCH
		val weight = val(1);
#else
		val pdiff_sq = (r.z == 0) ? val(patch_comparison_gather(tr)) : patch_comparison(tr);
		val weight = range(pdiff_sq);
#endif

#if T && ME == 1 // temporal & motion estimation max weight
		me_tmp = vec3(tr.xy,0) * step(maxweight, weight.x) + me_tmp * (1 - step(maxweight, weight.x));
		maxweight = max(maxweight, weight.x);
#elif T && ME == 2 // temporal & motion estimation weighted average
		me_sum += vec3(tr.xy,0) * weight.x;
		me_weight += weight.x;
#endif

#if D1W
		weight = val(weight.x);
#endif

		weight *= spatial_r(r);

#if AS
		float spatial_as_weight = spatial_as(tr);
		sum_as += px * spatial_as_weight;
		total_weight_as += spatial_as_weight;
#endif

#if WD == 2 || C == 1 // weight discard (mean), spatial correlation
		all_weights[r_index] = val_pack(weight);
		all_pixels[r_index] = val_pack(px);
		r_index++;
#elif WD == 1 // weight discard (moving cumulative average)
		val wd_scale = val(1.0/r_iter);

		val below_threshold = WDS * abs(min(val(0.0), weight - (total_weight * wd_scale * WDT * WD1TK(sqrt(wd_scale*WDP)))));
		val wdkf = MAP(WDK, below_threshold);

		wd_sum += px * weight * wdkf;
		wd_total_weight += weight * wdkf;
		r_iter++;
#endif
#if C == 1 // spatial correlation
		avg_coord += r * r_scale;
#endif

		sum += px * weight;
		total_weight += weight;
	} // FOR_RESEARCH
	} // FOR_FRAME

	val avg_weight = total_weight * r_scale;

#if defined(LUMA_raw) && V == 4
	return unval(avg_weight);
#elif defined(CHROMA_raw) && V == 4
	return vec4(0.5); // XXX visualize for chroma
#endif

#if WD == 2 || C == 1 // weight discard (mean), spatial correlation
#if WD == 2 // weight discard (mean)
	total_weight = val(0);
	sum = val(0);
#endif

#if C == 1 // spatial correlation
	val cov_rx = val(0); val cov_ry = val(0); val cov_rz = val(0);
	vec3 var_coord = vec3(0);
	val var_weight = val(0);
#endif

	r_index = 0;
	FOR_FRAME(r) FOR_RESEARCH(r) {
		val px = val_unpack(all_pixels[r_index]);
		val weight = val_unpack(all_weights[r_index]);

#if WD == 2 // weight discard (mean)
		val below_threshold = WDS * abs(min(val(0.0), weight - (avg_weight * WDT)));
		weight *= MAP(WDK, below_threshold);
#endif

#if C == 1 // spatial correlation
		cov_rx += (r.x - avg_coord.x) * (weight - avg_weight);
		cov_ry += (r.y - avg_coord.y) * (weight - avg_weight);
		cov_rz += (r.z - avg_coord.z) * (weight - avg_weight);
		var_coord += POW2(r - avg_coord);
		var_weight += POW2(weight - avg_weight);
#endif

#if WD == 2 // weight discard (mean)
		sum += px * weight;
		total_weight += weight;
#endif
#if WD == 2 && C == 1 // weight discard (mean) AND spatial correlation
		all_weights[r_index] = val_pack(weight);
		all_pixels[r_index] = val_pack(px);
#endif

		r_index++;
	} // FOR_FRAME FOR_RESEARCH
#endif

#if WD == 1 // weight discard (moving cumulative average)
	total_weight = wd_total_weight;
	sum = wd_sum;
#endif

#if C == 1 // spatial correlation
	total_weight = val(0);
	sum = val(0);

	cov_rx *= r_scale; cov_ry *= r_scale; cov_rz *= r_scale; var_coord *= r_scale; var_weight *= r_scale;

	val corr_rx = cov_rx / max(val(EPSILON), sqrt(var_coord.x) * sqrt(var_weight));
	val corr_ry = cov_ry / max(val(EPSILON), sqrt(var_coord.y) * sqrt(var_weight));
	val corr_rz = cov_rz / max(val(EPSILON), sqrt(var_coord.z) * sqrt(var_weight));

	r_index = 0;
	FOR_FRAME(r) FOR_RESEARCH(r) {
		val px = val_unpack(all_pixels[r_index]);
		val weight = val_unpack(all_weights[r_index]);

		weight *= CK(abs(corr_rx - r.x * hr_scale) * abs(corr_rx) * CS);
		weight *= CK(abs(corr_ry - r.y * hr_scale) * abs(corr_ry) * CS);
		weight *= CK(abs(corr_rz - r.z * hr_scale) * abs(corr_rz) * CS);

		sum += px * weight;
		total_weight += weight;

		r_index++;
	}
#endif

#if WD || C // weight discard, spatial correlation
	avg_weight = total_weight * r_scale;
#endif

	total_weight += SW * spatial_r(vec3(0));
	sum += poi * SW * spatial_r(vec3(0));
	result = val(sum / max(val(EPSILON),total_weight));

	// store frames for temporal
#if T > 1

#endif
#if T && TRF
	imageStore(PREV1, ivec2(HOOKED_pos*HOOKED_size), unval(result));
#elif T
	imageStore(PREV1, ivec2(HOOKED_pos*HOOKED_size), unval(poi2));
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
	val usm = AS_input - sum_as/max(val(EPSILON),total_weight_as);
	usm = exp(log(abs(usm))*ASP) * sign(usm); // avoiding pow() since it's buggy on nvidia
	usm *= gaussian(abs((AS_base + usm - 0.5) / 1.5) * ASA);
	usm *= ASF;
	result = AS_base + usm;
#endif

#if EP // extremes preserve
	float luminance = EP_texOff(0).x;
	// EPSILON is needed since pow(0,0) is undefined
	float ep_weight = pow(EPSILON,max(min(1-luminance, luminance)*2), (luminance < 0.5 ? DP : BP));
	result = mix(poi, result, ep_weight);
#else
	float ep_weight = 0;
#endif

#if V == 1
	result = clamp(pow(abs(poi - result), val(0.25)), 0.0, 1.0);
#elif V == 2
	result = (poi - result) * 0.5 + 0.5;
#elif V == 3
	result = avg_weight;
#elif V == 5
	result = 0.5 + usm;
#elif V == 6
	result = val(1 - ep_weight);
#endif

// XXX visualize chroma for these
#if defined(CHROMA_raw) && (V == 3 || V == 4 || V == 6)
	return vec4(0.5);
#endif

	return unval(result);
}

