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

// FidelityFX CAS by AMD
// ported to mpv by agyild

// Changelog
// Optimized texture lookups for OpenGL 4.0+, DirectX 10+, and OpenGL ES 3.1+ (9 -> 4).
// Changed rcp + mul operations to div for better clarity when CAS_GO_SLOWER is set to 1, since the compiler should automatically
// optimize those instructions anyway.
// Made it directly operate on LUMA plane, since the original shader was operating on LUMA by deriving it from RGB. This should
// cause a major increase in performance, especially on OpenGL 4.0+ renderers (4 texture lookups vs. 9)
// Removed transparency preservation mechanism since the alpha channel is a separate source plan than LUMA
// Added custom gamma curve support for relinearization
// Removed final blending between the original and the sharpened pixels since it was redundant
//
// Notes
// The filter is designed to run in linear light, and does have an optional relinerization and delinearization pass which
// assumes BT.1886 content by default. Do not forget to change SOURCE_TRC and TARGET_TRC variables depending
// on what kind of content the filter is running on. You might want to create seperate versions of the file with different
// colorspace values, and apply them via autoprofiles. Note that running in non-linear light will result in oversharpening.
//
// By default the shader only runs on non-scaled content since it is designed for use without scaling, if the content is
// scaled you should probably use CAS-scaled.glsl instead. However this behavior can be overriden by changing the WHEN
// directives with "OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * / 1.0 < !" which allows it to be used as a pre-upscale sharpener.

//!HOOK LUMA
//!BIND HOOKED
//!DESC FidelityFX Sharpening (Relinearization)
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * / 1.0 > ! OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * / 1.0 < ! *

// User variables - Relinearization
// Compatibility
#define SOURCE_TRC 4 // Is needed to convert from source colorspace to linear light. 0 = None (Skip conversion), 1 = Rec709, 2 = PQ, 3 = sRGB, 4 = BT.1886, 5 = HLG, 6 = Custom
#define CUSTOM_GAMMA 2.2 // Custom power gamma curve to use if and when SOURCE_TRC is 6.

// Shader code

float From709(float rec709) {
	return max(min(rec709 / float(4.5), float(0.081)), pow((rec709 + float(0.099)) / float(1.099), float(1.0 / 0.45)));
}

float FromPq(float pq) {
	float p = pow(pq, float(0.0126833));
	return (pow(clamp(p - float(0.835938), 0.0, 1.0) / (float(18.8516) - float(18.6875) * p), float(6.27739)));
}

float FromSrgb(float srgb) {
	return max(min(srgb / 12.92, float(0.04045)), pow((srgb + float(0.055)) / float(1.055), float(2.4)));
}

float FromHlg(float hlg) {
	const float a = 0.17883277;
	const float b = 0.28466892;
	const float c = 0.55991073;

	float linear;
	if (hlg >= 0.0 && hlg <= 0.5) {
		linear = pow(hlg, 2.0) / 3.0;
	} else {
		linear = (exp((hlg - c) / a) + b) / 12.0;
	}

	return linear;
}

vec4 hook() {
	vec4 col = HOOKED_tex(HOOKED_pos);
	col.r = clamp(col.r, 0.0, 1.0);
#if (SOURCE_TRC == 1)
	col.r = From709(col.r);
#elif (SOURCE_TRC == 2)
	col.r = FromPq(col.r);
#elif (SOURCE_TRC == 3)
	col.r = FromSrgb(col.r);
#elif (SOURCE_TRC == 4)
	col.r = pow(col.r, float(2.4));
#elif (SOURCE_TRC == 5)
	col.r = FromHlg(col.r);
#elif (SOURCE_TRC == 6)
	col.r = pow(col.r, float(CUSTOM_GAMMA));
#endif
	return col;
}

//!HOOK LUMA
//!BIND HOOKED
//!DESC FidelityFX Sharpening
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * / 1.0 > ! OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * / 1.0 < ! *

// User variables
// Intensity
#define SHARPENING 0.0 // Adjusts the range the shader adapts to high contrast (0 is not all the way off).  Higher values = more high contrast sharpening. 0.0 to 1.0.

// Performance
#define CAS_BETTER_DIAGONALS 1 // If set to 0, drops certain math and texture lookup operations for better performance. 0 or 1.
#define CAS_GO_SLOWER 0 // If set to 1, disables the use of optimized approximate transcendental functions which might slightly increase accuracy in exchange of performance. 0 or 1.

// Compatibility
#define TARGET_TRC 4 // Is needed to convert from source colorspace to target colorspace. 0 = None (Skip conversion), 1 = Rec709, 2 = PQ, 3 = sRGB, 4 = BT.1886, 5 = HLG, 6 = Custom
#define CUSTOM_GAMMA 2.2 // Custom power gamma curve to use if and when TARGET_TRC is 6.

// Shader code

float To709(float linear) {
	return max(min(linear * float(4.5), float(0.018)), float(1.099) * pow(linear, float(0.45)) - float(0.099));
}

float ToPq(float linear) {
	float p = pow(linear, float(0.159302));
	return pow((float(0.835938) + float(18.8516) * p) / (float(1.0) + float(18.6875) * p), float(78.8438));
}

