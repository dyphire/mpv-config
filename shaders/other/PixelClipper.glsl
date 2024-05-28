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

//!HOOK POSTKERNEL
//!BIND POSTKERNEL
//!BIND PREKERNEL
//!DESC Pixel Clipper (Upscaling AR)
//!WHEN POSTKERNEL.w PREKERNEL.w / 1.000 > POSTKERNEL.h PREKERNEL.h / 1.000 > *

#define TWELVE_TAP_AR 0

const float strength = 0.8;

vec4 hook() {
    vec2 pp = PREKERNEL_pos * PREKERNEL_size - vec2(0.5);
    vec2 fp = floor(pp);

    vec4 f = PREKERNEL_tex(vec2((fp + vec2( 0.5, 0.5)) * PREKERNEL_pt));
    vec4 g = PREKERNEL_tex(vec2((fp + vec2( 1.5, 0.5)) * PREKERNEL_pt));
    vec4 j = PREKERNEL_tex(vec2((fp + vec2( 0.5, 1.5)) * PREKERNEL_pt));
    vec4 k = PREKERNEL_tex(vec2((fp + vec2( 1.5, 1.5)) * PREKERNEL_pt));
#if (TWELVE_TAP_AR == 1)
    vec4 b = PREKERNEL_tex(vec2((fp + vec2(0.5, -0.5)) * PREKERNEL_pt));
    vec4 c = PREKERNEL_tex(vec2((fp + vec2(1.5, -0.5)) * PREKERNEL_pt));
    vec4 e = PREKERNEL_tex(vec2((fp + vec2(-0.5, 0.5)) * PREKERNEL_pt));
    vec4 h = PREKERNEL_tex(vec2((fp + vec2( 2.5, 0.5)) * PREKERNEL_pt));
    vec4 i = PREKERNEL_tex(vec2((fp + vec2(-0.5, 1.5)) * PREKERNEL_pt));
    vec4 l = PREKERNEL_tex(vec2((fp + vec2( 2.5, 1.5)) * PREKERNEL_pt));
    vec4 n = PREKERNEL_tex(vec2((fp + vec2(0.5, 2.5) ) * PREKERNEL_pt));
    vec4 o = PREKERNEL_tex(vec2((fp + vec2(1.5, 2.5) ) * PREKERNEL_pt));
#endif

    vec4 min_pix = vec4(1e8);
    min_pix = min(min_pix, f);
    min_pix = min(min_pix, g);
    min_pix = min(min_pix, j);
    min_pix = min(min_pix, k);
#if (TWELVE_TAP_AR == 1)
    min_pix = min(min_pix, b);
    min_pix = min(min_pix, c);
    min_pix = min(min_pix, e);
    min_pix = min(min_pix, h);
    min_pix = min(min_pix, i);
    min_pix = min(min_pix, l);
    min_pix = min(min_pix, n);
    min_pix = min(min_pix, o);
#endif

    vec4 max_pix = vec4(1e-8);
    max_pix = max(max_pix, f);
    max_pix = max(max_pix, g);
    max_pix = max(max_pix, j);
    max_pix = max(max_pix, k);
#if (TWELVE_TAP_AR == 1)
    max_pix = max(max_pix, b);
    max_pix = max(max_pix, c);
    max_pix = max(max_pix, e);
    max_pix = max(max_pix, h);
    max_pix = max(max_pix, i);
    max_pix = max(max_pix, l);
    max_pix = max(max_pix, n);
    max_pix = max(max_pix, o);
#endif

    //Sample current high-res pixel
    vec4 hr_pix = POSTKERNEL_texOff(0.0);

    // Clamp the intensity so it doesn't ring
    vec4 clipped = clamp(hr_pix, min_pix, max_pix);
    return mix(hr_pix, clipped, strength);
}

//!HOOK CHROMA_SCALED
//!BIND CHROMA
//!BIND CHROMA_SCALED
//!DESC Pixel Clipper (Chroma AR)
//!WHEN CHROMA_SCALED.w CHROMA.w / 1.000 > CHROMA_SCALED.h CHROMA.h / 1.000 > *

#define TWELVE_TAP_AR 0

const float strength = 0.8;

