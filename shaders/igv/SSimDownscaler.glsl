// SSimDownscaler by Shiandow
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 3.0 of the License, or (at your option) any later version.
// 
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this library.

//!HOOK POSTKERNEL
//!BIND HOOKED
//!BIND PREKERNEL
//!SAVE L2
//!WIDTH NATIVE_CROPPED.w
//!WHEN NATIVE_CROPPED.h POSTKERNEL.h >
//!COMPONENTS 3
//!DESC SSimDownscaler calc L2 pass 1

#define axis 1

#define offset      vec2(0,0)

#define MN(B,C,x)   (x < 1.0 ? ((2.-1.5*B-(C))*x + (-3.+2.*B+C))*x*x + (1.-(B)/3.) : (((-(B)/6.-(C))*x + (B+5.*C))*x + (-2.*B-8.*C))*x+((4./3.)*B+4.*C))
#define Kernel(x)   MN(1.0/3.0, 1.0/3.0, abs(x))
#define taps        2.0

vec4 hook() {
    vec2 base = PREKERNEL_pt * (PREKERNEL_pos * input_size + tex_offset);

    // Calculate bounds
    float low  = ceil((PREKERNEL_pos - taps*POSTKERNEL_pt) * input_size - offset + tex_offset - 0.5)[axis];
    float high = floor((PREKERNEL_pos + taps*POSTKERNEL_pt) * input_size - offset + tex_offset - 0.5)[axis];

    float W = 0.0;
    vec4 avg = vec4(0);
    vec2 pos = base;

    for (float k = low; k <= high; k++) {
        pos[axis] = PREKERNEL_pt[axis] * (k - offset[axis] + 0.5);
        float rel = (pos[axis] - base[axis])*POSTKERNEL_size[axis];
        float w = Kernel(rel);

        avg += w * pow(clamp(textureLod(PREKERNEL_raw, pos, 0.0) * PREKERNEL_mul, 0.0, 1.0), vec4(2.0));
        W += w;
    }
    avg /= W;

    return avg;
}

//!HOOK POSTKERNEL
//!BIND HOOKED
//!BIND L2
//!SAVE L2
//!WHEN NATIVE_CROPPED.w POSTKERNEL.w >
//!COMPONENTS 3
//!DESC SSimDownscaler calc L2 pass 2

#define axis 0

#define offset      vec2(0,0)

#define MN(B,C,x)   (x < 1.0 ? ((2.-1.5*B-(C))*x + (-3.+2.*B+C))*x*x + (1.-(B)/3.) : (((-(B)/6.-(C))*x + (B+5.*C))*x + (-2.*B-8.*C))*x+((4./3.)*B+4.*C))
#define Kernel(x)   MN(1.0/3.0, 1.0/3.0, abs(x))
#define taps        2.0

vec4 hook() {
    // Calculate bounds
    float low  = ceil((L2_pos - taps*POSTKERNEL_pt) * L2_size - offset - 0.5)[axis];
    float high = floor((L2_pos + taps*POSTKERNEL_pt) * L2_size - offset - 0.5)[axis];

    float W = 0.0;
    vec4 avg = vec4(0);
    vec2 pos = L2_pos;

    for (float k = low; k <= high; k++) {
        pos[axis] = L2_pt[axis] * (k - offset[axis] + 0.5);
        float rel = (pos[axis] - L2_pos[axis])*POSTKERNEL_size[axis];
        float w = Kernel(rel);

        avg += w * textureLod(L2_raw, pos, 0.0) * L2_mul;
        W += w;
    }
    avg /= W;

    return avg;
}

//!HOOK POSTKERNEL
//!BIND HOOKED
//!SAVE M
//!WHEN NATIVE_CROPPED.h POSTKERNEL.h >
//!COMPONENTS 3
//!DESC SSimDownscaler calc Mean

#define locality    8.0

#define offset      vec2(0,0)

#define Kernel(x)   pow(1.0 / locality, abs(x))
#define taps        3.0
#define maxtaps     taps

vec4 ScaleH(vec2 pos) {
    // Calculate bounds
    float low  = floor(-0.5*maxtaps - offset)[0];
    float high = floor(+0.5*maxtaps - offset)[0];

    float W = 0.0;
    vec4 avg = vec4(0);

    for (float k = 0.0; k < maxtaps; k++) {
        pos[0] = POSTKERNEL_pos[0] + POSTKERNEL_pt[0] * (k + low + 1.0);
        float rel = (k + low + 1.0) + offset[0];
        float w = Kernel(rel);

        avg += w * clamp(POSTKERNEL_tex(pos), 0.0, 1.0);
        W += w;
    }
    avg /= W;

    return avg;
}

