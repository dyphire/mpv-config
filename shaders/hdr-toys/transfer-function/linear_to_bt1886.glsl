//!HOOK OUTPUT
//!BIND HOOKED
//!DESC linear to bt.1886

const float DISPGAMMA = 2.4;
const float L_W = 1.0;
const float L_B = 0.0;
float bt1886_r(float L, float gamma, float Lw, float Lb) {
    // The reference EOTF specified in Rec. ITU-R BT.1886
    // L = a(max[(V+b),0])^g
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma));
    float V = pow(max(L / a, 0.0), 1.0 / gamma) - b;
    return V;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    // Encode linear code values with transfer function
    color.rgb = vec3(
        bt1886_r(color.r, DISPGAMMA, L_W, L_B),
        bt1886_r(color.g, DISPGAMMA, L_W, L_B),
        bt1886_r(color.b, DISPGAMMA, L_W, L_B)
    );
    return color;
}
