// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/blob/v1.1.4/sdk/include/FidelityFX/gpu/cas/ffx_cas.h

*/


//!PARAM STR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.5


//!HOOK SCALED
//!BIND HOOKED
//!DESC [AMD_CAS_scl_RT] (SDK v1.1.4)
//!WHEN STR

#define min3(a, b, c) min(a, min(b, c))
#define max3(a, b, c) max(a, max(b, c))

ivec2 cas_clamp(ivec2 p) { return clamp(p, ivec2(0), ivec2(HOOKED_size) - 1); }

vec4 hook() {

	ivec2 pos = ivec2(HOOKED_pos * HOOKED_size);

	//  a b c
	//  d e f
	//  g h i
	vec3 a = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2(-1, -1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 b = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2( 0, -1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 c = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2( 1, -1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 d = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2(-1,  0)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 e = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos),                 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 f = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2( 1,  0)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 g = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2(-1,  1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 h = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2( 0,  1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 i = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2( 1,  1)), 0).rgb * HOOKED_mul, 1.0)).rgb;

	//    b
	//  d e f
	//    h
	float mnR = min3(min3(d.r, e.r, f.r), b.r, h.r);
	float mnG = min3(min3(d.g, e.g, f.g), b.g, h.g);
	float mnB = min3(min3(d.b, e.b, f.b), b.b, h.b);
	float mnR2 = min3(min3(mnR, a.r, c.r), g.r, i.r);
	float mnG2 = min3(min3(mnG, a.g, c.g), g.g, i.g);
	float mnB2 = min3(min3(mnB, a.b, c.b), g.b, i.b);
	mnR += mnR2;
	mnG += mnG2;
	mnB += mnB2;

	float mxR = max3(max3(d.r, e.r, f.r), b.r, h.r);
	float mxG = max3(max3(d.g, e.g, f.g), b.g, h.g);
	float mxB = max3(max3(d.b, e.b, f.b), b.b, h.b);
	float mxR2 = max3(max3(mxR, a.r, c.r), g.r, i.r);
	float mxG2 = max3(max3(mxG, a.g, c.g), g.g, i.g);
	float mxB2 = max3(max3(mxB, a.b, c.b), g.b, i.b);
	mxR += mxR2;
	mxG += mxG2;
	mxB += mxB2;

	float rcpMR = 1.0 / mxR;
	float rcpMG = 1.0 / mxG;
	float rcpMB = 1.0 / mxB;
	float ampR = clamp(min(mnR, 2.0 - mxR) * rcpMR, 0.0, 1.0);
	float ampG = clamp(min(mnG, 2.0 - mxG) * rcpMG, 0.0, 1.0);
	float ampB = clamp(min(mnB, 2.0 - mxB) * rcpMB, 0.0, 1.0);
	ampR = sqrt(ampR);
	ampG = sqrt(ampG);
	ampB = sqrt(ampB);

	//  0 w 0
	//  w 1 w
	//  0 w 0
	float peak = -1.0 / mix(8.0, 5.0, STR);
	// float wR = ampR * peak;
	float wG = ampG * peak;
	// float wB = ampB * peak;

	float rcpWeight = 1.0 / (1.0 + 4.0 * wG);
	vec3 result;
	result.r = clamp((b.r * wG + d.r * wG + f.r * wG + h.r * wG + e.r) * rcpWeight, 0.0, 1.0);
	result.g = clamp((b.g * wG + d.g * wG + f.g * wG + h.g * wG + e.g) * rcpWeight, 0.0, 1.0);
	result.b = clamp((b.b * wG + d.b * wG + f.b * wG + h.b * wG + e.b) * rcpWeight, 0.0, 1.0);

	result = delinearize(vec4(result, 1.0)).rgb;
	float alpha = texelFetch(HOOKED_raw, cas_clamp(pos), 0).a * HOOKED_mul;
	return vec4(result, alpha);

}

