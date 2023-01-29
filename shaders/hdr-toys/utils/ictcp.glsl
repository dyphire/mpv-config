// https://professional.dolby.com/siteassets/pdfs/ictcp_dolbywhitepaper_v071.pdf

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Ictcp

const float pq_m1 = 0.1593017578125;
const float pq_m2 = 78.84375;
const float pq_c1 = 0.8359375;
const float pq_c2 = 18.8515625;
const float pq_c3 = 18.6875;

const float pq_C  = 10000.0;

float Y_to_ST2084(float C) {
    float L = C / pq_C;
    float Lm = pow(L, pq_m1);
    float N = (pq_c1 + pq_c2 * Lm) / (1.0 + pq_c3 * Lm);
    N = pow(N, pq_m2);
    return N;
}

float ST2084_to_Y(float N) {
    float Np = pow(N, 1.0 / pq_m2);
    float L = Np - pq_c1;
    if (L < 0.0 ) L = 0.0;
    L = L / (pq_c2 - pq_c3 * Np);
    L = pow(L, 1.0 / pq_m1);
    return L * pq_C;
}

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

vec3 XYZ_to_LMS(float X, float Y, float Z) {
    mat3 M = mat3(
         0.359, 0.696, -0.036,
        -0.192, 1.100,  0.075,
         0.007, 0.075,  0.843);
    return vec3(X, Y, Z) * M;
}

vec3 LMS_to_XYZ(float L, float M, float S) {
    mat3 MM = mat3(
         2.071, -1.327,  0.207,
         0.365,  0.681, -0.045,
        -0.049, -0.050,  1.188);
    return vec3(L, M, S) * MM;
}

vec3 LMS_to_ICtCp(float L, float M, float S) {
    vec3 VV = vec3(L, M, S);
    VV.r = Y_to_ST2084(VV.r);
    VV.g = Y_to_ST2084(VV.g);
    VV.b = Y_to_ST2084(VV.b);
    mat3 MM = mat3(
         2048,   2048,    0,
         6610, -13613, 7003,
        17933, -17390, -543) / 4096;
    return VV * MM;
}

vec3 ICtCp_to_LMS(float I, float Ct, float Cp) {
    vec3 VV = vec3(I, Ct, Cp);
    mat3 MM = mat3(
        1.0,  0.009,  0.111,
        1.0, -0.009, -0.111,
        1.0,  0.560, -0.321);
    VV *= MM;
    VV.r = ST2084_to_Y(VV.r);
    VV.g = ST2084_to_Y(VV.g);
    VV.b = ST2084_to_Y(VV.b);
    return VV;
}

vec3 RGB_to_Ictcp(vec3 color, float L_sdr) {
    color *= L_sdr;
    color = RGB_to_XYZ(color.r, color.g, color.b);
    color = XYZ_to_LMS(color.r, color.g, color.b);
    color = LMS_to_ICtCp(color.r, color.g, color.b);
    return color;
}

vec3 Ictcp_to_RGB(vec3 color, float L_sdr) {
    color = ICtCp_to_LMS(color.r, color.g, color.b);
    color = LMS_to_XYZ(color.r, color.g, color.b);
    color = XYZ_to_RGB(color.r, color.g, color.b);
    color /= L_sdr;
    return color;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = RGB_to_Ictcp(color.rgb, L_sdr);
    color.rgb = Ictcp_to_RGB(color.rgb, L_sdr);
    return color;
}
