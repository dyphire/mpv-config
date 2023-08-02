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
//!DESC Pixel Clipper (Anti-Ringing)
//!WHEN POSTKERNEL.w PREKERNEL.w / 1.000 > POSTKERNEL.h PREKERNEL.h / 1.000 > *

const float strength = 1.0;

vec4 hook() {
    vec2 pp = PREKERNEL_pos * PREKERNEL_size - vec2(0.5);
    vec2 fp = floor(pp);

    vec4 f = PREKERNEL_tex(vec2((fp + vec2( 0.5, 0.5)) * PREKERNEL_pt));
    vec4 g = PREKERNEL_tex(vec2((fp + vec2( 1.5, 0.5)) * PREKERNEL_pt));
    vec4 j = PREKERNEL_tex(vec2((fp + vec2( 0.5, 1.5)) * PREKERNEL_pt));
    vec4 k = PREKERNEL_tex(vec2((fp + vec2( 1.5, 1.5)) * PREKERNEL_pt));

    vec4 min_pix = vec4(1e8);
    min_pix = min(min_pix, f);
    min_pix = min(min_pix, g);
    min_pix = min(min_pix, j);
    min_pix = min(min_pix, k);

    vec4 max_pix = vec4(1e-8);
    max_pix = max(max_pix, f);
    max_pix = max(max_pix, g);
    max_pix = max(max_pix, j);
    max_pix = max(max_pix, k);

    // Sample current high-res pixel
    vec4 hr_pix = POSTKERNEL_texOff(0.0);

    // Clamp the intensity so it doesn't ring
    vec4 clipped = clamp(hr_pix, min_pix, max_pix);
    return mix(hr_pix, clipped, strength);
}
