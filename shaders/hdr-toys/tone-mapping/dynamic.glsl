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

//!PARAM CONTRAST_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000000
1000.0

//!BUFFER FRAME_DATA
//!VAR uint L_min
//!VAR uint L_max
//!VAR uint L_sum
//!VAR float L_avg
//!STORAGE

//!HOOK OUTPUT
//!BIND FRAME_DATA
//!SAVE EMPTY
//!WIDTH 1
//!HEIGHT 1
//!COMPUTE 1 1
//!DESC luminance analysis (initial)

void hook() {
    L_min = 10000;
    L_max = 0;
    L_sum = 0;
    L_avg = 0.0;
}

//!HOOK OUTPUT
//!BIND HOOKED
//!SAVE BLURRED
//!DESC luminance analysis (gaussian blur horizonal)
// Fast pixel shader gaussian blur by butterw pass1

#define Offsets vec3(0.0, 1.3846153846, 3.2307692308)
#define K		vec3(0.2270270270, 0.3162162162, 0.0702702703)

vec4 hook(){
	vec4 c0 = HOOKED_tex(HOOKED_pos) * K[0];
	uint i = 1;
    c0 += HOOKED_tex(HOOKED_pos + HOOKED_pt * vec2(Offsets[i], 0)) * K[i];
    c0 += HOOKED_tex(HOOKED_pos - HOOKED_pt * vec2(Offsets[i], 0)) * K[i];
	i = 2;
    c0 += HOOKED_tex(HOOKED_pos + HOOKED_pt * vec2(Offsets[i], 0)) * K[i];
    c0 += HOOKED_tex(HOOKED_pos - HOOKED_pt * vec2(Offsets[i], 0)) * K[i];
	return c0;
}

//!HOOK OUTPUT
//!BIND BLURRED
//!SAVE BLURRED
//!DESC luminance analysis (gaussian blur vertical)
// Fast pixel shader gaussian blur by butterw pass2

#define Offsets vec3(0.0, 1.3846153846, 3.2307692308)
#define K		vec3(0.2270270270, 0.3162162162, 0.0702702703)

vec4 hook(){
	vec4 c0 = BLURRED_tex(BLURRED_pos) * K[0];
	uint i = 1;
    c0 += BLURRED_tex(BLURRED_pos + BLURRED_pt * vec2(0, Offsets[i])) * K[i];
    c0 += BLURRED_tex(BLURRED_pos - BLURRED_pt * vec2(0, Offsets[i])) * K[i];
	i = 2;
    c0 += BLURRED_tex(BLURRED_pos + BLURRED_pt * vec2(Offsets[i], 0)) * K[i];
    c0 += BLURRED_tex(BLURRED_pos - BLURRED_pt * vec2(Offsets[i], 0)) * K[i];
	return c0;
}

//!HOOK OUTPUT
//!BIND BLURRED
//!BIND FRAME_DATA
//!SAVE EMPTY
//!COMPUTE 32 32
//!DESC luminance analysis (min, max, sum)

void hook() {
    vec4 texelValue = texelFetch(BLURRED_raw, ivec2(gl_GlobalInvocationID.xy), 0);
    float L = L_sdr * dot(texelValue.rgb, vec3(0.2627, 0.6780, 0.0593));

    atomicMin(L_min, uint(L));
    atomicMax(L_max, uint(L));
    atomicAdd(L_sum, uint(L));
}

//!HOOK OUTPUT
//!BIND FRAME_DATA
//!SAVE EMPTY
//!WIDTH 1
//!HEIGHT 1
//!COMPUTE 1 1
//!DESC luminance analysis (average)

void hook() {
    const float size1 = gl_WorkGroupSize.x * gl_WorkGroupSize.y;
    const float size2 = gl_NumWorkGroups.x * gl_NumWorkGroups.y;
    const float size3 = size1 * size2;
    L_avg = L_sum / size3;
}

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND FRAME_DATA
//!DESC tone mapping (hable2, dynamic)

