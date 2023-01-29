// Filmic curve by Hajime Uchimura. Also known as the "Gran Turismo curve".
// https://www.slideshare.net/nikuque/hdr-theory-and-practicce-jp

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (uchimura)

const float P = 1.00;   // max display brightness
const float a = 1.00;   // contrast
const float m = 0.22;   // linear section start
const float l = 0.40;   // linear section length
const float c = 1.33;   // black
const float b = 0.00;   // pedestal

float f(float x, float P, float a, float m, float l, float c, float b) {
    float l0 = ((P - m) * l) / a;
    float L0 = m - m / a;
    float L1 = m + (1.0 - m) / a;
    float S0 = m + l0;
    float S1 = m + a * l0;
    float C2 = (a * P) / (P - S1);
    float CP = -C2 / P;

    float w0 = 1.0 - smoothstep(0.0, m, x);
    float w2 = step(m + l0, x);
    float w1 = 1.0 - w0 - w2;

    float T = m * pow(x / m, c) + b;
    float S = P - (P - S1) * exp(CP * (x - S0));
    float L = m + a * (x - m);

    return T * w0 + L * w1 + S * w2;
}

float curve(float x) {
    return f(x, P, a, m, l, c, b);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
