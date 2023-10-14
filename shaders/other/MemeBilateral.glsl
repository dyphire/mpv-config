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

//!PARAM distance_coeff
//!TYPE float
//!MINIMUM 0.0
0.5

//!PARAM intensity_coeff
//!TYPE float
//!MINIMUM 0.0
512.0

//!HOOK CHROMA
//!BIND CHROMA
//!BIND LUMA
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!WHEN CHROMA.w LUMA.w <
//!OFFSET ALIGN
//!DESC Meme Bilateral (Upscaling Chroma)

float comp_wd1(vec2 distance) {
    float d = min(length(distance), 2.0);
    if (d < 1.0) {
        return (6.0 + d * d * (-15.0 + d * 9.0)) / 6.0;
    } else {
        return (12.0 + d * (-24.0 + d * (15.0 + d * -3.0))) / 6.0;
    }
}

float comp_wd2(vec2 distance) {
    return exp(-distance_coeff * pow(length(distance), 2.0));
}

float comp_wi(float distance) {
    return exp(-intensity_coeff * pow(distance, 2.0));
}

float comp_w(float wd, float wi) {
    float w = wd * wi;
    // return clamp(w, 1e-32, 1.0);
    return w;
}

vec4 hook() {
    float division_limit = 1e-4;
    float luma_zero = LUMA_texOff(0.0).x;
    vec4 output_pix = vec4(0.0, 0.0, 0.0, 1.0);

    vec2 pp = CHROMA_pos * CHROMA_size - vec2(0.5);
    vec2 fp = floor(pp);
    pp -= fp;

    vec2 chroma_pixels[12];
    chroma_pixels[0] = CHROMA_tex(vec2((fp + vec2(0.5, -0.5)) * CHROMA_pt)).xy;
    chroma_pixels[1] = CHROMA_tex(vec2((fp + vec2(1.5, -0.5)) * CHROMA_pt)).xy;
    chroma_pixels[2] = CHROMA_tex(vec2((fp + vec2(-0.5, 0.5)) * CHROMA_pt)).xy;
    chroma_pixels[3] = CHROMA_tex(vec2((fp + vec2( 0.5, 0.5)) * CHROMA_pt)).xy;
    chroma_pixels[4] = CHROMA_tex(vec2((fp + vec2( 1.5, 0.5)) * CHROMA_pt)).xy;
    chroma_pixels[5] = CHROMA_tex(vec2((fp + vec2( 2.5, 0.5)) * CHROMA_pt)).xy;
    chroma_pixels[6] = CHROMA_tex(vec2((fp + vec2(-0.5, 1.5)) * CHROMA_pt)).xy;
    chroma_pixels[7] = CHROMA_tex(vec2((fp + vec2( 0.5, 1.5)) * CHROMA_pt)).xy;
    chroma_pixels[8] = CHROMA_tex(vec2((fp + vec2( 1.5, 1.5)) * CHROMA_pt)).xy;
    chroma_pixels[9] = CHROMA_tex(vec2((fp + vec2( 2.5, 1.5)) * CHROMA_pt)).xy;
    chroma_pixels[10] = CHROMA_tex(vec2((fp + vec2(0.5, 2.5) ) * CHROMA_pt)).xy;
    chroma_pixels[11] = CHROMA_tex(vec2((fp + vec2(1.5, 2.5) ) * CHROMA_pt)).xy;

    float luma_pixels[12];
    luma_pixels[0] = LUMA_tex(vec2((fp + vec2(0.5, -0.5)) * CHROMA_pt)).x;
    luma_pixels[1] = LUMA_tex(vec2((fp + vec2(1.5, -0.5)) * CHROMA_pt)).x;
    luma_pixels[2] = LUMA_tex(vec2((fp + vec2(-0.5, 0.5)) * CHROMA_pt)).x;
    luma_pixels[3] = LUMA_tex(vec2((fp + vec2( 0.5, 0.5)) * CHROMA_pt)).x;
    luma_pixels[4] = LUMA_tex(vec2((fp + vec2( 1.5, 0.5)) * CHROMA_pt)).x;
    luma_pixels[5] = LUMA_tex(vec2((fp + vec2( 2.5, 0.5)) * CHROMA_pt)).x;
    luma_pixels[6] = LUMA_tex(vec2((fp + vec2(-0.5, 1.5)) * CHROMA_pt)).x;
    luma_pixels[7] = LUMA_tex(vec2((fp + vec2( 0.5, 1.5)) * CHROMA_pt)).x;
    luma_pixels[8]  = LUMA_tex(vec2((fp + vec2( 1.5, 1.5)) * CHROMA_pt)).x;
    luma_pixels[9]  = LUMA_tex(vec2((fp + vec2( 2.5, 1.5)) * CHROMA_pt)).x;
    luma_pixels[10] = LUMA_tex(vec2((fp + vec2(0.5, 2.5) ) * CHROMA_pt)).x;
    luma_pixels[11] = LUMA_tex(vec2((fp + vec2(1.5, 2.5) ) * CHROMA_pt)).x;


// Sharp spatial filter
    float wd1[12];
    wd1[0]  = comp_wd1(vec2( 0.0,-1.0) - pp);
    wd1[1]  = comp_wd1(vec2( 1.0,-1.0) - pp);
    wd1[2]  = comp_wd1(vec2(-1.0, 0.0) - pp);
    wd1[3]  = comp_wd1(vec2( 0.0, 0.0) - pp);
    wd1[4]  = comp_wd1(vec2( 1.0, 0.0) - pp);
    wd1[5]  = comp_wd1(vec2( 2.0, 0.0) - pp);
    wd1[6]  = comp_wd1(vec2(-1.0, 1.0) - pp);
    wd1[7]  = comp_wd1(vec2( 0.0, 1.0) - pp);
    wd1[8]  = comp_wd1(vec2( 1.0, 1.0) - pp);
    wd1[9]  = comp_wd1(vec2( 2.0, 1.0) - pp);
    wd1[10] = comp_wd1(vec2( 0.0, 2.0) - pp);
    wd1[11] = comp_wd1(vec2( 1.0, 2.0) - pp);

    float wt1 = 0.0;
    for (int i = 0; i < 12; i++) {
        wt1 += wd1[i];
    }

    vec2 ct1 = vec2(0.0);
    for (int i = 0; i < 12; i++) {
        ct1 += wd1[i] * chroma_pixels[i];
    }

    vec2 chroma_spatial = ct1 / wt1;

// Bilateral filter
    float wd2[12];
    wd2[0]   = comp_wd2(vec2( 0.0,-1.0) - pp);
    wd2[1]   = comp_wd2(vec2( 1.0,-1.0) - pp);
    wd2[2]   = comp_wd2(vec2(-1.0, 0.0) - pp);
    wd2[3]   = comp_wd2(vec2( 0.0, 0.0) - pp);
    wd2[4]   = comp_wd2(vec2( 1.0, 0.0) - pp);
    wd2[5]   = comp_wd2(vec2( 2.0, 0.0) - pp);
    wd2[6]   = comp_wd2(vec2(-1.0, 1.0) - pp);
    wd2[7]   = comp_wd2(vec2( 0.0, 1.0) - pp);
    wd2[8]   = comp_wd2(vec2( 1.0, 1.0) - pp);
    wd2[9]   = comp_wd2(vec2( 2.0, 1.0) - pp);
    wd2[10]  = comp_wd2(vec2( 0.0, 2.0) - pp);
    wd2[11]  = comp_wd2(vec2( 1.0, 2.0) - pp);

    float wi[12];
    for (int i = 0; i < 12; i++) {
        wi[i] = comp_wi(luma_zero - luma_pixels[i]);
    }

    float w[12];
    for (int i = 0; i < 12; i++) {
        w[i] = comp_w(wd2[i], wi[i]);
    }

    float wt2 = 0.0;
    for (int i = 0; i < 12; i++) {
        wt2 += w[i];
    }

    vec2 ct2 = vec2(0.0);
    for (int i = 0; i < 12; i++) {
        ct2 += w[i] * chroma_pixels[i];
    }

    vec2 chroma_bilat = ct2 / wt2;


// Coefficient of determination
    float luma_avg_12 = 0.0;
    for(int i = 0; i < 12; i++) {
        luma_avg_12 += luma_pixels[i];
    }
    luma_avg_12 /= 12.0;
    
    float luma_var_12 = 0.0;
    for(int i = 0; i < 12; i++) {
        luma_var_12 += pow(luma_pixels[i] - luma_avg_12, 2.0);
    }
    
    vec2 chroma_avg_12 = vec2(0.0);
    for(int i = 0; i < 12; i++) {
        chroma_avg_12 += chroma_pixels[i];
    }
    chroma_avg_12 /= 12.0;
    
    vec2 chroma_var_12 = vec2(0.0);
    for(int i = 0; i < 12; i++) {
        chroma_var_12 += pow(chroma_pixels[i] - chroma_avg_12, vec2(2.0));
    }
    
    vec2 luma_chroma_cov_12 = vec2(0.0);
    for(int i = 0; i < 12; i++) {
        luma_chroma_cov_12 += (luma_pixels[i] - luma_avg_12) * (chroma_pixels[i] - chroma_avg_12);
    }
    
    vec2 corr = abs(luma_chroma_cov_12 / max(sqrt(luma_var_12 * chroma_var_12), division_limit));
    corr = clamp(corr, 0.0, 1.0);

    output_pix.xy = mix(chroma_spatial, chroma_bilat, pow(corr, vec2(2.0)) / 2.0);
    output_pix.xy = clamp(output_pix.xy, 0.0, 1.0);
    return  output_pix;
}