vec4 hook() {
    vec2 pp = CHROMA_pos * CHROMA_size - vec2(0.5);
    vec2 fp = floor(pp);

    vec4 f = CHROMA_tex(vec2((fp + vec2( 0.5, 0.5)) * CHROMA_pt));
    vec4 g = CHROMA_tex(vec2((fp + vec2( 1.5, 0.5)) * CHROMA_pt));
    vec4 j = CHROMA_tex(vec2((fp + vec2( 0.5, 1.5)) * CHROMA_pt));
    vec4 k = CHROMA_tex(vec2((fp + vec2( 1.5, 1.5)) * CHROMA_pt));
#if (TWELVE_TAP_AR == 1)
    vec4 b = CHROMA_tex(vec2((fp + vec2(0.5, -0.5)) * CHROMA_pt));
    vec4 c = CHROMA_tex(vec2((fp + vec2(1.5, -0.5)) * CHROMA_pt));
    vec4 e = CHROMA_tex(vec2((fp + vec2(-0.5, 0.5)) * CHROMA_pt));
    vec4 h = CHROMA_tex(vec2((fp + vec2( 2.5, 0.5)) * CHROMA_pt));
    vec4 i = CHROMA_tex(vec2((fp + vec2(-0.5, 1.5)) * CHROMA_pt));
    vec4 l = CHROMA_tex(vec2((fp + vec2( 2.5, 1.5)) * CHROMA_pt));
    vec4 n = CHROMA_tex(vec2((fp + vec2(0.5, 2.5) ) * CHROMA_pt));
    vec4 o = CHROMA_tex(vec2((fp + vec2(1.5, 2.5) ) * CHROMA_pt));
#endif

    vec4 min_pix = vec4(1e8);
    min_pix = min(min_pix, f);
    min_pix = min(min_pix, g);
    min_pix = min(min_pix, j);
    min_pix = min(min_pix, k);
#if (TWELVE_TAP_AR == 1)
    min_pix = min(min_pix, b);
    min_pix = min(min_pix, c);
    min_pix = min(min_pix, e);
    min_pix = min(min_pix, h);
    min_pix = min(min_pix, i);
    min_pix = min(min_pix, l);
    min_pix = min(min_pix, n);
    min_pix = min(min_pix, o);
#endif

    vec4 max_pix = vec4(1e-8);
    max_pix = max(max_pix, f);
    max_pix = max(max_pix, g);
    max_pix = max(max_pix, j);
    max_pix = max(max_pix, k);
#if (TWELVE_TAP_AR == 1)
    max_pix = max(max_pix, b);
    max_pix = max(max_pix, c);
    max_pix = max(max_pix, e);
    max_pix = max(max_pix, h);
    max_pix = max(max_pix, i);
    max_pix = max(max_pix, l);
    max_pix = max(max_pix, n);
    max_pix = max(max_pix, o);
#endif

    //Sample current high-res pixel
    vec4 hr_pix = CHROMA_SCALED_texOff(0.0);

    // Clamp the intensity so it doesn't ring
    vec4 clipped = clamp(hr_pix, min_pix, max_pix);
    return mix(hr_pix, clipped, strength);
}

//!HOOK POSTKERNEL
//!BIND PREKERNEL
//!BIND POSTKERNEL
//!DESC Pixel Clipper (Downscaling AR)
//!WHEN POSTKERNEL.w PREKERNEL.w / 1.000 < POSTKERNEL.h PREKERNEL.h / 1.000 < *

const float strength = 1.0;

vec4 hook() {
    int radius = int(ceil((PREKERNEL_size.x / POSTKERNEL_size.x) * 0.5));
    vec4 pix = vec4(0.0);
    vec4 min_pix = vec4(1e8);
    vec4 max_pix = vec4(1e-8);

    for (int dx = -radius; dx <= radius; dx++) {
        for (int dy = -radius; dy <= radius; dy++) {
            pix = PREKERNEL_texOff(vec2(dx, dy));
            min_pix = min(pix, min_pix);
            max_pix = max(pix, max_pix);
        }
    }

    vec4 lr_pix = POSTKERNEL_texOff(0.0);
    vec4 clipped = clamp(lr_pix, min_pix, max_pix);
    return mix(lr_pix, clipped, strength);
}
