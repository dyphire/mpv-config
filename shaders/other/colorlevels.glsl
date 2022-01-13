//!HOOK OUTPUT
//!BIND HOOKED
//!DESC signal range scaling
vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    const float REFBLACK = (  64. / 1023.);
    const float REFWHITE = ( 940. / 1023.);

    color.rgb *= REFWHITE - REFBLACK;
    color.rgb += REFBLACK;
    return color;
}