
//!DESC Reduce static noise (luma)
//!HOOK LUMA
//!BIND HOOKED

// Change this to tune the strength of the noise
// Apparently this has to be float on some setups
#define STRENGTH 48.0

// PRNG taken from mpv's deband shader
float mod289(float x)  { return x - floor(x / 289.0) * 289.0; }
float permute(float x) { return mod289((34.0*x + 1.0) * x); }
float rand(float x)    { return fract(x / 41.0); }

vec4 hook()  {
    vec3 _m = vec3(HOOKED_pos, 1.0) + vec3(1.0);
    float h = permute(permute(permute(_m.x)+_m.y)+_m.z);
    vec4 noise;
    noise.x = rand(h);
    return HOOKED_tex(HOOKED_pos) + vec4(STRENGTH/8192.0) * (noise - 0.5);
}

