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

// Profile description: Tuned for anime/cartoons, may be useful for other content. Slow, but higher quality.

/* The recommended usage of this shader and its variant profiles is to add them 
 * to input.conf and then dispatch the appropriate shader via a keybind during 
 * media playback. Here is an example input.conf entry:
 *
 * F4 no-osd change-list glsl-shaders toggle "~~/shaders/nlmeans_luma.glsl"; show-text "Non-local means (LUMA only)"
 *
 * These shaders can also be enabled by default in mpv.conf, for example:
 *
 * glsl-shaders='~~/shaders/nlmeans.glsl'
 *
 * Both of the examples above assume the shaders are located in a subdirectory 
 * named "shaders" within mpv's config directory. Refer to the mpv 
 * documentation for more details.
 *
 * This shader is highly configurable via user variables below. Although the 
 * default settings should offer good quality at a reasonable speed, you are 
 * encouraged to tweak them to your preferences. Be mindful that certain 
 * settings may greatly affect speed.
 *
 * Denoising is most useful for noisy content. If there is no perceptible 
 * noise, you probably won't see a positive difference.
 *
 * The default settings are generally tuned for low noise and high detail 
 * preservation. The "medium" and "heavy" profiles are tuned for higher levels 
 * of noise.
 *
 * The denoiser will not work properly if the content has been upscaled 
 * beforehand, whether it was done by you or someone down the line. Consider 
 * issuing a command to downscale in the mpv console, like so:
 *
 * vf toggle scale=-2:720
 *
 * ...replacing 720 with whatever resolution seems appropriate. Rerun the 
 * command to undo the downscale. It may take some trial-and-error to find the 
 * proper resolution.
 */

/* Regarding speed
 *
 * Speed may vary wildly for different vo and gpu-api settings. Generally 
 * vo=gpu-next and gpu-api=vulkan are recommended for the best speed, but this 
 * may be different for your system.
 *
 * If your GPU doesn't support textureGather, or if you are on a version of mpv 
 * prior to 0.35.0, then consider setting RI/RFI to 0, or try the LQ and VLQ 
 * profiles.
 *
 * textureGather is LUMA only and limited to the following configurations:
 *
 * - PS={3,7}:P=3:PST=0:RI={0,1,3}:RFI={0,1,2}:M!=1
 *   - Default, very fast, rotations and reflections should be free
 *   - If this is unusually slow then try changing gpu-api and vo
 *   - If it's still slow, try setting RI/RFI to 0.
 *
 * - PS=6:RI={0,1,3}:RFI={0,1,2}
 *   - Currently the only scalable variant
 *   - Patch shape is asymmetric on two axis
 *   - Rotations should have very little speed impact
 *   - Reflections may have a significant speed impact
 *
 * Options which always disable textureGather:
 * 	- RF
 * 	- PD
 */

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!BIND HOOKED
//!DESC Non-local means (downscale)
//!SAVE PRERF
//!WIDTH HOOKED.w 2 /
//!HEIGHT HOOKED.h 2 /

