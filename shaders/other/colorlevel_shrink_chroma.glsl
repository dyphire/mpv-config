
//!DESC color levels - (CHROMA)
//!HOOK CHROMA
//!BIND HOOKED

const float min = 16.0 / 255.0;
const float max = (240.0 - 16.0) / 255.0;

vec4 hook()
{
    return (HOOKED_texOff(0) * max) + min;
}

