
//!DESC color-alt_luma (Black & White)
//!HOOK LUMA
//!BIND HOOKED

vec4 hook()
{
    float color = LUMA_texOff(0).x;
    return vec4(1.0 - color);
}

