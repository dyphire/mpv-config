// Copyright (c) 2020 Advanced Micro Devices, Inc. All rights reserved.
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


// ============================================================================
// Contrast Adaptive Sharpening - deus0ww - 2020-08-04
// 
// Orginal: https://github.com/GPUOpen-Effects/FidelityFX-CAS
// Reshade: https://gist.github.com/SLSNe/bbaf2d77db0b2a2a0755df581b3cf00c
// Reshade: https://gist.github.com/martymcmodding/30304c4bffa6e2bd2eb59ff8bb09d135
// ============================================================================


//!HOOK SCALED
//!BIND HOOKED
//!DESC Contrast Adaptive Sharpening [0.50]

#define SHARPNESS 0.50  // Sharpening strength

#define saturate(x) clamp(x, 0.0, 1.0)

const float peak = -1.0 / mix(8.0, 5.0, saturate(SHARPNESS));

vec4 hook() {
	// fetch a 3x3 neighborhood around the pixel 'e',
	//	a b c
	//	d(e)f
	//	g h i
	vec3 a = HOOKED_texOff(ivec2(-1, -1)).rgb;
	vec3 b = HOOKED_texOff(ivec2( 0, -1)).rgb;
	vec3 c = HOOKED_texOff(ivec2( 1, -1)).rgb;
	vec3 d = HOOKED_texOff(ivec2(-1,  0)).rgb;
	vec3 e = HOOKED_texOff(ivec2( 0,  0)).rgb;
	vec3 f = HOOKED_texOff(ivec2( 1,  0)).rgb;
	vec3 g = HOOKED_texOff(ivec2(-1,  1)).rgb;
	vec3 h = HOOKED_texOff(ivec2( 0,  1)).rgb;
	vec3 i = HOOKED_texOff(ivec2( 1,  1)).rgb;

	// Soft min and max.
	//	a b c			  b
	//	d e f * 0.5	 +	d e f * 0.5
	//	g h i			  h
	// These are 2.0x bigger (factored out the extra multiply).
    vec3 mnRGB = min(min(min(d, e), min(f, b)), h);
    vec3 mnRGB2 = min(mnRGB, min(min(a, c), min(g, i)));
    mnRGB += mnRGB2;

    vec3 mxRGB = max(max(max(d, e), max(f, b)), h);
    vec3 mxRGB2 = max(mxRGB, max(max(a, c), max(g, i)));
    mxRGB += mxRGB2;

	// Smooth minimum distance to signal limit divided by smooth max.
	vec3 ampRGB = saturate(min(mnRGB, 2.0 - mxRGB) / mxRGB);
	
	// Shaping amount of sharpening.
	vec3 wRGB = sqrt(ampRGB) * peak;
	
	// Filter shape.
	//  0 w 0
	//  w 1 w
	//  0 w 0  
	vec3 weightRGB = 1.0 + 4.0 * wRGB;
	vec3 window = (b + d) + (f + h);
	return vec4(saturate((window * wRGB + e) / weightRGB).rgb, HOOKED_tex(HOOKED_pos).a);
}
