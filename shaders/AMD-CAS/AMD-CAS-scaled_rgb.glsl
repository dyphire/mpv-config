// LICENSE
// =======
// Copyright (c) 2017-2019 Advanced Micro Devices, Inc. All rights reserved.
// -------
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// -------
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
// -------
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Mod of AMD-CAS-scaled.glsl

//!HOOK MAIN
//!BIND HOOKED
//!DESC AMD-CAS-scaled_rgb (Relinearization)
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * / 1.0 >

// User variables - Relinearization
// Compatibility
#define SOURCE_TRC 4 // Is needed to convert from source colorspace to linear light. 0 = None (Skip conversion), 1 = Rec709, 2 = PQ, 3 = sRGB, 4 = BT.1886, 5 = HLG

// Shader code

vec3 From709(vec3 rec709) {
	return max(min(rec709 / vec3(4.5), vec3(0.081)), pow((rec709 + vec3(0.099)) / vec3(1.099), vec3(1.0 / 0.45)));
}

vec3 FromPq(vec3 pq) {
	vec3 p = pow(pq, vec3(0.0126833));
	return (pow(clamp(p - vec3(0.835938), 0.0, 1.0) / (vec3(18.8516) - vec3(18.6875) * p), vec3(6.27739)));
}

vec3 FromSrgb(vec3 srgb) {
	return max(min(srgb / 12.92, vec3(0.04045)), pow((srgb + vec3(0.055)) / vec3(1.055), vec3(2.4)));
}

vec3 FromHlg(vec3 hlg) {
	const float a = 0.17883277;
	const float b = 0.28466892;
	const float c = 0.55991073;

	vec3 linear;
	if (hlg.r >= 0.0 && hlg.r <= 0.5) {
		linear.r = pow(hlg.r, 2.0) / 3.0;
	} else {
		linear.r = (exp((hlg.r - c) / a) + b) / 12.0;
	}
	if (hlg.g >= 0.0 && hlg.g <= 0.5) {
		linear.g = pow(hlg.g, 2.0) / 3.0;
	} else {
		linear.g = (exp((hlg.g - c) / a) + b) / 12.0;
	}
	if (hlg.b >= 0.0 && hlg.b <= 0.5) {
		linear.b = pow(hlg.b, 2.0) / 3.0;
	} else {
		linear.b = (exp((hlg.b - c) / a) + b) / 12.0;
	}

	return linear;
}

