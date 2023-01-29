// "film-like" tonemap, by Jim Hejl.
// https://twitter.com/jimhejl/status/633777619998130176

//!PARAM L_hdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 10000
1000.0

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (hejl2015)

vec3 curve(vec3 rgb, float w) {
    vec4 vh = vec4(rgb, w);
    vec4 va = (1.425 * vh) + 0.05;
    vec4 vf = ((vh * va + 0.004) / ((vh * (va + 0.55) + 0.0491))) - 0.0821;
    return vf.rgb / vf.www;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = curve(color.rgb, L_hdr / L_sdr);
    return color;
}