float ToSrgb(float linear) {
	return max(min(linear * float(12.92), float(0.0031308)), float(1.055) * pow(linear, float(0.41666)) - float(0.055));
}

float ToHlg(float linear) {
	const float a = 0.17883277;
	const float b = 0.28466892;
	const float c = 0.55991073;

	float hlg;
	if (linear <= 1.0 / 12.0) {
		hlg = sqrt(3.0 * linear);
	} else {
		hlg = a * log(12.0 * linear - b) + c;
	}

	return hlg;
}

#if (CAS_GO_SLOWER == 0)

float APrxLoSqrtF1(float a) {
	return uintBitsToFloat((floatBitsToUint(a) >> uint(1)) + uint(0x1fbc4639));
}

float APrxLoRcpF1(float a) {
	return uintBitsToFloat(uint(0x7ef07ebb) - floatBitsToUint(a));
}

float APrxMedRcpF1(float a) {
	float b = uintBitsToFloat(uint(0x7ef19fff) - floatBitsToUint(a));
	return b * (-b * a + float(2.0));
}

#endif

vec4 hook()
{
	// fetch a 3x3 neighborhood around the pixel 'e',
	//  a b c
	//  d(e)f
	//  g h i

#if (defined(HOOKED_gather) && (__VERSION__ >= 400 || (GL_ES && __VERSION__ >= 310)))
	vec4 efhi = HOOKED_gather(vec2(HOOKED_pos + vec2(0.5) * HOOKED_pt), 0);

	float e = efhi.w;
	float f = efhi.z;
	float h = efhi.x;

	vec3 abd = HOOKED_gather(vec2(HOOKED_pos - vec2(0.5) * HOOKED_pt), 0).wzx;
	float b = abd.y;
	float d = abd.z;

	#if (CAS_BETTER_DIAGONALS == 1)
		float a = abd.x;
		float i = efhi.y;
	#endif
#else
	float e = HOOKED_tex(HOOKED_pos).r;
	float f = HOOKED_texOff(vec2(1.0, 0.0)).r;
	float h = HOOKED_texOff(vec2(0.0, 1.0)).r;
	
	#if (CAS_BETTER_DIAGONALS == 1)
		float a = HOOKED_texOff(vec2(-1.0, -1.0)).r;
		float i = HOOKED_texOff(vec2(1.0, 1.0)).r;
	#endif
	
	float b = HOOKED_texOff(vec2( 0.0, -1.0)).r;
	float d = HOOKED_texOff(vec2(-1.0,  0.0)).r;
#endif
#if (CAS_BETTER_DIAGONALS == 1)
	float c = HOOKED_texOff(vec2( 1.0, -1.0)).r;
	float g = HOOKED_texOff(vec2(-1.0,  1.0)).r;
#endif

	// Soft min and max.
	//  a b c			b
	//  d e f * 0.5	+ d e f * 0.5
	//  g h i			h
	// These are 2.0x bigger (factored out the extra multiply).

	float mnL = min(min(min(d, e), min(f, b)), h);
	float mxL = max(max(max(d, e), max(f, b)), h);
#if (CAS_BETTER_DIAGONALS == 1)
		float mnL2 = min(mnL, min(min(a, c), min(g, i)));
		mnL += mnL2;

		float mxL2 = max(mxL, max(max(a, c), max(g, i)));
		mxL += mxL2;
#endif

	// Smooth minimum distance to signal limit divided by smooth max.
	const float bdval = bool(CAS_BETTER_DIAGONALS) ? 2.0 : 1.0;
#if (CAS_GO_SLOWER == 1)
	float ampL = clamp(min(mnL, bdval - mxL) / mxL, 0.0, 1.0);
#else
	float ampL = clamp(min(mnL, bdval - mxL) * APrxLoRcpF1(mxL), 0.0, 1.0);
#endif

	// Shaping amount of sharpening.
#if (CAS_GO_SLOWER == 1)
	ampL = sqrt(ampL);
#else
	ampL = APrxLoSqrtF1(ampL);
#endif

   // Filter shape.
   //  0 w 0
   //  w 1 w
   //  0 w 0

	const float peak = -(mix(8.0, 5.0, clamp(SHARPENING, 0.0, 1.0)));
	float wL = ampL / peak;

	// Filter.
	// Using green coef only
	float Weight = 1.0 + 4.0 * wL;
	vec4 pix = vec4(0.0, 0.0, 0.0, 1.0);
	pix.r = ((b + d + f + h) * wL) + e;
#if (CAS_GO_SLOWER == 1)
	pix.r /= Weight;
#else
	pix.r *= APrxMedRcpF1(Weight);
#endif
	pix.r = clamp(pix.r, 0.0, 1.0);

#if (TARGET_TRC == 1)
	pix.r = To709(pix.r);
#elif (TARGET_TRC == 2)
	pix.r = ToPq(pix.r);
#elif (TARGET_TRC == 3)
	pix.r = ToSrgb(pix.r);
#elif (TARGET_TRC == 4)
	pix.r = pow(pix.r, float(1.0 / 2.4));
#elif (TARGET_TRC == 5)
	pix.r = ToHlg(pix.r);
#elif (TARGET_TRC == 6)
	pix.r = pow(pix.r, float(1.0 / CUSTOM_GAMMA));
#endif

	return pix;
}