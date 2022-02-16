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

// Mod from AMD-FSR.glsl

//!HOOK MAIN
//!BIND HOOKED
//!DESC FSR_EASU
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * / 1.0 >
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h

// User variables
#define FSR_EASU_PASSTHROUGH_ALPHA 1 // If set to 1, preserves transparency in the image. Can be disabled for more performance. 0 or 1.

// Shader code

float APrxLoRcpF1(float a) {
	return uintBitsToFloat(uint(0x7ef07ebb) - floatBitsToUint(a));
}

float APrxLoRsqF1(float a) {
	return uintBitsToFloat(uint(0x5f347d74) - (floatBitsToUint(a) >> uint(1)));
}

vec3 AMin3F3(vec3 x, vec3 y, vec3 z) {
	return min(x, min(y, z));
}

vec3 AMax3F3(vec3 x, vec3 y, vec3 z) {
	return max(x, max(y, z));
}

 // Filtering for a given tap for the scalar.
 void FsrEasuTap(
	inout vec3 aC,  // Accumulated color, with negative lobe.
	inout float aW, // Accumulated weight.
	vec2 off,       // Pixel offset from resolve position to tap.
	vec2 dir,       // Gradient direction.
	vec2 len,       // Length.
	float lob,      // Negative lobe strength.
	float clp,      // Clipping point.
	vec3 c){        // Tap color.
	// Rotate offset by direction.
	vec2 v;
	v.x = (off.x * ( dir.x)) + (off.y * dir.y);
	v.y = (off.x * (-dir.y)) + (off.y * dir.x);
	// Anisotropy.
	v *= len;
	// Compute distance^2.
	float d2 = v.x * v.x + v.y * v.y;
	// Limit to the window as at corner, 2 taps can easily be outside.
	d2 = min(d2, clp);
	// Approximation of lancos2 without sin() or rcp(), or sqrt() to get x.
	//  (25/16 * (2/5 * x^2 - 1)^2 - (25/16 - 1)) * (1/4 * x^2 - 1)^2
	//  |_______________________________________|   |_______________|
	//                   base                             window
	// The general form of the 'base' is,
	//  (a*(b*x^2-1)^2-(a-1))
	// Where 'a=1/(2*b-b^2)' and 'b' moves around the negative lobe.
	float wB = float(2.0 / 5.0) * d2 + float(-1.0);
	float wA = lob * d2 + float(-1.0);
	wB *= wB;
	wA *= wA;
	wB = float(25.0 / 16.0) * wB + float(-(25.0 / 16.0 - 1.0));
	float w = wB * wA;
	// Do weighted average.
	aC += c * w;
	aW += w;
}

// Accumulate direction and length.
void FsrEasuSet(
	inout vec2 dir,
	inout float len,
	vec2 pp,
	bool biS, bool biT, bool biU, bool biV,
	float lA, float lB, float lC, float lD, float lE){
	// Compute bilinear weight, branches factor out as predicates are compiler time immediates.
	//  s t
	//  u v
	float w = float(0.0);
	if(biS) w = (float(1.0) - pp.x) * (float(1.0) - pp.y);
	if(biT) w = pp.x * (float(1.0) - pp.y);
	if(biU) w = (float(1.0) - pp.x) * pp.y;
	if(biV) w = pp.x * pp.y;
	// Direction is the '+' diff.
	//    a
	//  b c d
	//    e
	// Then takes magnitude from abs average of both sides of 'c'.
	// Length converts gradient reversal to 0, smoothly to non-reversal at 1, shaped, then adding horz and vert terms.
	float dc = lD - lC;
	float cb = lC - lB;
	float lenX = max(abs(dc), abs(cb));
	lenX = APrxLoRcpF1(lenX);
	float dirX = lD - lB;
	dir.x += dirX * w;
	lenX = clamp(abs(dirX) * lenX, float(0.0), float(1.0));
	lenX *= lenX;
	len += lenX * w;
	// Repeat for the y axis.
	float ec = lE - lC;
	float ca = lC - lA;
	float lenY = max(abs(ec), abs(ca));
	lenY = APrxLoRcpF1(lenY);
	float dirY = lE - lA;
	dir.y += dirY * w;
	lenY = clamp(abs(dirY) * lenY, float(0.0), float(1.0));
	lenY *= lenY;
	len += lenY * w;
}

