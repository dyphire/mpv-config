// https://github.com/GPUOpen-Effects/FidelityFX-LPM

//!HOOK MAIN
//!BIND HOOKED
//!DESC luma preserving mapper

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    return color;
}