vec4 hook() {
	vec4 col = HOOKED_tex(HOOKED_pos);
	col.rgb = clamp(col.rgb, 0.0, 1.0);
#if (SOURCE_TRC == 0)
	return col;
#elif (SOURCE_TRC == 1)
	return vec4(From709(col.rgb), col.a);
#elif (SOURCE_TRC == 2)
	return vec4(FromPq(col.rgb), col.a);
#elif (SOURCE_TRC == 3)
	return vec4(FromSrgb(col.rgb), col.a);
#elif (SOURCE_TRC == 4)
	return vec4(pow(col.rgb, vec3(2.4)), col.a);
#elif (SOURCE_TRC == 5)
	return vec4(FromHlg(col.rgb), col.a);
#endif
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC AMD-CAS-scaled_rgb
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * / 1.0 >
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h

// User variables - Upsampling and Sharpening
// Intensity
#define SHARPENING 1.0 // Sharpening intensity: Adjusts sharpening intensity by averaging the original pixels to the sharpened result. 1.0 is the unmodified default. Will be ignored if SKIP_ORI_LOOKUP is 1. 0.0 to 1.0.
#define CONTRAST 0.0 // Adjusts the range the shader adapts to high contrast (0 is not all the way off).  Higher values = more high contrast sharpening. 0.0 to 1.0.

// Performance
#define CAS_BETTER_DIAGONALS 1 // If set to 0, drops certain math and texture lookup operations for better performance. 0 or 1.
#define CAS_SLOW 0 // If set to 1, uses all the three RGB coefficients for calculating weights which might slightly increase quality in exchange of performance, otherwise only uses the green coefficient by default. 0 or 1.
#define CAS_GO_SLOWER 0 // If set to 1, disables the use of optimized approximate transcendental functions which might slightly increase accuracy in exchange of performance. 0 or 1.
#define SKIP_ORI_LOOKUP 0 // If set to 1, skips transparency preservation and the optional blending step for better performance. 0 or 1.

// Compatibility
#define TARGET_TRC 4 // Is needed to convert from source colorspace to target colorspace. 0 = None (Skip conversion), 1 = Rec709, 2 = PQ, 3 = sRGB, 4 = BT.1886, 5 = HLG

// Shader code

vec3 To709(vec3 linear) {
	return max(min(linear * vec3(4.5), vec3(0.018)), vec3(1.099) * pow(linear, vec3(0.45)) - vec3(0.099));
}

vec3 ToPq(vec3 linear) {
	vec3 p = pow(linear, vec3(0.159302));
	return pow((vec3(0.835938) + vec3(18.8516) * p) / (vec3(1.0) + vec3(18.6875) * p), vec3(78.8438));
}

vec3 ToSrgb(vec3 linear) {
	return max(min(linear * vec3(12.92), vec3(0.0031308)), vec3(1.055) * pow(linear, vec3(0.41666)) - vec3(0.055));
}

vec3 ToHlg(vec3 linear) {
	const float a = 0.17883277;
	const float b = 0.28466892;
	const float c = 0.55991073;

	vec3 hlg;
	if (linear.r <= 1.0 / 12.0) {
		hlg.r = sqrt(3.0 * linear.r);
	} else {
		hlg.r = a * log(12.0 * linear.r - b) + c;
	}
	if (linear.g <= 1.0 / 12.0) {
		hlg.g = sqrt(3.0 * linear.g);
	} else {
		hlg.g = a * log(12.0 * linear.g - b) + c;
	}
	if (linear.b <= 1.0 / 12.0) {
		hlg.b = sqrt(3.0 * linear.b);
	} else {
		hlg.b = a * log(12.0 * linear.b - b) + c;
	}

	return hlg;
}

#if (CAS_GO_SLOWER == 0)

float APrxLoSqrtF1(float a) {
	return uintBitsToFloat((floatBitsToUint(a) >> uint(1)) + uint(0x1fbc4639));
}

vec3 APrxLoSqrtF3(vec3 a) {
	return vec3(APrxLoSqrtF1(a.x), APrxLoSqrtF1(a.y), APrxLoSqrtF1(a.z));
}

float APrxLoRcpF1(float a) {
	return uintBitsToFloat(uint(0x7ef07ebb) - floatBitsToUint(a));
}

vec3 APrxLoRcpF3(vec3 a) {
	return vec3(APrxLoRcpF1(a.x), APrxLoRcpF1(a.y), APrxLoRcpF1(a.z));
}

float APrxMedRcpF1(float a) {
	float b = uintBitsToFloat(uint(0x7ef19fff) - floatBitsToUint(a));
	return b * (-b * a + float(2.0));
}

vec3 APrxMedRcpF3(vec3 a) {
	return vec3(APrxMedRcpF1(a.x), APrxMedRcpF1(a.y), APrxMedRcpF1(a.z));
}

#endif

vec4 hook()
{
	// Scaling algorithm adaptively interpolates between nearest 4 results of the non-scaling algorithm.
	//  a b c d
	//  e f g h
	//  i j k l
	//  m n o p
	// Working these 4 results.
	//  +-----+-----+
	//  |     |     |
	//  |  f..|..g  |
	//  |  .  |  .  |
	//  +-----+-----+
	//  |  .  |  .  |
	//  |  j..|..k  |
	//  |     |     |
	//  +-----+-----+

	vec2 pp = HOOKED_pos * HOOKED_size - 0.5;
	vec2 fp = floor(pp);
	pp -= fp;

// Gather optimization only causes an unnecessary increase in instructions when CAS_BETTER_DIAGONALS is 0
#if (CAS_BETTER_DIAGONALS == 1) && (defined(HOOKED_gather) && (__VERSION__ >= 400 || (GL_ES && __VERSION__ >= 310)))
	vec4 abef_r = HOOKED_gather(vec2((fp - vec2(0.5)) * HOOKED_pt), 0);
	vec4 abef_g = HOOKED_gather(vec2((fp - vec2(0.5)) * HOOKED_pt), 1);
	vec4 abef_b = HOOKED_gather(vec2((fp - vec2(0.5)) * HOOKED_pt), 2);

	vec3 a = vec3(abef_r.w, abef_g.w, abef_b.w);
	vec3 b = vec3(abef_r.z, abef_g.z, abef_b.z);
	vec3 e = vec3(abef_r.x, abef_g.x, abef_b.x);
	vec3 f = vec3(abef_r.y, abef_g.y, abef_b.y);

	vec4 cdgh_r = HOOKED_gather(vec2((fp + vec2(1.5, -0.5)) * HOOKED_pt), 0);
	vec4 cdgh_g = HOOKED_gather(vec2((fp + vec2(1.5, -0.5)) * HOOKED_pt), 1);
	vec4 cdgh_b = HOOKED_gather(vec2((fp + vec2(1.5, -0.5)) * HOOKED_pt), 2);

	vec3 c = vec3(cdgh_r.w, cdgh_g.w, cdgh_b.w);
	vec3 d = vec3(cdgh_r.z, cdgh_g.z, cdgh_b.z);
	vec3 g = vec3(cdgh_r.x, cdgh_g.x, cdgh_b.x);
	vec3 h = vec3(cdgh_r.y, cdgh_g.y, cdgh_b.y);

	vec4 ijmn_r = HOOKED_gather(vec2((fp + vec2(-0.5, 1.5)) * HOOKED_pt), 0);
	vec4 ijmn_g = HOOKED_gather(vec2((fp + vec2(-0.5, 1.5)) * HOOKED_pt), 1);
	vec4 ijmn_b = HOOKED_gather(vec2((fp + vec2(-0.5, 1.5)) * HOOKED_pt), 2);

	vec3 i = vec3(ijmn_r.w, ijmn_g.w, ijmn_b.w);
	vec3 j = vec3(ijmn_r.z, ijmn_g.z, ijmn_b.z);
	vec3 m = vec3(ijmn_r.x, ijmn_g.x, ijmn_b.x);
	vec3 n = vec3(ijmn_r.y, ijmn_g.y, ijmn_b.y);

	vec4 klop_r = HOOKED_gather(vec2((fp + vec2(1.5)) * HOOKED_pt), 0);
	vec4 klop_g = HOOKED_gather(vec2((fp + vec2(1.5)) * HOOKED_pt), 1);
	vec4 klop_b = HOOKED_gather(vec2((fp + vec2(1.5)) * HOOKED_pt), 2);

	vec3 k = vec3(klop_r.w, klop_g.w, klop_b.w);
	vec3 l = vec3(klop_r.z, klop_g.z, klop_b.z);
	vec3 o = vec3(klop_r.x, klop_g.x, klop_b.x);
	vec3 p = vec3(klop_r.y, klop_g.y, klop_b.y);
#else
	ivec2 sp = ivec2(fp);

	#if (CAS_BETTER_DIAGONALS == 1)
		vec3 a = texelFetch(HOOKED_raw, sp + ivec2(-1, -1), 0).rgb * HOOKED_mul;
		vec3 d = texelFetch(HOOKED_raw, sp + ivec2( 2, -1), 0).rgb * HOOKED_mul;
		vec3 m = texelFetch(HOOKED_raw, sp + ivec2(-1,  2), 0).rgb * HOOKED_mul;
		vec3 p = texelFetch(HOOKED_raw, sp + ivec2( 2,  2), 0).rgb * HOOKED_mul;
	#endif

	vec3 b = texelFetch(HOOKED_raw, sp + ivec2( 0, -1), 0).rgb * HOOKED_mul;
	vec3 e = texelFetch(HOOKED_raw, sp + ivec2(-1,  0), 0).rgb * HOOKED_mul;
	vec3 f = texelFetch(HOOKED_raw, sp                , 0).rgb * HOOKED_mul;

	vec3 c = texelFetch(HOOKED_raw, sp + ivec2( 1, -1), 0).rgb * HOOKED_mul;
	vec3 g = texelFetch(HOOKED_raw, sp + ivec2( 1,  0), 0).rgb * HOOKED_mul;
	vec3 h = texelFetch(HOOKED_raw, sp + ivec2( 2,  0), 0).rgb * HOOKED_mul;

	vec3 i = texelFetch(HOOKED_raw, sp + ivec2(-1,  1), 0).rgb * HOOKED_mul;
	vec3 j = texelFetch(HOOKED_raw, sp + ivec2( 0,  1), 0).rgb * HOOKED_mul;
	vec3 n = texelFetch(HOOKED_raw, sp + ivec2( 0,  2), 0).rgb * HOOKED_mul;

	vec3 k = texelFetch(HOOKED_raw, sp + ivec2( 1,  1), 0).rgb * HOOKED_mul;
	vec3 l = texelFetch(HOOKED_raw, sp + ivec2( 2,  1), 0).rgb * HOOKED_mul;
	vec3 o = texelFetch(HOOKED_raw, sp + ivec2( 1,  2), 0).rgb * HOOKED_mul;
#endif

	// Soft min and max.
	// These are 2.0x bigger (factored out the extra multiply).
	//  a b c             b
	//  e f g * 0.5  +  e f g * 0.5  [F]
	//  i j k             j

#if (CAS_SLOW == 1)
	vec3 mnf  = min(min(b, min(e, f)), min(g, j));
	vec3 mxf  = max(max(b, max(e, f)), max(g, j));
#else
	float mnfG = min(min(b.g, min(e.g, f.g)), min(g.g, j.g));
	float mxfG = max(max(b.g, max(e.g, f.g)), max(g.g, j.g));
#endif
#if (CAS_BETTER_DIAGONALS == 1)
	#if (CAS_SLOW == 1)
		vec3 mnf2 = min(min(mnf, min(a, c)), min(i, k));
		mnf += mnf2;

		vec3 mxf2 = max(max(mxf, max(a, c)), max(i, k));
		mxf += mxf2;
	#else
		float mnfG2 = min(min(mnfG, min(a.g, c.g)), min(i.g, k.g));
		mnfG += mnfG2;

		float mxfG2 = max(max(mxfG, max(a.g, c.g)), max(i.g, k.g));
		mxfG += mxfG2;
	#endif
#endif

	//  b c d             c
	//  f g h * 0.5  +  f g h * 0.5  [G]
	//  j k l             k
#if (CAS_SLOW == 1)
	vec3 mng  = min(min(c, min(f, g)), min(h, k));
	vec3 mxg  = max(max(c, max(f, g)), max(h, k));
#else
	float mngG = min(min(c.g, min(f.g, g.g)), min(h.g, k.g));
	float mxgG = max(max(c.g, max(f.g, g.g)), max(h.g, k.g));
#endif
#if (CAS_BETTER_DIAGONALS == 1)
	#if (CAS_SLOW == 1)
		vec3 mng2 = min(min(mng, min(b, d)), min(j, l));
		mng += mng2;

		vec3 mxg2 = max(max(mxg, max(b, d)), max(j, l));
		mxg += mxg2;
	#else
		float mngG2 = min(min(mngG, min(b.g, d.g)), min(j.g, l.g));
		mngG += mngG2;

		float mxgG2 = max(max(mxgG, max(b.g, d.g)), max(j.g, l.g));
		mxgG += mxgG2;
	#endif
#endif

	//  e f g             f
	//  i j k * 0.5  +  i j k * 0.5  [J]
	//  m n o             n
#if (CAS_SLOW == 1)
	vec3 mnj = min(min(f, min(i, j)), min(k, n));
	vec3 mxj = max(max(f, max(i, j)), max(k, n));
#else
	float mnjG  = min(min(f.g, min(i.g, j.g)), min(k.g, n.g));
	float mxjG  = max(max(f.g, max(i.g, j.g)), max(k.g, n.g));
#endif
#if (CAS_BETTER_DIAGONALS == 1)
	#if (CAS_SLOW == 1)
		vec3 mnj2 = min(min(mnj, min(e, g)), min(m, o));
		mnj += mnj2;

		vec3 mxj2 = max(max(mxj, max(e, g)), max(m, o));
		mxj += mxj2;
	#else
		float mnjG2 = min(min(mnjG, min(e.g, g.g)), min(m.g, o.g));
		mnjG += mnjG2;

		float mxjG2 = max(max(mxjG, max(e.g, g.g)), max(m.g, o.g));
		mxjG += mxjG2;
	#endif
#endif

	//  f g h             g
	//  j k l * 0.5  +  j k l * 0.5  [K]
	//  n o p             o
#if (CAS_SLOW == 1)
	vec3 mnk = min(min(g, min(j, k)), min(l, o));
	vec3 mxk = max(max(g, max(j, k)), max(l, o));
#else
	float mnkG = min(min(g.g, min(j.g, k.g)), min(l.g, o.g));
	float mxkG = max(max(g.g, max(j.g, k.g)), max(l.g, o.g));
#endif
#if (CAS_BETTER_DIAGONALS == 1)
	#if (CAS_SLOW == 1)
		vec3 mnk2 = min(min(mnk, min(f, h)), min(n, p));
		mnk += mnk2;

		vec3 mxk2 = max(max(mxk, max(f, h)), max(n, p));
		mxk += mxk2;
	#else
		float mnkG2 = min(min(mnkG, min(f.g, h.g)), min(n.g, p.g));
		mnkG += mnkG2;

		float mxkG2 = max(max(mxkG, max(f.g, h.g)), max(n.g, p.g));
		mxkG += mxkG2;
	#endif
#endif

	// Smooth minimum distance to signal limit divided by smooth max.
	const float bdval = bool(CAS_BETTER_DIAGONALS) ? 2.0 : 1.0;
#if (CAS_SLOW == 1)
	#if (CAS_GO_SLOWER == 1)
		vec3 ampf = clamp(min(mnf, bdval - mxf) / mxf, 0.0, 1.0);
		vec3 ampg = clamp(min(mng, bdval - mxg) / mxg, 0.0, 1.0);
		vec3 ampj = clamp(min(mnj, bdval - mxj) / mxj, 0.0, 1.0);
		vec3 ampk = clamp(min(mnk, bdval - mxk) / mxk, 0.0, 1.0);
	#else
		vec3 ampf = clamp(min(mnf, bdval - mxf) * APrxLoRcpF3(mxf), 0.0, 1.0);
		vec3 ampg = clamp(min(mng, bdval - mxg) * APrxLoRcpF3(mxg), 0.0, 1.0);
		vec3 ampj = clamp(min(mnj, bdval - mxj) * APrxLoRcpF3(mxj), 0.0, 1.0);
		vec3 ampk = clamp(min(mnk, bdval - mxk) * APrxLoRcpF3(mxk), 0.0, 1.0);
	#endif
#else
	#if (CAS_GO_SLOWER == 1)
		float ampfG = clamp(min(mnfG, bdval - mxfG) / mxfG, 0.0, 1.0);
		float ampgG = clamp(min(mngG, bdval - mxgG) / mxgG, 0.0, 1.0);
		float ampjG = clamp(min(mnjG, bdval - mxjG) / mxjG, 0.0, 1.0);
		float ampkG = clamp(min(mnkG, bdval - mxkG) / mxkG, 0.0, 1.0);
	#else
		float ampfG = clamp(min(mnfG, bdval - mxfG) * APrxLoRcpF1(mxfG), 0.0, 1.0);
		float ampgG = clamp(min(mngG, bdval - mxgG) * APrxLoRcpF1(mxgG), 0.0, 1.0);
		float ampjG = clamp(min(mnjG, bdval - mxjG) * APrxLoRcpF1(mxjG), 0.0, 1.0);
		float ampkG = clamp(min(mnkG, bdval - mxkG) * APrxLoRcpF1(mxkG), 0.0, 1.0);
	#endif
#endif

	// Shaping amount of sharpening.
#if (CAS_SLOW == 1)
	#if (CAS_GO_SLOWER == 1)
		ampf = sqrt(ampf);
		ampg = sqrt(ampg);
		ampj = sqrt(ampj);
		ampk = sqrt(ampk);
	#else
		ampf = APrxLoSqrtF3(ampf);
		ampg = APrxLoSqrtF3(ampg);
		ampj = APrxLoSqrtF3(ampj);
		ampk = APrxLoSqrtF3(ampk);
	#endif
#else
	#if (CAS_GO_SLOWER == 1)
		ampfG = sqrt(ampfG);
		ampgG = sqrt(ampgG);
		ampjG = sqrt(ampjG);
		ampkG = sqrt(ampkG);
	#else
		ampfG = APrxLoSqrtF1(ampfG);
		ampgG = APrxLoSqrtF1(ampgG);
		ampjG = APrxLoSqrtF1(ampjG);
		ampkG = APrxLoSqrtF1(ampkG);
	#endif
#endif

	// Filter shape.
	//  0 w 0
	//  w 1 w
	//  0 w 0

	const float peak = -(mix(8.0, 5.0, clamp(CONTRAST, 0.0, 1.0)));
#if (CAS_SLOW == 1)
	vec3 wf = ampf / peak;
	vec3 wg = ampg / peak;
	vec3 wj = ampj / peak;
	vec3 wk = ampk / peak;
#else
	float wfG = ampfG / peak;
	float wgG = ampgG / peak;
	float wjG = ampjG / peak;
	float wkG = ampkG / peak;
#endif

	// Blend between 4 results.
	//  s t
	//  u v
	float s = (1.0 - pp.x) * (1.0 - pp.y);
	float t = pp.x * (1.0 - pp.y);
	float u = (1.0 - pp.x) * pp.y;
	float v = pp.x * pp.y;

	// Thin edges to hide bilinear interpolation (helps diagonals).
	const float thinB = 0.03125; // 1.0 / 32.0

#if (CAS_SLOW == 1)
	#if (CAS_GO_SLOWER == 1)
		s /= thinB + mxf.g - mnf.g;
		t /= thinB + mxg.g - mng.g;
		u /= thinB + mxj.g - mnj.g;
		v /= thinB + mxk.g - mnk.g;
	#else
		s *= APrxLoRcpF1(thinB + mxf.g - mnf.g);
		t *= APrxLoRcpF1(thinB + mxg.g - mng.g);
		u *= APrxLoRcpF1(thinB + mxj.g - mnj.g);
		v *= APrxLoRcpF1(thinB + mxk.g - mnk.g);
	#endif
#else
	#if (CAS_GO_SLOWER == 1)
		s /= thinB + mxfG - mnfG;
		t /= thinB + mxgG - mngG;
		u /= thinB + mxjG - mnjG;
		v /= thinB + mxkG - mnkG;
	#else
		s *= APrxLoRcpF1(thinB + mxfG - mnfG);
		t *= APrxLoRcpF1(thinB + mxgG - mngG);
		u *= APrxLoRcpF1(thinB + mxjG - mnjG);
		v *= APrxLoRcpF1(thinB + mxkG - mnkG);
	#endif
#endif

	// Final weighting.
	//    b c
	//  e f g h
	//  i j k l
	//    n o
	//  _____  _____  _____  _____
	//         fs        gt
	//
	//  _____  _____  _____  _____
	//  fs      s gt  fs  t     gt
	//         ju        kv
	//  _____  _____  _____  _____
	//         fs        gt
	//  ju      u kv  ju  v     kv
	//  _____  _____  _____  _____
	//
	//         ju        kv
#if (CAS_SLOW == 1)
	vec3 qbe = wf * s;
	vec3 qch = wg * t;
	vec3 qf  = wg * t + wj * u + s;
	vec3 qg  = wf * s + wk * v + t;
	vec3 qj  = wf * s + wk * v + u;
	vec3 qk  = wg * t + wj * u + v;
	vec3 qin = wj * u;
	vec3 qlo = wk * v;
#else
	float qbeG = wfG * s;
	float qchG = wgG * t;
	float qfG  = wgG * t + wjG * u + s;
	float qgG  = wfG * s + wkG * v + t;
	float qjG  = wfG * s + wkG * v + u;
	float qkG  = wgG * t + wjG * u + v;
	float qinG = wjG * u;
	float qloG = wkG * v;
#endif

	// Filter.
#if (CAS_SLOW == 1)
	vec3 W = 2.0 * qbe + 2.0 * qch + 2.0 * qin + 2.0 * qlo + qf + qg + qj + qk;
	vec3 pix = b * qbe + e * qbe + c * qch + h * qch + i * qin + n * qin + l * qlo + o * qlo + f * qf + g * qg + j * qj + k * qk;
	#if (CAS_GO_SLOWER == 1)
		pix /= W;
	#else
		pix *= APrxMedRcpF3(W);
	#endif
#else
	// Using green coef only
	float W = 2.0 * qbeG + 2.0 * qchG + 2.0 * qinG + 2.0 * qloG + qfG + qgG + qjG + qkG;
	vec3 pix = b * qbeG + e * qbeG + c * qchG + h * qchG + i * qinG + n * qinG + l * qloG + o * qloG + f * qfG + g * qgG + j * qjG + k * qkG;
	#if (CAS_GO_SLOWER == 1)
		pix /= W;
	#else
		pix *= APrxMedRcpF1(W);
	#endif
#endif

#if (SKIP_ORI_LOOKUP == 0)
	vec4 col = HOOKED_tex(HOOKED_pos);
	pix = mix(col.rgb, pix, clamp(SHARPENING, 0.0, 1.0));
#endif
	pix = clamp(pix, 0.0, 1.0);

#if (TARGET_TRC == 1)
	pix = To709(pix);
#elif (TARGET_TRC == 2)
	pix = ToPq(pix);
#elif (TARGET_TRC == 3)
	pix = ToSrgb(pix);
#elif (TARGET_TRC == 4)
	pix = pow(pix, vec3(1.0 / 2.4));
#elif (TARGET_TRC == 5)
	pix = ToHlg(pix);
#endif

#if (SKIP_ORI_LOOKUP == 0)
	return vec4(pix, col.a);
#else
	return vec4(pix, 1.0);
#endif

}