vec4 hook()
{
	return HOOKED_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!BIND HOOKED
//!DESC Non-local means (undownscale)
//!BIND PRERF
//!SAVE RF
//!WIDTH HOOKED.w
//!HEIGHT HOOKED.h

vec4 hook()
{
	return PRERF_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!BIND HOOKED
//!DESC Non-local means (downscale)
//!SAVE PRERF_LUMA
//!WIDTH HOOKED.w 1.25 /
//!HEIGHT HOOKED.h 1.25 /

vec4 hook()
{
	return HOOKED_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!BIND HOOKED
//!DESC Non-local means (undownscale)
//!BIND PRERF_LUMA
//!SAVE RF_LUMA
//!WIDTH HOOKED.w
//!HEIGHT HOOKED.h

vec4 hook()
{
	return PRERF_LUMA_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!BIND HOOKED
//!BIND RF
//!BIND RF_LUMA
//!DESC Non-local means (nlmeans_anime_hq.glsl)

/* User variables
 *
 * It is usually preferable to denoise chroma and luma differently, so the user 
 * variables for luma and chroma are split.
 */

/* S = denoising factor
 * P = patch size
 * R = research size
 *
 * The denoising factor controls the level of blur, higher is blurrier.
 *
 * Patch size should usually be an odd number greater than or equal to 3. 
 * Higher values are slower and not always better.
 *
 * Research size usually be an odd number greater than or equal to 3. Higher 
 * values are usually better, but slower and offer diminishing returns.
 *
 * Even-numbered patch/research sizes will sample between pixels unless PS=6. 
 * It's not known whether this is ever useful behavior or not. This is 
 * incompatible with textureGather optimizations, so enable RF when using even 
 * patch/research sizes.
 */
#ifdef LUMA_raw
#define S 3
#define P 4
#define R 5
#else
#define S 3
#define P 3
#define R 5
#endif

/* Adaptive sharpening
 *
 * Uses the blur incurred by denoising plus the weight map to perform an 
 * unsharp mask that gets applied most strongly to edges.
 *
 * Sharpening will amplify noise, so the denoising factor (S) should usually be 
 * increased to compensate.
 *
 * AS: 2 for sharpening, 1 for sharpening+denoising, 0 to disable
 * ASF: Sharpening factor, higher numbers make a sharper underlying image
 * ASP: Weight power, higher numbers use more of the sharp image
 */
#ifdef LUMA_raw
#define AS 0
#define ASF 1.0
#define ASP 2.0
#else
#define AS 0
#define ASF 1.0
#define ASP 2.0
#endif

/* Starting weight
 *
 * Lower numbers give less weight to the pixel-of-interest, which may help 
 * handle higher noise levels, ringing, and may be useful for other things too?
 *
 * EPSILON should be used instead of zero to avoid divide-by-zero errors. The 
 * avg_weight variable may be used to make SW adapt to the local noise level, 
 * e.g., SW=max(avg_weight, EPSILON)
 */
#ifdef LUMA_raw
#define SW 1.0
#else
#define SW 1.0
#endif

/* Weight discard
 *
 * Discard weights that fall below a fraction of the average weight. This culls 
 * the most dissimilar samples from the blur, yielding a much more pleasant 
 * result, especially around edges.
 * 
 * WD:
 * 	- 2: True average. Very good quality, but slower and uses more memory.
 * 	- 1: Moving cumulative average. Inaccurate, tends to blur directionally.
 * 	- 0: Disable
 *
 * WDT: Threshold coefficient, higher numbers discard more
 * WDP (WD=1): Higher numbers reduce the threshold more for small sample sizes
 */
#ifdef LUMA_raw
#define WD 2
#define WDT 1.0
#define WDP 6.0
#else
#define WD 2
#define WDT 1.0
#define WDP 6.0
#endif

/* Search shape
 *
 * Determines the shape of patches and research zones. Different shapes have 
 * different speed and quality characteristics. Every shape (besides square) is 
 * smaller than square.
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
 */
#ifdef LUMA_raw
#define RS 3
#define PS 6
#else
#define RS 3
#define PS 3
#endif

/* Rotational/reflectional invariance
 *
 * Number of rotations/reflections to try for each patch comparison. Slow, but 
 * improves feature preservation, although adding more rotations/reflections 
 * gives diminishing returns. The most similar rotation/reflection will be used.
 *
 * The angle in degrees of each rotation is 360/(RI+1), so RI=1 will do a 
 * single 180 degree rotation, RI=3 will do three 90 degree rotations, etc.
 *
 * RI: Rotational invariance
 * RFI (0 to 2): Reflectional invariance
 */
#ifdef LUMA_raw
#define RI 3
#define RFI 0
#else
#define RI 0
#define RFI 0
#endif

/* Temporal denoising
 *
 * Caveats:
 * 	- Slower, each frame needs to be researched
 * 	- Requires vo=gpu-next and nlmeans_temporal.glsl
 * 	- Luma-only (this is a bug)
 * 	- Buggy
 *
 * Gather samples across multiple frames. May cause motion blur and may 
 * struggle more with noise that persists across multiple frames (compression 
 * noise, repeating frames), but can work very well on high quality video.
 *
 * Motion estimation (ME) should improve quality without impacting speed.
 *
 * T: number of frames used
 * ME: motion estimation, 0 for none, 1 for max weight, 2 for weighted avg
 */
#ifdef LUMA_raw
#define T 0
#define ME 1
#else
#define T 0
#define ME 0
#endif

/* Spatial kernel
 *
 * Increasing the spatial denoising factor (SS) reduces the weight of further 
 * pixels.
 *
 * Spatial distortion instructs the spatial kernel to view that axis as 
 * closer/further, for instance SD=(1,1,0.5) would make the temporal axis 
 * appear closer and increase blur between frames.
 *
 * The intra-patch variants do not yet have well-understood effects. They are 
 * intended to make large patch sizes more useful. Likely slower.
 *
 * SS: spatial denoising factor
 * SD: spatial distortion (X, Y, time)
 * PSS: intra-patch spatial denoising factor
 * PST: enables intra-patch spatial kernel if P>=PST, 0 fully disables
 * PSD: intra-patch spatial distortion (X, Y)
 */
#ifdef LUMA_raw
#define SS 0.0
#define SD vec3(1,1,1)
#define PST 0
#define PSS 0.0
#define PSD vec2(1,1)
#else
#define SS 0.0
#define SD vec3(1,1,1)
#define PST 0
#define PSS 0.0
#define PSD vec2(1,1)
#endif

/* Extremes preserve
 *
 * Reduces denoising around very bright/dark areas. The downscaling factor of 
 * EP (located near the top of this shader) controls the area sampled for 
 * luminance (higher numbers consider more area).
 *
 * EP: 1 to enable, 0 to disable
 * DP: EP strength on dark patches, 0 to fully denoise
 * BP: EP strength on bright patches, 0 to fully denoise
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

/* Robust filtering
 *
 * This setting is dependent on code generation from nlmeans_cfg, so this 
 * setting can only be enabled via nlmeans_cfg.
 *
 * Compares the pixel-of-interest against downscaled pixels.
 *
 * This will virtually always improve quality, but will always disable 
 * textureGather optimizations.
 *
 * The downscale factor can be modified in the WIDTH/HEIGHT directives for the 
 * RF texture (for CHROMA, RGB) and RF_LUMA (LUMA only) textures near the top 
 * of this shader, higher numbers increase blur.
 *
 * Any notation of RF as a positive number should be assumed to be referring to 
 * the downscaling factor, e.g., RF=3 means RF is set to 1 and the downscaling 
 * factor is set to 3.
 */
#ifdef LUMA_raw
#define RF 1
#else
#define RF 1
#endif

/* Estimator
 *
 * Don't change this setting.
 *
 * 0: means
 * 1: Euclidean medians (extremely slow, may be good for heavy noise)
 * 2: weight map (not a denoiser, maybe useful for generating image masks)
 * 3: weighted median intensity (slow, may be good for heavy noise)
 */
#ifdef LUMA_raw
#define M 0
#else
#define M 0
#endif

/* Patch donut
 *
 * If enabled, ignores center pixel of patch comparisons.
 *
 * Not sure if this is any use? May be removed at any time.
 */
#ifdef LUMA_raw
#define PD 0
#else
#define PD 0
#endif

/* Blur factor
 *
 * 0 to 1, only useful for alternative estimators. You're probably looking for 
 * "S" (denoising factor), go back to the top of the shader!
 */
#ifdef LUMA_raw
#define BF 1.0
#else
#define BF 1.0
#endif

/* Shader code */

#define EPSILON 0.00000000001

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

// donut increment, increments without landing on (0,0,0)
// much faster than a "continue" statement
#define DINCR(z,c) (z.c++,(z.c += int(z == vec3(0))))

// search shapes and their corresponding areas
#define S_1X1(z) for (z = vec3(0); z.x <= 0; z.x++)

#define S_TRIANGLE(z,hz,incr) for (z.y = -hz; z.y <= 0; z.y++) for (z.x = -abs(abs(z.y) - hz); z.x <= abs(abs(z.y) - hz); incr)
#define S_TRUNC_TRIANGLE(z,hz,incr) for (z.y = -hz; z.y <= 0; z.y++) for (z.x = -abs(abs(z.y) - hz); z.x <= abs(abs(z.y) - hz)*int(z.y!=0); incr)
#define S_TRIANGLE_A(hz,Z) int(pow(hz, 2)+Z)

#define S_DIAMOND(z,hz,incr) for (z.x = -hz; z.x <= hz; z.x++) for (z.y = -abs(abs(z.x) - hz); z.y <= abs(abs(z.x) - hz); incr)
#define S_DIAMOND_A(hz,Z) int(pow(hz, 2)*2+Z)

#define S_VERTICAL(z,hz,incr) for (z.x = 0; z.x <= 0; z.x++) for (z.y = -hz; z.y <= hz; incr)
#define S_HORIZONTAL(z,hz,incr) for (z.x = -hz; z.x <= hz; incr) for (z.y = 0; z.y <= 0; z.y++)

#define S_PLUS(z,hz,incr) for (z.x = -hz; z.x <= hz; z.x++) for (z.y = -hz * int(z.x == 0); z.y <= hz * int(z.x == 0); incr)
#define S_PLUS_A(hz,Z) (Z*2 - 1)

#define S_SQUARE(z,hz,incr) for (z.x = -hz; z.x <= hz; z.x++) for (z.y = -hz; z.y <= hz; incr)
#define S_SQUARE_EVEN(z,hz,incr) for (z.x = -hz; z.x < hz; z.x++) for (z.y = -hz; z.y < hz; incr)

#define T1 (T+1)
#define FOR_FRAME(r) for (r.z = 0; r.z < T1; r.z++)

// Skip comparing the pixel-of-interest against itself, unless RF is enabled
#if RF
#define RINCR(z,c) (z.c++)
#else
#define RINCR DINCR
#endif

#define R_AREA(a) (a * T1 + RF-1)

// research shapes
#if R == 0 || R == 1
#define FOR_RESEARCH(r) S_1X1(r)
const int r_area = R_AREA(1);
#elif RS == 7
#define FOR_RESEARCH(r) S_PLUS(r,hr,RINCR(r,y))
const int r_area = R_AREA(S_PLUS_A(hr,R));
#elif RS == 6
#define FOR_RESEARCH(r) S_SQUARE_EVEN(r,hr,RINCR(r,y))
const int r_area = R_AREA(R*R);
#elif RS == 5
#define FOR_RESEARCH(r) S_TRUNC_TRIANGLE(r,hr,RINCR(r,x))
const int r_area = R_AREA(S_TRIANGLE_A(hr,hr));
#elif RS == 4
#define FOR_RESEARCH(r) S_TRIANGLE(r,hr,RINCR(r,x))
const int r_area = R_AREA(S_TRIANGLE_A(hr,R));
#elif RS == 3
#define FOR_RESEARCH(r) S_DIAMOND(r,hr,RINCR(r,y))
const int r_area = R_AREA(S_DIAMOND_A(hr,R));
#elif RS == 2
#define FOR_RESEARCH(r) S_VERTICAL(r,hr,RINCR(r,y))
const int r_area = R_AREA(R);
#elif RS == 1
#define FOR_RESEARCH(r) S_HORIZONTAL(r,hr,RINCR(r,x))
const int r_area = R_AREA(R);
#elif RS == 0
#define FOR_RESEARCH(r) S_SQUARE(r,hr,RINCR(r,y))
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
#define PINCR(z,c) (z.c++)
#endif

#define P_AREA(a) (a - PD)

// patch shapes
#if P == 0 || P == 1
#define FOR_PATCH(p) S_1X1(p)
const int p_area = P_AREA(1);
#elif PS == 7
#define FOR_PATCH(p) S_PLUS(p,hp,PINCR(p,y))
const int p_area = P_AREA(S_PLUS_A(hp,P));
#elif PS == 6
#define FOR_PATCH(p) S_SQUARE_EVEN(p,hp,PINCR(p,y))
const int p_area = P_AREA(P*P);
#elif PS == 5
#define FOR_PATCH(p) S_TRUNC_TRIANGLE(p,hp,PINCR(p,x))
const int p_area = P_AREA(S_TRIANGLE_A(hp,hp));
#elif PS == 4
#define FOR_PATCH(p) S_TRIANGLE(p,hp,PINCR(p,x))
const int p_area = P_AREA(S_TRIANGLE_A(hp,P));
#elif PS == 3
#define FOR_PATCH(p) S_DIAMOND(p,hp,PINCR(p,y))
const int p_area = P_AREA(S_DIAMOND_A(hp,P));
#elif PS == 2
#define FOR_PATCH(p) S_VERTICAL(p,hp,PINCR(p,y))
const int p_area = P_AREA(P);
#elif PS == 1
#define FOR_PATCH(p) S_HORIZONTAL(p,hp,PINCR(p,x))
const int p_area = P_AREA(P);
#elif PS == 0
#define FOR_PATCH(p) S_SQUARE(p,hp,PINCR(p,y))
const int p_area = P_AREA(P*P);
#endif

const float r_scale = 1.0/r_area;
const float p_scale = 1.0/p_area;

#define load_(off)  HOOKED_tex(HOOKED_pos + HOOKED_pt * vec2(off))

#if RF && defined(LUMA_raw)
#define load2_(off) RF_LUMA_tex(RF_LUMA_pos + RF_LUMA_pt * vec2(off))
#define gather_offs(off) (RF_LUMA_mul * vec4(textureGatherOffsets(RF_LUMA_raw, RF_LUMA_pos + vec2(off) * RF_LUMA_pt, offsets)))
#define gather(off) RF_LUMA_gather(RF_LUMA_pos + (off)*RF_LUMA_pt, 0)
#elif RF
#define load2_(off) RF_tex(RF_pos + RF_pt * vec2(off))
#else
#define load2_(off) HOOKED_tex(HOOKED_pos + HOOKED_pt * vec2(off))
#define gather_offs(off) (HOOKED_mul * vec4(textureGatherOffsets(HOOKED_raw, HOOKED_pos + vec2(off) * HOOKED_pt, offsets)))
#define gather(off) HOOKED_gather(HOOKED_pos + (off)*HOOKED_pt, 0)
#endif

#if T
vec4 load(vec3 off)
{
	switch (int(off.z)) {
	case 0: return load_(off);
	}
}
vec4 load2(vec3 off)
{
	switch (int(off.z)) {
	case 0: return load2_(off);
	}
}
#else
#define load(off) load_(off)
#define load2(off) load2_(off)
#endif

vec4 poi = load(vec3(0)); // pixel-of-interest

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

vec4 patch_comparison(vec3 r, vec3 r2)
{
	vec3 p;
	vec4 min_rot = vec4(p_area);

	FOR_ROTATION FOR_REFLECTION {
		vec4 pdiff_sq = vec4(0);
		FOR_PATCH(p) {
			vec3 transformed_p = vec3(ref(rot(p.xy, ri), rfi), p.z);
			vec4 diff_sq = pow(load(p + r2) - load2(transformed_p + r), vec4(2));
#if PST && P >= PST
			float pdist = exp(-pow(length(p.xy*PSD)*PSS, 2));
			diff_sq = pow(max(diff_sq, EPSILON), vec4(pdist));
#endif
			pdiff_sq += diff_sq;
		}
		min_rot = min(min_rot, pdiff_sq);
	}

	return min_rot * p_scale;
}

#define NO_GATHER (PD == 0) // never textureGather if any of these conditions are false
#define REGULAR_ROTATIONS (RI == 0 || RI == 1 || RI == 3)

#if defined(LUMA_gather) && ((PS == 3 || PS == 7) && P == 3) && PST == 0 && M != 1 && REGULAR_ROTATIONS && NO_GATHER
// 3x3 diamond/plus patch_comparison_gather
const ivec2 offsets[4] = { ivec2(0,-1), ivec2(-1,0), ivec2(0,1), ivec2(1,0) };
vec4 poi_patch = gather_offs(0);
vec4 patch_comparison_gather(vec3 r, vec3 r2)
{
	float min_rot = p_area - 1;
	vec4 transformer = gather_offs(r);
	FOR_ROTATION {
		FOR_REFLECTION {
			float diff_sq = dot(pow(poi_patch - transformer, vec4(2)), vec4(1));
			min_rot = min(diff_sq, min_rot);
#if RFI
			switch(rfi) {
			case 0: transformer = transformer.zyxw; break;
			case 1: transformer = transformer.zwxy; break; // undoes last mirror, performs another mirror
			case 2: transformer = transformer.zyxw; break; // undoes last mirror
			}
#endif
		}
#if RI == 3
		transformer = transformer.wxyz;
#elif RI == 1
		transformer = transformer.zwxy;
#endif
	}
	return vec4(min_rot + pow(poi.x - load2(r).x, 2), 0, 0, 0) * p_scale;
}
#elif defined(LUMA_gather) && PS == 6 && REGULAR_ROTATIONS && NO_GATHER
// tiled even square patch_comparison_gather
vec4 patch_comparison_gather(vec3 r, vec3 r2)
{
	vec2 tile;
	float min_rot = p_area;

	/* gather order:
	 * w z
	 * x y
	 */
	FOR_ROTATION FOR_REFLECTION {
		float pdiff_sq = 0;
		for (tile.x = -hp; tile.x < hp; tile.x+=2) for (tile.y = -hp; tile.y < hp; tile.y+=2) {
			vec4 poi_patch = gather(tile + r2.xy);
			vec4 transformer = gather(ref(rot(tile + 0.5, ri), rfi) - 0.5 + r.xy);

#if RI
			for (float i = 0; i < ri; i+=90)
				transformer = transformer.wxyz; // rotate 90 degrees
#endif
#if RFI // XXX output is a little off
			switch(rfi) {
			case 1: transformer = transformer.zyxw; break;
			case 2: transformer = transformer.xwzy; break;
			}
#endif

			vec4 diff_sq = pow(poi_patch - transformer, vec4(2));
#if PST && P >= PST
			vec4 pdist = vec4(
				exp(-pow(length((tile+vec2(0,1))*PSD)*PSS, 2)),
				exp(-pow(length((tile+vec2(1,1))*PSD)*PSS, 2)),
				exp(-pow(length((tile+vec2(1,0))*PSD)*PSS, 2)),
				exp(-pow(length((tile+vec2(0,0))*PSD)*PSS, 2))
			);
			diff_sq = pow(max(diff_sq, EPSILON), pdist);
#endif
			pdiff_sq += dot(diff_sq, vec4(1));
		}
		min_rot = min(min_rot, pdiff_sq);
	}

	return vec4(min_rot, 0, 0, 0) * p_scale;
}
#else
#define patch_comparison_gather patch_comparison
#endif

vec4 hook()
{
	vec4 total_weight = vec4(0);
	vec4 sum = vec4(0);
	vec4 result = vec4(0);

	vec3 r = vec3(0);
	vec3 p = vec3(0);
	vec3 me = vec3(0);

#if T && ME == 1 // temporal & motion estimation
	vec3 me_tmp = vec3(0);
	float maxweight = 0;
#elif T && ME == 2 // temporal & motion estimation
	vec3 me_sum = vec3(0);
	float me_weight = 0;
#endif

#if WD == 2 || M == 3 // weight discard, weighted median intensities
	int r_index = 0;
	vec4 all_weights[r_area];
	vec4 all_pixels[r_area];
#elif WD == 1 // weight discard
	vec4 no_weights = vec4(0);
	vec4 discard_total_weight = vec4(0);
	vec4 discard_sum = vec4(0);
#endif

#if M == 1 // Euclidean medians
	vec4 minsum = vec4(0);
#endif

	FOR_FRAME(r) {
#if T && ME == 1 // temporal & motion estimation max weight
	if (r.z > 0) {
		me += me_tmp;
		me_tmp = vec3(0);
		maxweight = 0;
	}
#elif T && ME == 2 // temporal & motion estimation weighted average
	if (r.z > 0) {
		me += round(me_sum / me_weight);
		me_sum = vec3(0);
		me_weight = 0;
	}
#endif
	FOR_RESEARCH(r) {
		// main NLM logic
		const float h = S*0.013;
		const float pdiff_scale = 1.0/(h*h);
		vec4 pdiff_sq = (r.z == 0) ? patch_comparison_gather(r+me, vec3(0)) : patch_comparison(r+me, vec3(0));
		vec4 weight = exp(-pdiff_sq * pdiff_scale);

#if T && ME == 1 // temporal & motion estimation max weight
		me_tmp = vec3(r.xy,0) * step(maxweight, weight.x) + me_tmp * (1 - step(maxweight, weight.x));
		maxweight = max(maxweight, weight.x);
#elif T && ME == 2 // temporal & motion estimation weighted average
		me_sum += vec3(r.xy,0) * weight.x;
		me_weight += weight.x;
#endif

		weight *= exp(-pow(length(r*SD)*SS, 2)); // spatial kernel

#if WD == 2 || M == 3 // weight discard, weighted median intensity
		all_weights[r_index] = weight;
		all_pixels[r_index] = load(r+me);
		r_index++;
#elif WD == 1 // weight discard
		vec4 wd_scale = 1.0/max(no_weights, 1);
		vec4 keeps = step(total_weight*wd_scale * WDT*exp(-wd_scale*WDP), weight);
		discard_sum += load(r+me) * weight * (1 - keeps);
		discard_total_weight += weight * (1 - keeps);
		no_weights += keeps;
#endif

		sum += load(r+me) * weight;
		total_weight += weight;

#if M == 1 // Euclidean median
		// Based on: https://arxiv.org/abs/1207.3056
		// XXX might not work with ME
		vec3 r2;
		vec4 wpdist_sum = vec4(0);
		FOR_FRAME(r2) FOR_RESEARCH(r2) {
			vec4 pdist = (r.z + r2.z) == 0 ? patch_comparison_gather(r+me, r2+me) : patch_comparison(r+me, r2+me);
			wpdist_sum += sqrt(pdist) * (1-weight);
		}

		vec4 newmin = step(wpdist_sum, minsum); // wpdist_sum <= minsum
		newmin *= 1 - step(wpdist_sum, vec4(0)); // && wpdist_sum > 0
		newmin += step(minsum, vec4(0)); // || minsum <= 0
		newmin = min(newmin, 1);

		minsum = (newmin * wpdist_sum) + ((1-newmin) * minsum);
		result = (newmin * load(r+me)) + ((1-newmin) * result);
#endif
	} // FOR_RESEARCH
	} // FOR_FRAME

#if T // temporal
#endif

	vec4 avg_weight = total_weight * r_scale;
	vec4 old_avg_weight = avg_weight;

#if WD == 2 // true average
	total_weight = vec4(0);
	sum = vec4(0);
	vec4 no_weights = vec4(0);

	for (int i = 0; i < r_area; i++) {
		vec4 keeps = step(avg_weight*WDT, all_weights[i]);
		all_weights[i] *= keeps;
		sum += all_pixels[i] * all_weights[i];
		total_weight += all_weights[i];
		no_weights += keeps;
	}
#elif WD == 1 // moving cumulative average
	total_weight -= discard_total_weight;
	sum -= discard_sum;
#endif
#if WD // weight discard
	avg_weight = total_weight / no_weights;
#endif

	total_weight += SW;
	sum += poi * SW;

#if M == 3 // weighted median intensity
	const float hr_area = r_area/2.0;
	vec4 is_median, gt, lt, gte, lte, neq;

	for (int i = 0; i < r_area; i++) {
		gt = lt = vec4(0);
		for (int j = 0; j < r_area; j++) {
			gte = step(all_pixels[i]*all_weights[i], all_pixels[j]*all_weights[j]);
			lte = step(all_pixels[j]*all_weights[j], all_pixels[i]*all_weights[i]);
			neq = 1 - gte * lte;
			gt += gte * neq;
			lt += lte * neq;
		}
		is_median = step(gt, vec4(hr_area)) * step(lt, vec4(hr_area));
		result += step(result, vec4(0)) * is_median * all_pixels[i];
	}
#elif M == 2 // weight map
	result = avg_weight;
#elif M == 0 // mean
	result = sum / total_weight;
#endif

#if AS == 1 // sharpen+denoise
	vec4 sharpened = result + (poi - result) * ASF;
	vec4 sharpening_power = pow(avg_weight, vec4(ASP));
#elif AS == 2 // sharpen only
	vec4 sharpened = poi + (poi - result) * ASF;
	vec4 sharpening_power = pow(avg_weight, vec4(ASP));
#endif

#if EP // extremes preserve
	float luminance = EP_LUMA_texOff(0).x;
	// EPSILON is needed since pow(0,0) is undefined
	float ep_weight = pow(max(min(1-luminance, luminance)*2, EPSILON), (luminance < 0.5 ? DP : BP));
	result = mix(poi, result, ep_weight);
#endif

#if AS == 1 // sharpen+denoise
	result = mix(sharpened, result, sharpening_power);
#elif AS == 2 // sharpen only
	result = mix(sharpened, poi, sharpening_power);
#endif

	return mix(poi, result, BF);
}

