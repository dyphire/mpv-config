// Hyperbola tone mapping by suzuki.
// http://technorgb.blogspot.com/2018/02/hyperbola-tone-mapping.html
// https://www.desmos.com/calculator/yztov9da0f

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (suzuki)

const float x1 = 0.001;
const float y1 = 0.0005;

const float x2 = 0.58535;
const float y2 = 0.50135;

const float x3 = 49.261;
const float y3 = 1.0;

const float al = (y2 - y1) / (x2 - x1);
const float bl = y1 - al * x1;  // = y2 - al * x2;

const float at = al * pow(x1, 2.0) * pow(y1, 2.0) / pow(y1 - al * x1, 2.0);
const float bt = al * pow(x1, 2.0) / (y1 - al * x1);
const float ct = pow(y1, 2.0) / (y1 - al * x1);

const float as = al * pow(x2 - x3, 2.0) * pow(y2 - y3, 2.0) / pow(al * (x2 - x3) - y2 + y3, 2.0);
const float bs = (al * x2 * (x3 - x2) + x3 * (y2 - y3)) / (al * (x2 - x3) - y2 + y3);
const float cs = (y3 * (al * (x2 - x3) + y2) - pow(y2, 2.0)) / (al * (x2 - x3) - y2 + y3);

float curve(float x) {
    x = clamp(x, 0.0, x3);

    if (x < x1) {
        x = -at / (x + bt) + ct;
    } else if (x1 <= x && x < x2) {
        x = al * x + bl;
    } else if (x2 <= x) {
        x = -as / (x + bs) + cs;
    }

    return x;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
