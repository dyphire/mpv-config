//!DESC MinBlur-USM
//!HOOK LUMA
//!BIND HOOKED

#define CMPSWAP(i, j) if (a[i] > a[j]) {\
    float t = a[i];\
    a[i] = a[j];\
    a[j] = t;\
}

float remove_grain_20() {
    float r = 0.;
    r += HOOKED_texOff(vec2(-1, -1)).x;
    r += HOOKED_texOff(vec2(+0, -1)).x;
    r += HOOKED_texOff(vec2(+1, -1)).x;
    r += HOOKED_texOff(vec2(-1, +0)).x;
    r += HOOKED_texOff(vec2(+0, +0)).x;
    r += HOOKED_texOff(vec2(+1, +0)).x;
    r += HOOKED_texOff(vec2(-1, +1)).x;
    r += HOOKED_texOff(vec2(+0, +1)).x;
    r += HOOKED_texOff(vec2(+1, +1)).x;
    r /= 9;
    return r;
}

float remove_grain_11() {
    float r = 0.;
    r += HOOKED_texOff(vec2(-1, -1)).x * 1.;
    r += HOOKED_texOff(vec2(+0, -1)).x * 2.;
    r += HOOKED_texOff(vec2(+1, -1)).x * 1.;
    r += HOOKED_texOff(vec2(-1, +0)).x * 2.;
    r += HOOKED_texOff(vec2(+0, +0)).x * 4.;
    r += HOOKED_texOff(vec2(+1, +0)).x * 2.;
    r += HOOKED_texOff(vec2(-1, +1)).x * 1.;
    r += HOOKED_texOff(vec2(+0, +1)).x * 2.;
    r += HOOKED_texOff(vec2(+1, +1)).x * 1.;
    r /= 16;
    return r;
}

float remove_grain_4() {
    float a[9];
    a[0] = HOOKED_texOff(vec2(-1, -1)).x;
    a[1] = HOOKED_texOff(vec2(+0, -1)).x;
    a[2] = HOOKED_texOff(vec2(+1, -1)).x;
    a[3] = HOOKED_texOff(vec2(-1, +0)).x;
    a[4] = HOOKED_texOff(vec2(+0, +0)).x;
    a[5] = HOOKED_texOff(vec2(+1, +0)).x;
    a[6] = HOOKED_texOff(vec2(-1, +1)).x;
    a[7] = HOOKED_texOff(vec2(+0, +1)).x;
    a[8] = HOOKED_texOff(vec2(+1, +1)).x;
    CMPSWAP(0, 1); CMPSWAP(2, 3); CMPSWAP(4, 5); CMPSWAP(7, 8);
    CMPSWAP(0, 2); CMPSWAP(1, 3); CMPSWAP(6, 8);
    CMPSWAP(1, 2); CMPSWAP(6, 7); CMPSWAP(5, 8);
    CMPSWAP(4, 7); CMPSWAP(3, 8);
    CMPSWAP(4, 6); CMPSWAP(5, 7);
    CMPSWAP(5, 6); CMPSWAP(2, 7);
    CMPSWAP(0, 5); CMPSWAP(1, 6); CMPSWAP(3, 7);
    CMPSWAP(0, 4); CMPSWAP(1, 5); CMPSWAP(3, 6);
    CMPSWAP(1, 4); CMPSWAP(2, 5);
    CMPSWAP(2, 4); CMPSWAP(3, 5);
    CMPSWAP(3, 4);
    return a[4];
}

vec4 hook() {
    float src = HOOKED_tex(HOOKED_pos).x;
    float rg11 = remove_grain_11();
    float rg4 = remove_grain_4();
    float min_blur = (src - rg11) * (src - rg4) < 0 ? src : abs(src - rg11) < abs(src - rg4) ? rg11 : rg4;
    return vec4(src + src - min_blur, 0, 0, 0);
}
