// The MIT License(MIT)
//
// Copyright(c) 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files(the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and / or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// NVIDIA Image Scaling v1.0.2 by NVIDIA
// ported to mpv by agyild

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC NVIDIA Image Sharpening v1.0.2
//!COMPUTE 32 32 256 1

// User variables
#define SHARPNESS 0.25 // Amount of sharpening. 0.0 to 1.0.
#define NIS_THREAD_GROUP_SIZE 256 // May be set to 128 for better performance on NVIDIA hardware, otherwise set to 256. Don't forget to modify the COMPUTE directive accordingly as well (e.g., COMPUTE 32 32 128 1).
#define NIS_HDR_MODE 0 // Must be set to 1 for content with PQ colorspace. 0 or 1.

// Constant variables
#define NIS_BLOCK_WIDTH 32
#define NIS_BLOCK_HEIGHT 32
#define kSupportSize 5
#define kNumPixelsX (NIS_BLOCK_WIDTH + kSupportSize + 1)
#define kNumPixelsY (NIS_BLOCK_HEIGHT + kSupportSize + 1)
#define NIS_SCALE_FLOAT 1.0f
const float sharpen_slider = clamp(SHARPNESS, 0.0f, 1.0f) - 0.5f;
const float MaxScale = (sharpen_slider >= 0.0f) ? 1.25f : 1.75f;
const float MinScale = (sharpen_slider >= 0.0f) ? 1.25f : 1.0f;
const float LimitScale = (sharpen_slider >= 0.0f) ? 1.25f : 1.0f;
const float kDetectRatio = 2 * 1127.f / 1024.f;
const float kDetectThres = (bool(NIS_HDR_MODE) ? 32.0f : 64.0f) / 1024.0f;
const float kMinContrastRatio = bool(NIS_HDR_MODE) ? 1.5f : 2.0f;
const float kMaxContrastRatio = bool(NIS_HDR_MODE) ? 5.0f : 10.0f;
const float kSharpStartY = bool(NIS_HDR_MODE) ? 0.35f : 0.45f;
const float kSharpEndY = bool(NIS_HDR_MODE) ? 0.55f : 0.9f;
const float kSharpStrengthMin = max(0.0f, 0.4f + sharpen_slider * MinScale * (bool(NIS_HDR_MODE) ? 1.1f : 1.2));
const float kSharpStrengthMax = ((bool(NIS_HDR_MODE) ? 2.2f : 1.6f) + sharpen_slider * MaxScale * 1.8f);
const float kSharpLimitMin = max((bool(NIS_HDR_MODE) ? 0.06f :0.1f), (bool(NIS_HDR_MODE) ? 0.1f : 0.14f) + sharpen_slider * LimitScale * (bool(NIS_HDR_MODE) ? 0.28f : 0.32f)); //
const float kSharpLimitMax = ((bool(NIS_HDR_MODE) ? 0.6f : 0.5f) + sharpen_slider * LimitScale * 0.6f);
const float kRatioNorm = 1.0f / (kMaxContrastRatio - kMinContrastRatio);
const float kSharpScaleY = 1.0f / (kSharpEndY - kSharpStartY);
const float kSharpStrengthScale = kSharpStrengthMax - kSharpStrengthMin;
const float kSharpLimitScale = kSharpLimitMax - kSharpLimitMin;
const float kContrastBoost = 1.0f;
const float kEps = 1.0f / 255.0f;
#define kSrcNormX HOOKED_pt.x
#define kSrcNormY HOOKED_pt.y
#define kDstNormX kSrcNormX
#define kDstNormY kSrcNormY

// HLSL to GLSL macros
#define saturate(x) clamp(x, 0, 1)
#define lerp(a, b, x) mix(a, b, x)

// CS Shared variables
shared float shPixelsY[kNumPixelsY][kNumPixelsX];

// Shader code
float getY(vec3 rgba) {
#if (NIS_HDR_MODE == 1)
	return float(0.262f) * rgba.x + float(0.678f) * rgba.y + float(0.0593f) * rgba.z;
#else
	return float(0.2126f) * rgba.x + float(0.7152f) * rgba.y + float(0.0722f) * rgba.z;
#endif
}

