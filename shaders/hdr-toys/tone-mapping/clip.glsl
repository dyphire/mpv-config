// Crop code values that are out of the SDR range

//!PARAM CONTRAST_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000000
1000.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (clip)

const float DISPGAMMA = 2.4;
const float L_W = 1.0;
const float L_B = 0.0;

float bt1886_r(float L, float gamma, float Lw, float Lb) {
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma));
    float V = pow(max(L / a, 0.0), 1.0 / gamma) - b;
    return V;
}

float bt1886_f(float V, float gamma, float Lw, float Lb) {
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma));
    float L = a * pow(max(V + b, 0.0), gamma);
    return L;
}

vec3 tone_mapping_clip(vec3 color) {
    color.rgb = vec3(
        bt1886_r(color.r, DISPGAMMA, L_W, L_W / CONTRAST_sdr),
        bt1886_r(color.g, DISPGAMMA, L_W, L_W / CONTRAST_sdr),
        bt1886_r(color.b, DISPGAMMA, L_W, L_W / CONTRAST_sdr)
    );

    color.rgb = vec3(
        bt1886_f(color.r, DISPGAMMA, L_W, L_B),
        bt1886_f(color.g, DISPGAMMA, L_W, L_B),
        bt1886_f(color.b, DISPGAMMA, L_W, L_B)
    );
    return color;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = tone_mapping_clip(color.rgb);
    return color;
}
