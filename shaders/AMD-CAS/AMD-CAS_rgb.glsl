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

// Mod of AMD-CAS.glsl

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC AMD-CAS_rgb (Relinearization)

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

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC AMD-CAS_rgb

// User variables
// Intensity
#define SHARPENING 1.0 // Sharpening intensity: Adjusts sharpening intensity by averaging the original pixels to the sharpened result.  1.0 is the unmodified default. 0.0 to 1.0.
#define CONTRAST 0.0 // Adjusts the range the shader adapts to high contrast (0 is not all the way off).  Higher values = more high contrast sharpening. 0.0 to 1.0.

// Performance
#define CAS_BETTER_DIAGONALS 1 // If set to 0, drops certain math and texture lookup operations for better performance. 0 or 1.
#define CAS_SLOW 0 // If set to 1, uses all the three RGB coefficients for calculating weights which might slightly increase quality in exchange of performance, otherwise only uses the green coefficient by default. 0 or 1.
#define CAS_GO_SLOWER 0 // If set to 1, disables the use of optimized approximate transcendental functions which might slightly increase accuracy in exchange of performance. 0 or 1.
#define SKIP_ALPHA 0 // If set to 1, skips transparency preservation for better performance on OpenGL 4.0+ renderers. 0 or 1.

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
	// fetch a 3x3 neighborhood around the pixel 'e',
	//  a b c
	//  d(e)f
	//  g h i

// Gather optimization only causes an unnecessary increase in instructions when CAS_BETTER_DIAGONALS is 0
// And is only useful if we are skipping transparency preservation
#if (SKIP_ALPHA == 1) && (CAS_BETTER_DIAGONALS == 1) && (defined(MAIN_gather) && (__VERSION__ >= 400 || (GL_ES && __VERSION__ >= 310)))
	vec4 efhi_r = HOOKED_gather(vec2(HOOKED_pos + vec2(0.5) * HOOKED_pt), 0);
	vec4 efhi_g = HOOKED_gather(vec2(HOOKED_pos + vec2(0.5) * HOOKED_pt), 1);
	vec4 efhi_b = HOOKED_gather(vec2(HOOKED_pos + vec2(0.5) * HOOKED_pt), 2);

	vec3 e = vec3(efhi_r.w, efhi_g.w, efhi_b.w);
	vec3 f = vec3(efhi_r.z, efhi_g.z, efhi_b.z);
	vec3 h = vec3(efhi_r.x, efhi_g.x, efhi_b.x);
	vec3 i = vec3(efhi_r.y, efhi_g.y, efhi_b.y);
#else
	vec4 e = HOOKED_tex(HOOKED_pos);
	vec3 f = HOOKED_texOff(vec2(1.0, 0.0)).rgb;
	vec3 h = HOOKED_texOff(vec2(0.0, 1.0)).rgb;
	#if (CAS_BETTER_DIAGONALS == 1)
		vec3 i = HOOKED_texOff(vec2(1.0, 1.0)).rgb;
	#endif
#endif
#if (CAS_BETTER_DIAGONALS == 1)
	vec3 a = HOOKED_texOff(vec2(-1.0, -1.0)).rgb;
	vec3 c = HOOKED_texOff(vec2( 1.0, -1.0)).rgb;
	vec3 g = HOOKED_texOff(vec2(-1.0,  1.0)).rgb;
#endif
	vec3 b = HOOKED_texOff(vec2( 0.0, -1.0)).rgb;
	vec3 d = HOOKED_texOff(vec2(-1.0,  0.0)).rgb;

	// Soft min and max.
	//  a b c			b
	//  d e f * 0.5	+ d e f * 0.5
	//  g h i			h
	// These are 2.0x bigger (factored out the extra multiply).

#if (CAS_SLOW == 1)
	vec3 mn = min(min(min(d, e.rgb), min(f, b)), h);
	vec3 mx = max(max(max(d, e.rgb), max(f, b)), h);
#else
	float mnG = min(min(min(d.g, e.g), min(f.g, b.g)), h.g);
	float mxG = max(max(max(d.g, e.g), max(f.g, b.g)), h.g);
#endif
#if (CAS_BETTER_DIAGONALS == 1)
	#if (CAS_SLOW == 1)
		vec3 mn2 = min(mn, min(min(a, c), min(g, i)));
		mn += mn2;

		vec3 mx2 = max(mx, max(max(a, c), max(g, i)));
		mx += mx2;
	#else
		float mnG2 = min(mnG, min(min(a.g, c.g), min(g.g, i.g)));
		mnG += mnG2;

		float mxG2 = max(mxG, max(max(a.g, c.g), max(g.g, i.g)));
		mxG += mxG2;
	#endif
#endif

	// Smooth minimum distance to signal limit divided by smooth max.
	const float bdval = bool(CAS_BETTER_DIAGONALS) ? 2.0 : 1.0;
#if (CAS_SLOW == 1)
	#if (CAS_GO_SLOWER == 1)
		vec3 amp = clamp(min(mn, bdval - mx) / mx, 0.0, 1.0);
	#else
		vec3 amp = clamp(min(mn, bdval - mx) * APrxLoRcpF3(mx), 0.0, 1.0);
	#endif
#else
	#if (CAS_GO_SLOWER == 1)
		float ampG = clamp(min(mnG, bdval - mxG) / mxG, 0.0, 1.0);
	#else
		float ampG = clamp(min(mnG, bdval - mxG) * APrxLoRcpF1(mxG), 0.0, 1.0);
	#endif
#endif

	// Shaping amount of sharpening.
#if (CAS_SLOW == 1)
	#if (CAS_GO_SLOWER == 1)
		amp = sqrt(amp);
	#else
		amp = APrxLoSqrtF3(amp);
	#endif
#else
	#if (CAS_GO_SLOWER == 1)
		ampG = sqrt(ampG);
	#else
		ampG = APrxLoSqrtF1(ampG);
	#endif
#endif

   // Filter shape.
   //  0 w 0
   //  w 1 w
   //  0 w 0

	const float peak = -(mix(8.0, 5.0, clamp(CONTRAST, 0.0, 1.0)));
#if (CAS_SLOW == 1)
	vec3 w = amp / peak;
#else
	float wG = ampG / peak;
#endif

	// Filter.
#if (CAS_SLOW == 1)
	vec3 Weight = 1.0 + 4.0 * w;
	vec3 pix = ((b + d + f + h) * w) + e.rgb;
	#if (CAS_GO_SLOWER == 1)
		pix /= Weight;
	#else
		pix *= APrxMedRcpF3(Weight);
	#endif
#else
	// Using green coef only
	float Weight = 1.0 + 4.0 * wG;
	vec3 pix = ((b + d + f + h) * wG) + e.rgb;
	#if (CAS_GO_SLOWER == 1)
		pix /= Weight;
	#else
		pix *= APrxMedRcpF1(Weight);
	#endif
#endif
	pix = clamp(mix(e.rgb, pix, clamp(SHARPENING, 0.0, 1.0)), 0.0, 1.0);

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

#if (SKIP_ALPHA == 1)
	return vec4(pix, 1.0);
#else
	return vec4(pix, e.a);
#endif
}