// Scale linear code value to cd/m^2

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!PARAM Lb_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
0.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC linear to luminance

vec3 linCV_to_Y(vec3 linCV, float Ymax, float Ymin) {
    return linCV * (Ymax - Ymin) + Ymin;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = linCV_to_Y(color.rgb, L_sdr, Lb_sdr);
    return color;
}
