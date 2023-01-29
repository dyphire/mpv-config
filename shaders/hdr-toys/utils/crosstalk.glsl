// The crosstalk matrix is applied such that saturations of
// linear signals are reduced to achromatic to avoid hue
// changes caused by clipping of compressed highlight parts.

//!PARAM alpha
//!TYPE float
//!MINIMUM 0.00
//!MAXIMUM 0.33
0.04

//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN alpha
//!DESC crosstalk

vec3 crosstalk(vec3 x, float a) {
    float b = 1.0 - 2.0 * a;
    mat3  M = mat3(
        b, a, a,
        a, b, a,
        a, a, b);
    return x * M;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = crosstalk(color.rgb, alpha);
    return color;
}
