
//!DESC color levels +
//!HOOK MAINPRESUB
//!BIND HOOKED

const float min = 16.0 / 255.0;
const float max = 255.0 / (235.0 - 16.0);

vec4 hook()
{
    return (HOOKED_texOff(0) - min) * max;
}

