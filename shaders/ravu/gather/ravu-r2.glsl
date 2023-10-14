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

//!DESC RAVU (step1, luma, r2)
//!HOOK LUMA
//!BIND HOOKED
//!BIND ravu_lut2
//!SAVE ravu_int11
//!WHEN HOOKED.w OUTPUT.w / 0.833333 < HOOKED.h OUTPUT.h / 0.833333 < *
vec4 hook() {
vec4 gathered0 = HOOKED_mul * textureGatherOffset(HOOKED_raw, HOOKED_pos, ivec2(-1, -1), 0);
vec4 gathered1 = HOOKED_mul * textureGatherOffset(HOOKED_raw, HOOKED_pos, ivec2(-1, 1), 0);
vec4 gathered2 = HOOKED_mul * textureGatherOffset(HOOKED_raw, HOOKED_pos, ivec2(1, -1), 0);
vec4 gathered3 = HOOKED_mul * textureGatherOffset(HOOKED_raw, HOOKED_pos, ivec2(1, 1), 0);
vec3 abd = vec3(0.0);
float gx, gy;
gx = (gathered0[2]-gathered0[3]);
gy = (gathered0[0]-gathered0[3]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (gathered0[1]-gathered0[0]);
gy = (gathered1[3]-gathered0[3])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered1[2]-gathered1[3]);
gy = (gathered1[0]-gathered0[0])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered1[1]-gathered1[0]);
gy = (gathered1[0]-gathered1[3]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (gathered2[3]-gathered0[3])/2.0;
gy = (gathered0[1]-gathered0[2]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered2[0]-gathered0[0])/2.0;
gy = (gathered1[2]-gathered0[2])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (gathered3[3]-gathered1[3])/2.0;
gy = (gathered1[1]-gathered0[1])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (gathered3[0]-gathered1[0])/2.0;
gy = (gathered1[1]-gathered1[2]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered2[2]-gathered0[2])/2.0;
gy = (gathered2[0]-gathered2[3]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered2[1]-gathered0[1])/2.0;
gy = (gathered3[3]-gathered2[3])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (gathered3[2]-gathered1[2])/2.0;
gy = (gathered3[0]-gathered2[0])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (gathered3[1]-gathered1[1])/2.0;
gy = (gathered3[0]-gathered3[3]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered2[2]-gathered2[3]);
gy = (gathered2[1]-gathered2[2]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (gathered2[1]-gathered2[0]);
gy = (gathered3[2]-gathered2[2])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered3[2]-gathered3[3]);
gy = (gathered3[1]-gathered2[1])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered3[1]-gathered3[0]);
gy = (gathered3[1]-gathered3[2]);
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
w = texture(ravu_lut2, vec2(0.25, coord_y));
res += (gathered0[3] + gathered3[1]) * w[0];
res += (gathered0[0] + gathered3[2]) * w[1];
res += (gathered1[3] + gathered2[1]) * w[2];
res += (gathered1[0] + gathered2[2]) * w[3];
w = texture(ravu_lut2, vec2(0.75, coord_y));
res += (gathered0[2] + gathered3[0]) * w[0];
res += (gathered0[1] + gathered3[3]) * w[1];
res += (gathered1[2] + gathered2[0]) * w[2];
res += (gathered1[1] + gathered2[3]) * w[3];
res = clamp(res, 0.0, 1.0);
return vec4(res, 0.0, 0.0, 0.0);
}
//!DESC RAVU (step2, luma, r2)
//!HOOK LUMA
//!BIND HOOKED
//!BIND ravu_lut2
//!BIND ravu_int11
//!SAVE ravu_int10
//!WHEN HOOKED.w OUTPUT.w / 0.833333 < HOOKED.h OUTPUT.h / 0.833333 < *
vec4 hook() {
vec4 gathered0 = HOOKED_mul * textureGatherOffset(HOOKED_raw, HOOKED_pos, ivec2(0, -1), 0);
vec4 gathered1 = ravu_int11_mul * textureGatherOffset(ravu_int11_raw, ravu_int11_pos, ivec2(-1, -1), 0);
float sample0 = HOOKED_texOff(vec2(-1.0, 0.0)).x;
float sample2 = HOOKED_texOff(vec2(0.0, 1.0)).x;
float sample7 = HOOKED_texOff(vec2(1.0, 1.0)).x;
float sample15 = HOOKED_texOff(vec2(2.0, 0.0)).x;
float sample12 = ravu_int11_texOff(vec2(0.0, -2.0)).x;
float sample3 = ravu_int11_texOff(vec2(0.0, 1.0)).x;
float sample14 = ravu_int11_texOff(vec2(1.0, -1.0)).x;
float sample11 = ravu_int11_texOff(vec2(1.0, 0.0)).x;
vec3 abd = vec3(0.0);
float gx, gy;
gx = (gathered1[3]-sample0);
gy = (gathered1[0]-sample0);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (gathered0[0]-gathered1[0]);
gy = (sample2-sample0)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered1[1]-sample2);
gy = (sample3-gathered1[0])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample7-sample3);
gy = (sample3-sample2);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (gathered0[3]-sample0)/2.0;
gy = (gathered0[0]-gathered1[3]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered1[2]-gathered1[0])/2.0;
gy = (gathered1[1]-gathered1[3])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (gathered0[1]-sample2)/2.0;
gy = (sample7-gathered0[0])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (sample11-sample3)/2.0;
gy = (sample7-gathered1[1]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample12-gathered1[3])/2.0;
gy = (gathered1[2]-gathered0[3]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered0[2]-gathered0[0])/2.0;
gy = (gathered0[1]-gathered0[3])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (sample14-gathered1[1])/2.0;
gy = (sample11-gathered1[2])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (sample15-sample7)/2.0;
gy = (sample11-gathered0[1]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample12-gathered0[3]);
gy = (gathered0[2]-sample12);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (gathered0[2]-gathered1[2]);
gy = (sample14-sample12)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample14-gathered0[1]);
gy = (sample15-gathered0[2])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample15-sample11);
gy = (sample15-sample14);
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
w = texture(ravu_lut2, vec2(0.25, coord_y));
res += (sample0 + sample15) * w[0];
res += (gathered1[0] + sample14) * w[1];
res += (sample2 + gathered0[2]) * w[2];
res += (sample3 + sample12) * w[3];
w = texture(ravu_lut2, vec2(0.75, coord_y));
res += (gathered1[3] + sample11) * w[0];
res += (gathered0[0] + gathered0[1]) * w[1];
res += (gathered1[1] + gathered1[2]) * w[2];
res += (sample7 + gathered0[3]) * w[3];
res = clamp(res, 0.0, 1.0);
return vec4(res, 0.0, 0.0, 0.0);
}
//!DESC RAVU (step3, luma, r2)
//!HOOK LUMA
//!BIND HOOKED
//!BIND ravu_lut2
//!BIND ravu_int11
//!SAVE ravu_int01
//!WHEN HOOKED.w OUTPUT.w / 0.833333 < HOOKED.h OUTPUT.h / 0.833333 < *
vec4 hook() {
vec4 gathered0 = HOOKED_mul * textureGatherOffset(HOOKED_raw, HOOKED_pos, ivec2(-1, 0), 0);
vec4 gathered1 = ravu_int11_mul * textureGatherOffset(ravu_int11_raw, ravu_int11_pos, ivec2(-1, -1), 0);
float sample12 = HOOKED_texOff(vec2(0.0, -1.0)).x;
float sample3 = HOOKED_texOff(vec2(0.0, 2.0)).x;
float sample14 = HOOKED_texOff(vec2(1.0, 0.0)).x;
float sample11 = HOOKED_texOff(vec2(1.0, 1.0)).x;
float sample0 = ravu_int11_texOff(vec2(-2.0, 0.0)).x;
float sample2 = ravu_int11_texOff(vec2(-1.0, 1.0)).x;
float sample7 = ravu_int11_texOff(vec2(0.0, 1.0)).x;
float sample15 = ravu_int11_texOff(vec2(1.0, 0.0)).x;
vec3 abd = vec3(0.0);
float gx, gy;
gx = (gathered0[3]-sample0);
gy = (gathered0[0]-sample0);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (gathered1[0]-gathered0[0]);
gy = (sample2-sample0)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered0[1]-sample2);
gy = (sample3-gathered0[0])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample7-sample3);
gy = (sample3-sample2);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (gathered1[3]-sample0)/2.0;
gy = (gathered1[0]-gathered0[3]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered0[2]-gathered0[0])/2.0;
gy = (gathered0[1]-gathered0[3])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (gathered1[1]-sample2)/2.0;
gy = (sample7-gathered1[0])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (sample11-sample3)/2.0;
gy = (sample7-gathered0[1]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample12-gathered0[3])/2.0;
gy = (gathered0[2]-gathered1[3]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (gathered1[2]-gathered1[0])/2.0;
gy = (gathered1[1]-gathered1[3])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (sample14-gathered0[1])/2.0;
gy = (sample11-gathered0[2])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (sample15-sample7)/2.0;
gy = (sample11-gathered1[1]);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample12-gathered1[3]);
gy = (gathered1[2]-sample12);
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (gathered1[2]-gathered0[2]);
gy = (sample14-sample12)/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample14-gathered1[1]);
gy = (sample15-gathered1[2])/2.0;
abd += vec3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample15-sample11);
gy = (sample15-sample14);
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
w = texture(ravu_lut2, vec2(0.25, coord_y));
res += (sample0 + sample15) * w[0];
res += (gathered0[0] + sample14) * w[1];
res += (sample2 + gathered1[2]) * w[2];
res += (sample3 + sample12) * w[3];
w = texture(ravu_lut2, vec2(0.75, coord_y));
res += (gathered0[3] + sample11) * w[0];
res += (gathered1[0] + gathered1[1]) * w[1];
res += (gathered0[1] + gathered0[2]) * w[2];
res += (sample7 + gathered1[3]) * w[3];
res = clamp(res, 0.0, 1.0);
return vec4(res, 0.0, 0.0, 0.0);
}
//!DESC RAVU (step4, luma, r2)
//!HOOK LUMA
//!BIND HOOKED
//!BIND ravu_int01
//!BIND ravu_int10
//!BIND ravu_int11
//!WIDTH 2 HOOKED.w *
//!HEIGHT 2 HOOKED.h *
//!OFFSET -0.500000 -0.500000
//!WHEN HOOKED.w OUTPUT.w / 0.833333 < HOOKED.h OUTPUT.h / 0.833333 < *
vec4 hook() {
    vec2 dir = fract(HOOKED_pos * HOOKED_size) - 0.5;
    if (dir.x < 0.0) {
        if (dir.y < 0.0)
            return HOOKED_texOff(-dir);
        return ravu_int01_texOff(-dir);
    } else {
        if (dir.y < 0.0)
            return ravu_int10_texOff(-dir);
        return ravu_int11_texOff(-dir);
    }
}
//!TEXTURE ravu_lut2
//!SIZE 2 648
//!FORMAT rgba16f
//!FILTER NEAREST
6fd8e43bf0484e3cfeec3d3cd92b1f3c58f38d3c3744583e6b9b593e9d28943caa9f4e3b7cb7ec3c51c81a3d841c15bc00cde33c6e2c383edf651e3eb2849d3d69330ebddf17933dc7fa98bd9c41b23d8317a4bc359e0d3e7868a23eb314773c0bac263ccf5f95bc64e299bcb3a4373c63886cbc4e96893e88548d3ebf9e70bcd20e03bb2b6d7bbbd10b62bbaf10f7b8bfc8873c3d4a673e9fcf743e6a70e43c128dd3bcdfcaf63cab66de3ca4527abccc3b633c254b473ec0c2533ef45d8c3d9892923bde74ccbc08f3d0bc4969923b59f6dfbc771a973eb7689a3e9b13e4bcba5c213bfbe5c1bc8727d7bc85cfbc37cde896bcca35903eb27f973e85783fbcd7cfb5bcc7ae4e3bd2e366ba9d6ecfbcfd6d823c7caa723e248a803ed21d293d008bcc3935fff4bce6dcf9bce2e2e6ba83840dbdc3d69e3ea281a23e9c3200bd9b0c8b3b9046fdbccbcc0ebd617272bbec2d14bd623a9b3e3b11a33ea7f2a5bcd894aabb4eb090bc6774bbbc527998bca4ba91bc2c7d8c3ebfde943e313f8b3c1ae8be3bd5e023bd658026bd7f66c93a0ae141bd8a28a73e5f5bab3e3c0526bd98030b3ce6e710bd1e4628bd7bdb25bc11ef59bdb121a03e86a9a93ea91a52bcc809693c3a60b5bc453704bd34c0fdbc57c083bd4e51923e3c3c9f3e68991e3d263c2b3c92742dbd234f2ebdde28a03bec8b58bdc651a73ebd4dae3e9b8037bd4196833c0b211bbdf0be37bd425786bc883a92bde8cc9f3e01f3ae3e9e8f2d3a7aa9153d98d38dbccb23fdbc54ab8abdf9c106be07a58f3e4da2a43e10fbde3d90a5313b2eb928bd0c2329bde4a9dabb53d75abdec67a93e0acfb33e41c92cbdce54553cec3c03bdbd4631bd9ae804bdfcb2a2bd41199d3e7ea9b13e1fcea63cd2f1573dd67c0dbb569192bcf42fecbd04cf42be4102873e3124a13ec425473e40b6c5bb074510bd96e90fbdb19baabc592140bd88dfa33edc6ab63e8efe03bddb133e3bd849a6bc007726bd819b50bd7f1d9abd6669953efd55b73e17960c3d181a623d596c663cec2338bb24741cbe9f6d4cbea9e4753e56c0a03eb16f6d3e74a5f03bd99f57bd7c357abdddfb5ebbeba11dbd2347a63e78a8ba3e872a28bd5b5c8dba286ebcbc727374bd62333fbd68f916bdbd618b3edafcb83e7a4d0a3da2a1f73cd33c073d1f7c9b3b735126be7add07beecef0e3edb1cb23e0066753e2b11543c142c723b22a840bb6cbf553c7c7ce63b7ab6523e05ff7f3e48382b3c404867bb645a873c90cb8c3c262143bc8857de3a7fe3d03d0c9d823edcc3fb3d2c1f583d517d073c1205f6ba9731aebdf7bb363d5238283e4b4a2a3e9a531a3edab41f3c58c396bcb915b2bccfe65a3ccd2c77bcbbd7863eff37923ef5d989bc6bde893a48eee0bb3ca90fbc8674dc3ab50ed73b3801593e0c8b853e6896093d6fe884bb0f4f2a3c62ac473c52a008bc298fba3cbdf8183e96f8493eb19cf63ddcde953b5fecc8bc3d23eabca76cbe3bd519dcbc836c943eb4589e3ee23cf2bca7a4c83b9de9c4bcb47f01bd8a3da13aa410d9bc38e78a3e259fa03e515227bc70700ebca670d1bb38e06abce24c87bc4c0601bb18a3643e9ded893ecd3f623d04b71b3b547af7bc3bf906bd2453efba234314bda6349c3ebd29a63ec374fcbcd70c423c5189f6bc17c129bd565da2bbfbe347bdea6f953ea944ac3ea0c973bc61f32a3cf045acbc61fb14bd69d280bcf9033fbdaab6873e225ea43e9750be3cdd80203c5ab525bd88e739bd1080b33aa43151bde46da33ee953b03e20fc1abd81a2b53cd19806bde85341bd78fc97bcddea9fbd6375973e7ff7b33ee142ec3b0005153d8842bdbc07453dbd16390cbd1ea4ddbdeeb58b3ee155b23e26045e3df2ab7c3ccd0f37bdd5a255bd9abfb43bc62665bdb274a23ebc93b63ef92c2cbd0a1a063d2022fabc244e3bbdcea123bd4e9be0bddd20903ef36abb3e13bf3a3d336d4a3d39763fbc204b08bd1cd695bdee1224bea823803ee190b53e8f07fe3d7eb54e3c62ee2fbdcf7f68bdb8f38fbbba5673bd565ea13e9dd8bf3e93a11fbdec69083d6317abbc095307bd19918fbdd24703be3330823ee328c13ed0f6b23dbe791b3df7e8103c93eec83b84f9ecbd63b332be59d7523e8dd9ac3e3f71463e672d133cacdc10bdefdf6abd15f579bcc31055bd737f943e7fc0c83e8d00ffbcbc1bb53c3e3493bb8feba7bc696abcbd1379f4bdcbe04f3ec9b9cc3ef921e43d13e4ab3c4275df3cd438083da20c0abe09c82ebe7787293e86c4ab3ec94a643e80da103c572bedbcc6e0c5bd8a9d3c3b89e6f1bc1267883e61f1d43e93791fbd314a70bbc3327d3c1ff42fbd501d97bd26c682bdebe6f93d228bd33e06d3083e2afd103c013c323c77538f3d8a2b09be6966dfbdfcc12a3dc48ab43eb59d843ef36d6d3cb63be339855337bcf54ed03cf62d503c56a7443ea79e813e94b5533c26d1a33b5482813c1a041a3c84397cbb63c8133c7fabdd3d63a0713e509ef63d3a8d263c7b664cbc7c5384ba4af88c3c37fb753cde19b13d5050343e408a553ed724133c46a092bc1768c7bcb7a6823c8fcb7ebc2bbc833e9c16973e72f79fbc93ec4b3badeb34bcbc2248bc9241e63b5f812cbbaa934a3e0a15903eb98d153d7e0fd639d2e49eba44fa36ba3a68713bcae7df392001123e0422523e0431193e628f933bc7bac6bcd88801bde94d003cb42fd5bc1c7b913ec4b2a23e537604bd684f133cf3c2d0bc61e61bbded16a83b09e800bd6c1e863e53cbaa3e34d36fbcf80121bb12ae2dbcefd7b1bc093e23bc3882a4bc3d4e5b3e3d2b963e5de56a3db219543b4189fabc745910bd33d037baad8d10bdf171993e17d4a93ed66606bdecd6803ca4f1f8bca54647bd84c1a4ba236c55bda3ee8f3e9e15b63eab77a4bc9e8c793c72e7b0bc663f3abdee5818bcf07864bdd1e4813ed6c5b23eab27663c6c552d3c2b7725bd4b2949bd28767f3b534848bdccf59f3e20b6b43e54c329bd8af7c63cd719ffbc2f3160bd01df56bc834f9abdc9308f3eb50fbf3effac36bb84c9013d6cb9b2bcdf9d67bd2f4896bc529dbdbd1123843eb32fc13e53f3b53c5905893c54fb31bddb2c74bd2cec073c0f1e5fbdf4b29d3e3c9fbd3ef6c83bbdcaf6ea3c5fa2b9bc15bc64bd47bbfcbc578dbcbdcf39813e7ea2cb3e964fb93cffd3003d81e90cbcafd333bd75cb3ebdd774e0bd277d663e9ae1c83ec6ed743dfce0863cfda326bd3c3686bd90cf94ba39436fbd83f6993e03e9c83e807233bd86b3c13cc0c082bb75c64abd200363bdcc58bbbdc6c24b3e510cde3ee18b343d5628713cfd54373c384fd0bba815b0bd9f4cccbd1643213ebca7ce3e7532d73d5fd1583c7a1df2bcadc68ebd703d3bbcf6f145bd5d88873e1fb3d63ec9b21cbd43294c3c42d96d3cc2ea0bbd15a0a2bd63f097bde073043ed093f23e151d6c3d962b793bd2f4a33c74329d3c164dd1bddcb7b7bdbf4cd93d6df1d83e50dff33d6ef2133c83ab71bc34c6e7bd8cd0c03b91d1bbbc0caa6e3ed0ede83e514d55bd4fc006bc34d2c83c0929a5bc5063b8bd5f32babc0924fa3ccf04053f2a2e883d8db3abbb3182513c4f205f3d90eee8bd7c7844bd9ab075bb73f2f33ea904023e27ae213c96ea83bbd7ac12bcb461d43ce139413cfbd03e3e7f878f3e0947a8bab2faad3af0a8913c16e7d23b6f46bcbccec752baed0e683d4e54a33ee40dfb3d6b4d45ba55aae23ba772aebb8723053d2f66a9bcaa2ce23da8408e3e9cdfca3dccfc023ca9118cbc892ee3bc1e38a03c237178bc9aad803e82f99b3e78afc0bcbdf6d13b847875bcacaaa2bc6444823ccfc8dabbd8da423e76d39e3ef348993cf64c063c06f34fbc329cccbc80a4e83c29464cbcee7f313e80438a3e97ad8f3d7284723b3358c2bc9ed210bd0df4293cd5c8c5bce5ce8e3e1ae0a63e283a12bd5fbd1a3c9812d0bc6ab437bdc96f3c3c1e1401bd5661813ea2e7b43e7282cebc75347d3ada7f6bbc88c8eabcdb77643b2f3cd7bc2a13573e3e36a43e69a70b3d64b7333b459cf8bcd7a719bdd9fa513a7a3606bde662963eaf8bad3e9acb11bdf327763cbba7f1bc362962bd9c4ca53bd91240bd4f578a3e6b4abf3e703104bd171d803cf19db4bcfc275abd8d20093af81f57bde7117a3ebd9fbe3e1d0d9fbb62f61f3c322120bdc74557bd0f93d93bd3a235bd91a49b3e7679b93e6b163fbdcc929c3cca0de6bc12a67fbd5a171dbb4ecb6fbd4409873e4fd2c93e84b8d1bcb3fdcc3c16e4a3bcabe586bdaf407dbbb31092bdab7f7a3e85a8cd3e793b28bc86a9833cd5da27bddf0683bdb039313c505d4ebd9ba4983ef7d3c33ed6a155bd21df943c38ca6dbceefd8fbd0e2d4abcc1c97cbd37ea693e7459db3e374184bc4abd9e3c898b22bb2bd981bd5359b2bcd20e93bdb9a9503e365adc3e2071c23b3989903c3f2620bd6c3b8ebd0e08e03a1cca60bd6079943e8f37cf3e21654fbd6e7f323c11c9113cd71f9abd4825e2bcd71951bdcd6f2a3ee387f53e0f9142bcedc2b23b8d31a53c658d47bd012940bd24e067bdaba0063eefb4ef3e7ff6dc3c1fe1703c8ee3cebcb11d98bde72025bc34d831bdeed57b3efb3fe13e3ec242bd3fce423b71f4d13cefac86bd1c8a47bdbd7612bd9588d43de9fb053fdbe0b4bb7f9bb7bac730e33cc8290abd8c9a78bd44dd33bd3393a43ddc59ff3ecfd0063d90ad073ce762e9bb0505e6bdc3337b3b0cfeaabc8467553edff6f63e1e1f80bd49f8f2bb8868eb3c7bf02cbd6b4e91bdb26382bb0c26f03c07fa0f3fa488863b3f21a2bb495d993c9bf13cb97a5aa4bd41268dbc0cfe643b8b8b0b3ff691103de36f673c43f9b0b8c8351cbc00c0a83c55a2d53b6c1f453ec987903e6032d2bb0e40923ca6c3f73b161c81bc88297bbb963e94bba6d8a03dc7b7b53e39a0853d5c3e5c3c0fd9b83c76cc64bbf87285bec6b0943da752db3d4360083fbcba803cc794ea3b6aba81bcdc7d01bdf026c63c785972bc9c4d7b3eeadba03ec714ebbc2831a93b29bb5abc81add9bc1e68d53c051e24bc8a4d3f3e3d9aac3eaea9aabbcefd5e3ca651b5bc076984bce7859c3cb024e3bbd42b243e63ecab3e3d5a863cf2702b3b0558b5bc0c9622bd206b623c060ab4bc87b18b3e6f0fab3e731222bd0647063c59fac6bc71b751bde321a23c44a6e0bcb986783e2011be3ed6be1fbd32245a3b045b95bc203e04bd1233a43ca9a5d1bc50384f3e86f9b03eb9a99a3b38d6913a754debbcecff25bdc43d4c3b9847efbc8029933eb934b13eddf920bdd491343c3d90dcbc273d7bbd338c4d3c797712bde7cc833e3006c83e812343bd2e4e6d3c616bc4bc94ad72bd154a613c396e2dbd0a46733e219ec73e85bbf6bc316acd3b3fd80ebd918868bd000e1f3c5a021bbddc5c963ef892be3e398c56bd2949343cab7abfbc88f88cbdb725fe3b14fb1abd4a477c3e3cdad33e8f1c48bd7618963c60669abcb3f297bd22152b3c4b3045bd14666f3ec0bed73ef4162fbd6253643c32221bbda3f089bdcaf1613cdab638bd9db6933ec236c93ef64171bdd3e8093cd44d29bc06fda2bd8596913b1a690fbdb80a5a3ed6a0e53ef8274abd5f45433cf238f4ba06e8a2bddd6e993a13f52abdb779483ee28ae83ed17323bdb11a923c49f01ebdf66290bda1e0613b650250bdb52e903e2e4ad43ee4396bbd18f9653b205fe73bd714b2bda8268dbb950bcebc9d6b293e13e1fb3e362e53bde243483bec48823c6a349fbde10c3bbcba1cf3bc1c84103ec980fb3e030505bde87c703c6ad1c8bccd7a99bd9f4f07bcb2c117bd5ddd6f3ef8b8e83e836870bd06cf79375c7f903cb60fa7bd2a9babbcd3ad86bc1b94f83d1997063f24a53bbdf88184baabb0b73cdf408dbd9934bdbcfb09bbbca5d5d53db183033f36f3c9bcff3d853b31e602bb374de0bdbb24c43a59aa5fbcefa2473e9c36003f7c059cbd145668bb10ed983cb3d277bdc5902abd0cc80dbb5800873d5b6d0c3f1c0fcfbcb9546ebbbc14a13c35c434bd286c27bdab7838bc45f04e3d8897093f7dfafdbbe7fe383cb002133c02c132bc6347d13cdf5f1e3bac9c373e012e983e30f262bc9ce3093cd2d6663a350ddbbc35266c3d967ec13bb308db3df5fcb73e07734bbc82430c3bedb4383d7c8a6bbc91d5873d0c983dbd97d97a3dc6d2c73e36cb90bb30a2cd3b176767bc73a512bdfa42f13c66ef5fbc3a2b753e4a88a53ee6c90ebd42dc9e3bed8338bc173801bdefb11d3d200e37bc3fc4353ef431b73eea22cabc179a853bd9f33cbc42c328bc1550303daebbcabb389afb3d8a65bc3e697b22bc9c14913a1538a2bc224e35bdc2a2923c802d9ebc1d73883e572baf3eb94c35bd8c06c33b35fcabbc2ef569bdb681eb3cdeb3b1bccc916c3eab31c63eff2859bd10df8f3badae96bc1b1c0cbd811c053d8819a2bc05843c3efc10c03e4860c2bc89ebb4ba1afbc8bcce4839bdf929df3bc239ccbce58b8e3e2dd0b53e393b35bdb6c4c63b6044b2bc600b8abd061ba73c63a6c5bcdc7d783e0081d03eb62c81bddf282f3c7fa0b4bcffc97fbdf0fade3cb5bfd7bcaefa5f3ef811d13e0cc85dbd9e760a3bbbcaeabca08581bdbdba723cf235f3bc10248f3eeccec53e63e27abde68a7d3b9d268abca04498bde4df853c8089a5bcf2d1673e12dadd3ed53f8cbd4136323c47be86bc3685a3bd19c2c63c22d0c1bcb272603ee3addf3e6eeb91bdb4ed163c1dd607bda05a94bdb5f59e3c267711bd7ab08d3e5a76cf3e34358ebde301f43a8cb10cbcd79ba5bd9414653c98b57fbcff064d3eea94eb3e87ab91bd11bfdc3bb1e6dabbb2a8acbd1d328b3c45dd8fbc7106493e6e2fec3ea31495bdca86873cb99424bd03db91bd700ef73b6e4137bd40a28c3e6e56d93e396f89bd7d52273a477e95ba2fc5a6bdc161813b9af931bc97fe2d3e6b20fa3e3f898ebd65fc5f3bbb75203ad5f2a4bdba3ed93be86147bc4ca7283ea2e9f73ecaea88bd3212453c69d4d6bc493d9cbdccd257bbfc17f6bcd3326c3e275bee3e903d94bd68c2453a6cdb3e3b685c97bd23cd5cbc7ba800bc7ef30e3ee060033f84ca7abda7b9e73a2318703b781b94bdfbaf99bb2c7512bc3a0d0d3e7e63003fd7a170bde427943a9852cfbb997ad1bdf398b3b88fa420bc7c53513e2419013f7b0fbbbdbcd5e1b91feda33b064b6abdefb217bdf74a13bb34c9be3d7f190a3fa9b126bd638c143a1c166c3b33693cbd4cb6aebc9ebca9bbf11ca43d1362053fba7206bdd59f213c6018ca3b6bdf9bbc413d033d480a333cc4cd2a3e28359d3ea66d62bcc1e5bf3bb80e6b3beabd00bd0dcb993d9de1e23a5e08d53d299cc03ee78e0fbdf9fa963a23ec4cbd8f6e94bcec379b3db0b0523dde648f3d9d3fcd3e2ef7febca70dc73bdf1f53bc339a16bd1c9a003d89c15bbce767733e32aaa63e6b1a1abdb0038e3b216f1bbced38f0bc2174313dbe1b1fbc74ce313eaee2b93ea7c412bdde66953b3dc4b2bb9b80aabc8e0c663de91429bc8f55f33d45dac13e46b1b0bc986a883a65669cbc3b1237bd2c54963c608fa0bc1038883e486caf3e0d0337bda039bb3b2b84adbcbce15cbdfde1f13cdebda7bc61b56b3e7cbac63ed37e6dbd456a8c3bd4d09abc08ead3bcc9b40d3d5fe090bc77b13a3e284bc13e8f9314bd92b9b9bafe4acbbc89fa35bd811ee43bbb13c8bcbe6e8e3ee5efb53e38013abd8f13c33b9d05c4bc2cc581bd82d9a83c9550b0bc0926783e5bb2d03e60a28abd555f2c3cec77d4bc37fe5fbd727be23cec9ab1bc3c585f3e4569d13e7ffc80bdfa24093b89ecf2bcfb0c7bbd352d733c5581eabcd71c8f3e86d6c53e4d9a81bd4a927a3badd2a4bc847e8cbd8a85863cda3f89bc45aa673eb2efdd3e208698bd9760303c632cc0bc485b92bd20f9c73c82fb84bc6524603ebbd3df3ecdfca3bd99a7163c1f5111bd90648ebde08b9f3c05b507bdb7a58d3e9287cf3e6c8594bdd550f13a36a77ebcc1d591bd9edb653ce9b10bbc0cec4c3e58a3eb3e4ac5a5bd49dcda3bf4fd8ebc2c4d95bd76c78b3c7132d7bbb6db483e8e44ec3e76e9acbdf284873c743f37bd007289bd7230f73b459324bd91a18c3e8a57d93e55dd91bd185b263afbcf31bc288b8ebd056c813b8b2f94ba70fa2d3ee821fa3e12caa6bd7ab35e3bb4e246bc7af488bd6bb0d93ba6282a3a879a283e39eff73e1406a5bdf20d453c7a13f6bcb73f94bd4b0658bbb4d1d6bc82316c3ec05cee3e8e3e9cbd5534453ac9a100bc5cc57abd80d75cbcc52c3f3b5df20e3ee860033ff35d97bd22c4e63ad65212bc86a070bd77a299bb110b713b24090d3e3d64003fd52294bd3534933ab17920bc830abbbd36de73b89efecebb294c513e8817013f4279d1bd2543e1b9b96713bb0cb026bd8fb317bd13e4a33b82c9be3d65190a3f3a496abdb21f143a788ca9bb8e6d06bd12bbaebc391a6c3b311aa43d3f62053fca6d3cbde36f673c55a2d53b6032d2bb00c0a83c3cf9b0b86c1f453ec987903ec8351cbc0e40923c953e94bb39a0853d88297bbba6c3f73ba6d8a03dc7b7b53e161c81bc5a3e5c3cc6b0943dbbba803cf87285be11d9b83ca752db3d4360083f73cc64bbc794ea3b785972bcc714ebbcf026c63c6aba81bc9c4d7b3eeadba03edc7d01bd2831a93b051e24bcaea9aabb1e68d53c29bb5abc8a4d3f3e3d9aac3e81add9bcd1fd5e3ca724e3bb0e5a863c11869c3c7951b5bcd32b243e62ecab3e1b6984bcf2702b3b060ab4bc731222bd206b623c0558b5bc87b18b3e6f0fab3e0c9622bd0647063c44a6e0bcd6be1fbde021a23c59fac6bcb986783e2011be3e71b751bd32245a3ba9a5d1bcb9a99a3b1233a43c045b95bc50384f3e86f9b03e203e04bd38d6913a9847efbcddf920bdc43d4c3b754debbc8029933eb934b13eecff25bdd491343c797712bd812343bd338c4d3c3d90dcbce7cc833e3006c83e273d7bbd2e4e6d3c396e2dbd85bbf6bc154a613c616bc4bc0a46733e219ec73e94ad72bd336acd3b5b021bbd388c56bd010e1f3c3ed80ebddc5c963ef792be3e918868bd2949343c14fb1abd8f1c48bdb725fe3bab7abfbc4a477c3e3cdad33e88f88cbd7618963c4b3045bdf4162fbd22152b3c60669abc14666f3ec0bed73eb3f297bd6253643cdab638bdf64171bdcaf1613c32221bbd9db6933ec236c93ea3f089bdd3e8093c1a690fbdf8274abd8596913bd44d29bcb80a5a3ed6a0e53e06fda2bd5f45433c13f52abdd17323bdcc6e993ae938f4bab779483ee28ae83e06e8a2bdb11a923c650250bde4396bbda1e0613b49f01ebdb52e903e2e4ad43ef66290bd18f9653b950bcebc362e53bda8268dbb205fe73b9d6b293e13e1fb3ed714b2bde043483bba1cf3bc030505bde30c3bbcec48823c1c84103ec980fb3e6a349fbde87c703cb2c117bd836870bd9f4f07bc6ad1c8bc5ddd6f3ef8b8e83ecd7a99bd06cf7937d3ad86bc24a53bbd2a9babbc5c7f903c1b94f83d1997063fb60fa7bdf88184bafb09bbbc36f3c9bc9934bdbcacb0b73ca5d5d53db183033fdf408dbdff3d853b59aa5fbc7c059cbdbb24c43a31e602bbefa2473e9c36003f374de0bd145668bb0cc80dbb1c0fcfbcc5902abd10ed983c5800873d5b6d0c3fb3d277bdb9546ebbab7838bc7dfafdbb286c27bdbc14a13c45f04e3d8897093f35c434bda8e8203cc048173ce59f3bbb258ecc3c22a916bb7f34423e38e68e3ebb94f9bb5965ae3a91dd53ba1c11fb3d4737bcbc10b1913cd3f6673d1b55a33e10ecd23b928985ba7b92aebc38d0ca3df901043da245f43b4901e33d96568e3eb766abbb912a033c633e79bc7cc9c0bc7400a03ce2e98bbc8eb5803e77f59b3e72f3e2bc68f6d13b65c8dabbb448993c8a44823c067975bce6da423e75d39e3ebaaaa2bc434d063cf6464cbcb8ad8f3d01a4e83cfbf34fbcfa7f313e7c438a3e9e9bccbcbea0723b16d9c5bcbe3a12bd6de3293c2354c2bc41d08e3e42dfa63ea9cd10bd5ebd1a3c1c1401bd7b82cebcd86f3c3c9812d0bc5661813ea2e7b43e6bb437bd75347d3a2f3cd7bc69a70b3ddb77643bda7f6bbc2a13573e3e36a43e88c8eabcdcb7333ba13606bd93cb11bd56f6513a439cf8bcee62963ea98bad3ebca719bdf327763cd91240bd703104bd9c4ca53bbba7f1bc4f578a3e6b4abf3e362962bd171d803cf81f57bd1d0d9fbb8d20093af19db4bce7117a3ebd9fbe3efc275abd62f61f3cd3a235bd6b163fbd0f93d93b322120bd91a49b3e7679b93ec74557bdcc929c3c4ecb6fbd84b8d1bc5a171dbbca0de6bc4409873e4fd2c93e12a67fbdb3fdcc3cb31092bd793b28bcaf407dbb16e4a3bcab7f7a3e85a8cd3eabe586bd86a9833c505d4ebdd6a155bdb039313cd5da27bd9ba4983ef7d3c33edf0683bd21df943cc1c97cbd374184bc0e2d4abc38ca6dbc37ea693e7459db3eeefd8fbd4abd9e3cd20e93bd2071c23b5359b2bc898b22bbb9a9503e365adc3e2bd981bd3989903c1cca60bd21654fbd0e08e03a3f2620bd6079943e8f37cf3e6c3b8ebd6e7f323cd71951bd0f9142bc4825e2bc11c9113ccd6f2a3ee387f53ed71f9abdedc2b23b24e067bd7ff6dc3c012940bd8d31a53caba0063eefb4ef3e658d47bd1fe1703c34d831bd3ec242bde72025bc8ee3cebceed57b3efb3fe13eb11d98bd3fce423bbd7612bddbe0b4bb1c8a47bd71f4d13c9588d43de9fb053fefac86bd939bb7ba45dd33bdced0063d8b9a78bdc930e33c3493a43ddb59ff3ec9290abd90ad073c0cfeaabc1e1f80bdc3337b3be762e9bb8467553edff6f63e0505e6bd49f8f2bbb26382bba488863b6b4e91bd8868eb3c0c26f03c07fa0f3f7bf02cbd3f21a2bb41268dbcf691103d7a5aa4bd495d993c0cfe643b8b8b0b3f9bf13cb9f0436e3c6b647e3cea0e6b3c8d68d93ce621a4ba02f7403e7368823e968252bc54bca33ba8cb133cb69bf63dc58b7cbbbf79813cf8b3dd3d4a9f713e8c131a3c07b9263cf831763cc98a553e70e08c3c66824cbcbe16b13d5850343eb08b84ba05f3123cd6f27dbc79dd9fbc8eea823cbdc592bc30b3833e181b973ee5abc7bce4ed4b3bc5812cbbcc8d153dec40e63b5ceb34bc9a934a3e0e15903eb72248bc0f12d6398aefdf39f830193e2f6a713bc1e69eba1e01123e1422523e000637ba257f933b601ed5bceb7504bde161003c3abec6bc9579913eb2b3a23e5e8e01bd6a4f133c0ce800bd21d36fbcdd16a83bf4c2d0bc6c1e863e53cbaa3e61e61bbde50121bb4582a4bc64e56a3d0f3e23bc13ae2dbc404e5b3e3c2b963ef0d7b1bc1719543b818d10bde06606bdd3ca37ba3e89fabce871993e1ed4a93e925910bdecd6803c236c55bdab77a4bc84c1a4baa4f1f8bca3ee8f3e9e15b63ea54647bd9e8c793cf07864bdab27663cee5818bc72e7b0bcd1e4813ed6c5b23e663f3abd6c552d3c534848bd54c329bd28767f3b2b7725bdccf59f3e20b6b43e4b2949bd8af7c63c834f9abdffac36bb01df56bcd719ffbcc9308f3eb50fbf3e2f3160bd84c9013d529dbdbd53f3b53c2f4896bc6cb9b2bc1123843eb32fc13edf9d67bd5905893c0f1e5fbdf6c83bbd2cec073c54fb31bdf4b29d3e3c9fbd3edb2c74bdcaf6ea3c578dbcbd964fb93c47bbfcbc5fa2b9bccf39813e7ea2cb3e15bc64bdffd3003dd774e0bdc6ed743d75cb3ebd81e90cbc277d663e9ae1c83eafd333bdfce0863c39436fbd807233bd90cf94bafda326bd83f6993e03e9c83e3c3686bd86b3c13ccc58bbbde18b343d200363bdc0c082bbc6c24b3e510cde3e75c64abd5628713c9f4cccbd7532d73da815b0bdfd54373c1643213ebca7ce3e384fd0bb5fd1583cf6f145bdc9b21cbd703d3bbc7a1df2bc5d88873e1fb3d63eadc68ebd43294c3c63f097bd151d6c3d15a0a2bd42d96d3ce073043ed093f23ec2ea0bbd962b793bdcb7b7bd50dff33d164dd1bdd2f4a33cbf4cd93d6df1d83e74329d3c6ef2133c91d1bbbc514d55bd8cd0c03b83ab71bc0caa6e3ed0ede83e34c6e7bd4fc006bc5f32babc2a2e883d5063b8bd34d2c83c0924fa3ccf04053f0929a5bc8db3abbb7c7844bda904023e90eee8bd3182513c9ab075bb73f2f33e4f205f3d2b11543c7c7ce63b48382b3c6cbf553c142c723b7ab6523e05ff7f3e22a840bb404867bb8857de3adcc3fb3d262143bc645a873c7fe3d03d0c9d823e91cb8c3c2c1f583df7bb363d9a531a3e9731aebd517d073c5238283e4b4a2a3efb04f6bad9b41f3ccf2c77bcf6d989bcd4e65a3c59c396bcbbd7863eff37923eb815b2bc6bde893ab50ed73b6896093d8674dc3a48eee0bb3801593e0c8b853e3ca90fbc6fe884bb298fba3cb19cf63d52a008bc0f4f2a3cbdf8183e96f8493e62ac473cdcde953bd519dcbce23cf2bca76cbe3b5fecc8bc836c943eb4589e3e3d23eabca7a4c83ba410d9bc515227bc8b3da13a9de9c4bc38e78a3e259fa03eb47f01bd73700ebce70501bbc63f623de04c87bca570d1bb16a3643e9eed893e38e06abc04b71b3b234314bdc374fcbc2453efba547af7bca6349c3ebd29a63e3bf906bdd70c423cfbe347bda0c973bc565da2bb5189f6bcea6f953ea944ac3e17c129bd61f32a3cf9033fbd9750be3c69d280bcf045acbcaab6873e225ea43e61fb14bddd80203ca43151bd20fc1abd1080b33a5ab525bde46da33ee953b03e88e739bd81a2b53cddea9fbde142ec3b78fc97bcd19806bd6375973e7ff7b33ee85341bd0005153d1ea4ddbd26045e3d16390cbd8842bdbceeb58b3ee155b23e07453dbdf2ab7c3cc62665bdf92c2cbd9abfb43bcd0f37bdb274a23ebc93b63ed5a255bd0a1a063d4e9be0bd13bf3a3dcea123bd2022fabcdd20903ef36abb3e244e3bbd336d4a3dee1224be8f07fe3d1cd695bd39763fbca823803ee190b53e204b08bd7eb54e3cba5673bd93a11fbdb8f38fbb62ee2fbd565ea13e9dd8bf3ecf7f68bdec69083dd24703bed0f6b23d19918fbd6317abbc3330823ee328c13e095307bdbe791b3d63b332be3f71463e84f9ecbdf7e8103c59d7523e8dd9ac3e93eec83b672d133cc31055bd8d00ffbc15f579bcacdc10bd737f943e7fc0c83eefdf6abdbc1bb53c1379f4bdf921e43d696abcbd3e3493bbcbe04f3ec9b9cc3e8feba7bc13e4ab3c09c82ebec94a643ea20c0abe4275df3c7787293e86c4ab3ed438083d80da103c89e6f1bc93791fbd8a9d3c3b572bedbc1267883e61f1d43ec6e0c5bd314a70bb26c682bd06d3083e501d97bdc3327d3cebe6f93d228bd33e1ff42fbd2afd103c6966dfbdb59d843e8a2b09be013c323cfcc12a3dc48ab43e77538f3d99a5123ccf42e33b8caae63b76de4d3c1aade43a7c616c3eff6a6f3e90c0f6baa45d693c49c1a23caf78dd3da6e90cbb36056c3c056f393e7fe0123ea0cbab3ce96babbd57c23abe31cadf3d7d27953cb05b013e14ac853e043a833e6533a7bb02c9273c4d6177bc33fb7dbc5218393ca50a99bc67108a3e26038e3e93f09dbc04fac9baa625893cfbb4e63c91df3e3953649dbb3979673ee34f753e22a28ebbc68356bca9de063d7e45b63da585c3bb621c793cd1e3363e3a0c423efa82623c6bee943b7a16e2bc278ce6bc3cd7943b6c35cdbce53d973e3d969a3e74dbd1bcf692243b46ee96bc12443fbc294053380a67c2bc5733903ef486973e4ca9d7bcfeb680bc60b4bf3cedc6453dced29cbc41fd82bba4d86b3eeb457a3e48b6f7bb879cf139b6010ebdbba600bda1feddba1987f5bc20e59e3e4291a23eab74fabca83b8b3bc83914bd54eba5bc6ab472bb1e4efdbc433a9b3e5813a33e82d20ebd8ec55fbb16e681bcb2f5993c763d8abc8973a0bc5f948b3e22f6933ef30dcabc03bdbf3b8b0542bdab1f26bd756acc3a15f523bd112ca73ea55eab3e5a9626bdc90d0b3cb9f359bd670752bc76e325bcbce810bd8321a03ee4a9a93e7b4728bd89f0703c799c82bd6462203d3616fbbc0a86b9bc6c17923e40059f3ed7fc05bdc29e2b3ca4ac58bd7c9937bd52e3a03b3e872dbd2855a73e3f50ae3ef8612ebd6b97833c4a3a92bd1cca2e3aa75986bce1201bbd74cc9f3ec9f2ae3e81be37bd1dc0183da7e505bee65be03db86a89bd653894bcdc468f3e7646a43e365a01bd4ca3333bcffe5abdaae62cbd1eb4d9bb5ad028bdf56ba93e7cd1b33e663929bd5e56553c5eb3a2bd3ccea63ca4e804bd253d03bd4c199d3e8ea9b13e024731bdcc935d3deb5341be1b7a483e6fb2e9bdd3ca69bb8e50863e1e73a03ecb909cbc9061c4bb6c5740bdc32204bda24baabc3f6310bd00e5a33e7c6db63e6e0410bd5a133e3be71d9abd7a950c3df39b50bd024aa6bc8269953e1556b73ea37626bdc09c693d58764abefa446f3e96d41abe9734473c7c06743ef1ca9f3e5d1c8ebb69a0f53b0c3b1ebda5ba28bdad5b55bbf52258bd8e59a63e5cb4ba3ef9b47abdd4df8eba931817bd3f1d0a3dde403fbd3856bcbccb668b3e8e03b93e787474bd974d343d6d98f2bd1e2c823e75ad1dbe6d7b933c54a1013e161baa3e03392ebb76de4d3c8caae63bcf42e33b99a5123c90c0f6baff6a6f3e7c616c3e1cade43aa6e90cbbaf78dd3d49c1a23ca45d693ca0cbab3c7fe0123e056f393e36056c3c7b27953c2fcadf3d57c23abeea6babbd5f33a7bb043a833e14ac853eb05b013e5718393c33fb7dbc4f6177bc01c9273c91f09dbc25038e3e67108a3ea60a99bc8edf3e39fbb4e63ca625893c04fac9ba22a28ebbe34f753e3979673e53649dbba585c3bb7e45b63da9de063dc68356bcfa82623c3a0c423ed1e3363e621c793c3cd7943b278ce6bc7a16e2bc6bee943b74dbd1bc3d969a3ee53d973e6c35cdbc2a40533812443fbc46ee96bcf692243b4ca9d7bcf486973e5733903e0a67c2bcced29cbcedc6453d60b4bf3cfeb680bc48b6f7bbeb457a3ea4d86b3e41fd82bba1feddbabba600bdb6010ebd879cf139ab74fabc4291a23e20e59e3e1987f5bc6ab472bb54eba5bcc83914bda83b8b3b82d20ebd5813a33e433a9b3e1e4efdbc763d8abcb2f5993c16e681bc8ec55fbbf30dcabc22f6933e5f948b3e8973a0bc756acc3aab1f26bd8b0542bd03bdbf3b5a9626bda55eab3e112ca73e15f523bd76e325bc670752bcb9f359bdc90d0b3c7b4728bde4a9a93e8321a03ebce810bd3616fbbc6462203d799c82bd89f0703cd7fc05bd40059f3e6c17923e0a86b9bc52e3a03b7c9937bda4ac58bdc29e2b3cf8612ebd3f50ae3e2855a73e3e872dbda75986bc1cca2e3a4a3a92bd6b97833c81be37bdc9f2ae3e74cc9f3ee1201bbdb86a89bde65be03da7e505be1dc0183d365a01bd7646a43edc468f3e653894bc1eb4d9bbaae62cbdcffe5abd4ca3333b663929bd7cd1b33ef56ba93e5ad028bda4e804bd3ccea63c5eb3a2bd5e56553c024731bd8ea9b13e4c199d3e253d03bd6fb2e9bd1b7a483eeb5341becc935d3dcb909cbc1e73a03e8e50863ed3ca69bba24baabcc32204bd6c5740bd9061c4bb6e0410bd7c6db63e00e5a33e3f6310bdf39b50bd7a950c3de71d9abd5a133e3ba37626bd1556b73e8269953e024aa6bc96d41abefa446f3e58764abec09c693d5d1c8ebbf1ca9f3e7c06743e9734473cad5b55bba5ba28bd0c3b1ebd69a0f53bf9b47abd5cb4ba3e8e59a63ef52258bdde403fbd3f1d0a3d931817bdd4df8eba787474bd8e03b93ecb668b3e3856bcbc75ad1dbe1e2c823e6d98f2bd974d343d03392ebb161baa3e54a1013e6d7b933c6cbf553c48382b3c7c7ce63b2b11543c22a840bb05ff7f3e7ab6523e152c723b262143bcdcc3fb3d8557de3a404867bb90cb8c3c0c9d823e7fe3d03d655a873c9731aebd9a531a3ef7bb363d2c1f583d1605f6ba4b4a2a3e5238283e517d073ccfe65a3cf5d989bccd2c77bcdab41f3cb915b2bcff37923ebbd7863e58c396bc8674dc3a6896093db50ed73b6bde893a3ca90fbc0c8b853e3801593e48eee0bb52a008bcb19cf63d288fba3c6fe884bb62ac473c96f8493ebdf8183e0f4f2a3ca76cbe3be23cf2bcd519dcbcdcde953b3d23eabcb4589e3e836c943e5fecc8bc8b3da13a515227bca410d9bca7a4c83bb47f01bd259fa03e38e78a3e9de9c4bce24c87bccd3f623d4c0601bb70700ebc38e06abc9ded893e18a3643ea670d1bb2453efbac374fcbc234314bd04b71b3b3bf906bdbd29a63ea6349c3e547af7bc565da2bba0c973bcfbe347bdd70c423c17c129bda944ac3eea6f953e5189f6bc69d280bc9750be3cf9033fbd61f32a3c61fb14bd225ea43eaab6873ef045acbc1080b33a20fc1abda43151bddd80203c88e739bde953b03ee46da33e5ab525bd78fc97bce142ec3bddea9fbd81a2b53ce85341bd7ff7b33e6375973ed19806bd16390cbd26045e3d1ea4ddbd0005153d07453dbde155b23eeeb58b3e8842bdbc9abfb43bf92c2cbdc62665bdf2ab7c3cd5a255bdbc93b63eb274a23ecd0f37bdcea123bd13bf3a3d4e9be0bd0a1a063d244e3bbdf36abb3edd20903e2022fabc1cd695bd8f07fe3dee1224be336d4a3d204b08bde190b53ea823803e39763fbcb8f38fbb93a11fbdba5673bd7eb54e3ccf7f68bd9dd8bf3e565ea13e62ee2fbd19918fbdd0f6b23dd24703beec69083d095307bde328c13e3330823e6317abbc84f9ecbd3f71463e63b332bebe791b3d93eec83b8dd9ac3e59d7523ef7e8103c15f579bc8d00ffbcc31055bd672d133cefdf6abd7fc0c83e737f943eacdc10bd696abcbdf921e43d1379f4bdbc1bb53c8feba7bcc9b9cc3ecbe04f3e3e3493bba20c0abec94a643e09c82ebe13e4ab3cd438083d86c4ab3e7787293e4275df3c8a9d3c3b93791fbd89e6f1bc80da103cc6e0c5bd61f1d43e1267883e572bedbc501d97bd06d3083e26c682bd314a70bb1ff42fbd228bd33eebe6f93dc3327d3c8a2b09beb59d843e6966dfbd2afd103c77538f3dc48ab43efcc12a3d013c323cf54ed03c94b5533cf62d503cf36d6d3c855337bca79e813e56a7443eb93be33983397cbb509ef63d64c8133c26d1a33b1a041a3c63a0713e7fabdd3d5482813c4af88c3c408a553e37fb753c3a8d263c7d5384ba5050343ede19b13d7b664cbcb7a6823c72f79fbc8fcb7ebcd724133c1768c7bc9c16973e2bbc833e46a092bc9241e63bb98d153d5e812cbb93ec4b3bbc2248bc0a15903eaa934a3eadeb34bc3a68713b0431193ecae7df397e0fd63943fa36ba0422523e2001123ed2e49ebae94d003c537604bdb42fd5bc628f933bd88801bdc4b2a23e1c7b913ec7bac6bced16a83b34d36fbc09e800bd684f133c61e61bbd53cbaa3e6c1e863ef3c2d0bc093e23bc5de56a3d3882a4bcf80121bbefd7b1bc3d2b963e3d4e5b3e12ae2dbc33d037bad66606bdad8d10bdb219543b745910bd17d4a93ef171993e4189fabc84c1a4baab77a4bc236c55bdecd6803ca54647bd9e15b63ea3ee8f3ea4f1f8bcee5818bcab27663cf07864bd9e8c793c663f3abdd6c5b23ed1e4813e72e7b0bc28767f3b54c329bd534848bd6c552d3c4b2949bd20b6b43eccf59f3e2b7725bd01df56bcffac36bb834f9abd8af7c63c2f3160bdb50fbf3ec9308f3ed719ffbc2f4896bc53f3b53c529dbdbd84c9013ddf9d67bdb32fc13e1123843e6cb9b2bc2cec073cf6c83bbd0f1e5fbd5905893cdb2c74bd3c9fbd3ef4b29d3e54fb31bd47bbfcbc964fb93c578dbcbdcaf6ea3c15bc64bd7ea2cb3ecf39813e5fa2b9bc75cb3ebdc6ed743dd774e0bdffd3003dafd333bd9ae1c83e277d663e81e90cbc90cf94ba807233bd39436fbdfce0863c3c3686bd03e9c83e83f6993efda326bd200363bde18b343dcc58bbbd86b3c13c75c64abd510cde3ec6c24b3ec0c082bba815b0bd7532d73d9f4cccbd5628713c384fd0bbbca7ce3e1643213efd54373c703d3bbcc9b21cbdf6f145bd5fd1583cadc68ebd1fb3d63e5d88873e7a1df2bc15a0a2bd151d6c3d63f097bd43294c3cc2ea0bbdd093f23ee073043e42d96d3c164dd1bd50dff33ddcb7b7bd962b793b74329d3c6df1d83ebf4cd93dd2f4a33c8cd0c03b514d55bd91d1bbbc6ef2133c34c6e7bdd0ede83e0caa6e3e83ab71bc5063b8bd2a2e883d5f32babc4fc006bc0929a5bccf04053f0924fa3c34d2c83c90eee8bda904023e7c7844bd8db3abbb4f205f3d73f2f33e9ab075bb3182513cb461d43c0947a8bae139413c27ae213cd7ac12bc7f878f3efbd03e3e96ea83bb6f46bcbce40dfb3dcec752bab2faad3a17e7d23b4e54a33eed0e683df0a8913c8923053d9cdfca3d2f66a9bc7b4d45babd72aebba8408e3eaa2ce23d59aae23b1e38a03c78afc0bc237178bcccfc023c892ee3bc82f99b3e9aad803ea9118cbc6444823cf348993ccfc8dabbbdf6d13bacaaa2bc76d39e3ed8da423e847875bc80a4e83c97ad8f3d29464cbcf64c063c329cccbc80438a3eee7f313e06f34fbc0df4293c283a12bdd5c8c5bc7284723b9ed210bd1ae0a63ee5ce8e3e3358c2bcc96f3c3c7282cebc1e1401bd5fbd1a3c6ab437bda2e7b43e5661813e9812d0bcdb77643b69a70b3d2f3cd7bc76347d3a88c8eabc3e36a43e2a13573eda7f6bbcdafa513a9acb11bd7a3606bd65b7333bd7a719bdaf8bad3ee662963e459cf8bc9c4ca53b703104bdd91240bdf327763c362962bd6b4abf3e4f578a3ebba7f1bc8e20093a1d0d9fbbf81f57bd171d803cfc275abdbd9fbe3ee7117a3ef09db4bc0f93d93b6b163fbdd3a235bd62f61f3cc74557bd7679b93e91a49b3e322120bd5a171dbb84b8d1bc4ecb6fbdcc929c3c12a67fbd4fd2c93e4409873eca0de6bcaf407dbb793b28bcb31092bdb3fdcc3cabe586bd85a8cd3eab7f7a3e16e4a3bcb039313cd6a155bd505d4ebd86a9833cdf0683bdf7d3c33e9ba4983ed5da27bd0e2d4abc374184bcc1c97cbd21df943ceefd8fbd7459db3e37ea693e38ca6dbc5359b2bc2071c23bd20e93bd4abd9e3c2bd981bd365adc3eb9a9503e898b22bb0e08e03a21654fbd1cca60bd3989903c6c3b8ebd8f37cf3e6079943e3f2620bd4825e2bc0f9142bcd71951bd6e7f323cd71f9abde387f53ecd6f2a3e11c9113c012940bd7ff6dc3c24e067bdedc2b23b658d47bdefb4ef3eaba0063e8d31a53ce72025bc3ec242bd34d831bd1fe1703cb11d98bdfb3fe13eeed57b3e8ee3cebc1c8a47bddbe0b4bbbd7612bd3fce423befac86bde9fb053f9588d43d71f4d13c8c9a78bdcfd0063d44dd33bd7f9bb7bac8290abddc59ff3e3393a43dc730e33cc3337b3b1e1f80bd0cfeaabc90ad073c0505e6bddff6f63e8467553ee762e9bb6b4e91bda488863bb26382bb49f8f2bb7bf02cbd07fa0f3f0c26f03c8868eb3c7a5aa4bdf691103d41268dbc3f21a2bb9bf13cb98b8b0b3f0cfe643b495d993c00c0a83c6032d2bb55a2d53be36f673cc8351cbcc987903e6c1f453e38f9b0b889297bbb39a0853d963e94bb0e40923c161c81bcc7b7b53ea6d8a03da6c3f73bf87285bebbba803cc4b0943d613e5c3c8fcc64bb4360083fa952db3d10d9b83cf026c63cc714ebbc785972bcc794ea3bdc7d01bdeadba03e9c4d7b3e6aba81bc1e68d53caea9aabb051e24bc2831a93b81add9bc3d9aac3e8a4d3f3e29bb5abce7859c3c3d5a863cb024e3bbcefd5e3c076984bc63ecab3ed42b243ea651b5bc206b623c731222bd060ab4bcf2702b3b0c9622bd6f0fab3e87b18b3e0558b5bce321a23cd6be1fbd44a6e0bc0647063c71b751bd2011be3eb986783e59fac6bc1233a43cb9a99a3ba9a5d1bc32245a3b203e04bd86f9b03e50384f3e045b95bcc43d4c3bddf920bd9847efbc38d6913aecff25bdb934b13e8029933e754debbc338c4d3c812343bd797712bdd491343c273d7bbd3006c83ee7cc833e3d90dcbc154a613c85bbf6bc396e2dbd2e4e6d3c94ad72bd219ec73e0a46733e616bc4bc000e1f3c398c56bd5a021bbd316acd3b918868bdf892be3edc5c963e3fd80ebdb725fe3b8f1c48bd14fb1abd2949343c88f88cbd3cdad33e4a477c3eab7abfbc22152b3cf4162fbd4b3045bd7618963cb3f297bdc0bed73e14666f3e60669abccaf1613cf64171bddab638bd6253643ca3f089bdc236c93e9db6933e32221bbd8596913bf8274abd1a690fbdd3e8093c06fda2bdd6a0e53eb80a5a3ed44d29bcdd6e993ad17323bd13f52abd5f45433c06e8a2bde28ae83eb779483ef238f4baa1e0613be4396bbd650250bdb11a923cf66290bd2e4ad43eb52e903e49f01ebda8268dbb362e53bd950bcebc18f9653bd714b2bd13e1fb3e9d6b293e205fe73be10c3bbc030505bdba1cf3bce243483b6a349fbdc980fb3e1c84103eec48823c9f4f07bc836870bdb2c117bde87c703ccd7a99bdf8b8e83e5ddd6f3e6ad1c8bc2a9babbc24a53bbdd3ad86bc06cf7937b60fa7bd1997063f1b94f83d5c7f903c9934bdbc36f3c9bcfb09bbbcf88184badf408dbdb183033fa5d5d53dabb0b73cbb24c43a7c059cbd59aa5fbcff3d853b374de0bd9c36003fefa2473e31e602bbc5902abd1c0fcfbc0cc80dbb145668bbb3d277bd5b6d0c3f5800873d10ed983c286c27bd7dfafdbbab7838bcb9546ebb35c434bd8897093f45f04e3dbc14a13c6347d13c30f262bcdf5f1e3be7fe383c02c132bc012e983eac9c373eb002133c35266c3d07734bbc967ec13b9ce3093c350ddbbcf5fcb73eb308db3dd7d6663a92d5873d35cb90bbf8973dbd82430c3b7c8a6bbcc6d2c73e97d97a3dd9b4383d1843f13cf0c90ebd66ef5fbc1fa2cd3b7ea512bd4988a53e3d2b753e126767bcefb11d3dea22cabc200e37bc42dc9e3b173801bdf431b73e3fc4353eed8338bc1550303d697b22bcaebbcabb179a853b42c328bc8a65bc3e389afb3dd9f33cbca9a2923cb84c35bd6d2d9ebccf12913a1f4e35bd5a2baf3e1a73883e0038a2bcb681eb3cff2859bddeb3b1bc8c06c33b2ef569bdab31c63ecc916c3e35fcabbc811c053d4860c2bc8819a2bc10df8f3b1b1c0cbdfc10c03e05843c3eadae96bc032adf3b2e3b35bdb939ccbc8eebb4bac54839bd2bd0b53ee38b8e3e13fbc8bc061ba73cb62c81bd63a6c5bcb6c4c63b600b8abd0081d03edc7d783e6044b2bcf0fade3c0cc85dbdb5bfd7bcdf282f3cffc97fbdf811d13eaefa5f3e7fa0b4bcbdba723c63e27abdf235f3bc9e760a3ba08581bdeccec53e10248f3ebbcaeabce4df853cd53f8cbd8089a5bce68a7d3ba04498bd12dadd3ef2d1673e9d268abc19c2c63c6eeb91bd22d0c1bc4136323c3685a3bde3addf3eb272603e47be86bcb5f59e3c34358ebd267711bdb4ed163ca05a94bd5a76cf3e7ab08d3e1dd607bd9414653c87ab91bd98b57fbce301f43ad79ba5bdea94eb3eff064d3e8cb10cbc1d328b3ca31495bd45dd8fbc11bfdc3bb2a8acbd6e2fec3e7106493eb1e6dabb700ef73b396f89bd6e4137bdca86873c03db91bd6e56d93e40a28c3eb99424bdc161813b3f898ebd9af931bc7d52273a2fc5a6bd6b20fa3e97fe2d3e477e95baba3ed93bcaea88bde86147bc65fc5f3bd5f2a4bda2e9f73e4ca7283ebb75203accd257bb903d94bdfc17f6bc3212453c493d9cbd275bee3ed3326c3e69d4d6bc23cd5cbc84ca7abd7ba800bc68c2453a685c97bde060033f7ef30e3e6cdb3e3bfbaf99bbd7a170bd2c7512bca7b9e73a781b94bd7e63003f3a0d0d3e2318703bf398b3b87b0fbbbd8fa420bce427943a997ad1bd2419013f7c53513e9852cfbbefb217bda9b126bdf74a13bbbcd5e1b9064b6abd7f190a3f34c9be3d1feda33b4cb6aebcba7206bd9ebca9bb638c143a33693cbd1362053ff11ca43d1c166c3b413d033da56d62bc480a333cd59f213c6bdf9bbc28359d3ec4cd2a3e6018ca3b0dcb993de78e0fbd9de1e23ac1e5bf3beabd00bd299cc03e5e08d53db80e6b3bec379b3d2ef7febc89b0523dfbfa963a8f6e94bc9d3fcd3ede648f3dfbeb4cbd0d9a003d611a1abd8bc15bbcb70dc73b299a16bd32aaa63ee467733ee11f53bc2174313da7c412bdbe1b1fbcb0038e3bed38f0bcaee2b93e74ce313e216f1bbc8e0c663d46b1b0bce91429bcde66953b9b80aabc45dac13e8f55f33d3ec4b2bb4554963c100337bd758fa0bc666c883a3c1237bd446caf3e1338883e78669cbcfde1f13cd37e6dbddebda7bca039bb3bbce15cbd7cbac63e61b56b3e2b84adbcc9b40d3d8f9314bd5fe090bc446a8c3b08ead3bc284bc13e77b13a3ed4d09abc771ee43b42013abdc213c8bc8db9b9ba94fa35bde7efb53ec06e8e3e064bcbbc82d9a83c60a28abd9550b0bc8f13c33b2cc581bd5bb2d03e0926783e9d05c4bc727be23c7ffc80bdec9ab1bc555f2c3c37fe5fbd4569d13e3c585f3eec77d4bc352d733c4d9a81bd5581eabcfa24093bfb0c7bbd86d6c53ed71c8f3e89ecf2bc8a85863c208698bdda3f89bc4a927a3b847e8cbdb2efdd3e45aa673eadd2a4bc20f9c73ccdfca3bd82fb84bc9760303c485b92bdbbd3df3e6524603e632cc0bce08b9f3c6c8594bd05b507bd99a7163c90648ebd9287cf3eb7a58d3e1f5111bd9edb653c4ac5a5bde9b10bbcd550f13ac1d591bd58a3eb3e0cec4c3e36a77ebc76c78b3c76e9acbd7132d7bb49dcda3b2c4d95bd8e44ec3eb6db483ef4fd8ebc7230f73b55dd91bd459324bdf284873c007289bd8a57d93e91a18c3e743f37bd056c813b12caa6bd8b2f94ba185b263a288b8ebde821fa3e70fa2d3efbcf31bc6bb0d93b1406a5bda6282a3a7ab35e3b7af488bd39eff73e879a283eb4e246bc4b0658bb8e3e9cbdb4d1d6bcf20d453cb73f94bdc05cee3e82316c3e7a13f6bc80d75cbcf35d97bdc52c3f3b5534453a5cc57abde860033f5df20e3ec9a100bc77a299bbd52294bd110b713b22c4e63a86a070bd3d64003f24090d3ed65212bc36de73b84279d1bd9efecebb3534933a830abbbd8817013f294c513eb17920bc8fb317bd3a496abd13e4a33b2543e1b90cb026bd65190a3f82c9be3db96713bb12bbaebcca6d3cbd391a6c3bb21f143a8e6d06bd3f62053f311aa43d788ca9bb00c0a83cc8351cbc3bf9b0b8e36f673c6032d2bbc987903e6c1f453e55a2d53b89297bbb161c81bca6c3f73b0e40923c39a0853dc7b7b53ea6d8a03d963e94bbf87285be8acc64bb11d9b83c603e5c3cbbba803c4360083fa852db3dc4b0943df026c63cdc7d01bd6aba81bcc794ea3bc714ebbceadba03e9c4d7b3e785972bc1e68d53c81add9bc29bb5abc2831a93baea9aabb3d9aac3e8a4d3f3e051e24bc11869c3c1b6984bc7951b5bcd1fd5e3c0e5a863c62ecab3ed32b243ea724e3bb206b623c0c9622bd0558b5bcf2702b3b731222bd6f0fab3e87b18b3e060ab4bce021a23c71b751bd59fac6bc0647063cd6be1fbd2011be3eb986783e44a6e0bc1233a43c203e04bd045b95bc32245a3bb9a99a3b86f9b03e50384f3ea9a5d1bcc43d4c3becff25bd754debbc38d6913addf920bdb934b13e8029933e9847efbc338c4d3c273d7bbd3d90dcbcd491343c812343bd3006c83ee7cc833e797712bd154a613c94ad72bd616bc4bc2e4e6d3c85bbf6bc219ec73e0a46733e396e2dbd010e1f3c918868bd3ed80ebd346acd3b388c56bdf792be3edc5c963e5b021bbdb725fe3b88f88cbdab7abfbc2949343c8f1c48bd3cdad33e4a477c3e14fb1abd22152b3cb3f297bd60669abc7618963cf4162fbdc0bed73e14666f3e4b3045bdcaf1613ca3f089bd32221bbd6253643cf64171bdc236c93e9db6933edab638bd8596913b06fda2bdd44d29bcd3e8093cf8274abdd6a0e53eb80a5a3e1a690fbdcc6e993a06e8a2bde938f4ba5f45433cd17323bde28ae83eb779483e13f52abda1e0613bf66290bd49f01ebdb11a923ce4396bbd2e4ad43eb52e903e650250bda8268dbbd714b2bd205fe73b18f9653b362e53bd13e1fb3e9d6b293e950bcebce30c3bbc6a349fbdec48823ce043483b030505bdc980fb3e1c84103eba1cf3bc9f4f07bccd7a99bd6ad1c8bce87c703c836870bdf8b8e83e5ddd6f3eb2c117bd2a9babbcb60fa7bd5c7f903c06cf793724a53bbd1997063f1b94f83dd3ad86bc9934bdbcdf408dbdacb0b73cf88184ba36f3c9bcb183033fa5d5d53dfb09bbbcbb24c43a374de0bd31e602bbff3d853b7c059cbd9c36003fefa2473e59aa5fbcc5902abdb3d277bd10ed983c145668bb1c0fcfbc5b6d0c3f5800873d0cc80dbb286c27bd35c434bdbc14a13cb9546ebb7dfafdbb8897093f45f04e3dab7838bc258ecc3cbb94f9bb21a916bba8e8203ce59f3bbb38e68e3e7f34423ec048173c4737bcbc10ecd23b10b1913c5965ae3a1c11fb3d1b55a33ed3f6673d8edd53bafa01043dc566abbba145f43b918985ba3ad0ca3d96568e3e4901e33d7a92aebc7300a03c72f3e2bce3e98bbc922a033c7cc9c0bc77f59b3e8eb5803e643e79bc8a44823cbaaaa2bc067975bc68f6d13bb448993c75d39e3ee6da423e65c8dabb01a4e83c9e9bccbcfbf34fbc434d063cb8ad8f3d7c438a3efa7f313ef6464cbc6de3293ca9cd10bd2354c2bcbea0723bbe3a12bd42dfa63e41d08e3e16d9c5bcd86f3c3c6bb437bd9812d0bc5ebd1a3c7b82cebca2e7b43e5661813e1c1401bddb77643b88c8eabcda7f6bbc75347d3a69a70b3d3e36a43e2a13573e2f3cd7bc57f6513abca719bd439cf8bcddb7333b93cb11bda98bad3eee62963ea13606bd9c4ca53b362962bdbba7f1bcf327763c703104bd6b4abf3e4f578a3ed91240bd8c20093afc275abdf19db4bc171d803c1d0d9fbbbd9fbe3ee7117a3ef81f57bd0f93d93bc74557bd322120bd62f61f3c6b163fbd7679b93e91a49b3ed3a235bd5a171dbb12a67fbdca0de6bccc929c3c84b8d1bc4fd2c93e4409873e4ecb6fbdaf407dbbabe586bd16e4a3bcb3fdcc3c793b28bc85a8cd3eab7f7a3eb31092bdb039313cdf0683bdd5da27bd86a9833cd6a155bdf7d3c33e9ba4983e505d4ebd0e2d4abceefd8fbd38ca6dbc21df943c374184bc7459db3e37ea693ec1c97cbd5359b2bc2bd981bd898b22bb4abd9e3c2071c23b365adc3eb9a9503ed20e93bd0e08e03a6c3b8ebd3f2620bd3989903c21654fbd8f37cf3e6079943e1cca60bd4825e2bcd71f9abd11c9113c6e7f323c0f9142bce387f53ecd6f2a3ed71951bd012940bd658d47bd8d31a53cedc2b23b7ff6dc3cefb4ef3eaba0063e24e067bde72025bcb11d98bd8ee3cebc1fe1703c3ec242bdfb3fe13eeed57b3e34d831bd1c8a47bdefac86bd71f4d13c3fce423bdbe0b4bbe9fb053f9588d43dbd7612bd8b9a78bdc9290abdc930e33c939bb7baced0063ddb59ff3e3493a43d45dd33bdc3337b3b0505e6bde762e9bb90ad073c1e1f80bddff6f63e8467553e0cfeaabc6b4e91bd7bf02cbd8868eb3c49f8f2bba488863b07fa0f3f0c26f03cb26382bb7a5aa4bd9bf13cb9495d993c3f21a2bbf691103d8b8b0b3f0cfe643b41268dbc8d68d93c968252bce621a4baf0436e3cea0e6b3c7368823e02f7403e6b647e3cc68b7cbb8c131a3cbf79813c54bca33bb69bf63d4a9f713ef8b3dd3da8cb133c70e08c3cb08b84ba67824cbc07b9263cc98a553e5850343ebe16b13df831763c8eea823ce5abc7bcbdc592bc04f3123c79dd9fbc181b973e30b3833ed6f27dbcec40e63bb72248bc5ceb34bce5ed4b3bcc8d153d0e15903e9a934a3ec5812cbb2f6a713b010637bac1e69eba1012d639f830193e1422523e1e01123e82efdf39e161003c5e8e01bd3abec6bc257f933beb7504bdb2b3a23e9579913e601ed5bcdd16a83b61e61bbdf4c2d0bc6a4f133c21d36fbc53cbaa3e6c1e863e0ce800bd0f3e23bcf0d7b1bc13ae2dbce50121bb64e56a3d3c2b963e404e5b3e4582a4bcd3ca37ba925910bd3e89fabc1719543be06606bd1ed4a93ee871993e818d10bd84c1a4baa54647bda4f1f8bcecd6803cab77a4bc9e15b63ea3ee8f3e236c55bdee5818bc663f3abd72e7b0bc9e8c793cab27663cd6c5b23ed1e4813ef07864bd28767f3b4b2949bd2b7725bd6c552d3c54c329bd20b6b43eccf59f3e534848bd01df56bc2f3160bdd719ffbc8af7c63cffac36bbb50fbf3ec9308f3e834f9abd2f4896bcdf9d67bd6cb9b2bc84c9013d53f3b53cb32fc13e1123843e529dbdbd2cec073cdb2c74bd54fb31bd5905893cf6c83bbd3c9fbd3ef4b29d3e0f1e5fbd47bbfcbc15bc64bd5fa2b9bccaf6ea3c964fb93c7ea2cb3ecf39813e578dbcbd75cb3ebdafd333bd81e90cbcffd3003dc6ed743d9ae1c83e277d663ed774e0bd90cf94ba3c3686bdfda326bdfce0863c807233bd03e9c83e83f6993e39436fbd200363bd75c64abdc0c082bb86b3c13ce18b343d510cde3ec6c24b3ecc58bbbda815b0bd384fd0bbfd54373c5628713c7532d73dbca7ce3e1643213e9f4cccbd703d3bbcadc68ebd7a1df2bc5fd1583cc9b21cbd1fb3d63e5d88873ef6f145bd15a0a2bdc2ea0bbd42d96d3c43294c3c151d6c3dd093f23ee073043e63f097bd164dd1bd74329d3cd2f4a33c962b793b50dff33d6df1d83ebf4cd93ddcb7b7bd8cd0c03b34c6e7bd83ab71bc6ef2133c514d55bdd0ede83e0caa6e3e91d1bbbc5063b8bd0929a5bc34d2c83c4fc006bc2a2e883dcf04053f0924fa3c5f32babc90eee8bd4f205f3d3182513c8db3abbba904023e73f2f33e9ab075bb7c7844bd6cbf553c22a840bb142c723b2b11543c48382b3c05ff7f3e7ab6523e7c7ce63b262143bc90cb8c3c655a873c414867bbdcc3fb3d0c9d823e7fe3d03d8557de3a9731aebd1505f6ba517d073c2c1f583d9a531a3e4b4a2a3e5238283ef7bb363dd4e65a3cb815b2bc59c396bcd9b41f3cf6d989bcff37923ebbd7863ecf2c77bc8674dc3a3ca90fbc48eee0bb6ade893a6896093d0c8b853e3801593eb50ed73b52a008bc62ac473c0f4f2a3c6fe884bbb19cf63d96f8493ebdf8183e288fba3ca76cbe3b3d23eabc5fecc8bcdcde953be23cf2bcb4589e3e836c943ed519dcbc8a3da13ab47f01bd9de9c4bca7a4c83b515227bc259fa03e38e78a3ea410d9bce04c87bc38e06abca570d1bb73700ebcc63f623d9eed893e16a3643ee70501bb2453efba3bf906bd547af7bc04b71b3bc374fcbcbd29a63ea6349c3e234314bd565da2bb17c129bd5189f6bcd70c423ca0c973bca944ac3eea6f953efbe347bd69d280bc61fb14bdf045acbc61f32a3c9750be3c225ea43eaab6873ef9033fbd1080b33a88e739bd5ab525bddd80203c20fc1abde953b03ee46da33ea43151bd78fc97bce85341bdd19806bd81a2b53ce142ec3b7ff7b33e6375973eddea9fbd16390cbd07453dbd8842bdbc0005153d26045e3de155b23eeeb58b3e1ea4ddbd9abfb43bd5a255bdcd0f37bdf2ab7c3cf92c2cbdbc93b63eb274a23ec62665bdcea123bd244e3bbd2022fabc0a1a063d13bf3a3df36abb3edd20903e4e9be0bd1cd695bd204b08bd39763fbc336d4a3d8f07fe3de190b53ea823803eee1224beb8f38fbbcf7f68bd62ee2fbd7eb54e3c93a11fbd9dd8bf3e565ea13eba5673bd19918fbd095307bd6317abbcec69083dd0f6b23de328c13e3330823ed24703be84f9ecbd93eec83bf7e8103cbe791b3d3f71463e8dd9ac3e59d7523e63b332be15f579bcefdf6abdacdc10bd672d133c8d00ffbc7fc0c83e737f943ec31055bd696abcbd8feba7bc3e3493bbbc1bb53cf921e43dc9b9cc3ecbe04f3e1379f4bda20c0abed438083d4275df3c13e4ab3cc94a643e86c4ab3e7787293e09c82ebe8a9d3c3bc6e0c5bd572bedbc80da103c93791fbd61f1d43e1267883e89e6f1bc501d97bd1ff42fbdc3327d3c314a70bb06d3083e228bd33eebe6f93d26c682bd8a2b09be77538f3d013c323c2afd103cb59d843ec48ab43efcc12a3d6966dfbd76de4d3c90c0f6ba1bade43a99a5123c8caae63bff6a6f3e7c616c3ecf42e33ba5e90cbba0cbab3c36056c3ca45d693caf78dd3d7fe0123e056f393e49c1a23c7c27953c6133a7bbb05b013eea6babbd2fcadf3d043a833e14ac853e57c23abe5218393c93f09dbca50a99bc02c9273c33fb7dbc26038e3e67108a3e4d6177bc8cdf3e3922a28ebb53649dbb04fac9bafbb4e63ce34f753e3979673ea625893ca585c3bbfa82623c621c793cc68356bc7e45b63d3a0c423ed1e3363ea9de063d3cd7943b74dbd1bc6c35cdbc6bee943b278ce6bc3d969a3ee53d973e7a16e2bc284053384ca9d7bc0a67c2bcf692243b12443fbcf486973e5733903e46ee96bcced29cbc48b6f7bb41fd82bbfeb680bcedc6453deb457a3ea4d86b3e60b4bf3ca1feddbaab74fabc1987f5bc879cf139bba600bd4291a23e20e59e3eb6010ebd6ab472bb82d20ebd1e4efdbca83b8b3b54eba5bc5813a33e433a9b3ec83914bd763d8abcf30dcabc8973a0bc8ec55fbbb2f5993c22f6933e5f948b3e16e681bc756acc3a5a9626bd15f523bd03bdbf3bab1f26bda55eab3e112ca73e8b0542bd76e325bc7b4728bdbce810bdc90d0b3c670752bce4a9a93e8321a03eb9f359bd3616fbbcd7fc05bd0a86b9bc89f0703c6462203d40059f3e6c17923e799c82bd52e3a03bf8612ebd3e872dbdc29e2b3c7c9937bd3f50ae3e2855a73ea4ac58bda75986bc81be37bde1201bbd6b97833c1cca2e3ac9f2ae3e74cc9f3e4a3a92bdb86a89bd365a01bd653894bc1dc0183de65be03d7646a43edc468f3ea7e505be1eb4d9bb663929bd5ad028bd4ca3333baae62cbd7cd1b33ef56ba93ecffe5abda4e804bd024731bd253d03bd5e56553c3ccea63c8ea9b13e4c199d3e5eb3a2bd6fb2e9bdcb909cbcd3ca69bbcc935d3d1b7a483e1e73a03e8e50863eeb5341bea24baabc6e0410bd3f6310bd9061c4bbc32204bd7c6db63e00e5a33e6c5740bdf39b50bda37626bd024aa6bc5a133e3b7a950c3d1556b73e8269953ee71d9abd96d41abe5d1c8ebb9734473cc09c693dfa446f3ef1ca9f3e7c06743e58764abead5b55bbf9b47abdf52258bd69a0f53ba5ba28bd5cb4ba3e8e59a63e0c3b1ebdde403fbd787474bd3856bcbcd4df8eba3f1d0a3d8e03b93ecb668b3e931817bda7ad1dbeb3352ebb577b933ce34d343d142c823e151baa3e49a1013e0398f2bd