float toeLength = 0.0;
float toeStrength = 0.5;
float shoulderAngle = 1.0;
float shoulderLength = 0.5;
float shoulderStrength = 0.0;

float x0 = 0.0;
float y0 = 0.0;
float x1 = 0.0;
float y1 = 0.0;
float W  = 0.0;
float overshootX = 0.0;
float overshootY = 0.0;

// Convert from "user" to "direct" parameters
void calc_direct_params_from_user() {
    // constraints
    toeLength = clamp(toeLength, 0.0, 1.0);
    toeStrength = clamp(toeStrength, 0.0, 1.0);
    shoulderAngle = clamp(shoulderAngle, 0.0, 1.0);
    shoulderLength = clamp(shoulderLength, 1e-5, 0.999 - 0.5 * toeLength);
    shoulderStrength = clamp(shoulderStrength, 0.0, 10.0);

    // apply base params
    x0 = toeLength * 0.5; // toe goes from 0 to 0.5
    y0 = (1.0 - toeStrength) * x0; // lerp from 0 to x0

    float remainingY = 1.0 - y0;

    float initialW = x0 + remainingY;

    float y1_offset = (1.0 - shoulderLength) * remainingY;
    x1 = x0 + y1_offset;
    y1 = y0 + y1_offset;

    // filmic shoulder strength is in F stops
    float extraW = exp2(shoulderStrength) - 1.0;

    W = initialW + extraW;

    overshootX = (W * 2.0) * shoulderAngle * shoulderStrength;
    overshootY = 0.5 * shoulderAngle * shoulderStrength;
}

float curve_segment_eval(float x, float lnA, float B, float offsetX, float offsetY, float scaleX, float scaleY) {
    float x0 = (x - offsetX) * scaleX;
    float y0 = 0.0;

    // log(0) is undefined but our function should evaluate to 0. There are better ways to handle this,
    // but it's doing it the slow way here for clarity.
    if (x0 > 0.0) {
        y0 = exp(lnA + B * log(x0));
    }

    return y0 * scaleY + offsetY;
}

float curve_segment_eval_inv(float y, float lnA, float B, float offsetX, float offsetY, float scaleX, float scaleY) {
    float y0 = (y - offsetY) / scaleY;
    float x0 = 0.0;

    // watch out for log(0) again
    if (y0 > 0.0) {
        x0 = exp((log(y0) - lnA) / B);
    }
    float x = x0 / scaleX + offsetX;

    return x;
}

// find a function of the form:
//   f(x) = e^(lnA + Bln(x))
// where
//   f(0)   = 0; not really a constraint
//   f(x0)  = y0
//   f'(x0) = m
vec2 solve_AB(float x0, float y0, float m) {
    float B   = (m * x0) / y0;
    float lnA = log(y0) - B * log(x0);
    return vec2(lnA, B);
}

// convert to y=mx+b
vec2 as_slope_intercept(float x0, float x1, float y0, float y1) {
    float dy = (y1 - y0);
    float dx = (x1 - x0);
    float m  = dx == 0.0 ? 1.0 : dy / dx;
    float b  = y0 - x0 * m;
    return vec2(m, b);
}

// f(x) = (mx+b)^g
// f'(x) = gm(mx+b)^(g-1)
float eval_derivative_linear_gamma(float m, float b, float g, float x) {
    return g * m * pow(m * x + b, g - 1.0);
}

