// default to SMPTE "legal" signal range

//!PARAM DEPTH
//!TYPE int
10

//!PARAM BLACK
//!TYPE float
0.0625

//!PARAM WHITE
//!TYPE float
0.91796875

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC signal range scaling

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float D = pow(2, DEPTH);
    const float B = BLACK * D / (D - 1);
    const float W = WHITE * D / (D - 1);

    color.rgb *= W - B;
    color.rgb += B;
    return color;
}
