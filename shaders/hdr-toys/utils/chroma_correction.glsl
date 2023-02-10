// ITU-R BT.2446 Conversion Method C - 6.1.8
// Optional processing of chroma correction above HDR Reference White

// In SDR production, highlight parts are sometimes intentionally expressed as white. The processing
// described in this section is optionally used to shift chroma above HDR Reference White to achromatic
// when the converted SDR content requires a degree of consistency for SDR production content. This
// processing is applied as needed before the tone-mapping processing.

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

//!PARAM sigma
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.2

//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN sigma
//!DESC chroma correction

vec3 RGB_to_XYZ(float R, float G, float B) {
    mat3 M = mat3(
        0.6370, 0.1446, 0.1689,
        0.2627, 0.6780, 0.0593,
        0.0000, 0.0281, 1.0610);
    return vec3(R, G, B) * M;
}

vec3 XYZ_to_RGB(float X, float Y, float Z) {
    mat3 M = mat3(
         1.7167, -0.3557, -0.2534,
        -0.6667,  1.6165,  0.0158,
         0.0176, -0.0428,  0.9421);
    return vec3(X, Y, Z) * M;
}

vec3 XYZD65_to_XYZD50(float X, float Y, float Z) {
    mat3 M = mat3(
         1.0479298208405488,   0.022946793341019088, -0.05019222954313557,
         0.029627815688159344, 0.990434484573249,    -0.01707382502938514,
        -0.009243058152591178, 0.015055144896577895,  0.7518742899580008);
    return vec3(X, Y, Z) * M;
}

vec3 XYZD50_to_XYZD65(float X, float Y, float Z) {
    mat3 M = mat3(
         0.9554734527042182,   -0.023098536874261423, 0.0632593086610217,
        -0.028369706963208136,  1.0099954580058226,   0.021041398966943008,
         0.012314001688319899, -0.020507696433477912, 1.3303659366080753);
    return vec3(X, Y, Z) * M;
}

float delta = 6.0 / 29.0;
float deltac = delta * 2.0 / 3.0;

float f1(float x, float delta) {
    return x > pow(delta, 3.0) ?
        pow(x, 1.0 / 3.0) :
        deltac + x / (3.0 * pow(delta, 2.0));
}

float f2(float x, float delta) {
    return x > delta ?
        pow(x, 3.0) :
        (x - deltac) * (3.0 * pow(delta, 2.0));
}

vec3 XYZn = RGB_to_XYZ(L_sdr, L_sdr, L_sdr);

vec3 XYZ_to_Lab(float X, float Y, float Z) {
    X = f1(X / XYZn.x, delta);
    Y = f1(Y / XYZn.y, delta);
    Z = f1(Z / XYZn.z, delta);

    float L = 116.0 * Y - 16.0;
    float a = 500.0 * (X - Y);
    float b = 200.0 * (Y - Z);

    return vec3(L, a, b);
}

vec3 Lab_to_XYZ(float L, float a, float b) {
    float Y = (L + 16.0) / 116.0;
    float X = Y + a / 500.0;
    float Z = Y - b / 200.0;

    X = f2(X, delta) * XYZn.x;
    Y = f2(Y, delta) * XYZn.y;
    Z = f2(Z, delta) * XYZn.z;

    return vec3(X, Y, Z);
}

float pi = 3.141592653589793;
float epsilon = 0.02;

vec3 Lab_to_LCHab(float L, float a, float b) {
    float C = length(vec2(a, b));
    float H = (abs(a) < epsilon && abs(b) < epsilon) ?
        0.0 :
        atan(b, a) * 180.0 / pi;
    return vec3(L, C, H);
}

vec3 LCHab_to_Lab(float L, float C, float H) {
    C = max(C, 0.0);
    H *= pi / 180.0;
    float a = C * cos(H);
    float b = C * sin(H);
    return vec3(L, a, b);
}

float chroma_correction(float L, float Lref, float Lmax, float sigma) {
    float cor = 1.0;
    if (L > Lref)
        cor = max(1.0 - sigma * (L - Lref) / (Lmax - Lref), 0.0);

    return cor;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    vec3 L_ref;
    L_ref = RGB_to_XYZ(L_sdr, L_sdr, L_sdr);
    L_ref = XYZ_to_Lab(L_ref.r, L_ref.g, L_ref.b);

    vec3 L_max;
    L_max = RGB_to_XYZ(L_hdr, L_hdr, L_hdr);
    L_max = XYZ_to_Lab(L_max.r, L_max.g, L_max.b);

    color.rgb *= L_sdr;
    color.rgb = RGB_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZD65_to_XYZD50(color.r, color.g, color.b);
    color.rgb = XYZ_to_Lab(color.r, color.g, color.b);
    color.rgb = Lab_to_LCHab(color.r, color.g, color.b);
    color.g  *= chroma_correction(color.r, L_ref.r, L_max.r, sigma);
    color.rgb = LCHab_to_Lab(color.r, color.g, color.b);
    color.rgb = Lab_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZD50_to_XYZD65(color.r, color.g, color.b);
    color.rgb = XYZ_to_RGB(color.r, color.g, color.b);
    color.rgb /= L_sdr;
    return color;
}