vec4 hook() {
    // Calculate bounds
    float low  = floor(-0.5*maxtaps - offset)[1];
    float high = floor(+0.5*maxtaps - offset)[1];

    float W = 0.0;
    vec4 avg = vec4(0);
    vec2 pos = POSTKERNEL_pos;

    for (float k = 0.0; k < maxtaps; k++) {
        pos[1] = POSTKERNEL_pos[1] + POSTKERNEL_pt[1] * (k + low + 1.0);
        float rel = (k + low + 1.0) + offset[1];
        float w = Kernel(rel);

        avg += w * ScaleH(pos);
        W += w;
    }
    avg /= W;

    return avg;
}

//!HOOK POSTKERNEL
//!BIND HOOKED
//!BIND L2
//!BIND M
//!SAVE R
//!WHEN NATIVE_CROPPED.h POSTKERNEL.h >
//!COMPONENTS 3
//!DESC SSimDownscaler calc R

#define locality    8.0

#define offset      vec2(0,0)

#define Kernel(x)   pow(1.0 / locality, abs(x))
#define taps        3.0
#define maxtaps     taps

mat2x4 ScaleH(vec2 pos) {
    // Calculate bounds
    float low  = floor(-0.5*maxtaps - offset)[0];
    float high = floor(+0.5*maxtaps - offset)[0];

    float W = 0.0;
    mat2x4 avg = mat2x4(0);

    for (float k = 0.0; k < maxtaps; k++) {
        pos[0] = L2_pos[0] + L2_pt[0] * (k + low + 1.0);
        float rel = (k + low + 1.0) + offset[0];
        float w = Kernel(rel);

        avg += w * mat2x4(pow(clamp(POSTKERNEL_tex(pos), 0.0, 1.0), vec4(2.0)), L2_tex(pos));
        W += w;
    }
    avg /= W;

    return avg;
}

vec4 hook() {
    // Calculate bounds
    float low  = floor(-0.5*maxtaps - offset)[1];
    float high = floor(+0.5*maxtaps - offset)[1];

    float W = 0.0;
    mat2x4 avg = mat2x4(0);
    vec2 pos = L2_pos;

    for (float k = 0.0; k < maxtaps; k++) {
        pos[1] = L2_pos[1] + L2_pt[1] * (k + low + 1.0);
        float rel = (k + low + 1.0) + offset[1];
        float w = Kernel(rel);

        avg += w * ScaleH(pos);
        W += w;
    }
    avg /= W;

    vec3 Sl = abs(avg[0].rgb - pow(M_texOff(0).rgb, vec3(2.0)));
    vec3 Sh = abs(avg[1].rgb - pow(M_texOff(0).rgb, vec3(2.0)));
    return vec4(mix(vec3(0.5), 1.0 / (1.0 + sqrt(Sh / Sl)), lessThan(vec3(5e-6), Sl)), 0.0);
}

//!HOOK POSTKERNEL
//!BIND HOOKED
//!BIND M
//!BIND R
//!WHEN NATIVE_CROPPED.h POSTKERNEL.h >
//!DESC SSimDownscaler final pass

#define locality    8.0

#define offset      vec2(0,0)

#define Kernel(x)   pow(1.0 / locality, abs(x))
#define taps        3.0
#define maxtaps     taps

#define Gamma(x)    ( pow(x, vec3(1.0/2.0)) )
#define GammaInv(x) ( pow(clamp(x, 0.0, 1.0), vec3(2.0)) )

mat3x3 ScaleH(vec2 pos) {
    // Calculate bounds
    float low  = floor(-0.5*maxtaps - offset)[0];
    float high = floor(+0.5*maxtaps - offset)[0];

    float W = 0.0;
    mat3x3 avg = mat3x3(0);

    for (float k = 0.0; k < maxtaps; k++) {
        pos[0] = POSTKERNEL_pos[0] + POSTKERNEL_pt[0] * (k + low + 1.0);
        float rel = (k + low + 1.0) + offset[0];
        float w = Kernel(rel);
        vec3 M = Gamma(M_tex(pos).rgb);
        vec3 R = R_tex(pos).rgb;
        R = 1.0 / R - 1.0;
        avg += w * mat3x3(R*M, M, R);
        W += w;
    }
    avg /= W;

    return avg;
}

vec4 hook() {
    // Calculate bounds
    float low  = floor(-0.5*maxtaps - offset)[1];
    float high = floor(+0.5*maxtaps - offset)[1];

    float W = 0.0;
    mat3x3 avg = mat3x3(0);
    vec2 pos = POSTKERNEL_pos;

    for (float k = 0.0; k < maxtaps; k++) {
        pos[1] = POSTKERNEL_pos[1] + POSTKERNEL_pt[1] * (k + low + 1.0);
        float rel = (k + low + 1.0) + offset[1];
        float w = Kernel(rel);

        avg += w * ScaleH(pos);
        W += w;
    }
    avg /= W;
    vec4 L = clamp(POSTKERNEL_texOff(0), 0.0, 1.0);
    return vec4(GammaInv(avg[1] + avg[2] * Gamma(L.rgb) - avg[0]), L.w);
}