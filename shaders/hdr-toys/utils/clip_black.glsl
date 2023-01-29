//!HOOK OUTPUT
//!BIND HOOKED
//!DESC clip code value (black)

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = max(color.rgb, 0.0);
    return color;
}
