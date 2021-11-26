//!DESC scale antiringing
//!HOOK POSTKERNEL
//!BIND PREKERNEL
//!BIND HOOKED

//-- Configurable parameters --
const float radius = 0.5;
const float strength = 1.0;
//-- Configurable parameters end --

const float sq2i = 0.7071067811865475;

vec4 hook() {
    vec2 kpos = (input_size * PREKERNEL_pos + tex_offset) / PREKERNEL_size;

#define get(x,y) PREKERNEL_tex(kpos + PREKERNEL_pt * radius * vec2(x,y))

    vec4 c0 = get(-1,  0);
    vec4 c1 = get( 1,  0);
    vec4 c2 = get( 0, -1);
    vec4 c3 = get( 0,  1);

    vec4 c4 = get(-sq2i,  sq2i);
    vec4 c5 = get( sq2i,  sq2i);
    vec4 c6 = get(-sq2i, -sq2i);
    vec4 c7 = get( sq2i, -sq2i);

    vec4 lo = min( min(min(c0,c1), min(c2,c3)), min(min(c4,c5), min(c6,c7)) );
    vec4 hi = max( max(max(c0,c1), max(c2,c3)), max(max(c4,c5), max(c6,c7)) );

    vec4 color = HOOKED_texOff(0);
    return mix(color, clamp(color, lo, hi), strength);
}

//!DESC cscale antiringing
//!HOOK CHROMA_SCALED
//!BIND CHROMA
//!BIND HOOKED

// !!! WARNING: This introduces some error due to failing to account for chroma
// offsets, but I don't have a good solution for that.. If you don't like it,
// you can remove this pass

//-- Configurable parameters --
const float radius = 0.5;
const float strength = 1.0;
//-- Configurable parameters end --

const float sq2i = 0.7071067811865475;

vec4 hook() {

#define get(x,y) CHROMA_texOff(radius * vec2(x,y))

    vec4 c0 = get(-1,  0);
    vec4 c1 = get( 1,  0);
    vec4 c2 = get( 0, -1);
    vec4 c3 = get( 0,  1);

    vec4 c4 = get(-sq2i,  sq2i);
    vec4 c5 = get( sq2i,  sq2i);
    vec4 c6 = get(-sq2i, -sq2i);
    vec4 c7 = get( sq2i, -sq2i);

    vec4 lo = min( min(min(c0,c1), min(c2,c3)), min(min(c4,c5), min(c6,c7)) );
    vec4 hi = max( max(max(c0,c1), max(c2,c3)), max(max(c4,c5), max(c6,c7)) );

    vec4 color = HOOKED_texOff(0);
    return mix(color, clamp(color, lo, hi), strength);
}
