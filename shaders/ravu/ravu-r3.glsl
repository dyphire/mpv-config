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

//!DESC RAVU (step1, luma, r3, compute)
//!HOOK LUMA
//!BIND HOOKED
//!BIND ravu_lut3
//!SAVE ravu_int11
//!WHEN HOOKED.w OUTPUT.w / 0.707106 < HOOKED.h OUTPUT.h / 0.707106 < *
//!COMPUTE 32 8
shared float inp0[481];
void hook() {
ivec2 group_base = ivec2(gl_WorkGroupID) * ivec2(gl_WorkGroupSize);
int local_pos = int(gl_LocalInvocationID.x) * 13 + int(gl_LocalInvocationID.y);
for (int id = int(gl_LocalInvocationIndex); id < 481; id += int(gl_WorkGroupSize.x * gl_WorkGroupSize.y)) {
int x = id / 13, y = id % 13;
inp0[id] = HOOKED_tex(HOOKED_pt * vec2(float(group_base.x+x)+(-1.5), float(group_base.y+y)+(-1.5))).x;
}
groupMemoryBarrier();
barrier();
{
float luma6 = inp0[local_pos + 13];
float luma7 = inp0[local_pos + 14];
float luma8 = inp0[local_pos + 15];
float luma9 = inp0[local_pos + 16];
float luma10 = inp0[local_pos + 17];
float luma11 = inp0[local_pos + 18];
float luma1 = inp0[local_pos + 1];
float luma12 = inp0[local_pos + 26];
float luma13 = inp0[local_pos + 27];
float luma14 = inp0[local_pos + 28];
float luma15 = inp0[local_pos + 29];
float luma2 = inp0[local_pos + 2];
float luma16 = inp0[local_pos + 30];
float luma17 = inp0[local_pos + 31];
float luma18 = inp0[local_pos + 39];
float luma3 = inp0[local_pos + 3];
float luma19 = inp0[local_pos + 40];
float luma20 = inp0[local_pos + 41];
float luma21 = inp0[local_pos + 42];
float luma22 = inp0[local_pos + 43];
float luma23 = inp0[local_pos + 44];
float luma4 = inp0[local_pos + 4];
float luma24 = inp0[local_pos + 52];
float luma25 = inp0[local_pos + 53];
float luma26 = inp0[local_pos + 54];
float luma27 = inp0[local_pos + 55];
float luma28 = inp0[local_pos + 56];
float luma29 = inp0[local_pos + 57];
float luma31 = inp0[local_pos + 66];
float luma32 = inp0[local_pos + 67];
float luma33 = inp0[local_pos + 68];
float luma34 = inp0[local_pos + 69];
vec3 abd = vec3(0.0);
float gx, gy;
gx = (luma13-luma1)/2.0;
gy = (luma8-luma6)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (luma14-luma2)/2.0;
gy = (-luma10+8.0*luma9-8.0*luma7+luma6)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma15-luma3)/2.0;
gy = (-luma11+8.0*luma10-8.0*luma8+luma7)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma16-luma4)/2.0;
gy = (luma11-luma9)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (-luma25+8.0*luma19-8.0*luma7+luma1)/12.0;
gy = (luma14-luma12)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (-luma26+8.0*luma20-8.0*luma8+luma2)/12.0;
gy = (-luma16+8.0*luma15-8.0*luma13+luma12)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (-luma27+8.0*luma21-8.0*luma9+luma3)/12.0;
gy = (-luma17+8.0*luma16-8.0*luma14+luma13)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (-luma28+8.0*luma22-8.0*luma10+luma4)/12.0;
gy = (luma17-luma15)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (-luma31+8.0*luma25-8.0*luma13+luma7)/12.0;
gy = (luma20-luma18)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (-luma32+8.0*luma26-8.0*luma14+luma8)/12.0;
gy = (-luma22+8.0*luma21-8.0*luma19+luma18)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (-luma33+8.0*luma27-8.0*luma15+luma9)/12.0;
gy = (-luma23+8.0*luma22-8.0*luma20+luma19)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (-luma34+8.0*luma28-8.0*luma16+luma10)/12.0;
gy = (luma23-luma21)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma31-luma19)/2.0;
gy = (luma26-luma24)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (luma32-luma20)/2.0;
gy = (-luma28+8.0*luma27-8.0*luma25+luma24)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma33-luma21)/2.0;
gy = (-luma29+8.0*luma28-8.0*luma26+luma25)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma34-luma22)/2.0;
gy = (luma29-luma27)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
float a = abd.x, b = abd.y, d = abd.z;
float T = a + d, D = a * d - b * b;
float delta = sqrt(max(T * T / 4.0 - D, 0.0));
float L1 = T / 2.0 + delta, L2 = T / 2.0 - delta;
float sqrtL1 = sqrt(L1), sqrtL2 = sqrt(L2);
float theta = mix(mod(atan(L1 - a, b) + 3.141592653589793, 3.141592653589793), 0.0, abs(b) < 1.192092896e-7);
float lambda = sqrtL1;
float mu = mix((sqrtL1 - sqrtL2) / (sqrtL1 + sqrtL2), 0.0, sqrtL1 + sqrtL2 < 1.192092896e-7);
float angle = floor(theta * 24.0 / 3.141592653589793);
float strength = clamp(floor(log2(lambda * 2000.0 + 1.192092896e-7)), 0.0, 8.0);
float coherence = mix(mix(0.0, 1.0, mu >= 0.25), 2.0, mu >= 0.5);
float coord_y = ((angle * 9.0 + strength) * 3.0 + coherence + 0.5) / 648.0;
float res = 0.0;
vec4 w;
w = texture(ravu_lut3, vec2(0.1, coord_y));
res += (inp0[local_pos + 0] + inp0[local_pos + 70]) * w[0];
res += (inp0[local_pos + 1] + inp0[local_pos + 69]) * w[1];
res += (inp0[local_pos + 2] + inp0[local_pos + 68]) * w[2];
res += (inp0[local_pos + 3] + inp0[local_pos + 67]) * w[3];
w = texture(ravu_lut3, vec2(0.3, coord_y));
res += (inp0[local_pos + 4] + inp0[local_pos + 66]) * w[0];
res += (inp0[local_pos + 5] + inp0[local_pos + 65]) * w[1];
res += (inp0[local_pos + 13] + inp0[local_pos + 57]) * w[2];
res += (inp0[local_pos + 14] + inp0[local_pos + 56]) * w[3];
w = texture(ravu_lut3, vec2(0.5, coord_y));
res += (inp0[local_pos + 15] + inp0[local_pos + 55]) * w[0];
res += (inp0[local_pos + 16] + inp0[local_pos + 54]) * w[1];
res += (inp0[local_pos + 17] + inp0[local_pos + 53]) * w[2];
res += (inp0[local_pos + 18] + inp0[local_pos + 52]) * w[3];
w = texture(ravu_lut3, vec2(0.7, coord_y));
res += (inp0[local_pos + 26] + inp0[local_pos + 44]) * w[0];
res += (inp0[local_pos + 27] + inp0[local_pos + 43]) * w[1];
res += (inp0[local_pos + 28] + inp0[local_pos + 42]) * w[2];
res += (inp0[local_pos + 29] + inp0[local_pos + 41]) * w[3];
w = texture(ravu_lut3, vec2(0.9, coord_y));
res += (inp0[local_pos + 30] + inp0[local_pos + 40]) * w[0];
res += (inp0[local_pos + 31] + inp0[local_pos + 39]) * w[1];
res = clamp(res, 0.0, 1.0);
imageStore(out_image, ivec2(gl_GlobalInvocationID), vec4(res, 0.0, 0.0, 0.0));
}
}
//!DESC RAVU (step2, luma, r3, compute)
//!HOOK LUMA
//!BIND HOOKED
//!BIND ravu_lut3
//!BIND ravu_int11
//!WIDTH 2 HOOKED.w *
//!HEIGHT 2 HOOKED.h *
//!OFFSET -0.500000 -0.500000
//!WHEN HOOKED.w OUTPUT.w / 0.707106 < HOOKED.h OUTPUT.h / 0.707106 < *
//!COMPUTE 64 16 32 8
shared float inp0[481];
shared float inp1[481];
void hook() {
ivec2 group_base = ivec2(gl_WorkGroupID) * ivec2(gl_WorkGroupSize);
int local_pos = int(gl_LocalInvocationID.x) * 13 + int(gl_LocalInvocationID.y);
for (int id = int(gl_LocalInvocationIndex); id < 481; id += int(gl_WorkGroupSize.x * gl_WorkGroupSize.y)) {
int x = id / 13, y = id % 13;
inp0[id] = ravu_int11_tex(ravu_int11_pt * vec2(float(group_base.x+x)+(-2.5), float(group_base.y+y)+(-2.5))).x;
}
for (int id = int(gl_LocalInvocationIndex); id < 481; id += int(gl_WorkGroupSize.x * gl_WorkGroupSize.y)) {
int x = id / 13, y = id % 13;
inp1[id] = HOOKED_tex(HOOKED_pt * vec2(float(group_base.x+x)+(-1.5), float(group_base.y+y)+(-1.5))).x;
}
groupMemoryBarrier();
barrier();
{
float luma12 = inp0[local_pos + 15];
float luma7 = inp0[local_pos + 16];
float luma2 = inp0[local_pos + 17];
float luma24 = inp0[local_pos + 27];
float luma19 = inp0[local_pos + 28];
float luma14 = inp0[local_pos + 29];
float luma9 = inp0[local_pos + 30];
float luma4 = inp0[local_pos + 31];
float luma31 = inp0[local_pos + 40];
float luma26 = inp0[local_pos + 41];
float luma21 = inp0[local_pos + 42];
float luma16 = inp0[local_pos + 43];
float luma11 = inp0[local_pos + 44];
float luma33 = inp0[local_pos + 54];
float luma28 = inp0[local_pos + 55];
float luma23 = inp0[local_pos + 56];
float luma18 = inp1[local_pos + 14];
float luma13 = inp1[local_pos + 15];
float luma8 = inp1[local_pos + 16];
float luma3 = inp1[local_pos + 17];
float luma25 = inp1[local_pos + 27];
float luma20 = inp1[local_pos + 28];
float luma15 = inp1[local_pos + 29];
float luma6 = inp1[local_pos + 2];
float luma10 = inp1[local_pos + 30];
float luma1 = inp1[local_pos + 3];
float luma32 = inp1[local_pos + 40];
float luma27 = inp1[local_pos + 41];
float luma22 = inp1[local_pos + 42];
float luma17 = inp1[local_pos + 43];
float luma34 = inp1[local_pos + 54];
float luma29 = inp1[local_pos + 55];
vec3 abd = vec3(0.0);
float gx, gy;
gx = (luma13-luma1)/2.0;
gy = (luma8-luma6)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (luma14-luma2)/2.0;
gy = (-luma10+8.0*luma9-8.0*luma7+luma6)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma15-luma3)/2.0;
gy = (-luma11+8.0*luma10-8.0*luma8+luma7)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma16-luma4)/2.0;
gy = (luma11-luma9)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (-luma25+8.0*luma19-8.0*luma7+luma1)/12.0;
gy = (luma14-luma12)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (-luma26+8.0*luma20-8.0*luma8+luma2)/12.0;
gy = (-luma16+8.0*luma15-8.0*luma13+luma12)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (-luma27+8.0*luma21-8.0*luma9+luma3)/12.0;
gy = (-luma17+8.0*luma16-8.0*luma14+luma13)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (-luma28+8.0*luma22-8.0*luma10+luma4)/12.0;
gy = (luma17-luma15)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (-luma31+8.0*luma25-8.0*luma13+luma7)/12.0;
gy = (luma20-luma18)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (-luma32+8.0*luma26-8.0*luma14+luma8)/12.0;
gy = (-luma22+8.0*luma21-8.0*luma19+luma18)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (-luma33+8.0*luma27-8.0*luma15+luma9)/12.0;
gy = (-luma23+8.0*luma22-8.0*luma20+luma19)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (-luma34+8.0*luma28-8.0*luma16+luma10)/12.0;
gy = (luma23-luma21)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma31-luma19)/2.0;
gy = (luma26-luma24)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (luma32-luma20)/2.0;
gy = (-luma28+8.0*luma27-8.0*luma25+luma24)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma33-luma21)/2.0;
gy = (-luma29+8.0*luma28-8.0*luma26+luma25)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma34-luma22)/2.0;
gy = (luma29-luma27)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
float a = abd.x, b = abd.y, d = abd.z;
float T = a + d, D = a * d - b * b;
float delta = sqrt(max(T * T / 4.0 - D, 0.0));
float L1 = T / 2.0 + delta, L2 = T / 2.0 - delta;
float sqrtL1 = sqrt(L1), sqrtL2 = sqrt(L2);
float theta = mix(mod(atan(L1 - a, b) + 3.141592653589793, 3.141592653589793), 0.0, abs(b) < 1.192092896e-7);
float lambda = sqrtL1;
float mu = mix((sqrtL1 - sqrtL2) / (sqrtL1 + sqrtL2), 0.0, sqrtL1 + sqrtL2 < 1.192092896e-7);
float angle = floor(theta * 24.0 / 3.141592653589793);
float strength = clamp(floor(log2(lambda * 2000.0 + 1.192092896e-7)), 0.0, 8.0);
float coherence = mix(mix(0.0, 1.0, mu >= 0.25), 2.0, mu >= 0.5);
float coord_y = ((angle * 9.0 + strength) * 3.0 + coherence + 0.5) / 648.0;
float res = 0.0;
vec4 w;
w = texture(ravu_lut3, vec2(0.1, coord_y));
res += (inp0[local_pos + 3] + inp0[local_pos + 68]) * w[0];
res += (inp1[local_pos + 3] + inp1[local_pos + 54]) * w[1];
res += (inp0[local_pos + 17] + inp0[local_pos + 54]) * w[2];
res += (inp1[local_pos + 17] + inp1[local_pos + 40]) * w[3];
w = texture(ravu_lut3, vec2(0.3, coord_y));
res += (inp0[local_pos + 31] + inp0[local_pos + 40]) * w[0];
res += (inp1[local_pos + 31] + inp1[local_pos + 26]) * w[1];
res += (inp1[local_pos + 2] + inp1[local_pos + 55]) * w[2];
res += (inp0[local_pos + 16] + inp0[local_pos + 55]) * w[3];
w = texture(ravu_lut3, vec2(0.5, coord_y));
res += (inp1[local_pos + 16] + inp1[local_pos + 41]) * w[0];
res += (inp0[local_pos + 30] + inp0[local_pos + 41]) * w[1];
res += (inp1[local_pos + 30] + inp1[local_pos + 27]) * w[2];
res += (inp0[local_pos + 44] + inp0[local_pos + 27]) * w[3];
w = texture(ravu_lut3, vec2(0.7, coord_y));
res += (inp0[local_pos + 15] + inp0[local_pos + 56]) * w[0];
res += (inp1[local_pos + 15] + inp1[local_pos + 42]) * w[1];
res += (inp0[local_pos + 29] + inp0[local_pos + 42]) * w[2];
res += (inp1[local_pos + 29] + inp1[local_pos + 28]) * w[3];
w = texture(ravu_lut3, vec2(0.9, coord_y));
res += (inp0[local_pos + 43] + inp0[local_pos + 28]) * w[0];
res += (inp1[local_pos + 43] + inp1[local_pos + 14]) * w[1];
res = clamp(res, 0.0, 1.0);
imageStore(out_image, ivec2(gl_GlobalInvocationID) * 2 + ivec2(0, 1), vec4(res, 0.0, 0.0, 0.0));
}
{
float luma6 = inp0[local_pos + 15];
float luma1 = inp0[local_pos + 16];
float luma18 = inp0[local_pos + 27];
float luma13 = inp0[local_pos + 28];
float luma8 = inp0[local_pos + 29];
float luma3 = inp0[local_pos + 30];
float luma25 = inp0[local_pos + 40];
float luma20 = inp0[local_pos + 41];
float luma15 = inp0[local_pos + 42];
float luma10 = inp0[local_pos + 43];
float luma32 = inp0[local_pos + 53];
float luma27 = inp0[local_pos + 54];
float luma22 = inp0[local_pos + 55];
float luma17 = inp0[local_pos + 56];
float luma34 = inp0[local_pos + 67];
float luma29 = inp0[local_pos + 68];
float luma12 = inp1[local_pos + 14];
float luma7 = inp1[local_pos + 15];
float luma2 = inp1[local_pos + 16];
float luma24 = inp1[local_pos + 26];
float luma19 = inp1[local_pos + 27];
float luma14 = inp1[local_pos + 28];
float luma9 = inp1[local_pos + 29];
float luma4 = inp1[local_pos + 30];
float luma31 = inp1[local_pos + 39];
float luma26 = inp1[local_pos + 40];
float luma21 = inp1[local_pos + 41];
float luma16 = inp1[local_pos + 42];
float luma11 = inp1[local_pos + 43];
float luma33 = inp1[local_pos + 53];
float luma28 = inp1[local_pos + 54];
float luma23 = inp1[local_pos + 55];
vec3 abd = vec3(0.0);
float gx, gy;
gx = (luma13-luma1)/2.0;
gy = (luma8-luma6)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (luma14-luma2)/2.0;
gy = (-luma10+8.0*luma9-8.0*luma7+luma6)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma15-luma3)/2.0;
gy = (-luma11+8.0*luma10-8.0*luma8+luma7)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma16-luma4)/2.0;
gy = (luma11-luma9)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (-luma25+8.0*luma19-8.0*luma7+luma1)/12.0;
gy = (luma14-luma12)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (-luma26+8.0*luma20-8.0*luma8+luma2)/12.0;
gy = (-luma16+8.0*luma15-8.0*luma13+luma12)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (-luma27+8.0*luma21-8.0*luma9+luma3)/12.0;
gy = (-luma17+8.0*luma16-8.0*luma14+luma13)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (-luma28+8.0*luma22-8.0*luma10+luma4)/12.0;
gy = (luma17-luma15)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (-luma31+8.0*luma25-8.0*luma13+luma7)/12.0;
gy = (luma20-luma18)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (-luma32+8.0*luma26-8.0*luma14+luma8)/12.0;
gy = (-luma22+8.0*luma21-8.0*luma19+luma18)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (-luma33+8.0*luma27-8.0*luma15+luma9)/12.0;
gy = (-luma23+8.0*luma22-8.0*luma20+luma19)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (-luma34+8.0*luma28-8.0*luma16+luma10)/12.0;
gy = (luma23-luma21)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma31-luma19)/2.0;
gy = (luma26-luma24)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (luma32-luma20)/2.0;
gy = (-luma28+8.0*luma27-8.0*luma25+luma24)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma33-luma21)/2.0;
gy = (-luma29+8.0*luma28-8.0*luma26+luma25)/12.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (luma34-luma22)/2.0;
gy = (luma29-luma27)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
float a = abd.x, b = abd.y, d = abd.z;
float T = a + d, D = a * d - b * b;
float delta = sqrt(max(T * T / 4.0 - D, 0.0));
float L1 = T / 2.0 + delta, L2 = T / 2.0 - delta;
float sqrtL1 = sqrt(L1), sqrtL2 = sqrt(L2);
float theta = mix(mod(atan(L1 - a, b) + 3.141592653589793, 3.141592653589793), 0.0, abs(b) < 1.192092896e-7);
float lambda = sqrtL1;
float mu = mix((sqrtL1 - sqrtL2) / (sqrtL1 + sqrtL2), 0.0, sqrtL1 + sqrtL2 < 1.192092896e-7);
float angle = floor(theta * 24.0 / 3.141592653589793);
float strength = clamp(floor(log2(lambda * 2000.0 + 1.192092896e-7)), 0.0, 8.0);
float coherence = mix(mix(0.0, 1.0, mu >= 0.25), 2.0, mu >= 0.5);
float coord_y = ((angle * 9.0 + strength) * 3.0 + coherence + 0.5) / 648.0;
float res = 0.0;
vec4 w;
w = texture(ravu_lut3, vec2(0.1, coord_y));
res += (inp1[local_pos + 2] + inp1[local_pos + 67]) * w[0];
res += (inp0[local_pos + 16] + inp0[local_pos + 67]) * w[1];
res += (inp1[local_pos + 16] + inp1[local_pos + 53]) * w[2];
res += (inp0[local_pos + 30] + inp0[local_pos + 53]) * w[3];
w = texture(ravu_lut3, vec2(0.3, coord_y));
res += (inp1[local_pos + 30] + inp1[local_pos + 39]) * w[0];
res += (inp0[local_pos + 44] + inp0[local_pos + 39]) * w[1];
res += (inp0[local_pos + 15] + inp0[local_pos + 68]) * w[2];
res += (inp1[local_pos + 15] + inp1[local_pos + 54]) * w[3];
w = texture(ravu_lut3, vec2(0.5, coord_y));
res += (inp0[local_pos + 29] + inp0[local_pos + 54]) * w[0];
res += (inp1[local_pos + 29] + inp1[local_pos + 40]) * w[1];
res += (inp0[local_pos + 43] + inp0[local_pos + 40]) * w[2];
res += (inp1[local_pos + 43] + inp1[local_pos + 26]) * w[3];
w = texture(ravu_lut3, vec2(0.7, coord_y));
res += (inp1[local_pos + 14] + inp1[local_pos + 55]) * w[0];
res += (inp0[local_pos + 28] + inp0[local_pos + 55]) * w[1];
res += (inp1[local_pos + 28] + inp1[local_pos + 41]) * w[2];
res += (inp0[local_pos + 42] + inp0[local_pos + 41]) * w[3];
w = texture(ravu_lut3, vec2(0.9, coord_y));
res += (inp1[local_pos + 42] + inp1[local_pos + 27]) * w[0];
res += (inp0[local_pos + 56] + inp0[local_pos + 27]) * w[1];
res = clamp(res, 0.0, 1.0);
imageStore(out_image, ivec2(gl_GlobalInvocationID) * 2 + ivec2(1, 0), vec4(res, 0.0, 0.0, 0.0));
}
float res;
res = inp0[local_pos + 42];
imageStore(out_image, ivec2(gl_GlobalInvocationID) * 2 + ivec2(1, 1), vec4(res, 0.0, 0.0, 0.0));
res = inp1[local_pos + 28];
imageStore(out_image, ivec2(gl_GlobalInvocationID) * 2 + ivec2(0, 0), vec4(res, 0.0, 0.0, 0.0));
}
//!TEXTURE ravu_lut3
//!SIZE 5 648
//!FORMAT rgba16hf
//!FILTER NEAREST
9c121c993f162d171199c6123b9c47216820fe1f7c21a99c621a0424c632053376241f1c000000005b118398e11aba19679a5011609e871e2e254825591c4ea1af21f92320319432312aae2500000000550a9614631d1a1d6d90a307f49472aa192b6f2de0a8b49db19854a9492dd2325b314c2600000000d70d1997e11ae31a5e960d0e7399aa1f2ca550a55d1fdd98fe1c34a45934723416a41f1d00000000990c479461145b14ef96450d62a0bf1cf79dcc9d5a1c8da0461dd6234033c633c125c71f000000002d084198421aff19869ae20674a0c9a00e265f26b59f2ba129210f26913124322c2bcf2700000000420ebe98e21ca01c14970a0dec9b471c3aa844a8e819a99ade1f35a8d834ec3416a8771f0000000054097594bb19451be293ce09349fb81c5ea78ea73913bd9e971eb4a48434bd3492a2472000000000ca099f8d331647181a983f0c2ea2bf9e5b9e679d8ea209a3f51b0d255533f933c228122400000000e911969734201620d5916611209a2410faa9f8a9e198519a6c2137aa3c354f35efa9e52100000000d70bd994671c7d1c4f11ce81629d1119aea8b7a8199d0b9f0c1e71a8df341335afa6a72200000000988637084619281cf08f0f87a6a0bc98cba5aaa5cda1ada370163fa044349b347b1f7825000000001210489884215821f08e030ccd95631b18ab6bab1a1439980522b2ab6b3588356cab7d230000000089813696c81ef71e7918538dd596841a8ea9e5a932a05a9fdb1b8daa1c355a3595a8e22400000000aa8bf38c6e19681c9c160f920898881ceda56ea631a47ca64aa43aa87334d3349a1bfa29000000002f9cd281e81d511ff8166c9ce31c9e2452abc8ab4123801aaa1658ab4f357e3507ab7d1f00000000d893ef95cc1d0b206d1aad92318d6122e2a9f2aacf9c3ea024120fac19358f35c3a8842500000000388830944a17db1cf017ef113c1e8724a0a43ca692a6d0a910aa68ac6e340b353324bb2d0000000079808f95e8210c23fa145212b29b361fb3ab3aacd88fbe9e45238aac7935cd352bac6825000000003491d3965b1d1f212a1a48180e98cf210aa928abdaa2caa2161f34ad0735c9356ca8182700000000a410d298e187bb19fd9a9b21d82184281d9ab5a51ca8fdac8bacf3af27343f35d62a4d3000000000f91432937a21bf22fd19d61aca9d2114abaa00aca1a0bda09b2346ac5035d435aaabc52500000000c517619b4a1c0c21da1bb120e09fa3214ea774ab85a56ba50623b2adc734f735e1a51727000000008414179e2f99270a6ba02c27a722dd296d231da77ba93fae2dac9eb17b33cc355e2d9830000000005c2017a0dc25d826a519ee19eaa33a2531adfdadde1e08a1b42523ad9335fe35d4ac0e2700000000961fb006f32365259121be232da394955faa7aac13a84aa53a256eac5834e3353525d21e0000000055a0619b31a0a21c2320e3283d235d28b62bcaabeaae38ab56a8b0b2fb2fe836c332e62b000000002015de971680f6126d9755164d9c4022281d1e16da21df9d82133c219832be338224251a0000000040150d06f715ba92c09a0a165ea0602163244d24d411d8a4b418401e3e2f3533cd2e6e27000000009509ff0e341b831be59eac810a9cf71dc8205f276d1fbba69aa15388432c65305431992f00000000390db097961a451b6496590f3e99cd1f29a594a59a1f3398da1c7ca4433491342ba4f71c00000000380d8f9125104214b6995a10659fb51f67a062a0781fb6a03815b61fc7323d34e726af1f000000005c0d7f95c2149e0d2c9fd90aeea2e5218f22c3235d1e1ea6ad9fb225a7301732e62d1b2b000000001c0ff799371d7d1c8094370c0a9cbd1d39a858a81b16de98bc1f6ea8c73402350ea8301f00000000930bb5959518711c73937e0c799ea720d7a71aa83096069d921cc1a65b340935dca11120000000009a829918f496431c939d3512f4a12d20e2a346a142a0f8a27ea00c1ce6326e34db29822400000000e013fb9973200720ee0c93106b9bd81a00aa18aaa39cfd992d2176aa2a356835d3a93822000000002211749a131dff1c011a928c219c7f211aa924a9f9a1909e5117eda9be34623502a63b2400000000828d7b170c9bb4215f98320d51a08a252da984a5a1a6cba026a26ba705344e35e01ff22600000000e8113e9a6c2132227c0c82115798c21e1aabadabc199529b6f210aac5435ad353eab7224000000006012a89c3c1edf1f971e2e8c2d917b2355a9b6aa65a441a2189a5eace534b135c2a675270000000062116f9b7e98241eb920f195751ab0262ba68da8d3a719a81ea882ac30348c35c223102c000000005c8d8d99e22014238e17a384ba965d2261ab36ace498929c3c205eac4835d73563ab252500000000d613429d441a5d210f1ff31849972026bba88eabeca5cca4069bbdadbc340a3685a5e828000000002916e59c939a9d971d1d8e208e1c7328959c9fa56ca821acd4a909afb833a6352c29822e000000005b17459c77217824c319ae1a0c9ebc213aaba2ac05a18aa1a022e0ac36352336e8ab2827000000005417f69c12983822611d1a21829d49278aa50face6a7b3a7ae1c57af523476367d9fa82900000000b318309b7d9aeb9ea6a183260688582872237d932ba737ae62a8bfb07132aa35682d812f000000006913c49a0d20e323691f7f1c7b9e0221cca98facdca434a27622a2acd4345436d7aa0a2700000000121c0ca0329aa120e61f6724aea1e827229e6dacb9a8a8a89a23fdaf6833e736c221d02800000000981aa8982d9d289e33a626291c9d82271028ec9ba6a5fbaeb2a0e0b145311c36102ffa2e000000007320c79d2424c1264521a61b43a4d02411aca2ae56a075a03f2525ad0c3578368bac502800000000972185a16120d120bc25bb25fba50e25b8a161ad1ea812a9652859af903174372529492000000000ab1d6099a6a0ec9a93a71c2b4fa521275c2ad7a471a55caebc28d4b2752be236d6323629000000002b152b98ef8777111299ff16049b1922461d240c5e22689d0913332040321b3450243918000000007c167d93b41080965f996d175e9d1c2427238f1fed924da4189d941e442d373431305e2000000000c40b490d3595899848993a06129c3726c41815194a9b2b9f54a2c61a2e29d0324d33b22400000000d40dee970d1b9e1b499617105b99ed1f27a5e8a502204e97cd1cbea42e34b03474a49a1c00000000980e9c93af04e615759cfb12e69db52122a292a2d7217fa0e2952b966032aa34fe265f1c000000008811ac92e0127d98efa02b115ba14e25d799481bbb2433a3c4a251203730f4324f303024000000005d10ba9b041e3c1c32901f0a759c381f46a873a844101c95122096a8b834183509a8e71d00000000990e8e98131ab41c8693750e3d9ea9223ba87fa87a98a3990d1d67a83e345735fea2801d00000000ae816f1a799b0c1ea8a09615eaa07124baa52ba4f89600a117a261a16332ec34732ae920000000008214ba9be1209b1fb515540f489ce61d1baa3aaa549e11991e21b2aa1a358135d2a93422000000002f14ad9c3f1eed1caa1d6b8ff29c6d2495a9b2a939a4819c9d1a22aba334b2353aa6be23000000007a8add1b2ba0c5230695350ccaa20b292aab86a401a9f400d7a054a97c33f9353399ef2500000000c8133e9b3521be22a5157e0f799a6e200fabefabd59d739b692124ac3e35cc3522aba82400000000b416319e791d5e1f7e213f09829a77250fa94fab87a6a6a2218c02adaa340a36aaa58f27000000003a123897769dad1b3d249181069c4b28aba7f8a8c3a93ca54ba3d4acad333a3627214b29000000002115b29c23215a2480184e17c49c4f235aab6cacf7a0819f2121b1ac2c35113671ab702600000000bd18f09ccb93e7202c213c1ee59e542710a777abeaa849a6051480ae4a347736f8a07c290000000024143c94479b2d9faa212a223a9c5f264d1989a766aa4baa4da0e5aec1323c36f42ae02a000000008b18d09db220de24401d6c1a6a9e8323c9aae1ac42a4e8a04922faacf8346736a8ab562700000000a41bcd991e9e761e3720a523f8a11c27599d1fab19aafda89320a7af1d33ff36f51f712a000000008b10ee178396f3a0439d4326b79f64230a252396b8aaaaac202010b0fb303d362d2f872a00000000c9186d9ec91ebe2315223d1ba49f992333a9d3ac15a75ba1c621a3ac7634b23684aa412700000000a81ed99bd39c13952a21752549a4e6255a22fbaa86aa11aa5e24a3af51318e371926eb29000000004c0e191c4191b39ffba48b2826a1cb1e4f27961ff1a980ad082684b0d12f4c36a9309f2900000000492272a1762482260a22341ecba2f2228faa06af89a3189ee32379ac8a34f0360aad762800000000bc20a5951a9d67172026f725c0a5d821272445acf6a880aa1526daad202d4938102611270000000072175f1b1213dd9d59a6a429faa222994c27a61f4fa8faad1b2938af182896368732842200000000ed147698c0939414439a311848993c22091d6b963023419c6408401ff73155342b23381000000000c4164f994798e39523974014f59a3f255e21f09b8f192417129eaa1d632d2435e12c619c000000006f11cc975598e515af9c21105f954a26fb9baaa57126ec9800a2089d3d295b35f92f0e1900000000a40eab98741bc91ba9965311249917202ca52ba685205696d01cfba41e34cb34e4a40f1c00000000480f7395848c9918bf9d0415939cff2217a3fba46424c49f309877a027321d358e23551800000000dd128e95009895941ea2b214a99fbf27d3a104a26e27c59baca4d78c84309734782c4621000000009d11849cd61eb21bd188a00ad89c272058a880a80809988d3320a6a8ab342c352da8df1c00000000e211709bc01c1e1cf58c230c419eb92371a8fda88e8b1593a01f12a929349835eca40b1800000000c40daf110d947c1b6da13415cd9e1425eea510a7142467a055a03ba52d3268350a289b180000000097159c9c3b218f1f1518200c019d911f38aa56aa0f9f37966121ceaa0f359435dfa9b321000000004d16e89d5c201e1b9b1fd693d29e2825f3a940aa4ea437935720bbab9334ef3563a7df20000000008e1496940c182b1bb91eac99a8a16b2851aab1a862a502103a0d92aa78333e3650a0112100000000ce14159c39211923ff16000e7b9b06211dab0bac339fdf996b2120ac2f35e43540ab8b24000000009618159e5b1d551f82226793929ed02510a9faab30a7e89dc41ff6ac7a345d3628a7fb24000000009215a7988598240ee0252c9d189f49283fa8dfaa5ea9bd982d0b88ac4a33c436db9f5924000000000217929df520cd24f0188918f69d252467ab7fac0da38d9eb321bdac0f353a368dab67260000000033185998769b082130236e1ce0a09226d7a5ffab5aaab6a20f210aaed033e436c3a137270000000097135a0ee49b04a0ac263717e39ed525689a30aa60acf4a0731f6aade831263786278722000000001219e99e6a20fa247b1f7418429f8224b1aaf2acbfa58b9e4d22e1acc3349f36b4ab0227000000007b18f011769e41184724512128a2ae245a180fab67ac4aa5db2330aed4319237cb1ded27000000007206df18880944a39424a221979ef51e68244ea6c0ad49a4492444adeb2f5e371b2d369800000000bc1a27a0331e6023ef238a15a7a08724e0a8dfac82a8949d482272ac2d34fb36a4aa8b2600000000cd19af14929a7f9e5b242f2420a3c5209224a5a927adcda6d42464ad7f2f1138fc25dc26000000000b90791b73169ba23e1d6225f99dc4991e2757a2ecaddea68f2521ad752d7937fa2e35a0000000001f22a2a23b247d26c021e91d6ea19f207da919afeba45981412388ab1c34533758adc82700000000aa1d6c1812996b9c1e26672443a46e9759257fa871adfaa62f247eaa3d287e38b1253b25000000001187c213b11d32a2f497ef262e9839a127254a1c6dad3da914240da801a21538e12f1ca20000000077154c989591900f439bba180b9969228d1df3920924b89c0e958e1ed3318134ac1f800d00000000f2169d98a19c4a12c99c2a17569a0f25b920b0a0a524ab19fa9ca61d922dac353428af9d0000000067124195fc9d129cb695f310da977127441eb8a77b266f20cea3141f73298436c528d99c00000000360fda98371cb21b8f96b8114999202027a560a616211c96df1c2aa50f34e4348aa5991b000000004e101898638ae219139f50173c9bf92210a33fa65b26f09f35914ba2fa317e35049b161500000000f8122495109e7c9a93a10e18f59e7b2894a1cda42f29e69c86a3659b4930a93547226d1900000000eb11ee9cdc1f971a8f0df708199d85206aa887a8b70ceb0b8320b7a8a0343b3546a8611b000000008114619d7a1f7a18e00fbc00c29e142496a83ba9fe1830146f214aa91734ca3504a7899400000000031217969e13c5145fa2ad166e9d5c2515a63fa89428c1a1239be3a5eb31df352119b796000000007016689dbc21591ff316e30d779d242051aa65aac59e7b8fdd21bbaa0635a23518aade200000000061180c9fad216f18a91f9f9641a02c2539aa8baae0a2ac1a0d23aaab8c341236baa8991a000000004518179d6e20f090901c8a9ba7a0c12689a969aabd15c716e020a9aaa8334f3682a53099000000001c169d9c622164237f15750cc49cb32142ab16ac109fea96d8210eac1f35fa359fab4d2400000000301a599e171f561f6322709aa1a0892581a930ac3ba6601af82262ac5c34973672a90821000000008d186299b8150c1ac32445a0eda0b0265fa84eac2ea6f4206422caab5833f83600a8be8d000000000a19f89e222147250b14a418509fb724b0ab8fac0ca3a29c29229bacfc34583608ac112600000000e0185c981099f0214a24169846a1b025c2a67fac12aaa81c4523c5ac65333d3717a8532200000000a7148215069d1015bc26df9fc29f0b242fa094acd4aaee23dd2235abc931a537ada4a19d000000001b1aa59f63206d25c91ee21209a0b824caaa0aad02a628979f2293ac9d34cc3638ac5826000000006016be10ba9c0b1d2d26b784d4a01322ff9967ac75ac0f1dae2316ac68310338dba67b22000000003f0d8f18089720a09f27839c459d6b1b5e218babf8ac3e24f5229ca9e92f15388111d9a100000000dd1a16a0351e26240a23a685fca07424fda8dbacf6a8d318ab22d1abf933303778ab2f2500000000e415d7134998409bdb26fd1cb6a0ab1c3a213babb9ad771de92209aa092f4a3831a32320000000001e8927187014d6a2af26de19909adf985625d2a9b9ada820ec21b8a80c2d45380223ada000000000fd207fa26724d825c721071bf2a12f1ce1a800af3aa582201f25afaac1338a3793ad4a25000000001718f6180093d0889726ae1f8ca1bd9af3229aa942ae27210d22b0a6602a8138e79e851b00000000c28bcc0ae219d3a24124f221358a449b14248ca441ae1f981a1cb7a210218b38c125c79b000000006515e098d590df0a339c5119189961226a1e09107124ae9c7a92ed1db13197344f1b1e0c000000006a16bd99459cbc0bf89e231c4999662459204c9e0028229c2999641db82ddd350521b69c000000005d0f968e7f9d5413fa9b1a195e934b23751ced9cd3281d981f9d2a9a9a26fe36c01a239300000000b90ffe98591cd21b7296eb12199927202aa567a69b213496a91c31a50534f33415a6831b00000000b4100b99bf0d5e1955a04719989973229ea28da6072858a0190d6ca2c231c435e8a42c1600000000e70e6e95b09d68980ca2621b9a987e25279c8fa4412b7ba1dd9ecd9bed2d6f3663a06f9800000000ab12429d5820011ac7127b05549db42082a88da8450e78139a20a2a8993444356ca8f71900000000ec15c99e4a216291ee15da802e9f1224a8a84da9171ef9171e22f6a8fe33f035aea8079900000000dc124999c7100614d9a2a819639ba0241ea56ea8e82999a22f8c09a53831683684a68f8d00000000a617169e0c22761f55165f09409eb22075aa55aa369e400f3b22a0aa0035a93543aa2720000000009a194fa02e238d06491fe297caa02d258eaa7baabfa0f31d202418ab84342536e0a90b8e000000009719dd9e35212595e10f8099a3a0d52545a956aae823e41241228ca951337c3640a9009c000000000918559d8921f923610c2f0ec29d83228bab1cacc29d22940c22eaab1a350636ffab192400000000f91b1fa04e21721e3b21c49b12a14f2522aa15acc3a4841f712366ab4634b7363eab811e00000000cb1acc9c341d4f1ef61e609d30a17625c0a877ac2190891f4622aca93f331237ababc41300000000291dfba160225d26309e1c1dfaa11b2759acc8ac739b00a0f922afac0435693696ac8c2600000000ed1b559e050e7c2378239d9e12a12d2728a997ac6ca81f22922083ab5f335c372fabbf210000000004185b90b79b82225721489e059f2d23a6a470adfaa2a521da1f53a8f231cb3745acc71b000000007a1dfea1f021af263797071c23a29726e7ab43ad3fa3979b532377aca434e236dfac9f2600000000c41abb9bea986b22bb255a9f43a0312406a5ebac34ab2024b91f65a986311c38c2ab70220000000041154014a59ca81f9e24a69f639d01200b9d35ad63a8a7235c1e2ca68d302e38f6ab1919000000009618849f7c1fe224e520fc909ea05c2492a9c8ac0ba931201622d1aade334a3748ac9d240000000008194298e696001d1027219c1f9f6f1fb09d55ac10ad3a252f1e66a6aa2f6538c5aa411f0000000039140d12259af611ac25dc9dff9a5c1c141c79acc7aa1024d81b51a4882e6138abaa40170000000013207fa1e824c024ec222812a0a11e933ca988ae88a48e22b9257faac7338937c9adcf2300000000271637940a91001e5726438f5d9ee90f2813d0abc7ac6425b91f49a5472d7d38f9a9f61d000000003a13a98372988d95e5237f042a989219d11e01a92dac3121b217d5a1d7297a383ca62919000000005915fb98ee90010dc69c4519c7983422e01db81b73244b9ca78e5c1eb1319534c911290c0000000061163c992b99a59c159c211cb6995f24591d24210028ed9e3d9c5020b92ddb351c9e820c00000000470dc48fbe9d3295989ce11999897a23a09a51187c29ff9c879e661ca726fe365e9d191700000000b70f1999a91c831b3296e312fd98272031a515a69b2171965a1c2aa50534f33467a6d21b00000000b3109899110d2d1658a047190b9974226ca2e8a4072855a0b80d9ea2c231c4358ea65e1900000000890e6798f49e3b98c7a1e51b2e957925809bb6a06c2b44a2db9de89be62d7236b6a4e49700000000aa12549d9a20f71978137605429db420a2a86ca8440ec812582082a8993444358da8011a00000000ec152e9f1e220799f817da80c99e1224f6a8aea8171eee154a21a8a8fe33f0354da9629100000000cc124f9b328da88bada2cb193c999c2402a590a6f129eca2411017a53631693674a8771400000000a617409e3b222720400f5f09169eb220a0aa43aa369e55160c2275aa0035a93555aa761f000000009a19caa020240b8ef31de2974fa02d2518abe0a9bfa0491f2e238eaa843425367baa8d060000000091199ea03c22ea9b84127499d69ed3258aa942a9f0232b0f302144a950337d3658aaf494000000000918c29d0c22192422942f0e559d8322eaabffabc29d620c89218bab1a3506361cacf92300000000f91b12a17123811e841fc49b1fa04f2566ab3eabc3a43b214e2122aa4634b73615ac721e00000000c71a2da142220414821f5d9dc99c7425aba9adaba78fee1e2d1dbfa83f33133778ac581e00000000291dfaa1f9228c2600a01c1dfba11b27afac96ac739b309e602259ac04356936c8ac5d2600000000ed1b12a19220bf211f229d9e559e2d2783ab2fab6ca87823050e28a95f335c3797ac7c23000000000218039fd41fdc1ba021429e58902c2352a846acf3a25221bb9ba5a4f231cb3770ad8522000000007a1d23a253239f26979b071cfea1972677acdfac3fa33797f021e7aba434e23643adaf2600000000c41a43a0b91f702220245a9fbb9b312465a9c2ab34abbb25ea9806a586311c38ebac6b22000000004015639d5b1e1d19a623a49f401400202ca6f6ab63a89e24a59c0a9d8d302e3835ada91f0000000096189ea016229d243120fc90849f5c24d1aa48ac0ba9e5207c1f92a9de334a37c8ace2240000000008191f9f2f1e411f3a25219c42986f1f66a6c5aa10ad1027e696b09daa2f653855ac001d000000003814fe9ad71b43171024dc9d0d125c1c51a4acaac7aaac25269a141c882e613879acf811000000001320a1a1b925cf238e2221127fa11a937faac9ad87a4ec22e8243ca9c733893788aec0240000000027165d9eb91ff61d6425438f3794e90f49a5f9a9c7ac57260a912813472d7d38d0ab001e000000003a132a98b1172a1931219504ae839219d5a13ca62dace5237298d11ed7297a3801a98c950000000077150b990e95800db89cba184c9869228e1eac1f0924439b95918d1dd3318134f392900f00000000f216569afa9caf9dab192a179d980f25a61d3428a524c99ca19cb920922dac35b0a04a12000000006712da97cea3d99c6f20f31041957127141fc5287b26b695fc9d441e73298436b8a7129c00000000360f4999df1c991b1c96b811da9820202aa58aa516218f96371c27a50f34e43460a6b21b000000004e103c9b35911615f09f50171898f9224ba2049b5b26139f638a10a3fa317e353fa6e21900000000f812f59e86a36d19e69c0e1824957b28659b47222f2993a1109e94a14930a935cda47c9a00000000eb11199d8320611beb0bf708ee9c8520b7a846a8b70c8f0ddc1f6aa8a0343b3587a8971a000000008114c29e6f2189943014bc00619d14244aa904a7fe18e00f7a1f96a81734ca353ba97a180000000003126e9d239bb796c1a1ad1617965c25e3a5211994285fa29e1315a6eb31df353fa8c514000000007016779ddd21de207b8fe30d689d2420bbaa18aac59ef316bc2151aa0635a23565aa591f00000000611841a00d23991aac1a9f960c9f2c25aaabbaa8e0a2a91fad2139aa8c3412368baa6f18000000004518a7a0e0203099c7168a9b179dc126a9aa82a5bd15901c6e2089a9a8334f3669aaf090000000001c16c49cd8214d24ea96750c9d9cb3210eac9fab109f7f15622142ab1f35fa3516ac642300000000301aa1a0f8220821601a709a599e892562ac72a93ba66322171f81a95c34973630ac561f000000008d18eda06422be8df42045a06299b026caab00a82ea6c324b8155fa85833f8364eac0c1a000000000a19509f29221126a29ca418f89eb7249bac08ac0ca30b142221b0abfc3458368fac472500000000e01846a145235322a81c16985c98b025c5ac17a812aa4a241099c2a665333d377facf02100000000a714c29fdd22a19dee23df9f82150b2435abada4d4aabc26069d2fa0c931a53794ac1015000000001b1a09a09f2258262897e212a59fb82493ac38ac02a6c91e6320caaa9d34cc360aad6d25000000006016d4a0ae237b220f1db784be10132216acdba675ac2d26ba9cff996831033867ac0b1d000000003f0d459df522d9a13e24839c8f186b1b9ca98111f8ac9f2708975e21e92f15388bab20a000000000dd1afca0ab222f25d318a58516a07424d1ab78abf6a80a23351efda8f9333037dbac262400000000e415b6a0e9222320771dfd1cd713ab1c09aa31a3b9addb2649983a21092f4a383bab409b000000001e89909aec21ada0a820de192718df98b8a80223b9adaf26701456250c2d4538d2a9d6a200000000fd20f2a11f254a258220071b7fa22f1cafaa93ad3aa5c7216724e1a8c1338a3700afd8250000000017188ca10d22851b2721ae1ff618bd9ab0a6e79e42ae97260093f322602a81389aa9d08800000000c28b358a1a1cc79b1f98f221cc0a449bb7a2c12541ae4124e219142410218b388ca4d3a200000000ed14489978083510419c311876983c22401f2b233023439ac093081df73155346d96961400000000c416f59a129e619c241740144f993f25aa1de12c8f19239747985e21632d2435f09be395000000006f115f9500a20e19ec982110cc974a26089df92f7126af9c5598fb9b3d295b35aaa5e51500000000a40e2499d01c0f1c56965311ab981720fba4e4a48520a996741b2ca51e34cb342ba6c91b00000000480f939c30985518c49f04157395ff2277a08e236424bf9d848c17a327321d35fba4991800000000dd12a99faca44621c59bb2148e95bf27d78c782c6e271ea20098d3a18430973404a29594000000009d11d89c3320df1c988da00a849c2720a6a82da80809d188d61e58a8ab342c3580a8b21b00000000e211419ea01f0b181593230c709bb92312a9eca48e8bf58cc01c71a829349835fda81e1c00000000c40dcd9e55a09b1867a03415af1114253ba50a2814246da10d94eea52d32683510a77c1b000000009715019d6121b3213796200c9c9c911fceaadfa90f9f15183b2138aa0f35943556aa8f1f000000004d16d29e5720df203793d693e89d2825bbab63a74ea49b1f5c20f3a99334ef3540aa1e1b000000008e14a8a13a0d11210210ac9996946b2892aa50a062a5b91e0c1851aa78333e36b1a82b1b00000000ce147b9b6b218b24df99000e159c062120ac40ab339fff1639211dab2f35e4350bac1923000000009618929ec41ffb24e89d6793159ed025f6ac28a730a782225b1d10a97a345d36faab551f000000009215189f2d0b5924bd982c9da798492888acdb9f5ea9e02585983fa84a33c436dfaa240e000000000217f69db32167268d9e8918929d2524bdac8dab0da3f018f52067ab0f353a367faccd24000000003318e0a00f213727b6a26e1c599892260aaec3a15aaa3023769bd7a5d033e436ffab0821000000009713e39e731f8722f4a037175a0ed5256aad862760acac26e49b689ae831263730aa04a0000000001219429f4d2202278b9e7418e99e8224e1acb4abbfa57b1f6a20b1aac3349f36f2acfa24000000007b1828a2db23ed274aa55121f011ae2430aecb1d67ac4724769e5a18d43192370fab4118000000007206979e4924369849a4a221df18f51e44ad1b2dc0ad942488096824eb2f5e374ea644a300000000bc1aa7a048228b26949d8a1527a0872472aca4aa82a8ef23331ee0a82d34fb36dfac602300000000cd1920a3d424dc26cda62f24af14c52064adfc2527ad5b24929a92247f2f1138a5a97f9e000000000b90f99d8f2535a0dea66225791bc49921adfa2eecad3e1d73161e27752d793757a29ba2000000001f226ea14123c8275981e91da2a29f2088ab58adeba4c0213b247da91c34533719af7d2600000000aa1d43a42f243b25faa667246c186e977eaab12571ad1e26129959253d287e387fa86b9c0000000011872e9814241ca23da9ef26c21339a10da8e12f6dadf497b11d272501a215384a1c32a2000000002b15049b04133918689dff162b981a22332050245e221199ec87461d40321b342a0c7311000000007b165e9d189d5e204da46d177d931c24941e3130ed925f99b5102723442d37348f1f809600000000c40b129c54a2b2242b9f3a06490d3726c61a4d334a9b48993595c4182e29d0321519899800000000d40d5b99cd1c9a1c4e971710ee97ed1fbea474a4022049960d1b27a52e34b034e8a59e1b00000000980ee69de2955f1c7fa0fb129c93b5212b96fe26d721759caf0422a26032aa3492a2e6150000000088115ba1c4a2302433a32b11ac924e2551204f30bb24efa0e012d7993730f432481b7d98000000005d10759c1220e71d1c951f0aba9b381f96a809a844103290041e46a8b834183573a83c1c00000000990e3d9e0d1d801da399750e8e98a92267a8fea27a988693131a3ba83e3457357fa8b41c00000000ae81eaa017a2e92000a196156f1a712461a1732af896a8a0799bbaa56332ec342ba40c1e000000008214489c1e2134221199540fba9be61db2aad2a9549eb515e1201baa1a3581353aaa9b1f000000002f14f29c9d1abe23819c6b8fad9c6d2422ab3aa639a4aa1d3f1e95a9a334b235b2a9ed1c000000007a8acaa2d7a0ef25f400350cdd1b0b2954a9339901a906952ba02aab7c33f93586a4c52300000000c813799a6921a824739b7e0f3e9b6e2024ac22abd59da51535210fab3e35cc35efabbe2200000000b416829a218c8f27a6a23f09319e772502adaaa587a67e21791d0fa9aa340a364fab5e1f000000003a12069c4ba34b293ca5918138974b28d4ac2721c3a93d24769daba7ad333a36f8a8ad1b000000002115c49c21217026819f4e17b29c4f23b1ac71abf7a0801823215aab2c3511366cac5a2400000000bd18e59e05147c2949a63c1ef09c542780aef8a0eaa82c21cb9310a74a34773677abe7200000000024143a9c4da0e02a4baa2a223c945f26e5aef42a66aaaa21479b4d19c1323c3689a72d9f000000008b186a9e49225627e8a06c1ad09d8323faaca8ab42a4401db220c9aaf8346736e1acde2400000000a41bf8a19320712afda8a523cd991c27a7aff51f19aa37201e9e599d1d33ff361fab761e000000008b10b79f2020872aaaac4326ee17642310b02d2fb8aa439d83960a25fb303d362396f3a000000000c918a49fc62141275ba13d1b6d9e9923a3ac84aa15a71522c91e33a97634b236d3acbe2300000000a81e49a45e24eb2911aa7525d99be625a3af192686aa2a21d39c5a2251318e37fbaa1395000000004c0e26a108269f2980ad8b28191ccb1e84b0a930f1a9fba441914f27d12f4c36961fb39f000000004922cba2e3237628189e341e72a1f22279ac0aad89a30a2276248faa8a34f03606af822600000000bc20c0a51526112780aaf725a595d821daad1026f6a820261a9d2724202d493845ac6717000000007217faa21b298422faada4295f1b229938af87324fa859a612134c2718289636a61fdd9d0000000020154d9c8213251adf9d5516de9740223c218224da216d971680281d9832be331e16f6120000000040155ea0b4186e27d8a40a160d066021401ecd2ed411c09af71563243e2f35334d24ba920000000095090a9c9aa1992fbba6ac81ff0ef71d538854316d1fe59e341bc820432c65305f27831b00000000390d3e99da1cf71c3398590fb097cd1f7ca42ba49a1f6496961a29a54334913494a5451b00000000380d659f3815af1fb6a05a108f91b51fb61fe726781fb699251067a0c7323d3462a04214000000005c0deea2ad9f1b2b1ea6d90a7f95e521b225e62d5d1e2c9fc2148f22a7301732c3239e0d000000001c0f0a9cbc1f301fde98370cf799bd1d6ea80ea81b168094371d39a8c734023558a87d1c00000000930b799e921c1120069d7e0cb595a720c1a6dca1309673939518d7a75b3409351aa8711c000000009a82f4a17ea08224f8a2351299182d200c1cdb2942a0939df496e2a3e6326e3446a1431c00000000e0136b9b2d213822fd999310fb99d81a76aad3a9a39cee0c732000aa2a35683518aa0720000000002211219c51173b24909e928c749a7f21eda902a6f9a1011a131d1aa9be34623524a9ff1c00000000828d51a026a2f226cba0320d7b178a256ba7e01fa1a65f980c9b2da905344e3584a5b42100000000e81157986f217224529b82113e9ac21e0aac3eabc1997c0c6c211aab5435ad35adab32220000000060122d91189a752741a22e8ca89c7b235eacc2a665a4971e3c1e55a9e534b135b6aadf1f000000006211751a1ea8102c19a8f1956f9bb02682acc223d3a7b9207e982ba630348c358da8241e000000005c8dba963c202525929ca3848d995d225eac63abe4988e17e22061ab4835d73536ac142300000000d6134997069be828cca4f318429d2026bdad85a5eca50f1f441abba8bc340a368eab5d210000000029168e1cd4a9822e21ac8e20e59c732809af2c296ca81d1d939a959cb833a6359fa59d97000000005b170c9ea02228278aa1ae1a459cbc21e0ace8ab05a1c31977213aab36352336a2ac7824000000005417829dae1ca829b3a71a21f69c492757af7d9fe6a7611d12988aa5523476360fac382200000000b318068862a8812f37ae8326309b5828bfb0682d2ba7a6a17d9a72237132aa357d93eb9e0000000069137b9e76220a2734a27f1cc49a0221a2acd7aadca4691f0d20cca9d43454368face32300000000121caea19a23d028a8a867240ca0e827fdafc221b9a8e61f329a229e6833e7366daca12000000000981a1c9db2a0fa2efbae2629a8988227e0b1102fa6a533a62d9d102845311c36ec9b289e00000000732043a43f25502875a0a61bc79dd02425ad8bac56a04521242411ac0c357836a2aec126000000009721fba56528492012a9bb2585a10e2559af25291ea8bc256120b8a19031743761add12000000000ab1d4fa5bc2836295cae1c2b60992127d4b2d63271a593a7a6a05c2a752be236d7a4ec9a000000009615e89cd5160a1ac19ded151798ef21b7220d24f1219a975605a01cf6325233dc191d13000000004b1312a03621fc25c9a21f13f7966222fd24352b9d204999d7135a24ee308232442408130000000063105fa1ba9fa530de9d6a85e31886a0049fd230c2a3749ed51c042991298a2ff32aee1900000000ea0d7e990c1d291ddf98240e0e97ae1f36a415a4591f4796d31a35a5593473345ca5dc1a00000000840c71a0481dcf1f9da0330d99933c1d0524e125ce1c7196bd13809e3c33c533539efe13000000007d0619a49324a12afda4fa01cc957090c726ee2afc8ab29ad217e0245031cc3133253c18000000003f0ef39be31f7a1faa9a010dba984e1c36a817a8ec190497de1c3ba8d834ec3445a89c1c000000003609389f9b1e4920c09eaf095b94cb1cb1a489a2a213a993af1963a78334bc3493a73d1b00000000250158a38e1c9e242da403055d0fdd99a725fc28a7a077951a1443a03f33e133739f541700000000e811259a6d21e721569a64119a97291037aaefa9e498d9913520faa93c355035f8a9162000000000cc0b629d0c1ea8220c9ff581d2941e1971a8aea6159d6611651cafa8df341335b8a87c1c00000000208af8a07116a02514a4068c240f36938e9f1e20fba01b87c91802a640349634dda5f41b000000001310ce9506227d233998030c4998641bb2ab6cab1b14ee8e842118ab6b3588356bab5821000000009e81d396d81be2245a9f5b8d3296861a8daa95a832a07c18c81e8ea91b355a35e5a9f61e00000000fc8b3e9855a41f2ab4a6d392618cfd1c32a8df1aeda364175f1905a67234d13477a6561c00000000309ce31ca7167c1f821a6c9ca9819e2458ab07ab4023fb16e71d52ab4f357e35c8ab501f00000000d793328d211284253ea0ab92f09561220facc3a8cf9c6d1acc1de2a919358f35f2aa0b20000000001a88361e29aad52df2a957112c94b62457ac112432a64f182c17d0a46d34073558a6c71c000000008080b39b45236825be9e51128f95371f8aac2bacd48ffa14e821b3ab7935cd353aac0c230000000034910e98161f1827caa24918d396cf2134ad6ca8daa22a1a5b1d0aa90735c93528ab1f2100000000d210f12197ac5e3010ad9e21ea988a28e5af9e2ad6a7ef9ad7861e9b28343d35c3a5a11900000000f914c99d9b23c525bda0d61a3293211446acaaaba1a0fd197a21abaa5035d43500acbf2200000000c517e09f062317276ba5b120619ba321b2ade1a585a5db1b4a1c4ea7c734f73574ab0c2100000000fd14d0222baca63047ae31273c9ee2299ab1472d56a969a029992b237833ca3542a7c306000000005c20eaa3b4250e2708a1ee1917a03a2523add4acdd1ea519dc2531ad9335fe35fdadd82600000000961f2da33a25d21e4aa5be23ae0694956eac352513a89121f3235faa5834e3357aac6525000000003fa008236ba8d82b44abec28e29acc2883b2e932bfae212083a0522baf2fd5360aaca91c00000000ed15c19d0a1ad516e89c96159a97f1210d24b722ef2117981d13dc195233f632a01c5605000000001f13c9a2fc25362112a04b1349999d20352bfd246222f796081344248232ee305a24d713000000006a85de9da530ba9f5fa16310749ec2a3d230049f86a0e318ee19f32a8a2f91290429d51c00000000240edf98291d0c1d7e99ea0d4796591f15a436a4ae1f0e97dc1a5ca57334593435a5d31a00000000330d9da0cf1f481d71a0840c7196ce1ce12505243c1d9993fe13539ec5333c33809ebd1300000000fa01fda4a12a932419a47d06b29afc8aee2ac7267090cc953c183325cc315031e024d21700000000010daa9a7a1fe31ff39b3f0e0497ec1917a836a84e1cba989c1c45a8ec34d8343ba8de1c00000000af09c09e49209b1e389f3609a993a21389a2b1a4cb1c5b943d1b93a7bc34833463a7af190000000003052da49e248e1c58a325017795a7a0fc28a725dd995d0f5417739fe1333f3343a01a14000000006411569ae7216d21259ae811d991e498efa937aa29109a971620f8a950353c35faa9352000000000f5810c9fa8220c1e629dcc0b6611159daea671a81e19d2947c1cb8a81335df34afa8651c00000000068c14a4a0257116f8a0208a1b87fba01e208e9f3693240ff41bdda59634403402a6c91800000000030c39987d230622ce951310ee8e1b146cabb2ab641b499858216bab88356b3518ab8421000000005b8d5a9fe224d81bd3969e817c1832a095a88daa861a3296f61ee5a95a351b358ea9c81e00000000d392b4a61f2a55a43e98fc8b6417eda3df1a32a8fd1c618c561c77a6d134723405a65f19000000006c9c821a7c1fa716e31c309cfb16402307ab58ab9e24a981501fc8ab7e354f3552abe71d00000000ab923ea084252112328dd7936d1acf9cc3a80fac6122f0950b20f2aa8f351935e2a9cc1d000000005711f2a9d52d29aa361e1a884f1832a6112457acb6242c94c71c58a607356d34d0a42c17000000005112be9e68254523b39b8080fa14d48f2bac8aac371f8f950c233aaccd357935b3abe821000000004918caa21827161f0e9834912a1adaa26ca834adcf21d3961f2128abc93507350aa95b1d000000009e2110ad5e3097acf121d210ef9ad6a79e2ae5af8a28ea98a119c3a53d3528341e9bd78600000000d61abda0c5259b23c99df914fd19a1a0aaab46ac21143293bf2200acd4355035abaa7a2100000000b1206ba517270623e09fc517db1b85a5e1a5b2ada321619b0c2174abf735c7344ea74a1c00000000312747aea6302bacd022fd1469a056a9472d9ab1e2293c9ec30642a7ca3578332b23299900000000ee1908a10e27b425eaa35c20a519dd1ed4ac23ad3a2517a0d826fdadfe35933531addc2500000000be234aa5d21e3a252da3961f912113a835256eac9495ae0665257aace33558345faaf32300000000ec2844abd82b6ba808233fa02120bfaee93283b2cc28e29aa91c0aacd536af2f522b83a0000000005516df9d251a82134d9c20156d97da2182243c214022de97f6121e16be339832281d1680000000000a16d8a46e27b4185ea04015c09ad411cd2e401e60210d06ba924d2435333e2f6324f71500000000ac81bba6992f9aa10a9c9509e59e6d1f54315388f71dff0e831b5f276530432cc820341b00000000590f3398f71cda1c3e99390d64969a1f2ba47ca4cd1fb097451b94a59134433429a5961a000000005a10b6a0af1f3815659f380db699781fe726b61fb51f8f91421462a03d34c73267a0251000000000d90a1ea61b2bad9feea25c0d2c9f5d1ee62db225e5217f959e0dc3231732a7308f22c21400000000370cde98301fbc1f0a9c1c0f80941b160ea86ea8bd1df7997d1c58a80235c73439a8371d000000007e0c069d1120921c799e930b73933096dca1c1a6a720b595711c1aa809355b34d7a79518000000003512f8a282247ea0f4a19a82939d42a0db290c1c2d209918431c46a16e34e632e2a3f496000000009310fd9938222d216b9be013ee0ca39cd3a976aad81afb99072018aa68352a3500aa732000000000928c909e3b245117219c2211011af9a102a6eda97f21749aff1c24a96235be341aa9131d00000000320dcba0f22626a251a0828d5f98a1a6e01f6ba78a257b17b42184a54e3505342da90c9b000000008211529b72246f215798e8117c0cc1993eab0aacc21e3e9a3222adabad3554351aab6c21000000002e8c41a27527189a2d916012971e65a4c2a65eac7b23a89cdf1fb6aab135e53455a93c1e00000000f19519a8102c1ea8751a6211b920d3a7c22382acb0266f9b241e8da88c3530342ba67e9800000000a384929c25253c20ba965c8d8e17e49863ab5eac5d228d99142336acd735483561abe22000000000f318cca4e828069b4997d6130f1feca585a5bdad2026429d5d218eab0a36bc34bba8441a000000008e2021ac822ed4a98e1c29161d1d6ca82c2909af7328e59c9d979fa5a635b833959c939a00000000ae1a8aa12827a0220c9e5b17c31905a1e8abe0acbc21459c7824a2ac233636353aab7721000000001a21b3a7a829ae1c829d5417611de6a77d9f57af4927f69c38220fac763652348aa5129800000000832637ae812f62a80688b318a6a12ba7682dbfb05828309beb9e7d93aa35713272237d9a000000007f1c34a20a2776227b9e6913691fdca4d7aaa2ac0221c49ae3238fac5436d434cca90d20000000006724a8a8d0289a23aea1121ce61fb9a8c221fdafe8270ca0a1206dace7366833229e329a000000002629fbaefa2eb2a01c9d981a33a6a6a5102fe0b18227a898289eec9b1c36453110282d9d00000000a61b75a050283f2543a47320452156a08bac25add024c79dc126a2ae78360c3511ac242400000000bb2512a949206528fba59721bc251ea8252959af0e2585a1d12061ad74379031b8a16120000000001c2b5cae3629bc284fa5ab1d93a771a5d632d4b221276099ec9ad7a4e236752b5c2aa6a000000000ff16689d39180913049b2b1512995e225024332019222b987711240c1b344032461def87000000006d174da45e20189d5e9d7c165f99ed923130941e1c247d9380968f1f3734442d2723b410000000003a062b9fb22454a2129cc40b48994a9b4d33c61a3726490d89981519d0322e29c41835950000000017104e979a1ccd1c5b99d40d4996022074a4bea4ed1fee979e1be8a5b0342e3427a50d1b00000000fb127fa05f1ce295e69d980e759cd721fe262b96b5219c93e61592a2aa34603222a2af04000000002b1133a33024c4a25ba18811efa0bb244f3051204e25ac927d98481bf4323730d799e012000000001f0a1c95e71d1220759c5d103290441009a896a8381fba9b3c1c73a81835b83446a8041e00000000750ea399801d0d1d3d9e990e86937a98fea267a8a9228e98b41c7fa857353e343ba8131a00000000961500a1e92017a2eaa0ae81a8a0f896732a61a171246f1a0c1e2ba4ec346332baa5799b00000000540f119934221e21489c8214b515549ed2a9b2aae61dba9b9b1f3aaa81351a351baae120000000006b8f819cbe239d1af29c2f14aa1d39a43aa622ab6d24ad9ced1cb2a9b235a33495a93f1e00000000350cf400ef25d7a0caa27a8a069501a9339954a90b29dd1bc52386a4f9357c332aab2ba0000000007e0f739ba8246921799ac813a515d59d22ab24ac6e203e9bbe22efabcc353e350fab3521000000003f09a6a28f27218c829ab4167e2187a6aaa502ad7725319e5e1f4fab0a36aa340fa9791d0000000091813ca54b294ba3069c3a123d24c3a92721d4ac4b283897ad1bf8a83a36ad33aba7769d000000004e17819f70262121c49c21158018f7a071abb1ac4f23b29c5a246cac11362c355aab2321000000003c1e49a67c290514e59ebd182c21eaa8f8a080ae5427f09ce72077ab77364a3410a7cb93000000002a224baae02a4da03a9c2414aa2166aaf42ae5ae5f263c942d9f89a73c36c1324d19479b000000006c1ae8a0562749226a9e8b18401d42a4a8abfaac8323d09dde24e1ac6736f834c9aab22000000000a523fda8712a9320f8a1a41b372019aaf51fa7af1c27cd99761e1fabff361d33599d1e9e000000004326aaac872a2020b79f8b10439db8aa2d2f10b06423ee17f3a023963d36fb300a258396000000003d1b5ba14127c621a49fc918152215a784aaa3ac99236d9ebe23d3acb236763433a9c91e00000000752511aaeb295e2449a4a81e2a2186aa1926a3afe625d99b1395fbaa8e3751315a22d39c000000008b2880ad9f29082626a14c0efba4f1a9a93084b0cb1e191cb39f961f4c36d12f4f27419100000000341e189e7628e323cba249220a2289a30aad79acf22272a1822606aff0368a348faa762400000000f72580aa11271526c0a5bc202026f6a81026daadd821a595671745ac4938202d27241a9d00000000a429faad84221b29faa2721759a64fa8873238af22995f1bdd9da61f963618284c271213000000003118419c381064084899ed14439a30232b23401f3c22769894146b965534f731091dc0930000000040142417619c129ef59ac41623978f19e12caa1d3f254f99e395f09b2435632d5e214798000000002110ec980e1900a25f956f11af9c7126f92f089d4a26cc97e515aaa55b353d29fb9b559800000000531156960f1cd01c2499a40ea9968520e4a4fba41720ab98c91b2ba6cb341e342ca5741b000000000415c49f55183098939c480fbf9d64248e2377a0ff2273959918fba41d35273217a3848c00000000b214c59b4621aca4a99fdd121ea26e27782cd78cbf278e95959404a297348430d3a1009800000000a00a988ddf1c3320d89c9d11d18808092da8a6a82720849cb21b80a82c35ab3458a8d61e00000000230c15930b18a01f419ee211f58c8e8beca412a9b923709b1e1cfda89835293471a8c01c00000000341567a09b1855a0cd9ec40d6da114240a283ba51425af117c1b10a768352d32eea50d9400000000200c3796b3216121019d971515180f9fdfa9ceaa911f9c9c8f1f56aa94350f3538aa3b2100000000d6933793df205720d29e4d169b1f4ea463a7bbab2825e89d1e1b40aaef359334f3a95c2000000000ac99021011213a0da8a18e14b91e62a550a092aa6b2896942b1bb1a83e36783351aa0c1800000000000edf998b246b217b9bce14ff16339f40ab20ac0621159c19230bace4352f351dab3921000000006793e89dfb24c41f929e9618822230a728a7f6acd025159e551ffaab5d367a3410a95b1d000000002c9dbd9859242d0b189f9215e0255ea9db9f88ac4928a798240edfaac4364a333fa885980000000089188d9e6726b321f69d0217f0180da38dabbdac2524929dcd247fac3a360f3567abf520000000006e1cb6a237270f21e0a0331830235aaac3a10aae922659980821ffabe436d033d7a5769b000000003717f4a08722731fe39e9713ac2660ac86276aadd5255a0e04a030aa2637e831689ae49b0000000074188b9e02274d22429f12197b1fbfa5b4abe1ac8224e99efa24f2ac9f36c334b1aa6a200000000051214aa5ed27db2328a27b18472467accb1d30aeae24f01141180fab9237d4315a18769e00000000a22149a436984924979e72069424c0ad1b2d44adf51edf1844a34ea65e37eb2f68248809000000008a15949d8b264822a7a0bc1aef2382a8a4aa72ac872427a06023dfacfb362d34e0a8331e000000002f24cda6dc26d42420a3cd195b2427adfc2564adc520af147f9ea5a911387f2f9224929a000000006225dea635a08f25f99d0b903e1decadfa2e21adc499791b9ba257a27937752d1e27731600000000e91d5981c82741236ea11f22c021eba458ad88ab9f20a2a27d2619af53371c347da93b24000000006724faa63b252f2443a4aa1d1e2671adb1257eaa6e976c186b9c7fa87e383d285925129900000000ef263da91ca214242e981187f4976dade12f0da839a1c21332a24a1c153801a22725b11d00000000ba18b89c800d0e950b997715439b0924ac1f8e1e69224c98900ff3928134d3318d1d9591000000002a17ab19af9dfa9c569af216c99ca5243428a61d0f259d984a12b0a0ac35922db920a19c00000000f3106f20d99ccea3da976712b6957b26c528141f71274195129cb8a784367329441efc9d00000000b8111c96991bdf1c4999360f8f9616218aa52aa52020da98b21b60a6e4340f3427a5371c000000005017f09f161535913c9b4e10139f5b26049b4ba2f9221898e2193fa67e35fa3110a3638a000000000e18e69c6d1986a3f59ef81293a12f294722659b7b2824957c9acda4a935493094a1109e00000000f708eb0b611b8320199deb118f0db70c46a8b7a88520ee9c971a87a83b35a0346aa8dc1f00000000bc00301489946f21c29e8114e00ffe1804a74aa91424619d7a183ba9ca35173496a87a1f00000000ad16c1a1b796239b6e9d03125fa294282119e3a55c251796c5143fa8df35eb3115a69e1300000000e30d7b8fde20dd21779d7016f316c59e18aabbaa2420689d591f65aaa235063551aabc21000000009f96ac1a991a0d2341a06118a91fe0a2baa8aaab2c250c9f6f188baa12368c3439aaad21000000008a9bc7163099e020a7a04518901cbd1582a5a9aac126179df09069aa4f36a83389a96e2000000000750cea964d24d821c49c1c167f15109f9fab0eacb3219d9c642316acfa351f3542ab622100000000709a601a0821f822a1a0301a63223ba672a962ac8925599e561f30ac97365c3481a9171f0000000045a0f420be8d6422eda08d18c3242ea600a8caabb02662990c1a4eacf83658335fa8b81500000000a418a29c11262922509f0a190b140ca308ac9bacb724f89e47258fac5836fc34b0ab2221000000001698a81c5322452346a1e0184a2412aa17a8c5acb0255c98f0217fac3d376533c2a6109900000000df9fee23a19ddd22c29fa714bc26d4aaada435ab0b248215101594aca537c9312fa0069d00000000e212289758269f2209a01b1ac91e02a638ac93acb824a59f6d250aadcc369d34caaa632000000000b7840f1d7b22ae23d4a060162d2675acdba616ac1322be100b1d67ac03386831ff99ba9c00000000839c3e24d9a1f522459d3f0d9f27f8ac81119ca96b1b8f1820a08bab1538e92f5e21089700000000a685d3182f25ab22fca0dd1a0a23f6a878abd1ab742416a02624dbac3037f933fda8351e00000000fd1c771d2320e922b6a0e415db26b9ad31a309aaab1cd713409b3bab4a38092f3a21499800000000de19a820ada0ec21909a1e89af26b9ad0223b8a8df982718d6a2d2a945380c2d5625701400000000071b82204a251f25f2a1fd20c7213aa593adafaa2f1c7fa2d82500af8a37c133e1a8672400000000ae1f2721851b0d228ca11718972642aee79eb0a6bd9af618d0889aa98138602af322009300000000f2211f98c79b1a1c358ac28b412441aec125b7a2449bcc0ad3a28ca48b3810211424e219000000005119ae9c1e0c7a9218996515339c71244f1bed1d6122e098df0a09109734b1316a1ed59000000000231c229cb69c299949996a16f89e00280521641d6624bd99bc0b4c9edd35b82d5920459c000000001a191d9823931f9d5e935d0ffa9bd328c01a2a9a4b23968e5413ed9cfe369a26751c7f9d00000000eb123496831ba91c1999b90f72969b2115a631a52720fe98d21b67a6f33405342aa5591c00000000471958a02c16190d9899b41055a00728e8a46ca273220b995e198da6c435c2319ea2bf0d00000000621b7ba16f98dd9e9a98e70e0ca2412b63a0cd9b7e256e9568988fa46f36ed2d279cb09d000000007b057813f7199a20549dab12c712450e6ca8a2a8b420429d011a8da84435993482a8582000000000da80f91707991e222e9fec15ee15171eaea8f6a81224c99e62914da9f035fe33a8a84a2100000000a81999a28f8d2f8c639bdc12d9a2e82984a609a5a024499906146ea8683638311ea5c710000000005f09400f27203b22409ea6175516369e43aaa0aab220169e761f55aaa935003575aa0c2200000000e297f31d0b8e2024caa09a19491fbfa0e0a918ab2d254fa08d067baa253684348eaa2e23000000008099e412009c4122a3a09719e10fe82340a98ca9d525dd9e259556aa7c36513345a93521000000002f0e229419240c22c29d0918610cc29dffabeaab8322559df9231cac06361a358bab892100000000c49b841f811e712312a1f91b3b21c3a43eab66ab4f251fa0721e15acb736463422aa4e2100000000609d891fc413462230a1cb1af61e2190ababaca97625cc9c4f1e77ac12373f33c0a8341d000000001c1d00a08c26f922faa1291d309e739b96acafac1b27fba15d26c8ac6936043559ac6022000000009d9e1f22bf21922012a1ed1b78236ca82fab83ab2d27559e7c2397ac5c375f3328a9050e00000000489ea521c71bda1f059f04185721faa245ac53a82d235b90822270adcb37f231a6a4b79b00000000071c979b9f26532323a27a1d37973fa3dfac77ac9726fea1af2643ade236a434e7abf021000000005a9f20247022b91f43a0c41abb2534abc2ab65a93124bb9b6b22ebac1c38863106a5ea9800000000a69fa72319195c1e639d41159e2463a8f6ab2ca601204014a81f35ad2e388d300b9da59c00000000fc9031209d2416229ea09618e5200ba948acd1aa5c24849fe224c8ac4a37de3392a97c1f00000000219c3a25411f2f1e1f9f0819102710adc5aa66a66f1f4298001d55ac6538aa2fb09de69600000000dc9d10244017d81bff9a3914ac25c7aaabaa51a45c1c0d12f61179ac6138882e141c259a0000000028128e22cf23b925a0a11320ec2288a4c9ad7faa1e937fa1c02488ae8937c7333ca9e82400000000438f6425f61db91f5d9e27165726c7acf9a949a5e90f3794001ed0ab7d38472d28130a91000000007f0431212919b2172a983a13e5232dac3ca6d5a19219a9838d9501a97a38d729d11e72980000000045194b9c290ca78ec7985915c69c7324c9115c1e3422fb98010db81b9534b131e01dee9000000000211ced9e820c3d9cb6996116159c00281c9e50205f243c99a59c2421db35b92d591d2b9900000000e119ff9c1917879e9989470d989c7c295e9d661c7a23c48f32955118fe36a726a09abe9d00000000e3127196d21b5a1cfd98b70f32969b2167a62aa527201999831b15a6f334053431a5a91c00000000471955a05e19b80d0b99b31058a007288ea69ea2742298992d16e8a4c435c2316ca2110d00000000e51b44a2e497db9d2e95890ec7a16c2bb6a4e89b792567983b98b6a07236e62d809bf49e000000007605c812011a5820429daa127813440e8da882a8b420549df7196ca844359934a2a89a2000000000da80ee1562914a21c99eec15f817171e4da9a8a812242e9f0799aea8f035fe33f6a81e2200000000cb19eca2771441103c99cc12ada2f12974a817a59c244f9ba88b90a66936363102a5328d000000005f095516761f0c22169ea617400f369e55aa75aab220409e272043aaa9350035a0aa3b2200000000e297491f8d062e234fa09a19f31dbfa07baa8eaa2d25caa00b8ee0a92536843418ab20240000000074992b0ff4943021d69e91198412f02358aa44a9d3259ea0ea9b42a97d3650338aa93c22000000002f0e620cf9238921559d09182294c29d1cac8bab8322c29d1924ffab06361a35eaab0c2200000000c49b3b21721e4e211fa0f91b841fc3a415ac22aa4f2512a1811e3eabb736463466ab7123000000005d9dee1e581e2d1dc99cc71a821fa78f78acbfa874252da10414adab13373f33aba94222000000001c1d309e5d266022fba1291d00a0739bc8ac59ac1b27faa18c2696ac69360435afacf922000000009d9e78237c23050e559eed1b1f226ca897ac28a92d2712a1bf212fab5c375f3383ab922000000000429e52218522bb9b58900218a021f3a270ada5a42c23039fdc1b46accb37f23152a8d41f00000000071c3797af26f021fea17a1d979b3fa343ade7ab972623a29f26dface236a43477ac5323000000005a9fbb256b22ea98bb9bc41a202434abebac06a5312443a07022c2ab1c38863165a9b91f00000000a49f9e24a91fa59c40144015a62363a835ad0a9d0020639d1d19f6ab2e388d302ca65b1e00000000fc90e520e2247c1f849f961831200ba9c8ac92a95c249ea09d2448ac4a37de33d1aa162200000000219c1027001de696429808193a2510ad55acb09d6f1f1f9f411fc5aa6538aa2f66a62f1e00000000dc9dac25f811269a0d1238141024c7aa79ac141c5c1cfe9a4317acaa6138882e51a4d71b000000002112ec22c024e8247fa113208e2287a488ae3ca91a93a1a1cf23c9ad8937c7337faab92500000000438f5726001e0a91379427166425c7acd0ab2813e90f5d9ef61df9a97d38472d49a5b91f000000009504e5238c957298ae833a1331212dac01a9d11e92192a982a193ca67a38d729d5a1b11700000000ba18439b900f95914c987715b89c0924f3928d1d69220b99800dac1f8134d3318e1e0e95000000002a17c99c4a12a19c9d98f216ab19a524b0a0b9200f25569aaf9d3428ac35922da61dfa9c00000000f310b695129cfc9d419567126f207b26b8a7441e7127da97d99cc52884367329141fcea300000000b8118f96b21b371cda98360f1c96162160a627a520204999991b8aa5e4340f342aa5df1c000000005017139fe219638a18984e10f09f5b263fa610a3f9223c9b1615049b7e35fa314ba23591000000000e1893a17c9a109e2495f812e69c2f29cda494a17b28f59e6d194722a9354930659b86a300000000f7088f0d971adc1fee9ceb11eb0bb70c87a86aa88520199d611b46a83b35a034b7a8832000000000bc00e00f7a187a1f619d81143014fe183ba996a81424c29e899404a7ca3517344aa96f2100000000ad165fa2c5149e1317960312c1a194283fa815a65c256e9db7962119df35eb31e3a5239b00000000e30df316591fbc21689d70167b8fc59e65aa51aa2420779dde2018aaa2350635bbaadd21000000009f96a91f6f18ad210c9f6118ac1ae0a28baa39aa2c2541a0991abaa812368c34aaab0d23000000008a9b901cf0906e20179d4518c716bd1569aa89a9c126a7a0309982a54f36a833a9aae02000000000750c7f15642362219d9c1c16ea96109f16ac42abb321c49c4d249fabfa351f350eacd82100000000709a6322561f171f599e301a601a3ba630ac81a98925a1a0082172a997365c3462acf8220000000045a0c3240c1ab81562998d18f4202ea64eac5fa8b026eda0be8d00a8f8365833caab642200000000a4180b1447252221f89e0a19a29c0ca38facb0abb724509f112608ac5836fc349bac29220000000016984a24f02110995c98e018a81c12aa7facc2a6b02546a1532217a83d376533c5ac452300000000df9fbc261015069d8215a714ee23d4aa94ac2fa00b24c29fa19dada4a537c93135abdd2200000000e212c91e6d256320a59f1b1a289702a60aadcaaab82409a0582638accc369d3493ac9f2200000000b7842d260b1dba9cbe1060160f1d75ac67acff991322d4a07b22dba60338683116acae2300000000839c9f2720a008978f183f0d3e24f8ac8bab5e216b1b459dd9a181111538e92f9ca9f52200000000a5850a232624351e16a0dd1ad318f6a8dbacfda87424fca02f2578ab3037f933d1abab2200000000fd1cdb26409b4998d713e415771db9ad3bab3a21ab1cb6a0232031a34a38092f09aae92200000000de19af26d6a2701427181e89a820b9add2a95625df98909aada0022345380c2db8a8ec2100000000071bc721d82567247fa2fd2082203aa500afe1a82f1cf2a14a2593ad8a37c133afaa1f2500000000ae1f9726d0880093f6181718272142ae9aa9f322bd9a8ca1851be79e8138602ab0a60d2200000000f2214124d3a2e219cc0ac28b1f9841ae8ca41424449b358ac79bc1258b381021b7a21a1c000000003118439a9614c0937698ed14419c30236d96081d3c22489935102b235534f731401f78080000000040142397e39547984f99c41624178f19f09b5e213f25f59a619ce12c2435632daa1d129e000000002110af9ce5155598cc976f11ec987126aaa5fb9b4a265f950e19f92f5b353d29089d00a2000000005311a996c91b741bab98a40e569685202ba62ca5172024990f1ce4a4cb341e34fba4d01c000000000415bf9d9918848c7395480fc49f6424fba417a3ff22939c55188e231d35273277a0309800000000b2141ea2959400988e95dd12c59b6e2704a2d3a1bf27a99f4621782c97348430d78caca400000000a00ad188b21bd61e849c9d11988d080980a858a82720d89cdf1c2da82c35ab34a6a8332000000000230cf58c1e1cc01c709be21115938e8bfda871a8b923419e0b18eca49835293412a9a01f0000000034156da17c1b0d94af11c40d67a0142410a7eea51425cd9e9b180a2868352d323ba555a000000000200c15188f1f3b219c9c971537960f9f56aa38aa911f019db321dfa994350f35ceaa612100000000d6939b1f1e1b5c20e89d4d1637934ea440aaf3a92825d29edf2063a7ef359334bbab572000000000ac99b91e2b1b0c1896948e14021062a5b1a851aa6b28a8a1112150a03e36783392aa3a0d00000000000eff1619233921159cce14df99339f0bac1dab06217b9b8b2440abe4352f3520ac6b210000000067938222551f5b1d159e9618e89d30a7faab10a9d025929efb2428a75d367a34f6acc41f000000002c9de025240e8598a7989215bd985ea9dfaa3fa84928189f5924db9fc4364a3388ac2d0b000000008918f018cd24f520929d02178d9e0da37fac67ab2524f69d67268dab3a360f35bdacb321000000006e1c30230821769b59983318b6a25aaaffabd7a59226e0a03727c3a1e436d0330aae0f21000000003717ac2604a0e49b5a0e9713f4a060ac30aa689ad525e39e872286272637e8316aad731f0000000074187b1ffa246a20e99e12198b9ebfa5f2acb1aa8224429f0227b4ab9f36c334e1ac4d2200000000512147244118769ef0117b184aa567ac0fab5a18ae2428a2ed27cb1d9237d43130aedb2300000000a221942444a38809df18720649a4c0ad4ea66824f51e979e36981b2d5e37eb2f44ad4924000000008a15ef236023331e27a0bc1a949d82a8dface0a88724a7a08b26a4aafb362d3472ac4822000000002f245b247f9e929aaf14cd19cda627ada5a99224c52020a3dc26fc2511387f2f64add4240000000062253e1d9ba27316791b0b90dea6ecad57a21e27c499f99d35a0fa2e7937752d21ad8f2500000000e91dc0217d263b24a2a21f225981eba419af7da99f206ea1c82758ad53371c3488ab41230000000067241e266b9c12996c18aa1dfaa671ad7fa859256e9743a43b25b1257e383d287eaa2f2400000000ef26f49732a2b11dc21311873da96dad4a1c272539a12e981ca2e12f153801a20da8142400000000ff1611997311ec872b982b15689d5e222a0c461d1a22049b391850241b34403233200413000000006d175f998096b5107d937b164da4ed928f1f27231c245e9d5e2031303734442d941e189d000000003a06489989983595490dc40b2b9f4a9b1519c4183726129cb2244d33d0322e29c61a54a200000000171049969e1b0d1bee97d40d4e970220e8a527a5ed1f5b999a1c74a4b0342e34bea4cd1c00000000fb12759ce615af049c93980e7fa0d72192a222a2b521e69d5f1cfe26aa3460322b96e295000000002b11efa07d98e012ac92881133a3bb24481bd7994e255ba130244f30f43237305120c4a2000000001f0a32903c1c041eba9b5d101c95441073a846a8381f759ce71d09a81835b83496a8122000000000750e8693b41c131a8e98990ea3997a987fa83ba8a9223d9e801dfea257353e3467a80d1d000000009615a8a00c1e799b6f1aae8100a1f8962ba4baa57124eaa0e920732aec34633261a117a200000000540fb5159b1fe120ba9b82141199549e3aaa1baae61d489c3422d2a981351a35b2aa1e21000000006b8faa1ded1c3f1ead9c2f14819c39a4b2a995a96d24f29cbe233aa6b235a33422ab9d1a00000000350c0695c5232ba0dd1b7a8af40001a986a42aab0b29caa2ef253399f9357c3354a9d7a0000000007e0fa515be2235213e9bc813739bd59defab0fab6e20799aa82422abcc353e3524ac6921000000003f097e215e1f791d319eb416a6a287a64fab0fa97725829a8f27aaa50a36aa3402ad218c0000000091813d24ad1b769d38973a123ca5c3a9f8a8aba74b28069c4b2927213a36ad33d4ac4ba3000000004e1780185a242321b29c2115819ff7a06cac5aab4f23c49c702671ab11362c35b1ac2121000000003c1e2c21e720cb93f09cbd1849a6eaa877ab10a75427e59e7c29f8a077364a3480ae0514000000002a22aa212d9f479b3c9424144baa66aa89a74d195f263a9ce02af42a3c36c132e5ae4da0000000006c1a401dde24b220d09d8b18e8a042a4e1acc9aa83236a9e5627a8ab6736f834faac492200000000a5233720761e1e9ecd99a41bfda819aa1fab599d1c27f8a1712af51fff361d33a7af9320000000004326439df3a08396ee178b10aaacb8aa23960a256423b79f872a2d2f3d36fb3010b02020000000003d1b1522be23c91e6d9ec9185ba115a7d3ac33a99923a49f412784aab2367634a3acc6210000000075252a211395d39cd99ba81e11aa86aafbaa5a22e62549a4eb2919268e375131a3af5e24000000008b28fba4b39f4191191c4c0e80adf1a9961f4f27cb1e26a19f29a9304c36d12f84b0082600000000341e0a228226762472a14922189e89a306af8faaf222cba276280aadf0368a3479ace32300000000f725202667171a9da595bc2080aaf6a845ac2724d821c0a5112710264938202ddaad152600000000a42959a6dd9d12135f1b7217faad4fa8a61f4c272299faa2842287329636182838af1b290000000055166d97f6121680de972015df9dda211e16281d40224d9c251a8224be3398323c218213000000000a16c09aba92f7150d064015d8a4d4114d24632460215ea06e27cd2e35333e2f401eb41800000000ac81e59e831b341bff0e9509bba66d1f5f27c820f71d0a9c992f54316530432c53889aa100000000590f6496451b961ab097390d33989a1f94a529a5cd1f3e99f71c2ba4913443347ca4da1c000000005a10b699421425108f91380db6a0781f62a067a0b51f659faf1fe7263d34c732b61f381500000000d90a2c9f9e0dc2147f955c0d1ea65d1ec3238f22e521eea21b2be62d1732a730b225ad9f00000000370c80947d1c371df7991c0fde981b1658a839a8bd1d0a9c301f0ea80235c7346ea8bc1f000000007e0c7393711c9518b595930b069d30961aa8d7a7a720799e1120dca109355b34c1a6921c000000003512939d431cf49699189a82f8a242a046a1e2a32d20f4a18224db296e34e6320c1c7ea0000000009310ee0c07207320fb99e013fd99a39c18aa00aad81a6b9b3822d3a968352a3576aa2d2100000000928c011aff1c131d749a2211909ef9a124a91aa97f21219c3b2402a66235be34eda9511700000000320d5f98b4210c9b7b17828dcba0a1a684a52da98a2551a0f226e01f4e3505346ba726a20000000082117c0c32226c213e9ae811529bc199adab1aabc21e579872243eabad3554350aac6f21000000002e8c971edf1f3c1ea89c601241a265a4b6aa55a97b232d917527c2a6b135e5345eac189a00000000f195b920241e7e986f9b621119a8d3a78da82ba6b026751a102cc2238c35303482ac1ea800000000a3848e171423e2208d995c8d929ce49836ac61ab5d22ba96252563abd73548355eac3c2000000000f3180f1f5d21441a429dd613cca4eca58eabbba820264997e82885a50a36bc34bdad069b000000008e201d1d9d97939ae59c291621ac6ca89fa5959c73288e1c822e2c29a635b83309afd4a900000000ae1ac31978247721459c5b178aa105a1a2ac3aabbc210c9e2827e8ab23363635e0aca022000000001a21611d38221298f69c5417b3a7e6a70fac8aa54927829da8297d9f7636523457afae1c000000008326a6a1eb9e7d9a309bb31837ae2ba77d93722358280688812f682daa357132bfb062a8000000007f1c691fe3230d20c49a691334a2dca48faccca902217b9e0a27d7aa5436d434a2ac7622000000006724e61fa120329a0ca0121ca8a8b9a86dac229ee827aea1d028c221e7366833fdaf9a2300000000262933a6289e2d9da898981afbaea6a5ec9b102882271c9dfa2e102f1c364531e0b1b2a000000000a61b4521c1262424c79d732075a056a0a2ae11acd02443a450288bac78360c3525ad3f2500000000bb25bc25d120612085a1972112a91ea861adb8a10e25fba5492025297437903159af6528000000001c2b93a7ec9aa6a06099ab1d5cae71a5d7a45c2a21274fa53629d632e236752bd4b2bc2800000000ed159a971d13560517989615c19df121dc19a01cef21e89c0a1a0d245233f632b722d516000000001f1349990813d713f7964b13c9a29d2044245a24622212a0fc25352b8232ee30fd243621000000006a85749eee19d51ce3186310de9dc2a3f32a042986a05fa1a530d2308a2f9129049fba9f00000000240e4796dc1ad31a0e97ea0ddf98591f5ca535a5ae1f7e99291d15a47334593436a40c1d00000000330d7196fe13bd139993840c9da0ce1c539e809e3c1d71a0cf1fe125c5333c330524481d00000000fa01b29a3c18d217cc957d06fda4fc8a3325e024709019a4a12aee2acc315031c726932400000000010d04979c1cde1cba983f0eaa9aec1945a83ba84e1cf39b7a1f17a8ec34d83436a8e31f00000000af09a9933d1baf195b943609c09ea21393a763a7cb1c389f492089a2bc348334b1a49b1e000000000305779554171a145d0f25012da4a7a0739f43a0dd9958a39e24fc28e1333f33a7258e1c000000006411d991162035209a97e811569ae498f8a9faa92910259ae721efa950353c3537aa6d2100000000f58166117c1c651cd294cc0b0c9f159db8a8afa81e19629da822aea61335df3471a80c1e00000000068c1b87f41bc918240f208a14a4fba0dda502a63693f8a0a0251e20963440348e9f711600000000030cee8e582184214998131039981b146bab18ab641bce957d236cab88356b35b2ab0622000000005b8d7c18f61ec81e32969e815a9f32a0e5a98ea9861ad396e22495a85a351b358daad81b00000000d3926417561c5f19618cfc8bb4a6eda377a605a6fd1c3e981f2adf1ad134723432a855a4000000006c9cfb16501fe71da981309c821a4023c8ab52ab9e24e31c7c1f07ab7e354f3558aba71600000000ab926d1a0b20cc1df095d7933ea0cf9cf2aae2a96122328d8425c3a88f3519350fac21120000000057114f18c71c2c172c941a88f2a932a658a6d0a4b624361ed52d112407356d3457ac29aa000000005112fa140c23e8218f958080be9ed48f3aacb3ab371fb39b68252baccd3579358aac45230000000049182a1a1f215b1dd3963491caa2daa228ab0aa9cf210e9818276ca8c935073534ad161f000000009e21ef9aa119d786ea98d21010add6a7c3a51e9b8a28f1215e309e2a3d352834e5af97ac00000000d61afd19bf227a213293f914bda0a1a000acabaa2114c99dc525aaabd435503546ac9b2300000000b120db1b0c214a1c619bc5176ba585a574ab4ea7a321e09f1727e1a5f735c734b2ad062300000000312769a0c30629993c9efd1447ae56a942a72b23e229d022a630472dca3578339ab12bac00000000ee19a519d826dc2517a05c2008a1dd1efdad31ad3a25eaa30e27d4acfe35933523adb42500000000be2391216525f323ae06961f4aa513a87aac5faa94952da3d21e3525e33558346eac3a2500000000ec282120a91c83a0e39a3fa044abbfae0aac512bcc280923d82be932d536af2f83b26ba800000000
