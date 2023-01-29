// ITU-R BT.2446 Conversion Method A
// https://www.itu.int/pub/R-REP-BT.2446

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
//!DESC tone mapping (bt.2446a)

// https://gist.github.com/yohhoy/dafa5a47dade85d8b40625261af3776a
const float a = 0.2627;
const float b = 0.6780;
const float c = 0.0593; // a + b + c = 1
const float d = 1.8814; // 2 * (a + b)
const float e = 1.4747; // 2 * (1 - a)

vec3 RGB_to_YCbCr(float R, float G, float B) {
    const float Y  = a * R + b * G + c * B;
    const float Cb = (B - Y) / d;
    const float Cr = (R - Y) / e;
    return vec3(Y, Cb, Cr);
}

vec3 YCbCr_to_RGB(float Y, float Cb, float Cr) {
    const float R = Y + e * Cr;
    const float G = Y - (a * e / b) * Cr - (c * d / b) * Cb;
    const float B = Y + d * Cb;
    return vec3(R, G, B);
}

float f(float Y) {
    Y = pow(Y, 1.0 / 2.4);

    const float pHDR = 1.0 + 32.0 * pow(L_hdr / 10000.0, 1.0 / 2.4);
    const float pSDR = 1.0 + 32.0 * pow(L_sdr / 10000.0, 1.0 / 2.4);

    const float Yp = log(1.0 + (pHDR - 1.0) * Y) / log(pHDR);

    float Yc;
    if      (Yp <= 0.7399)  Yc = Yp * 1.0770;
    else if (Yp <  0.9909)  Yc = Yp * (-1.1510 * Yp + 2.7811) - 0.6302;
    else                    Yc = Yp * 0.5000 + 0.5000;

    const float Ysdr = (pow(pSDR, Yc) - 1.0) / (pSDR - 1.0);

    Y = pow(Ysdr, 2.4);

    return Y;
}

vec3 tone_mapping(vec3 YCbCr) {
    const float W = L_hdr / L_sdr;
    YCbCr /= W;

    float Y  = YCbCr.r;
    float Cb = YCbCr.g;
    float Cr = YCbCr.b;

    const float Ysdr = f(Y);

    const float Yr = Ysdr / (1.1 * Y);
    Cb *= Yr;
    Cr *= Yr;
    Y = Ysdr - max(0.1 * Cr, 0.0);

    return vec3(Y, Cb, Cr);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = RGB_to_YCbCr(color.r, color.g, color.b);
    color.rgb = tone_mapping(color.rgb);
    color.rgb = YCbCr_to_RGB(color.r, color.g, color.b);
    return color;
}