vec4 hook() {
	//------------------------------------------------------------------------------------------------------------------------------
	// Get position of 'f'.
	vec2 pp = HOOKED_pos * input_size - vec2(0.5);
	vec2 fp = floor(pp);
	pp -= fp;
	//------------------------------------------------------------------------------------------------------------------------------
	// 12-tap kernel.
	//    b c
	//  e f g h
	//  i j k l
	//    n o
	// Gather 4 ordering.
	//  a b
	//  r g
	// For packed FP16, need either {rg} or {ab} so using the following setup for gather in all versions,
	//    a b    <- unused (z)
	//    r g
	//  a b a b
	//  r g r g
	//    a b
	//    r g    <- unused (z)
	// Allowing dead-code removal to remove the 'z's.
	
 #if (defined(HOOKED_gather) && (__VERSION__ >= 400 || (GL_ES && __VERSION__ >= 310)))
	vec4 bczzR = HOOKED_gather(vec2((fp + vec2(1.0, -1.0)) / HOOKED_size), 0);
	vec4 bczzG = HOOKED_gather(vec2((fp + vec2(1.0, -1.0)) / HOOKED_size), 1);
	vec4 bczzB = HOOKED_gather(vec2((fp + vec2(1.0, -1.0)) / HOOKED_size), 2);
	
	vec4 ijfeR = HOOKED_gather(vec2((fp + vec2(0.0, 1.0)) / HOOKED_size), 0);
	vec4 ijfeG = HOOKED_gather(vec2((fp + vec2(0.0, 1.0)) / HOOKED_size), 1);
	vec4 ijfeB = HOOKED_gather(vec2((fp + vec2(0.0, 1.0)) / HOOKED_size), 2);
	
	vec4 klhgR = HOOKED_gather(vec2((fp + vec2(2.0, 1.0)) / HOOKED_size), 0);
	vec4 klhgG = HOOKED_gather(vec2((fp + vec2(2.0, 1.0)) / HOOKED_size), 1);
	vec4 klhgB = HOOKED_gather(vec2((fp + vec2(2.0, 1.0)) / HOOKED_size), 2);
	
	vec4 zzonR = HOOKED_gather(vec2((fp + vec2(1.0, 3.0)) / HOOKED_size), 0);
	vec4 zzonG = HOOKED_gather(vec2((fp + vec2(1.0, 3.0)) / HOOKED_size), 1);
	vec4 zzonB = HOOKED_gather(vec2((fp + vec2(1.0, 3.0)) / HOOKED_size), 2);
#else
	// pre-OpenGL 4.0 compatibility
	vec3 b = HOOKED_tex(vec2((fp + vec2(0.5, -0.5)) / HOOKED_size)).rgb;
	vec3 c = HOOKED_tex(vec2((fp + vec2(1.5, -0.5)) / HOOKED_size)).rgb;
	
	vec3 e = HOOKED_tex(vec2((fp + vec2(-0.5, 0.5)) / HOOKED_size)).rgb;
	vec3 f = HOOKED_tex(vec2((fp + vec2( 0.5, 0.5)) / HOOKED_size)).rgb;
	vec3 g = HOOKED_tex(vec2((fp + vec2( 1.5, 0.5)) / HOOKED_size)).rgb;
	vec3 h = HOOKED_tex(vec2((fp + vec2( 2.5, 0.5)) / HOOKED_size)).rgb;
	
	vec3 i = HOOKED_tex(vec2((fp + vec2(-0.5, 1.5)) / HOOKED_size)).rgb;
	vec3 j = HOOKED_tex(vec2((fp + vec2( 0.5, 1.5)) / HOOKED_size)).rgb;
	vec3 k = HOOKED_tex(vec2((fp + vec2( 1.5, 1.5)) / HOOKED_size)).rgb;
	vec3 l = HOOKED_tex(vec2((fp + vec2( 2.5, 1.5)) / HOOKED_size)).rgb;
	
	vec3 n = HOOKED_tex(vec2((fp + vec2(0.5, 2.5) )/ HOOKED_size)).rgb;
	vec3 o = HOOKED_tex(vec2((fp + vec2(1.5, 2.5) )/ HOOKED_size)).rgb;

	vec4 bczzR = vec4(b.r, c.r, 0.0, 0.0);
	vec4 bczzG = vec4(b.g, c.g, 0.0, 0.0);
	vec4 bczzB = vec4(b.b, c.b, 0.0, 0.0);
	
	vec4 ijfeR = vec4(i.r, j.r, f.r, e.r);
	vec4 ijfeG = vec4(i.g, j.g, f.g, e.g);
	vec4 ijfeB = vec4(i.b, j.b, f.b, e.b);
	
	vec4 klhgR = vec4(k.r, l.r, h.r, g.r);
	vec4 klhgG = vec4(k.g, l.g, h.g, g.g);
	vec4 klhgB = vec4(k.b, l.b, h.b, g.b);
	
	vec4 zzonR = vec4(0.0, 0.0, o.r, n.r);
	vec4 zzonG = vec4(0.0, 0.0, o.g, n.g);
	vec4 zzonB = vec4(0.0, 0.0, o.b, n.b);
#endif
	//------------------------------------------------------------------------------------------------------------------------------
	// Simplest multi-channel approximate luma possible (luma times 2, in 2 FMA/MAD).
	vec4 bczzL = bczzB * vec4(0.5) + (bczzR * vec4(0.5) + bczzG);
	vec4 ijfeL = ijfeB * vec4(0.5) + (ijfeR * vec4(0.5) + ijfeG);
	vec4 klhgL = klhgB * vec4(0.5) + (klhgR * vec4(0.5) + klhgG);
	vec4 zzonL = zzonB * vec4(0.5) + (zzonR * vec4(0.5) + zzonG);
	// Rename.
	float bL = bczzL.x;
	float cL = bczzL.y;
	float iL = ijfeL.x;
	float jL = ijfeL.y;
	float fL = ijfeL.z;
	float eL = ijfeL.w;
	float kL = klhgL.x;
	float lL = klhgL.y;
	float hL = klhgL.z;
	float gL = klhgL.w;
	float oL = zzonL.z;
	float nL = zzonL.w;
	// Accumulate for bilinear interpolation.
	vec2 dir = vec2(0.0);
	float len = float(0.0);
	FsrEasuSet(dir, len, pp, true, false, false, false, bL, eL, fL, gL, jL);
	FsrEasuSet(dir, len, pp, false, true, false, false, cL, fL, gL, hL, kL);
	FsrEasuSet(dir, len, pp, false, false, true, false, fL, iL, jL, kL, nL);
	FsrEasuSet(dir, len, pp, false, false, false, true, gL, jL, kL, lL, oL);
	//------------------------------------------------------------------------------------------------------------------------------
	// Normalize with approximation, and cleanup close to zero.
	vec2 dir2 = dir * dir;
	float dirR = dir2.x + dir2.y;
	bool zro = dirR < float(1.0 / 32768.0);
	dirR = APrxLoRsqF1(dirR);
	dirR = zro ? float(1.0) : dirR;
	dir.x = zro ? float(1.0) : dir.x;
	dir *= vec2(dirR);
	// Transform from {0 to 2} to {0 to 1} range, and shape with square.
	len = len * float(0.5);
	len *= len;
	// Stretch kernel {1.0 vert|horz, to sqrt(2.0) on diagonal}.
	float stretch = (dir.x * dir.x + dir.y * dir.y) * APrxLoRcpF1(max(abs(dir.x), abs(dir.y)));
	// Anisotropic length after rotation,
	//  x := 1.0 lerp to 'stretch' on edges
	//  y := 1.0 lerp to 2x on edges
	vec2 len2 = vec2(float(1.0) + (stretch - float(1.0)) * len, float(1.0) + float(-0.5) * len);
	// Based on the amount of 'edge',
	// the window shifts from +/-{sqrt(2.0) to slightly beyond 2.0}.
	float lob = float(0.5) + float((1.0 / 4.0 - 0.04) - 0.5) * len;
	// Set distance^2 clipping point to the end of the adjustable window.
	float clp = APrxLoRcpF1(lob);
	//------------------------------------------------------------------------------------------------------------------------------
	// Accumulation mixed with min/max of 4 nearest.
	//    b c
	//  e f g h
	//  i j k l
	//    n o
	vec3 min4 = min(AMin3F3(vec3(ijfeR.z, ijfeG.z, ijfeB.z), vec3(klhgR.w, klhgG.w, klhgB.w), vec3(ijfeR.y, ijfeG.y, ijfeB.y)), vec3(klhgR.x, klhgG.x, klhgB.x));
	vec3 max4 = max(AMax3F3(vec3(ijfeR.z, ijfeG.z, ijfeB.z), vec3(klhgR.w, klhgG.w, klhgB.w), vec3(ijfeR.y, ijfeG.y, ijfeB.y)), vec3(klhgR.x, klhgG.x, klhgB.x));

	// Accumulation.
	vec3 aC = vec3(0.0);
	float aW = float(0.0);
	FsrEasuTap(aC, aW, vec2( 0.0,-1.0) - pp,dir, len2, lob, clp, vec3(bczzR.x, bczzG.x, bczzB.x)); // b
	FsrEasuTap(aC, aW, vec2( 1.0,-1.0) - pp,dir, len2, lob, clp, vec3(bczzR.y, bczzG.y, bczzB.y)); // c
	FsrEasuTap(aC, aW, vec2(-1.0, 1.0) - pp,dir, len2, lob, clp, vec3(ijfeR.x, ijfeG.x, ijfeB.x)); // i
	FsrEasuTap(aC, aW, vec2( 0.0, 1.0) - pp,dir, len2, lob, clp, vec3(ijfeR.y, ijfeG.y, ijfeB.y)); // j
	FsrEasuTap(aC, aW, vec2( 0.0, 0.0) - pp,dir, len2, lob, clp, vec3(ijfeR.z, ijfeG.z, ijfeB.z)); // f
	FsrEasuTap(aC, aW, vec2(-1.0, 0.0) - pp,dir, len2, lob, clp, vec3(ijfeR.w, ijfeG.w, ijfeB.w)); // e
	FsrEasuTap(aC, aW, vec2( 1.0, 1.0) - pp,dir, len2, lob, clp, vec3(klhgR.x, klhgG.x, klhgB.x)); // k
	FsrEasuTap(aC, aW, vec2( 2.0, 1.0) - pp,dir, len2, lob, clp, vec3(klhgR.y, klhgG.y, klhgB.y)); // l
	FsrEasuTap(aC, aW, vec2( 2.0, 0.0) - pp,dir, len2, lob, clp, vec3(klhgR.z, klhgG.z, klhgB.z)); // h
	FsrEasuTap(aC, aW, vec2( 1.0, 0.0) - pp,dir, len2, lob, clp, vec3(klhgR.w, klhgG.w, klhgB.w)); // g
	FsrEasuTap(aC, aW, vec2( 1.0, 2.0) - pp,dir, len2, lob, clp, vec3(zzonR.z, zzonG.z, zzonB.z)); // o
	FsrEasuTap(aC, aW, vec2( 0.0, 2.0) - pp,dir, len2, lob, clp, vec3(zzonR.w, zzonG.w, zzonB.w)); // n
	//------------------------------------------------------------------------------------------------------------------------------
	// Normalize and dering.
	vec4 pix;
	pix.rgb = min(max4, max(min4, aC * vec3(1.0 / aW)));

	#if (FSR_EASU_PASSTHROUGH_ALPHA == 1)
		pix.a = HOOKED_tex(HOOKED_pos).a;
	#else
		pix.a = float(1.0);
	#endif
	return pix;
}