// CreateCurve
float curve(float x) {
    calc_direct_params_from_user();

    // normalize params to 1.0 range
    float invW = 1.0 / W;
    x0 /= W;
    x1 /= W;
    overshootX /= W;
    W = 1.0;

    // Precompute information for all three segments (mid, toe, shoulder)
    const vec2  tmp = as_slope_intercept(x0, x1, y0, y1);
    const float m = tmp.x,
                b = tmp.y,
                g = 1.0; // gamma

    // base function of linear section plus gamma is
    // y = (mx+b)^g

    // which we can rewrite as
    // y = exp(g*ln(m) + g*ln(x+b/m))

    // and our evaluation function is (skipping the if parts):
    /*
        float x0 = (x - m_offsetX)*m_scaleX;
        y0 = expf(m_lnA + m_B*logf(x0));
        return y0*m_scaleY + m_offsetY;
    */

    float   midOffsetX  = -(b / m),
            midOffsetY  = 0.0,
            midScaleX   = 1.0,
            midScaleY   = 1.0,
            midLnA      = g * log(m),
            midB        = g;

    const float toeM = eval_derivative_linear_gamma(m, b, g, x0);
    const float shoulderM = eval_derivative_linear_gamma(m, b, g, x1);

    y0 = max(pow(y0, g), 1e-6);
    y1 = max(pow(y1, g), 1e-6);
    overshootY = pow(1.0 + overshootY, g) - 1.0;

    const vec2  toeAB   = solve_AB(x0, y0, m);
    float   toeOffsetX  = 0.0,
            toeOffsetY  = 0.0,
            toeScaleX   = 1.0,
            toeScaleY   = 1.0,
            toeLnA      = toeAB.x,
            toeB        = toeAB.y;

    const float shoulderX0  = (1.0 + overshootX) - x1;
    const float shoulderY0  = (1.0 + overshootY) - y1;

    const vec2  shoulderAB  = solve_AB(shoulderX0, shoulderY0, m);
    float   shoulderOffsetX = 1.0 + overshootX,
            shoulderOffsetY = 1.0 + overshootY,
            shoulderScaleX  = -1.0,
            shoulderScaleY  = -1.0,
            shoulderLnA     = shoulderAB.x,
            shoulderB       = shoulderAB.y;

    // Normalize (correct for overshooting)
    const float scale = curve_segment_eval(1.0,
        shoulderLnA, shoulderB,
        shoulderOffsetX, shoulderOffsetY,
        shoulderScaleX, shoulderScaleY);
    const float invScale = 1.0 / scale;

    toeOffsetY *= invScale;
    toeScaleY  *= invScale;

    midOffsetY *= invScale;
    midScaleY  *= invScale;

    shoulderOffsetY *= invScale;
    shoulderScaleY  *= invScale;

    // FullCurve::Eval
    float normX = x * invW;
    if (normX < x0) {
        return curve_segment_eval(normX,
            toeLnA, toeB,
            toeOffsetX, toeOffsetY,
            toeScaleX, toeScaleY);
    } else if (normX < x1) {
        return curve_segment_eval(normX,
            midLnA, midB,
            midOffsetX, midOffsetY,
            midScaleX, midScaleY);
    } else {
        return curve_segment_eval(normX,
            shoulderLnA, shoulderB,
            shoulderOffsetX, shoulderOffsetY,
            shoulderScaleX, shoulderScaleY);
    }
}

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

vec3 XYZ_to_Cone(float X, float Y, float Z) {
    mat3 M = mat3(
         0.41478972, 0.579999,  0.0146480,
        -0.2015100,  1.120649,  0.0531008,
        -0.0166008,  0.264800,  0.6684799);
    return vec3(X, Y, Z) * M;
}

vec3 Cone_to_XYZ(float X, float Y, float Z) {
    mat3 M = mat3(
         1.9242264357876067,  -1.0047923125953657,  0.037651404030618,
         0.35031676209499907,  0.7264811939316552, -0.06538442294808501,
        -0.09098281098284752, -0.3127282905230739,  1.5227665613052603);
    return vec3(X, Y, Z) * M;
}

vec3 Cone_to_Iab(float L, float M, float S) {
    mat3 MM = mat3(
        0.5,       0.5,       0.0,
        3.524000, -4.066708,  0.542708,
        0.199076,  1.096799, -1.295875);
    return vec3(L, M, S) * MM;
}

vec3 Iab_to_Cone(float I, float a, float b) {
    mat3 M = mat3(
        1.0,                 0.1386050432715393,   0.05804731615611886,
        0.9999999999999999, -0.1386050432715393,  -0.05804731615611886,
        0.9999999999999998, -0.09601924202631895, -0.8118918960560388);
    return vec3(I, a, b) * M;
}