vec4 GetEdgeMap(float p[5][5], int i, int j) {
	const float g_0 = abs(p[0 + i][0 + j] + p[0 + i][1 + j] + p[0 + i][2 + j] - p[2 + i][0 + j] - p[2 + i][1 + j] - p[2 + i][2 + j]);
	const float g_45 = abs(p[1 + i][0 + j] + p[0 + i][0 + j] + p[0 + i][1 + j] - p[2 + i][1 + j] - p[2 + i][2 + j] - p[1 + i][2 + j]);
	const float g_90 = abs(p[0 + i][0 + j] + p[1 + i][0 + j] + p[2 + i][0 + j] - p[0 + i][2 + j] - p[1 + i][2 + j] - p[2 + i][2 + j]);
	const float g_135 = abs(p[1 + i][0 + j] + p[2 + i][0 + j] + p[2 + i][1 + j] - p[0 + i][1 + j] - p[0 + i][2 + j] - p[1 + i][2 + j]);

	const float g_0_90_max = max(g_0, g_90);
	const float g_0_90_min = min(g_0, g_90);
	const float g_45_135_max = max(g_45, g_135);
	const float g_45_135_min = min(g_45, g_135);

	float e_0_90 = 0;
	float e_45_135 = 0;

    if (g_0_90_max + g_45_135_max == 0)
    {
        return vec4(0, 0, 0, 0);
    }

    e_0_90 = min(g_0_90_max / (g_0_90_max + g_45_135_max), 1.0f);
    e_45_135 = 1.0f - e_0_90;

    bool c_0_90 = (g_0_90_max > (g_0_90_min * kDetectRatio)) && (g_0_90_max > kDetectThres) && (g_0_90_max > g_45_135_min);
    bool c_45_135 = (g_45_135_max > (g_45_135_min * kDetectRatio)) && (g_45_135_max > kDetectThres) && (g_45_135_max > g_0_90_min);
    bool c_g_0_90 = g_0_90_max == g_0;
    bool c_g_45_135 = g_45_135_max == g_45;

    float f_e_0_90 = (c_0_90 && c_45_135) ? e_0_90 : 1.0f;
    float f_e_45_135 = (c_0_90 && c_45_135) ? e_45_135 : 1.0f;

    float weight_0 = (c_0_90 && c_g_0_90) ? f_e_0_90 : 0.0f;
    float weight_90 = (c_0_90 && !c_g_0_90) ? f_e_0_90 : 0.0f;
    float weight_45 = (c_45_135 && c_g_45_135) ? f_e_45_135 : 0.0f;
    float weight_135 = (c_45_135 && !c_g_45_135) ? f_e_45_135 : 0.0f;

	return vec4(weight_0, weight_90, weight_45, weight_135);
}

float CalcLTIFast(const float y[5]) {
	const float a_min = min(min(y[0], y[1]), y[2]);
	const float a_max = max(max(y[0], y[1]), y[2]);

	const float b_min = min(min(y[2], y[3]), y[4]);
	const float b_max = max(max(y[2], y[3]), y[4]);

	const float a_cont = a_max - a_min;
	const float b_cont = b_max - b_min;

	const float cont_ratio = max(a_cont, b_cont) / (min(a_cont, b_cont) + kEps);
	return (1.0f - saturate((cont_ratio - kMinContrastRatio) * kRatioNorm)) * kContrastBoost;
}

float EvalUSM(const float pxl[5], const float sharpnessStrength, const float sharpnessLimit) {
	// USM profile
	float y_usm = -0.6001f * pxl[1] + 1.2002f * pxl[2] - 0.6001f * pxl[3];
	// boost USM profile
	y_usm *= sharpnessStrength;
	// clamp to the limit
	y_usm = min(sharpnessLimit, max(-sharpnessLimit, y_usm));
	// reduce ringing
	y_usm *= CalcLTIFast(pxl);

	return y_usm;
}

