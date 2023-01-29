//!HOOK OUTPUT
//!BIND HOOKED
//!DESC luminance to perceptual quantizer

// Constants from SMPTE ST 2084-2014
const float pq_m1 = 0.1593017578125;    // ( 2610.0 / 4096.0 ) / 4.0;
const float pq_m2 = 78.84375;           // ( 2523.0 / 4096.0 ) * 128.0;
const float pq_c1 = 0.8359375;          // ( 3424.0 / 4096.0 ) or pq_c3 - pq_c2 + 1.0;
const float pq_c2 = 18.8515625;         // ( 2413.0 / 4096.0 ) * 32.0;
const float pq_c3 = 18.6875;            // ( 2392.0 / 4096.0 ) * 32.0;

const float pq_C  = 10000.0;

// Converts from cd/m^2 to the non-linear perceptually quantized space
// Note that this is in float, and assumes normalization from 0 - 1
// (0 - pq_C for linear) and does not handle the integer coding in the Annex
// sections of SMPTE ST 2084-2014
float Y_to_ST2084(float C) {
    // Note that this does NOT handle any of the signal range
    // considerations from 2084 - this returns full range (0 - 1)
    float L = C / pq_C;
    float Lm = pow(L, pq_m1);
    float N = (pq_c1 + pq_c2 * Lm) / (1.0 + pq_c3 * Lm);
    N = pow(N, pq_m2);
    return N;
}

// ST.2084 Inverse EOTF (display light to non-linear PQ)
// converts from cd/m^2 to PQ code values
vec3 Y_to_ST2084_f3(vec3 L) {
    return vec3(Y_to_ST2084(L.r), Y_to_ST2084(L.g), Y_to_ST2084(L.b));
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = Y_to_ST2084_f3(color.rgb);
    return color;
}