const float b = 1.15;
const float g = 0.66;

const float d = -0.56;
const float d0 = 1.6295499532821566e-11;

vec3 RGB_to_Jzazbz(vec3 color, float L_sdr) {
    color *= L_sdr;

    color = RGB_to_XYZ(color.r, color.g, color.b);

    float Xm = (b * color.x) - ((b - 1.0) * color.z);
    float Ym = (g * color.y) - ((g - 1.0) * color.x);

    color = XYZ_to_Cone(Xm, Ym, color.z);

    color.r = Y_to_ST2084(color.r);
    color.g = Y_to_ST2084(color.g);
    color.b = Y_to_ST2084(color.b);

    color = Cone_to_Iab(color.r, color.g, color.b);

    color.r = ((1.0 + d) * color.r) / (1.0 + (d * color.r)) - d0;

    return color;
}

vec3 Jzazbz_to_RGB(vec3 color, float L_sdr) {
    color.r = (color.r + d0) / (1.0 + d - d * (color.r + d0));

    color = Iab_to_Cone(color.r, color.g, color.b);

    color.r = ST2084_to_Y(color.r);
    color.g = ST2084_to_Y(color.g);
    color.b = ST2084_to_Y(color.b);

    color = Cone_to_XYZ(color.r, color.g, color.b);

    float Xa = (color.x + ((b - 1.0) * color.z)) / b;
    float Ya = (color.y + ((g - 1.0) * Xa)) / g;

    color = XYZ_to_RGB(Xa, Ya, color.z);

    color /= L_sdr;

    return color;
}

vec3 Jzazbz_to_JzCzhz(vec3 color) {
    float az = color.g;
    float bz = color.b;

    color.g = sqrt(az * az + bz * bz);
    color.b = atan(bz, az);

    return color;
}

vec3 JzCzhz_to_Jzazbz(vec3 color) {
    float Cz = color.g;
    float hz = color.b;

    color.g = Cz * cos(hz);
    color.b = Cz * sin(hz);

    return color;
}

vec3 tone_mapping_hybrid(vec3 color) {
    vec3 src;
    vec3 dst;
    vec3 rgb;
    vec3 lum;
    vec3 sat;

    src = color;
    src = RGB_to_Jzazbz(src, L_sdr);
    src = Jzazbz_to_JzCzhz(src);

    rgb = vec3(curve(color.r), curve(color.g), curve(color.b));
    rgb = RGB_to_Jzazbz(rgb, L_sdr);
    rgb = Jzazbz_to_JzCzhz(rgb);

    float L = dot(color, vec3(0.2627, 0.6780, 0.0593));
    lum = color * curve(L) / L;
    lum = RGB_to_Jzazbz(lum, L_sdr);
    lum = Jzazbz_to_JzCzhz(lum);

    float norm = max(max(color.r, color.g), color.b);
    sat = color * curve(norm) / norm;
    sat = RGB_to_Jzazbz(sat, L_sdr);
    sat = Jzazbz_to_JzCzhz(sat);

    dst = vec3(mix(lum.r, sat.r, src.r), mix(lum.g, rgb.g, src.r), src.b);
    dst = JzCzhz_to_Jzazbz(dst);
    dst = Jzazbz_to_RGB(dst, L_sdr);

    return dst;
}

void calc_params() {
    float L_min_ev = log2(L_min / L_sdr);
    float L_max_ev = log2(L_max / L_sdr);
    float L_avg_ev = log2(L_avg / L_sdr);

    shoulderLength = L_avg_ev / L_max_ev;
    shoulderStrength = L_max_ev;
    toeLength = L_max_ev / CONTRAST_sdr;
    toeStrength = 0.5 + 0.5 * (L_min / toeLength);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    calc_params();
    color.rgb = tone_mapping_hybrid(color.rgb);
    return color;
}
