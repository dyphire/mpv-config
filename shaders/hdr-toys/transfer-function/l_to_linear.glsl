// Scale cd/m^2 to linear code value

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
//!DESC luminance to linear

vec3 Y_to_linCV(vec3 Y, float Ymax, float Ymin) {
    return (Y - Ymin) / (Ymax - Ymin);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = Y_to_linCV(color.rgb, L_sdr, Lb_sdr);
    return color;
}
