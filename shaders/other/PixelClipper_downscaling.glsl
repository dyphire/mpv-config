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