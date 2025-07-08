// https://www.itu.int/rec/R-REC-BT.1886

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC transfer function (bt.1886, inverse)

float bt1886_eotf(float V, float gamma, float Lw, float Lb) {
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma));
    float L = a * pow(max(V + b, 0.0), gamma);
    return L;
}

vec3 bt1886_eotf(vec3 color, float gamma, float Lw, float Lb) {
    return vec3(
        bt1886_eotf(color.r, gamma, Lw, Lb),
        bt1886_eotf(color.g, gamma, Lw, Lb),
        bt1886_eotf(color.b, gamma, Lw, Lb)
    );
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);

    color.rgb = bt1886_eotf(color.rgb, 2.4, 1.0, 0.001);

    return color;
}

//!TEXTURE TONE
//!SIZE 1024 1
//!FORMAT rgba16f
//!FILTER LINEAR
//!BORDER REPEAT
//!STORAGE

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND TONE
//!SAVE GARB
//!WIDTH 4096
//!HEIGHT 1
//!DESC bake lut

float bezier(float t, float a, float b, float c) {
    a = mix(a, b, t);
    b = mix(b, c, t);
    a = mix(a, b, t);
    return a;
}

vec2 bezier(float t, vec2 a, vec2 b, vec2 c) {
    return vec2(
        bezier(t, a.x, b.x, c.x),
        bezier(t, a.y, b.y, c.y)
    );
}

vec4 hook() {
    vec2 b = bezier(HOOKED_pos.x, vec2(0.0, 0.0), vec2(0.5, 0.8), vec2(1.0, 1.0));
    imageStore(TONE, ivec2(int(1023.0 * b.x), 0), vec4(vec3(b.y), 1.0));

    vec4 color = HOOKED_texOff(0);
    return color;
}

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND TONE
//!DESC tone-mapping

float cbrt(float x) {
    return sign(x) * pow(abs(x), 1.0 / 3.0);
}

vec3 RGB_to_XYZ(vec3 RGB) {
    mat3 M = mat3(
        0.41239079926595934, 0.357584339383878,   0.1804807884018343,
        0.21263900587151027, 0.715168678767756,   0.07219231536073371,
        0.01933081871559182, 0.11919477979462598, 0.9505321522496607);
    return RGB * M;
}

vec3 XYZ_to_RGB(vec3 XYZ) {
    mat3 M = mat3(
         3.2409699419045226,  -1.537383177570094,   -0.4986107602930034,
        -0.9692436362808796,   1.8759675015077202,   0.04155505740717559,
         0.05563007969699366, -0.20397695888897652,  1.0569715142428786);
    return XYZ * M;
}

vec3 XYZ_to_LMS(vec3 XYZ) {
    mat3 M = mat3(
        0.8190224379967030, 0.3619062600528904, -0.1288737815209879,
        0.0329836539323885, 0.9292868615863434,  0.0361446663506424,
        0.0481771893596242, 0.2642395317527308,  0.6335478284694309);
    return XYZ * M;
}

vec3 LMS_to_XYZ(vec3 LMS) {
    mat3 M = mat3(
         1.2268798758459243, -0.5578149944602171,  0.2813910456659647,
        -0.0405757452148008,  1.1122868032803170, -0.0717110580655164,
        -0.0763729366746601, -0.4214933324022432,  1.5869240198367816);
    return LMS * M;
}

vec3 LMS_to_Lab(vec3 LMS) {
    mat3 M = mat3(
        0.2104542683093140,  0.7936177747023054, -0.0040720430116193,
        1.9779985324311684, -2.4285922420485799,  0.4505937096174110,
        0.0259040424655478,  0.7827717124575296, -0.8086757549230774);

    LMS = vec3(
        cbrt(LMS.x),
        cbrt(LMS.y),
        cbrt(LMS.z)
    );

    return LMS * M;
}

vec3 Lab_to_LMS(vec3 Lab) {
    mat3 M = mat3(
        1.0000000000000000,  0.3963377773761749,  0.2158037573099136,
        1.0000000000000000, -0.1055613458156586, -0.0638541728258133,
        1.0000000000000000, -0.0894841775298119, -1.2914855480194092);

    Lab = Lab * M;

    return vec3(
        pow(Lab.x, 3.0),
        pow(Lab.y, 3.0),
        pow(Lab.z, 3.0)
    );
}

float L_to_Lr(float x) {
    const float k1 = 0.206;
    const float k2 = 0.03;
    const float k3 = (1.0 + k1) / (1.0 + k2);
    return 0.5 * (k3 * x - k1 + sqrt(pow(k3 * x - k1, 2.0) + 4.0 * k2 * k3 * x));
}

float Lr_to_L(float x) {
    const float k1 = 0.206;
    const float k2 = 0.03;
    const float k3 = (1.0 + k1) / (1.0 + k2);
    return (x * (x + k1)) / (k3 * (x + k2));
}

vec3 RGB_to_Lab(vec3 color) {
    color   = RGB_to_XYZ(color);
    color   = XYZ_to_LMS(color);
    color   = LMS_to_Lab(color);
    color.x = L_to_Lr(color.x);
    return color;
}

vec3 Lab_to_RGB(vec3 color) {
    color.x = Lr_to_L(color.x);
    color   = Lab_to_LMS(color);
    color   = LMS_to_XYZ(color);
    color   = XYZ_to_RGB(color);
    return color;
}

float curve(float x) {
    // TODO: remove two compare
    if (x <= 1e-6)
        return 0.0;
    if (x >= 1.0 - 1e-6)
        return 1.0;
    return imageLoad(TONE, ivec2(int(1023.0 * x), 0)).x;
}

vec3 tone_mapping_ictcp(vec3 ICtCp) {
    float I2  = curve(ICtCp.x);
    ICtCp.yz *= max(ICtCp.x / I2, I2 / ICtCp.x);
    ICtCp.x   = I2;

    return ICtCp;
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = RGB_to_Lab(color.rgb);
    color.rgb = tone_mapping_ictcp(color.rgb);
    color.rgb = Lab_to_RGB(color.rgb);

    return color;
}

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC transfer function (bt.1886)

float bt1886_eotf_inv(float L, float gamma, float Lw, float Lb) {
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma));
    float V = pow(max(L / a, 0.0), 1.0 / gamma) - b;
    return V;
}

vec3 bt1886_eotf_inv(vec3 color, float gamma, float Lw, float Lb) {
    return vec3(
        bt1886_eotf_inv(color.r, gamma, Lw, Lb),
        bt1886_eotf_inv(color.g, gamma, Lw, Lb),
        bt1886_eotf_inv(color.b, gamma, Lw, Lb)
    );
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);

    color.rgb = bt1886_eotf_inv(color.rgb, 2.4, 1.0, 0.001);

    return color;
}