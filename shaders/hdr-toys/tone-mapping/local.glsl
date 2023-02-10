//!HOOK OUTPUT
//!BIND HOOKED
//!COMPUTE 32 32
//!DESC tone mapping (local)

shared float L_max;

void metering() {
    ivec2 base = ivec2(gl_WorkGroupID) * ivec2(gl_WorkGroupSize);
    for (uint x = 0; x < gl_WorkGroupSize.x; x++) {
        for (uint y = 0; y < gl_WorkGroupSize.y; y++) {
            vec4 texelValue = texelFetch(HOOKED_raw, base + ivec2(x,y), 0);
            float L = dot(texelValue.rgb, vec3(0.2627, 0.6780, 0.0593));
            L_max = max(L_max, L);
        }
    }
}

float curve(float x, float w) {
    const float simple = x / (1.0 + x);
    const float extended = simple * (1.0 + x / (w * w));
    return extended;
}

vec4 color = HOOKED_tex(HOOKED_pos);
void hook() {
    L_max = 1.0;

    metering();

    barrier();

    float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L, L_max) / L;

    imageStore(out_image, ivec2(gl_GlobalInvocationID), color);
}
