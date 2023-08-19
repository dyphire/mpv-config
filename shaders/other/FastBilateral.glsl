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
//!BIND CHROMA
//!BIND LUMA
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!WHEN CHROMA.w LUMA.w <
//!OFFSET ALIGN
//!DESC Fast Bilateral

const float intensity_coeff = 128.0;

float comp_wi(float distance) {
    return exp(-intensity_coeff * distance * distance);
}

vec4 hook() {
    vec2 pp = CHROMA_pos * CHROMA_size - vec2(0.5);
    vec2 fp = floor(pp);
    pp -= fp;

    float luma_00 = LUMA_texOff(0).x;

    vec2 chroma_11 = CHROMA_tex(vec2(fp + vec2(0.5)) * CHROMA_pt).xy;
    vec2 chroma_12 = CHROMA_tex(vec2(fp + vec2(0.5, 1.5)) * CHROMA_pt).xy;
    vec2 chroma_21 = CHROMA_tex(vec2(fp + vec2(1.5, 0.5)) * CHROMA_pt).xy;
    vec2 chroma_22 = CHROMA_tex(vec2(fp + vec2(1.5, 1.5)) * CHROMA_pt).xy;

    float luma_11 = LUMA_tex(vec2(fp + vec2(0.5)) * CHROMA_pt).x;
    float luma_12 = LUMA_tex(vec2(fp + vec2(0.5, 1.5)) * CHROMA_pt).x;
    float luma_21 = LUMA_tex(vec2(fp + vec2(1.5, 0.5)) * CHROMA_pt).x;
    float luma_22 = LUMA_tex(vec2(fp + vec2(1.5, 1.5)) * CHROMA_pt).x;

    float wd11 = (1 - pp.y) * (1 - pp.x);
    float wd12 = pp.y * (1 - pp.x);
    float wd21 = (1 - pp.y) * pp.x;
    float wd22 = pp.y * pp.x;

    float wi11 = comp_wi(abs(luma_00 - luma_11));
    float wi12 = comp_wi(abs(luma_00 - luma_12));
    float wi21 = comp_wi(abs(luma_00 - luma_21));
    float wi22 = comp_wi(abs(luma_00 - luma_22));

    float w11 = wd11 * wi11;
    float w12 = wd12 * wi12;
    float w21 = wd21 * wi21;
    float w22 = wd22 * wi22;

    vec2 ct = chroma_11 * w11 + chroma_12 * w12 + chroma_21 * w21 + chroma_22 * w22;
    float wt = w11 + w12 + w21 + w22;

    vec4 output_pix = vec4(0.0, 0.0, 0.0, 1.0);
    output_pix.xy = ct / wt;
    return  output_pix;
}