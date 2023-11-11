// MIT License

// Copyright (c) 2023 João Chrisóstomo

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

//!HOOK CHROMA
//!BIND LUMA
//!BIND HOOKED
//!SAVE LUMA_LOWRES
//!WIDTH CHROMA.w
//!HEIGHT LUMA.h
//!WHEN CHROMA.w LUMA.w <
//!DESC Joint Bilateral (Downscaling Luma 1st Step)

vec4 hook() {
    float factor = ceil(LUMA_size.x / HOOKED_size.x);
    int start = int(ceil(-factor / 2.0 - 0.5));
    int end = int(floor(factor / 2.0 - 0.5));

    float output_luma = 0.0;
    int wt = 0;
    for (int dx = start; dx <= end; dx++) {
        output_luma += LUMA_texOff(vec2(dx + 0.5, 0.0)).x;
        wt++;
    }
    vec4 output_pix = vec4(output_luma / float(wt), 0.0, 0.0, 1.0);
    return output_pix;
}

//!HOOK CHROMA
//!BIND LUMA_LOWRES
//!BIND HOOKED
//!SAVE LUMA_LOWRES
//!WIDTH CHROMA.w
//!HEIGHT CHROMA.h
//!WHEN CHROMA.w LUMA.w <
//!DESC Joint Bilateral (Downscaling Luma 2nd Step)

vec4 hook() {
    float factor = ceil(LUMA_LOWRES_size.y / HOOKED_size.y);
    int start = int(ceil(-factor / 2.0 - 0.5));
    int end = int(floor(factor / 2.0 - 0.5));

    float output_luma = 0.0;
    int wt = 0;
    for (int dy = start; dy <= end; dy++) {
        output_luma += LUMA_LOWRES_texOff(vec2(0.0, dy + 0.5)).x;
        wt++;
    }
    vec4 output_pix = vec4(output_luma / float(wt), 0.0, 0.0, 1.0);
    return output_pix;
}

//!PARAM distance_coeff
//!TYPE float
//!MINIMUM 0.0
2.5

//!PARAM intensity_coeff
//!TYPE float
//!MINIMUM 0.0
512.0

//!HOOK CHROMA
//!BIND LUMA
//!BIND LUMA_LOWRES
//!BIND HOOKED
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!WHEN CHROMA.w LUMA.w <
//!OFFSET ALIGN
//!DESC Joint Bilateral (Upscaling Chroma)

float comp_wd(vec2 distance) {
    return exp(-distance_coeff * pow(length(distance), 2.0));
}

float comp_wi(float distance) {
    return exp(-intensity_coeff * pow(distance, 2.0));
}

