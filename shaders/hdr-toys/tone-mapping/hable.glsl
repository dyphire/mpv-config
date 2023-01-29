// Filmic curve by John Hable, Also known as the "Uncharted 2 curve".
// http://filmicworlds.com/blog/filmic-tonemapping-operators/

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
//!DESC tone mapping (hable)

const float A = 0.15;   // Shoulder Strength
const float B = 0.50;   // Linear Strength
const float C = 0.10;   // Linear Angle
const float D = 0.20;   // Toe Strength
const float E = 0.02;   // Toe Numerator
const float F = 0.30;   // Toe Denominator

float f(float x) {
    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

float curve(float x) {
    const float W = L_hdr / L_sdr;
    return f(x) / f(W);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
