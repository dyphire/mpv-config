//!HOOK OUTPUT
//!BIND HOOKED
//!DESC perceptual quantizer to luminance

// Constants from SMPTE ST 2084-2014
const float pq_m1 = 0.1593017578125;    // ( 2610.0 / 4096.0 ) / 4.0;
const float pq_m2 = 78.84375;           // ( 2523.0 / 4096.0 ) * 128.0;
const float pq_c1 = 0.8359375;          // ( 3424.0 / 4096.0 ) or pq_c3 - pq_c2 + 1.0;
const float pq_c2 = 18.8515625;         // ( 2413.0 / 4096.0 ) * 32.0;
const float pq_c3 = 18.6875;            // ( 2392.0 / 4096.0 ) * 32.0;

const float pq_C  = 10000.0;

// Converts from the non-linear perceptually quantized space to cd/m^2
// Note that this is in float, and assumes normalization from 0 - 1
// (0 - pq_C for linear) and does not handle the integer coding in the Annex
// sections of SMPTE ST 2084-2014
float ST2084_to_Y(float N) {
    // Note that this does NOT handle any of the signal range
    // considerations from 2084 - this assumes full range (0 - 1)
    float Np = pow(N, 1.0 / pq_m2);
    float L = Np - pq_c1;
    if (L < 0.0 ) L = 0.0;
    L = L / (pq_c2 - pq_c3 * Np);
    L = pow(L, 1.0 / pq_m1);
    return L * pq_C; // returns cd/m^2
}

// ST.2084 EOTF (non-linear PQ to display light)
// converts from PQ code values to cd/m^2
vec3 ST2084_to_Y_f3(vec3 rgb) {
    return vec3(ST2084_to_Y(rgb.r), ST2084_to_Y(rgb.g), ST2084_to_Y(rgb.b));
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = ST2084_to_Y_f3(color.rgb);
    return color;
}
