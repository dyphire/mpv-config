// https://github.com/jedypod/open-display-transform/blob/main/display-transforms/resolve-dctl/OpenDRT.dctl

//!HOOK MAIN
//!BIND HOOKED
//!DESC open display transform

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    return color;
}
