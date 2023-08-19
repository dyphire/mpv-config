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
//!DESC Joint Bilateral

const float distance_coeff = 2.0;
const float intensity_coeff = 128.0;

float comp_wd(vec2 distance) {
    return exp(-distance_coeff * (distance.x * distance.x + distance.y * distance.y));
}

float comp_wi(float distance) {
    return exp(-intensity_coeff * distance * distance);
}

float comp_w(float wd, float wi) {
    float w = wd * wi;
    // return clamp(w, 1e-32, 1.0);
    return w;
}

vec4 hook() {
    vec2 pp = CHROMA_pos * CHROMA_size - vec2(0.5);
    vec2 fp = floor(pp);
    pp -= fp;

    vec2 chroma_b = CHROMA_tex(vec2((fp + vec2(0.5, -0.5)) * CHROMA_pt)).xy;
    vec2 chroma_c = CHROMA_tex(vec2((fp + vec2(1.5, -0.5)) * CHROMA_pt)).xy;
    vec2 chroma_e = CHROMA_tex(vec2((fp + vec2(-0.5, 0.5)) * CHROMA_pt)).xy;
    vec2 chroma_f = CHROMA_tex(vec2((fp + vec2( 0.5, 0.5)) * CHROMA_pt)).xy;
    vec2 chroma_g = CHROMA_tex(vec2((fp + vec2( 1.5, 0.5)) * CHROMA_pt)).xy;
    vec2 chroma_h = CHROMA_tex(vec2((fp + vec2( 2.5, 0.5)) * CHROMA_pt)).xy;
    vec2 chroma_i = CHROMA_tex(vec2((fp + vec2(-0.5, 1.5)) * CHROMA_pt)).xy;
    vec2 chroma_j = CHROMA_tex(vec2((fp + vec2( 0.5, 1.5)) * CHROMA_pt)).xy;
    vec2 chroma_k = CHROMA_tex(vec2((fp + vec2( 1.5, 1.5)) * CHROMA_pt)).xy;
    vec2 chroma_l = CHROMA_tex(vec2((fp + vec2( 2.5, 1.5)) * CHROMA_pt)).xy;
    vec2 chroma_n = CHROMA_tex(vec2((fp + vec2(0.5, 2.5) ) * CHROMA_pt)).xy;
    vec2 chroma_o = CHROMA_tex(vec2((fp + vec2(1.5, 2.5) ) * CHROMA_pt)).xy;

    float luma_0 = LUMA_texOff(0.0).x;
    float luma_b = LUMA_tex(vec2((fp + vec2(0.5, -0.5)) * CHROMA_pt)).x;
    float luma_c = LUMA_tex(vec2((fp + vec2(1.5, -0.5)) * CHROMA_pt)).x;
    float luma_e = LUMA_tex(vec2((fp + vec2(-0.5, 0.5)) * CHROMA_pt)).x;
    float luma_f = LUMA_tex(vec2((fp + vec2( 0.5, 0.5)) * CHROMA_pt)).x;
    float luma_g = LUMA_tex(vec2((fp + vec2( 1.5, 0.5)) * CHROMA_pt)).x;
    float luma_h = LUMA_tex(vec2((fp + vec2( 2.5, 0.5)) * CHROMA_pt)).x;
    float luma_i = LUMA_tex(vec2((fp + vec2(-0.5, 1.5)) * CHROMA_pt)).x;
    float luma_j = LUMA_tex(vec2((fp + vec2( 0.5, 1.5)) * CHROMA_pt)).x;
    float luma_k = LUMA_tex(vec2((fp + vec2( 1.5, 1.5)) * CHROMA_pt)).x;
    float luma_l = LUMA_tex(vec2((fp + vec2( 2.5, 1.5)) * CHROMA_pt)).x;
    float luma_n = LUMA_tex(vec2((fp + vec2(0.5, 2.5) ) * CHROMA_pt)).x;
    float luma_o = LUMA_tex(vec2((fp + vec2(1.5, 2.5) ) * CHROMA_pt)).x;

    float wd_b = comp_wd(vec2( 0.0,-1.0) - pp);
    float wd_c = comp_wd(vec2( 1.0,-1.0) - pp);
    float wd_e = comp_wd(vec2(-1.0, 0.0) - pp);
    float wd_f = comp_wd(vec2( 0.0, 0.0) - pp);
    float wd_g = comp_wd(vec2( 1.0, 0.0) - pp);
    float wd_h = comp_wd(vec2( 2.0, 0.0) - pp);
    float wd_i = comp_wd(vec2(-1.0, 1.0) - pp);
    float wd_j = comp_wd(vec2( 0.0, 1.0) - pp);
    float wd_k = comp_wd(vec2( 1.0, 1.0) - pp);
    float wd_l = comp_wd(vec2( 2.0, 1.0) - pp);
    float wd_n = comp_wd(vec2( 0.0, 2.0) - pp);
    float wd_o = comp_wd(vec2( 1.0, 2.0) - pp);

    float wi_b = comp_wi(luma_0 - luma_b);
    float wi_c = comp_wi(luma_0 - luma_c);
    float wi_e = comp_wi(luma_0 - luma_e);
    float wi_f = comp_wi(luma_0 - luma_f);
    float wi_g = comp_wi(luma_0 - luma_g);
    float wi_h = comp_wi(luma_0 - luma_h);
    float wi_i = comp_wi(luma_0 - luma_i);
    float wi_j = comp_wi(luma_0 - luma_j);
    float wi_k = comp_wi(luma_0 - luma_k);
    float wi_l = comp_wi(luma_0 - luma_l);
    float wi_n = comp_wi(luma_0 - luma_n);
    float wi_o = comp_wi(luma_0 - luma_o);

    float w_b = comp_w(wd_b, wi_b);
    float w_c = comp_w(wd_c, wi_c);
    float w_e = comp_w(wd_e, wi_e);
    float w_f = comp_w(wd_f, wi_f);
    float w_g = comp_w(wd_g, wi_g);
    float w_h = comp_w(wd_h, wi_h);
    float w_i = comp_w(wd_i, wi_i);
    float w_j = comp_w(wd_j, wi_j);
    float w_k = comp_w(wd_k, wi_k);
    float w_l = comp_w(wd_l, wi_l);
    float w_n = comp_w(wd_n, wi_n);
    float w_o = comp_w(wd_o, wi_o);

    float wt = 0.0;
    wt += w_b;
    wt += w_c;
    wt += w_e;
    wt += w_f;
    wt += w_g;
    wt += w_h;
    wt += w_i;
    wt += w_j;
    wt += w_k;
    wt += w_l;
    wt += w_n;
    wt += w_o;

    vec2 ct = vec2(0.0);
    ct += w_b * chroma_b;
    ct += w_c * chroma_c;
    ct += w_e * chroma_e;
    ct += w_f * chroma_f;
    ct += w_g * chroma_g;
    ct += w_h * chroma_h;
    ct += w_i * chroma_i;
    ct += w_j * chroma_j;
    ct += w_k * chroma_k;
    ct += w_l * chroma_l;
    ct += w_n * chroma_n;
    ct += w_o * chroma_o;

    vec4 output_pix = vec4(0.0, 0.0, 0.0, 1.0);
    output_pix.xy = ct / wt;
    output_pix.xy = clamp(output_pix.xy, 0.0, 1.0);
    return  output_pix;
}