vec4 hook() {
    float luma_zero = LUMA_texOff(0.0).x;
    vec4 output_pix = vec4(0.0, 0.0, 0.0, 1.0);

    vec2 pp = HOOKED_pos * HOOKED_size - vec2(0.5);
    vec2 fp = floor(pp);
    pp -= fp;

    vec2 chroma_pixels[12];
    chroma_pixels[0]  = HOOKED_tex(vec2((fp + vec2(0.5, -0.5)) * HOOKED_pt)).xy;
    chroma_pixels[1]  = HOOKED_tex(vec2((fp + vec2(1.5, -0.5)) * HOOKED_pt)).xy;
    chroma_pixels[2]  = HOOKED_tex(vec2((fp + vec2(-0.5, 0.5)) * HOOKED_pt)).xy;
    chroma_pixels[3]  = HOOKED_tex(vec2((fp + vec2( 0.5, 0.5)) * HOOKED_pt)).xy;
    chroma_pixels[4]  = HOOKED_tex(vec2((fp + vec2( 1.5, 0.5)) * HOOKED_pt)).xy;
    chroma_pixels[5]  = HOOKED_tex(vec2((fp + vec2( 2.5, 0.5)) * HOOKED_pt)).xy;
    chroma_pixels[6]  = HOOKED_tex(vec2((fp + vec2(-0.5, 1.5)) * HOOKED_pt)).xy;
    chroma_pixels[7]  = HOOKED_tex(vec2((fp + vec2( 0.5, 1.5)) * HOOKED_pt)).xy;
    chroma_pixels[8]  = HOOKED_tex(vec2((fp + vec2( 1.5, 1.5)) * HOOKED_pt)).xy;
    chroma_pixels[9]  = HOOKED_tex(vec2((fp + vec2( 2.5, 1.5)) * HOOKED_pt)).xy;
    chroma_pixels[10] = HOOKED_tex(vec2((fp + vec2( 0.5, 2.5)) * HOOKED_pt)).xy;
    chroma_pixels[11] = HOOKED_tex(vec2((fp + vec2( 1.5, 2.5)) * HOOKED_pt)).xy;

    float luma_pixels[12];
    luma_pixels[0]  = LUMA_LOWRES_tex(vec2((fp + vec2(0.5, -0.5)) * HOOKED_pt)).x;
    luma_pixels[1]  = LUMA_LOWRES_tex(vec2((fp + vec2(1.5, -0.5)) * HOOKED_pt)).x;
    luma_pixels[2]  = LUMA_LOWRES_tex(vec2((fp + vec2(-0.5, 0.5)) * HOOKED_pt)).x;
    luma_pixels[3]  = LUMA_LOWRES_tex(vec2((fp + vec2( 0.5, 0.5)) * HOOKED_pt)).x;
    luma_pixels[4]  = LUMA_LOWRES_tex(vec2((fp + vec2( 1.5, 0.5)) * HOOKED_pt)).x;
    luma_pixels[5]  = LUMA_LOWRES_tex(vec2((fp + vec2( 2.5, 0.5)) * HOOKED_pt)).x;
    luma_pixels[6]  = LUMA_LOWRES_tex(vec2((fp + vec2(-0.5, 1.5)) * HOOKED_pt)).x;
    luma_pixels[7]  = LUMA_LOWRES_tex(vec2((fp + vec2( 0.5, 1.5)) * HOOKED_pt)).x;
    luma_pixels[8]  = LUMA_LOWRES_tex(vec2((fp + vec2( 1.5, 1.5)) * HOOKED_pt)).x;
    luma_pixels[9]  = LUMA_LOWRES_tex(vec2((fp + vec2( 2.5, 1.5)) * HOOKED_pt)).x;
    luma_pixels[10] = LUMA_LOWRES_tex(vec2((fp + vec2( 0.5, 2.5)) * HOOKED_pt)).x;
    luma_pixels[11] = LUMA_LOWRES_tex(vec2((fp + vec2( 1.5, 2.5)) * HOOKED_pt)).x;

    float wd[12];
    wd[0]  = comp_wd(vec2( 0.0,-1.0) - pp);
    wd[1]  = comp_wd(vec2( 1.0,-1.0) - pp);
    wd[2]  = comp_wd(vec2(-1.0, 0.0) - pp);
    wd[3]  = comp_wd(vec2( 0.0, 0.0) - pp);
    wd[4]  = comp_wd(vec2( 1.0, 0.0) - pp);
    wd[5]  = comp_wd(vec2( 2.0, 0.0) - pp);
    wd[6]  = comp_wd(vec2(-1.0, 1.0) - pp);
    wd[7]  = comp_wd(vec2( 0.0, 1.0) - pp);
    wd[8]  = comp_wd(vec2( 1.0, 1.0) - pp);
    wd[9]  = comp_wd(vec2( 2.0, 1.0) - pp);
    wd[10] = comp_wd(vec2( 0.0, 2.0) - pp);
    wd[11] = comp_wd(vec2( 1.0, 2.0) - pp);

    float wi[12];
    for (int i = 0; i < 12; i++) {
        wi[i] = comp_wi(luma_zero - luma_pixels[i]);
    }

    float w[12];
    for (int i = 0; i < 12; i++) {
        w[i] = wd[i] * wi[i];
    }

    float wt2 = 0.0;
    for (int i = 0; i < 12; i++) {
        wt2 += w[i];
    }

    vec2 ct2 = vec2(0.0);
    for (int i = 0; i < 12; i++) {
        ct2 += w[i] * chroma_pixels[i];
    }

    vec2 chroma_bilat = clamp(ct2 / wt2, 0.0, 1.0);

    output_pix.xy = chroma_bilat;
    return output_pix;
}
