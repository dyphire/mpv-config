// https://github.com/ampas/aces-dev
// https://github.com/baldavenger/ACES_DCTL
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.postprocessing/PostProcessing/Shaders/ACES.hlsl

//!HOOK MAIN
//!BIND HOOKED
//!DESC aces transform

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    return color;
}
