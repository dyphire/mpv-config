// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

//!DESC Super-xBR (step1, yuv)
//!HOOK NATIVE
//!BIND HOOKED
//!WIDTH 2 HOOKED.w *
//!HEIGHT 2 HOOKED.h *
//!OFFSET -0.500000 -0.500000
//!WHEN LUMA.w 0 >
vec4 superxbr() {
vec4 i[4*4];
vec4 res;
#define i(x,y) i[(x)*4+(y)]
#define luma(x, y) i(x,y)[0]
#define GET_SAMPLE(pos) HOOKED_texOff(pos)
#define SAMPLE4_MUL(sample4, w) ((sample4)*(w))
vec2 dir = fract(HOOKED_pos * HOOKED_size) - 0.5;
dir = transpose(HOOKED_rot) * dir;
vec2 dist = HOOKED_size * min(HOOKED_pos, vec2(1.0) - HOOKED_pos);
if (dir.x * dir.y < 0.0 && dist.x > 1.0 && dist.y > 1.0)
    return vec4(0.0);
if (dir.x < 0.0 || dir.y < 0.0 || dist.x < 1.0 || dist.y < 1.0)
    return GET_SAMPLE(-dir);
#define IDX(x, y) vec2(float(x)-1.25, float(y)-1.25)
for (int x = 0; x < 4; x++)
for (int y = 0; y < 4; y++) {
i(x,y) = GET_SAMPLE(IDX(x,y));
}
{ // step
mat4 d1 = mat4( i(0,0), i(1,1), i(2,2), i(3,3) );
mat4 d2 = mat4( i(0,3), i(1,2), i(2,1), i(3,0) );
mat4 h1 = mat4( i(0,1), i(1,1), i(2,1), i(3,1) );
mat4 h2 = mat4( i(0,2), i(1,2), i(2,2), i(3,2) );
mat4 v1 = mat4( i(1,0), i(1,1), i(1,2), i(1,3) );
mat4 v2 = mat4( i(2,0), i(2,1), i(2,2), i(2,3) );
float dw = 0.129633;
float ow = 0.175068;
vec4 dk = vec4(-dw, dw+0.5, dw+0.5, -dw);
vec4 ok = vec4(-ow, ow+0.5, ow+0.5, -ow);
vec4 d1c = SAMPLE4_MUL(d1, dk);
vec4 d2c = SAMPLE4_MUL(d2, dk);
vec4 vc = SAMPLE4_MUL(v1+v2, ok)/2.0;
vec4 hc = SAMPLE4_MUL(h1+h2, ok)/2.0;
float d_edge = 0.0;
d_edge += -1.0 * abs(luma(2,0) - luma(0,2));
d_edge -= -1.0 * abs(luma(3,2) - luma(1,0));
d_edge += 1.0 * abs(luma(1,1) - luma(0,2));
d_edge -= 1.0 * abs(luma(2,1) - luma(1,0));
d_edge += 1.0 * abs(luma(2,0) - luma(1,1));
d_edge -= 1.0 * abs(luma(3,2) - luma(2,1));
d_edge += 2.0 * abs(luma(2,1) - luma(1,2));
d_edge -= 2.0 * abs(luma(2,2) - luma(1,1));
d_edge += -1.0 * abs(luma(3,1) - luma(1,3));
d_edge -= -1.0 * abs(luma(2,3) - luma(0,1));
d_edge += 1.0 * abs(luma(2,2) - luma(1,3));
d_edge -= 1.0 * abs(luma(1,2) - luma(0,1));
d_edge += 1.0 * abs(luma(3,1) - luma(2,2));
d_edge -= 1.0 * abs(luma(2,3) - luma(1,2));
float o_edge = 0.0;
o_edge += 1.0 * abs(luma(1,0) - luma(1,1));
o_edge -= 1.0 * abs(luma(0,1) - luma(1,1));
o_edge += 2.0 * abs(luma(1,1) - luma(1,2));
o_edge -= 2.0 * abs(luma(1,1) - luma(2,1));
o_edge += 1.0 * abs(luma(1,2) - luma(1,3));
o_edge -= 1.0 * abs(luma(2,1) - luma(3,1));
o_edge += 1.0 * abs(luma(2,0) - luma(2,1));
o_edge -= 1.0 * abs(luma(0,2) - luma(1,2));
o_edge += 2.0 * abs(luma(2,1) - luma(2,2));
o_edge -= 2.0 * abs(luma(1,2) - luma(2,2));
o_edge += 1.0 * abs(luma(2,2) - luma(2,3));
o_edge -= 1.0 * abs(luma(2,2) - luma(3,2));
float str = smoothstep(0.0, 0.600000 + 1e-6, abs(d_edge));
res = mix(mix(d2c, d1c, step(0.0, d_edge)),
      mix(hc,   vc, step(0.0, o_edge)), 1.0 - str);
vec4 lo = min(min( i(1,1), i(2,1) ), min( i(1,2), i(2,2) ));
vec4 hi = max(max( i(1,1), i(2,1) ), max( i(1,2), i(2,2) ));
res = clamp(res, lo, hi);
} // step
return res;
}  // superxbr
vec4 hook() {
    return superxbr();
}
//!DESC Super-xBR (step2, yuv)
//!HOOK NATIVE
//!BIND HOOKED
//!WHEN LUMA.w 0 >
vec4 superxbr() {
vec4 i[4*4];
vec4 res;
#define i(x,y) i[(x)*4+(y)]
#define luma(x, y) i(x,y)[0]
#define GET_SAMPLE(pos) HOOKED_texOff(pos)
#define SAMPLE4_MUL(sample4, w) ((sample4)*(w))
vec2 dir = fract(HOOKED_pos * HOOKED_size / 2.0) - 0.5;
if (dir.x * dir.y > 0.0)
    return GET_SAMPLE(0);
#define IDX(x, y) vec2(x+y-3,y-x)
for (int x = 0; x < 4; x++)
for (int y = 0; y < 4; y++) {
i(x,y) = GET_SAMPLE(IDX(x,y));
}
{ // step
mat4 d1 = mat4( i(0,0), i(1,1), i(2,2), i(3,3) );
mat4 d2 = mat4( i(0,3), i(1,2), i(2,1), i(3,0) );
mat4 h1 = mat4( i(0,1), i(1,1), i(2,1), i(3,1) );
mat4 h2 = mat4( i(0,2), i(1,2), i(2,2), i(3,2) );
mat4 v1 = mat4( i(1,0), i(1,1), i(1,2), i(1,3) );
mat4 v2 = mat4( i(2,0), i(2,1), i(2,2), i(2,3) );
float dw = 0.175068;
float ow = 0.129633;
vec4 dk = vec4(-dw, dw+0.5, dw+0.5, -dw);
vec4 ok = vec4(-ow, ow+0.5, ow+0.5, -ow);
vec4 d1c = SAMPLE4_MUL(d1, dk);
vec4 d2c = SAMPLE4_MUL(d2, dk);
vec4 vc = SAMPLE4_MUL(v1+v2, ok)/2.0;
vec4 hc = SAMPLE4_MUL(h1+h2, ok)/2.0;
float d_edge = 0.0;
d_edge += 1.0 * abs(luma(1,1) - luma(0,2));
d_edge -= 1.0 * abs(luma(2,1) - luma(1,0));
d_edge += 1.0 * abs(luma(2,0) - luma(1,1));
d_edge -= 1.0 * abs(luma(3,2) - luma(2,1));
d_edge += 4.0 * abs(luma(2,1) - luma(1,2));
d_edge -= 4.0 * abs(luma(2,2) - luma(1,1));
d_edge += 1.0 * abs(luma(2,2) - luma(1,3));
d_edge -= 1.0 * abs(luma(1,2) - luma(0,1));
d_edge += 1.0 * abs(luma(3,1) - luma(2,2));
d_edge -= 1.0 * abs(luma(2,3) - luma(1,2));
float o_edge = 0.0;
o_edge += 1.0 * abs(luma(1,0) - luma(1,1));
o_edge -= 1.0 * abs(luma(0,1) - luma(1,1));
o_edge += 4.0 * abs(luma(1,1) - luma(1,2));
o_edge -= 4.0 * abs(luma(1,1) - luma(2,1));
o_edge += 1.0 * abs(luma(1,2) - luma(1,3));
o_edge -= 1.0 * abs(luma(2,1) - luma(3,1));
o_edge += 1.0 * abs(luma(2,0) - luma(2,1));
o_edge -= 1.0 * abs(luma(0,2) - luma(1,2));
o_edge += 4.0 * abs(luma(2,1) - luma(2,2));
o_edge -= 4.0 * abs(luma(1,2) - luma(2,2));
o_edge += 1.0 * abs(luma(2,2) - luma(2,3));
o_edge -= 1.0 * abs(luma(2,2) - luma(3,2));
float str = smoothstep(0.0, 0.600000 + 1e-6, abs(d_edge));
res = mix(mix(d2c, d1c, step(0.0, d_edge)),
      mix(hc,   vc, step(0.0, o_edge)), 1.0 - str);
vec4 lo = min(min( i(1,1), i(2,1) ), min( i(1,2), i(2,2) ));
vec4 hi = max(max( i(1,1), i(2,1) ), max( i(1,2), i(2,2) ));
res = clamp(res, lo, hi);
} // step
return res;
}  // superxbr
vec4 hook() {
    return superxbr();
}