vec4 GetDirUSM(const float p[5][5]) {
	// sharpness boost & limit are the same for all directions
	const float scaleY = 1.0f - saturate((p[2][2] - kSharpStartY) * kSharpScaleY);
	// scale the ramp to sharpen as a function of luma
	const float sharpnessStrength = scaleY * kSharpStrengthScale + kSharpStrengthMin;
	// scale the ramp to limit USM as a function of luma
	const float sharpnessLimit = (scaleY * kSharpLimitScale + kSharpLimitMin) * p[2][2];

	vec4 rval;
	// 0 deg filter
	float interp0Deg[5];
	{
		for (int i = 0; i < 5; ++i)
		{
			interp0Deg[i] = p[i][2];
		}
	}

	rval.x = EvalUSM(interp0Deg, sharpnessStrength, sharpnessLimit);

	// 90 deg filter
	float interp90Deg[5];
	{
		for (int i = 0; i < 5; ++i)
		{
			interp90Deg[i] = p[2][i];
		}
	}

	rval.y = EvalUSM(interp90Deg, sharpnessStrength, sharpnessLimit);

	//45 deg filter
	float interp45Deg[5];
	interp45Deg[0] = p[1][1];
	interp45Deg[1] = lerp(p[2][1], p[1][2], 0.5f);
	interp45Deg[2] = p[2][2];
	interp45Deg[3] = lerp(p[3][2], p[2][3], 0.5f);
	interp45Deg[4] = p[3][3];

	rval.z = EvalUSM(interp45Deg, sharpnessStrength, sharpnessLimit);

	//135 deg filter
	float interp135Deg[5];
	interp135Deg[0] = p[3][1];
	interp135Deg[1] = lerp(p[3][2], p[2][1], 0.5f);
	interp135Deg[2] = p[2][2];
	interp135Deg[3] = lerp(p[2][3], p[1][2], 0.5f);
	interp135Deg[4] = p[1][3];

	rval.w = EvalUSM(interp135Deg, sharpnessStrength, sharpnessLimit);
	return rval;
}

void hook() {
	uvec2 blockIdx = gl_WorkGroupID.xy;
	uint threadIdx = gl_LocalInvocationID.x;

	const int dstBlockX = int(NIS_BLOCK_WIDTH * blockIdx.x);
	const int dstBlockY = int(NIS_BLOCK_HEIGHT * blockIdx.y);

	// fill in input luma tile in batches of 2x2 pixels
	// we use texture gather to get extra support necessary
	// to compute 2x2 edge map outputs too
	const float kShift = 0.5f - kSupportSize / 2;

	for (int i = int(threadIdx) * 2; i < kNumPixelsX * kNumPixelsY / 2; i += NIS_THREAD_GROUP_SIZE * 2) {
		uvec2 pos = uvec2(uint(i) % uint(kNumPixelsX), uint(i) / uint(kNumPixelsX) * 2);

		for (int dy = 0; dy < 2; dy++) {
			for (int dx = 0; dx < 2; dx++) {
				const float tx = (dstBlockX + pos.x + dx + kShift) * kSrcNormX;
				const float ty = (dstBlockY + pos.y + dy + kShift) * kSrcNormY;
				const vec4 px = HOOKED_tex(vec2(tx, ty));
				shPixelsY[pos.y + dy][pos.x + dx] = getY(px.xyz);
			}
		}
	}

	groupMemoryBarrier();
	barrier();

	for (int k = int(threadIdx); k < NIS_BLOCK_WIDTH * NIS_BLOCK_HEIGHT; k += NIS_THREAD_GROUP_SIZE)
	{
		const ivec2 pos = ivec2(uint(k) % uint(NIS_BLOCK_WIDTH), uint(k) / uint(NIS_BLOCK_WIDTH));

		// load 5x5 support to regs
		float p[5][5];

		for (int i = 0; i < 5; ++i)
		{
			for (int j = 0; j < 5; ++j)
			{
				p[i][j] = shPixelsY[pos.y + i][pos.x + j];
			}
		}

		// get directional filter bank output
		vec4 dirUSM = GetDirUSM(p);

		// generate weights for directional filters
		vec4 w = GetEdgeMap(p, kSupportSize / 2 - 1, kSupportSize / 2 - 1);

		// final USM is a weighted sum filter outputs
		const float usmY = (dirUSM.x * w.x + dirUSM.y * w.y + dirUSM.z * w.z + dirUSM.w * w.w);

		// do bilinear tap and correct rgb texel so it produces new sharpened luma
		const int dstX = dstBlockX + pos.x;
		const int dstY = dstBlockY + pos.y;

		vec4 op = HOOKED_tex(vec2((dstX + 0.5f) * kDstNormX, (dstY + 0.5f) * kDstNormY));
		op.x += usmY;
		op.y += usmY;
		op.z += usmY;

		imageStore(out_image, ivec2(dstX, dstY), op);
	}
}