// Histogram
// https://www.shadertoy.com/view/3dBXRW

//!PARAM enabled
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 2
0

//!PARAM samples
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
32.0

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN enabled
//!DESC histogram

float drawRect(float i, float valLen, float val, vec2 uv) {
    // draw the rectangle at appropriate place
	float rect = 0.;

    if (uv.x > i / valLen && uv.x < (i + 1.0) / valLen) {
        // draw the height of rect according to val
        if (val / (samples * samples * 0.25) < uv.y) {
        	rect = 1.;
        }
    }
	return rect;
}

float RGB_to_L(vec3 rgb) {
    float L = dot(rgb, vec3(0.2627, 0.6780, 0.0593));
    return L;
}

vec4 hook() {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = HOOKED_pos;

    // Time varying pixel color
    vec3 col = HOOKED_tex(uv).rgb;

    float[] val = float[] (
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    );
    float valLen = float(val.length());

    for (float u = 0.0; u < samples; u++) {
        for (float v = 0.0; v < samples; v++) {
            vec3 rgb = HOOKED_tex(vec2(u/samples, v/samples)).rgb;
            if (enabled == 2) {
                rgb *= L_sdr / 10000.0;
            }
        	float L = RGB_to_L(rgb);
            int index = int(floor(L * valLen));
            val[index]++;
    	}
    }

    // then add values in a array of length 10
    // then draw a "chart" based on the array, representing the histogram
    float hist = 0.0;
    for (float i = 0.0; i < valLen; i++) {
        hist += drawRect(i, valLen, val[int(i)], vec2(uv.x, 1.0 - uv.y));
    }

    // Output to screen
    return vec4(vec3(mix(uv.x, RGB_to_L(col) - 0.2, hist + 0.1)), 1.0);
}
