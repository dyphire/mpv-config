// Copyright (c) 2021 Advanced Micro Devices, Inc. All rights reserved.
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

//Mod from AMD-FSR.glsl


//!HOOK MAIN
//!BIND HOOKED
//!DESC FSR_RCAS
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h

// User variables - RCAS
#define SHARPNESS 0.25 // Controls the amount of sharpening. The scale is {0.0 := maximum, to N>0, where N is the number of stops (halving) of the reduction of sharpness}. 0.0 to N>0.
#define FSR_RCAS_DENOISE 1 // If set to 1, applies denoising in addition to sharpening. Can be disabled for better performance. 0 or 1.
#define FSR_RCAS_PASSTHROUGH_ALPHA 1 // If set to 1, preserves transparency in the image. 0 or 1.

// Shader code

#define FSR_RCAS_LIMIT (0.25 - (1.0 / 16.0)) // This is set at the limit of providing unnatural results for sharpening.

float APrxMedRcpF1(float a) {
	float b = uintBitsToFloat(uint(0x7ef19fff) - floatBitsToUint(a));
	return b * (-b * a + float(2.0));
}

float AMax3F1(float x, float y, float z) {
	return max(x, max(y, z)); 
}

float AMin3F1(float x, float y, float z) {
	return min(x, min(y, z));
}

vec4 hook() {
	// Algorithm uses minimal 3x3 pixel neighborhood.
	//    b 
	//  d e f
	//    h
	
	vec4 pix;

	vec3 b = HOOKED_texOff(vec2( 0.0, -1.0)).rgb;
	vec3 d = HOOKED_texOff(vec2(-1.0,  0.0)).rgb;
#if (FSR_RCAS_PASSTHROUGH_ALPHA == 1)
	vec4 ee = HOOKED_tex(HOOKED_pos);
	vec3 e = ee.rgb;
	pix.a = ee.a;
#else
	vec3 e = HOOKED_tex(HOOKED_pos).rgb;
	pix.a = float(1.0);
#endif
	vec3 f = HOOKED_texOff(vec2(1.0, 0.0)).rgb;
	vec3 h = HOOKED_texOff(vec2(0.0, 1.0)).rgb;

	// Rename (32-bit) or regroup (16-bit).
	float bR = b.r;
	float bG = b.g;
	float bB = b.b;
	float dR = d.r;
	float dG = d.g;
	float dB = d.b;
	float eR = e.r;
	float eG = e.g;
	float eB = e.b;
	float fR = f.r;
	float fG = f.g;
	float fB = f.b;
	float hR = h.r;
	float hG = h.g;
	float hB = h.b;

	// Min and max of ring.
	float mn4R = min(AMin3F1(bR, dR, fR), hR);
	float mn4G = min(AMin3F1(bG, dG, fG), hG);
	float mn4B = min(AMin3F1(bB, dB, fB), hB);
	float mx4R = max(AMax3F1(bR, dR, fR), hR);
	float mx4G = max(AMax3F1(bG, dG, fG), hG);
	float mx4B = max(AMax3F1(bB, dB, fB), hB);

	// Immediate constants for peak range.
	vec2 peakC = vec2(1.0, -1.0 * 4.0);

	// Limiters, these need to be high precision RCPs.
	float hitMinR = min(mn4R, eR) * (float(1.0) / (float(4.0) * mx4R));
	float hitMinG = min(mn4G, eG) * (float(1.0) / (float(4.0) * mx4G));
	float hitMinB = min(mn4B, eB) * (float(1.0) / (float(4.0) * mx4B));
	float hitMaxR = (peakC.x - max(mx4R, eR)) * (float(1.0) / (float(4.0) * mn4R + peakC.y));
	float hitMaxG = (peakC.x - max(mx4G, eG)) * (float(1.0) / (float(4.0) * mn4G + peakC.y));
	float hitMaxB = (peakC.x - max(mx4B, eB)) * (float(1.0) / (float(4.0) * mn4B + peakC.y));
	float lobeR = max(-hitMinR, hitMaxR);
	float lobeG = max(-hitMinG, hitMaxG);
	float lobeB = max(-hitMinB, hitMaxB);
	float lobe = max(float(-FSR_RCAS_LIMIT), min(AMax3F1(lobeR, lobeG, lobeB), float(0.0))) * exp2(-max(float(SHARPNESS), float(0.0)));

	// Apply noise removal.
#if (FSR_RCAS_DENOISE == 1)
	// Luma times 2.
	float bL = bB * float(0.5) + (bR* float(0.5) + bG);
	float dL = dB * float(0.5) + (dR* float(0.5) + dG);
	float eL = eB * float(0.5) + (eR* float(0.5) + eG);
	float fL = fB * float(0.5) + (fR* float(0.5) + fG);
	float hL = hB * float(0.5) + (hR* float(0.5) + hG);

	// Noise detection.
	float nz = float(0.25) * bL + float(0.25) * dL + float(0.25) * fL + float(0.25) * hL-eL;
	nz = clamp(abs(nz) * APrxMedRcpF1(AMax3F1(AMax3F1(bL, dL, eL), fL, hL) - AMin3F1(AMin3F1(bL, dL, eL), fL, hL)), 0.0, 1.0);
	nz = float(-0.5) * nz + float(1.0);
	lobe *= nz;
#endif

	// Resolve, which needs the medium precision rcp approximation to avoid visible tonality changes.
	float rcpL = APrxMedRcpF1(float(4.0) * lobe + float(1.0));
	pix.rgb = vec3((lobe * bR+ lobe * dR + lobe * hR + lobe * fR + eR) * rcpL,
				   (lobe * bG+ lobe * dG + lobe * hG + lobe * fG + eG) * rcpL,
				   (lobe * bB+ lobe * dB + lobe * hB + lobe * fB + eB) * rcpL);

	return pix;
}

