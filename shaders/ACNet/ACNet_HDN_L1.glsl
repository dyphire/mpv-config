/*
MIT License

Copyright (c) 2020 TianZer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/*
  description: Anime4KCPP Net HDN Level 1 GLSL
  Author: TianZerL
*/

//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L1
//!BIND LUMA
//!SAVE L1_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL1[9 * 4] = float[9 * 4]
(
-6.6326e-02, -2.2316e-01,  4.2471e-02,
 1.7064e-02, -6.8305e-01, -1.5978e-01,
 6.7568e-01,  3.2212e-01,  8.3561e-02,
-4.6649e-01, -6.8789e-02,  5.3455e-01,
-5.0941e-01,  7.0657e-02,  4.5647e-01,
-2.3657e-02,  3.5302e-02, -1.8316e-02,
-2.0316e-01,  4.7021e-02, -2.2313e-01,
 5.3465e-02,  7.0750e-01,  9.1366e-02,
-2.8566e-01, -2.0521e-02, -7.1786e-02,
 4.8186e-02, -9.3429e-02,  2.4493e-03,
 3.4654e-01,  7.2625e-02,  1.6615e-01,
 3.2101e-01,  3.2923e-01, -9.8548e-02
);

const float biasL1[4] = float[4]
(
-0.0264, -0.0229, -0.3021, -0.2579
);

vec4 hook()
{
    vec4 tl = LUMA_texOff(vec2(-1,-1));
    vec4 tc = LUMA_texOff(vec2(0,-1));
    vec4 tr = LUMA_texOff(vec2(1,-1));
    vec4 ml = LUMA_texOff(vec2(-1,0));
    vec4 mc = LUMA_texOff(vec2(0,0));
    vec4 mr = LUMA_texOff(vec2(1,0));
    vec4 bl = LUMA_texOff(vec2(-1,1));
    vec4 bc = LUMA_texOff(vec2(0,1));
    vec4 br = LUMA_texOff(vec2(1,1));

    vec4 c1234 = RELU(vec4(
        tl.x * kernelsL1[0*9+0] + tc.x * kernelsL1[0*9+1] + tr.x * kernelsL1[0*9+2] +
        ml.x * kernelsL1[0*9+3] + mc.x * kernelsL1[0*9+4] + mr.x * kernelsL1[0*9+5] +
        bl.x * kernelsL1[0*9+6] + bc.x * kernelsL1[0*9+7] + br.x * kernelsL1[0*9+8] + biasL1[0],

        tl.x * kernelsL1[1*9+0] + tc.x * kernelsL1[1*9+1] + tr.x * kernelsL1[1*9+2] +
        ml.x * kernelsL1[1*9+3] + mc.x * kernelsL1[1*9+4] + mr.x * kernelsL1[1*9+5] +
        bl.x * kernelsL1[1*9+6] + bc.x * kernelsL1[1*9+7] + br.x * kernelsL1[1*9+8] + biasL1[1],

        tl.x * kernelsL1[2*9+0] + tc.x * kernelsL1[2*9+1] + tr.x * kernelsL1[2*9+2] +
        ml.x * kernelsL1[2*9+3] + mc.x * kernelsL1[2*9+4] + mr.x * kernelsL1[2*9+5] +
        bl.x * kernelsL1[2*9+6] + bc.x * kernelsL1[2*9+7] + br.x * kernelsL1[2*9+8] + biasL1[2],

        tl.x * kernelsL1[3*9+0] + tc.x * kernelsL1[3*9+1] + tr.x * kernelsL1[3*9+2] +
        ml.x * kernelsL1[3*9+3] + mc.x * kernelsL1[3*9+4] + mr.x * kernelsL1[3*9+5] +
        bl.x * kernelsL1[3*9+6] + bc.x * kernelsL1[3*9+7] + br.x * kernelsL1[3*9+8] + biasL1[3]
    ));


    return c1234;
}

//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L1
//!BIND LUMA
//!SAVE L1_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL1[9 * 4] = float[9 * 4]
(
 1.1916e-02,  2.0413e-01, -1.8920e-02,
 6.0858e-02,  8.3548e-01,  1.4060e-01,
-9.1827e-01, -2.4551e-01, -4.6118e-02,
-5.2737e-02,  4.3151e-01,  1.7027e-01,
 2.6647e-01,  5.5240e-01,  3.4745e-03,
 5.3495e-02, -4.7059e-02, -2.6593e-02,
 1.5691e-01,  4.7332e-01,  2.6651e-03,
 1.7997e-02,  4.1367e-01,  1.3239e-02,
 4.6932e-02,  1.0278e-01,  1.0699e-02,
-3.4319e-02, -7.6373e-01, -9.7022e-02,
-1.4160e-01,  2.9567e-01,  6.6220e-01,
 7.3508e-05,  1.2683e-01, -6.3442e-02
);

const float biasL1[4] = float[4]
(
-0.0327, -0.0053, -0.7777,  0.0232
);

vec4 hook()
{
    vec4 tl = LUMA_texOff(vec2(-1,-1));
    vec4 tc = LUMA_texOff(vec2(0,-1));
    vec4 tr = LUMA_texOff(vec2(1,-1));
    vec4 ml = LUMA_texOff(vec2(-1,0));
    vec4 mc = LUMA_texOff(vec2(0,0));
    vec4 mr = LUMA_texOff(vec2(1,0));
    vec4 bl = LUMA_texOff(vec2(-1,1));
    vec4 bc = LUMA_texOff(vec2(0,1));
    vec4 br = LUMA_texOff(vec2(1,1));

    vec4 c5678 = RELU(vec4(
        tl.x * kernelsL1[0*9+0] + tc.x * kernelsL1[0*9+1] + tr.x * kernelsL1[0*9+2] +
        ml.x * kernelsL1[0*9+3] + mc.x * kernelsL1[0*9+4] + mr.x * kernelsL1[0*9+5] +
        bl.x * kernelsL1[0*9+6] + bc.x * kernelsL1[0*9+7] + br.x * kernelsL1[0*9+8] + biasL1[0],

        tl.x * kernelsL1[1*9+0] + tc.x * kernelsL1[1*9+1] + tr.x * kernelsL1[1*9+2] +
        ml.x * kernelsL1[1*9+3] + mc.x * kernelsL1[1*9+4] + mr.x * kernelsL1[1*9+5] +
        bl.x * kernelsL1[1*9+6] + bc.x * kernelsL1[1*9+7] + br.x * kernelsL1[1*9+8] + biasL1[1],

        tl.x * kernelsL1[2*9+0] + tc.x * kernelsL1[2*9+1] + tr.x * kernelsL1[2*9+2] +
        ml.x * kernelsL1[2*9+3] + mc.x * kernelsL1[2*9+4] + mr.x * kernelsL1[2*9+5] +
        bl.x * kernelsL1[2*9+6] + bc.x * kernelsL1[2*9+7] + br.x * kernelsL1[2*9+8] + biasL1[2],

        tl.x * kernelsL1[3*9+0] + tc.x * kernelsL1[3*9+1] + tr.x * kernelsL1[3*9+2] +
        ml.x * kernelsL1[3*9+3] + mc.x * kernelsL1[3*9+4] + mr.x * kernelsL1[3*9+5] +
        bl.x * kernelsL1[3*9+6] + bc.x * kernelsL1[3*9+7] + br.x * kernelsL1[3*9+8] + biasL1[3]
    ));


    return c5678;
}

//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L2
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-7.8588e-41, -5.0770e-40, -2.3334e-40,
 5.7174e-40,  6.9060e-41,  2.2264e-40,
-4.1631e-40,  4.5667e-40, -1.8115e-40,
-3.1000e-40,  3.1019e-40,  5.5423e-40,
-5.8518e-40,  2.1290e-40, -5.4579e-40,
-3.7753e-40,  3.6029e-40, -1.7875e-40,
 4.2296e-40,  6.5672e-41,  1.4976e-40,
-3.1479e-40, -3.2881e-40, -5.9818e-40,
 3.2053e-40,  3.0821e-40,  5.1321e-40,
-2.6557e-17, -3.8205e-17, -3.7077e-17,
-2.5168e-17, -3.4817e-17, -3.4186e-17,
-1.8056e-17, -2.3105e-17, -2.2581e-17,
 5.9355e-40,  2.4052e-40, -1.0027e-40,
 2.2060e-40,  3.4864e-40, -5.7403e-40,
 4.6936e-40, -3.3951e-40, -4.7715e-40,
-9.7917e-11, -1.0331e-10, -9.6141e-11,
-1.0581e-10, -1.1173e-10, -1.0317e-10,
-1.0192e-10, -1.0681e-10, -9.8738e-11,
-1.0402e-29, -2.3233e-29, -1.7882e-29,
-1.4804e-29, -3.7821e-29, -3.0750e-29,
-1.0448e-29, -2.6740e-29, -2.1676e-29,
 4.2124e-40,  2.5024e-40,  4.5312e-40,
-2.4880e-40,  2.9838e-41, -2.7215e-41,
-2.6347e-40,  1.5950e-40,  9.3734e-41,
-1.4936e-01, -1.0438e-01,  2.9827e-02,
 1.4751e-02, -1.6854e-01, -8.8101e-02,
 4.9228e-02, -3.0744e-02, -1.1512e-01,
-3.4996e-02, -2.5024e-02, -1.8880e-02,
 3.0008e-02,  4.8689e-02, -1.3415e-01,
-9.1698e-03, -1.1019e-02, -5.0655e-02,
-6.6579e-02, -2.6447e-02,  1.9791e-02,
-4.1727e-02,  3.6433e-02,  3.1516e-02,
-5.7619e-02,  2.3401e-02,  3.0785e-02,
-3.3610e-02,  1.2263e-01,  2.4351e-02,
 1.7148e-02,  1.7144e-01,  4.0305e-02,
 8.7902e-03, -7.0077e-02, -1.0688e-01,
 4.7460e-02, -1.4093e-03, -1.5911e-02,
-2.2978e-02,  9.9025e-02,  1.2867e-02,
 3.4704e-02,  1.4672e-01,  7.9188e-02,
-4.4222e-02, -3.9480e-02, -1.9193e-01,
-3.1897e-02,  1.0776e-01, -5.2742e-02,
 8.0377e-02,  2.5764e-01, -9.7330e-02,
-1.1593e-01, -5.3753e-02, -2.8918e-02,
 6.7939e-02,  2.3963e-01,  2.0856e-01,
 2.7964e-02,  2.7781e-01,  2.1859e-01,
-1.5196e-02,  9.6704e-03, -8.0136e-02,
 8.9441e-02,  1.0314e-01, -2.0204e-02,
-3.3970e-02, -1.4562e-02,  3.4723e-02,
 2.3357e-40, -1.4361e-40,  2.0498e-40,
-5.2355e-40, -6.0151e-40, -2.9264e-40,
 1.9715e-41,  5.9793e-41, -1.3675e-40,
 5.3771e-40,  6.5637e-41, -3.8471e-40,
-3.0820e-40, -1.7004e-40, -1.9371e-40,
-5.1159e-40,  7.3244e-41,  3.5861e-41,
 2.8441e-40,  4.5248e-41,  1.9771e-40,
-2.4681e-40,  3.6054e-40,  3.3496e-40,
-6.5048e-42, -1.6001e-40,  4.8243e-41,
-1.0165e-08, -9.9140e-09, -9.6054e-09,
-1.0511e-08, -1.0256e-08, -9.9066e-09,
-1.0521e-08, -1.0320e-08, -9.9896e-09,
 2.6042e-40,  4.2016e-40,  5.3537e-40,
 1.4594e-40,  1.1344e-40,  3.5144e-40,
-2.5736e-37, -1.3591e-39,  2.1029e-40,
-3.1420e-07, -3.0309e-07, -2.9630e-07,
-3.1196e-07, -2.9967e-07, -2.9249e-07,
-3.1296e-07, -3.0086e-07, -2.9332e-07,
-6.1256e-12, -5.9283e-12, -5.6508e-12,
-6.5297e-12, -6.4118e-12, -6.0667e-12,
-6.8382e-12, -6.8547e-12, -6.5225e-12,
-5.0327e-26, -1.0795e-25, -1.8952e-25,
-2.4220e-26, -5.9067e-26, -1.1323e-25,
-2.1499e-27, -5.5342e-27, -1.0333e-26,
 4.5039e-03, -1.3303e-02,  1.6183e-01,
 6.5951e-02, -7.1353e-02,  1.7254e-01,
-1.8671e-03,  1.0593e-01, -3.6872e-02,
 4.9102e-02, -2.4075e-03,  4.8194e-02,
-7.0892e-02, -1.8948e-01, -1.6586e-01,
-2.8102e-02,  2.0870e-02,  5.9228e-02,
 1.2673e-02,  3.3908e-02,  4.8282e-02,
 4.4369e-02,  5.6304e-02,  1.2225e-02,
 4.1855e-02,  1.1990e-01,  6.3799e-02,
-7.3884e-02,  1.4153e-02,  9.5825e-02,
 4.2850e-02, -3.5337e-02,  1.3615e-01,
-2.0900e-01, -2.2835e-02, -8.6987e-02,
-6.7793e-02,  1.3547e-01, -9.9666e-02,
 3.5498e-02,  5.3725e-02,  1.1501e-01,
-1.2238e-01,  3.5354e-02,  7.4216e-02,
-3.5288e-02,  7.0111e-03,  2.4820e-02,
-1.0649e-02,  1.6715e-01,  1.2825e-01,
 3.1145e-02,  1.2097e-01, -1.2073e-02,
-7.0603e-02,  5.5574e-02, -5.0025e-02,
-8.2885e-02,  1.0957e-01,  1.3311e-01,
 2.9147e-02, -1.1849e-02,  8.9953e-02,
-3.2247e-02, -1.0747e-02,  9.1431e-03,
 1.2114e-01, -5.9780e-02,  5.4821e-02,
-5.2592e-02, -6.9082e-02, -7.5981e-02
);

const float biasL[4] = float[4]
(
-3.1869e-08, -3.8279e-01, -6.3693e-05, -5.9054e-02
);

vec4 hook()
{
    vec4 tl1 = L1_1_texOff(vec2(-1,-1));
    vec4 tc1 = L1_1_texOff(vec2(0,-1));
    vec4 tr1 = L1_1_texOff(vec2(1,-1));
    vec4 ml1 = L1_1_texOff(vec2(-1,0));
    vec4 mc1 = L1_1_texOff(vec2(0,0));
    vec4 mr1 = L1_1_texOff(vec2(1,0));
    vec4 bl1 = L1_1_texOff(vec2(-1,1));
    vec4 bc1 = L1_1_texOff(vec2(0,1));
    vec4 br1 = L1_1_texOff(vec2(1,1));

    vec4 tl2 = L1_2_texOff(vec2(-1,-1));
    vec4 tc2 = L1_2_texOff(vec2(0,-1));
    vec4 tr2 = L1_2_texOff(vec2(1,-1));
    vec4 ml2 = L1_2_texOff(vec2(-1,0));
    vec4 mc2 = L1_2_texOff(vec2(0,0));
    vec4 mr2 = L1_2_texOff(vec2(1,0));
    vec4 bl2 = L1_2_texOff(vec2(-1,1));
    vec4 bc2 = L1_2_texOff(vec2(0,1));
    vec4 br2 = L1_2_texOff(vec2(1,1));

    vec4 c1234 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c1234;
}


//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L2
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-7.8533e-02,  1.3658e-01,  1.0923e-01,
-3.2530e-02, -2.1342e-01, -1.2200e-01,
-1.9196e-02,  1.0450e-01, -8.9044e-02,
-2.0110e-02,  6.1439e-02, -2.7405e-02,
 6.0823e-02, -6.4268e-03, -9.1778e-03,
 6.4877e-02, -6.1227e-02, -5.4466e-02,
 9.6375e-02,  1.7519e-01,  5.0725e-03,
 1.9159e-01,  3.9725e-01,  1.2851e-01,
-6.9197e-02,  4.9372e-02, -3.4221e-02,
 1.1583e-01,  1.3389e-01,  2.9135e-01,
 1.0290e-02,  1.1214e-01,  1.7560e-01,
-1.8048e-02,  8.4782e-02,  4.9925e-02,
-3.8447e-02, -1.3156e-01, -1.1072e-01,
 1.8256e-01,  2.2831e-01, -1.6508e-01,
 4.6781e-02,  1.4913e-01, -8.6956e-02,
 5.1365e-04,  6.7873e-02, -3.4787e-03,
 1.7689e-01,  1.8414e-01,  2.2286e-01,
 1.2571e-01,  1.7687e-01,  1.5949e-01,
 5.9904e-02,  1.6259e-01,  1.4313e-01,
 2.2234e-01,  4.0943e-01,  3.1469e-01,
 1.9799e-01,  4.3052e-01,  3.0510e-01,
 1.2259e-01, -1.0778e-02,  6.2284e-03,
 1.4508e-02, -6.9073e-02,  5.0998e-02,
 5.2962e-02, -1.5291e-01, -1.0491e-02,
-8.6903e-02, -1.0430e-01,  3.0130e-02,
 4.1691e-02, -1.2675e-01, -5.5169e-01,
 8.9644e-02,  3.6910e-02, -1.5459e-01,
 5.3656e-03,  6.7936e-02,  1.0793e-01,
-2.7424e-02, -1.7652e-01, -3.5776e-01,
 2.4593e-02, -5.6237e-01, -5.9038e-01,
-9.4807e-02, -7.5681e-02, -3.6990e-02,
 8.7385e-03, -5.7989e-02, -4.9573e-02,
-7.7422e-02, -1.1899e-01, -7.4023e-02,
 9.1539e-03, -1.1760e-01,  4.6825e-02,
 1.9901e-02, -3.9718e-02,  1.2997e-02,
 4.2209e-02, -5.2119e-02, -1.2255e-01,
 2.4262e-02,  5.3676e-02, -2.4767e-01,
-4.2933e-02, -2.2473e-01, -4.0310e-01,
-3.5160e-02,  1.9858e-01, -1.5943e-01,
 1.3208e-01, -1.0493e-01, -6.7076e-02,
-2.5244e-01,  1.1175e-02,  2.5568e-01,
-3.3867e-01,  3.1953e-02,  5.9426e-01,
 4.0551e-02,  4.4914e-03, -1.9348e-02,
-6.7386e-02, -1.5543e-01, -3.0883e-02,
 8.9177e-02, -4.6432e-02,  6.8227e-02,
 8.7784e-02,  3.6127e-02, -2.0375e-02,
 4.5461e-02, -4.9071e-02,  9.9435e-02,
-2.5700e-01, -2.7706e-01,  6.2776e-02,
-6.9571e-02, -5.7888e-03,  9.3852e-02,
 2.8490e-02, -2.7854e-01,  1.4209e-01,
 1.5373e-02, -4.3503e-02,  9.6895e-02,
 1.1682e-02,  1.5608e-01,  1.5844e-01,
 5.8027e-02,  2.6632e-02, -8.5479e-03,
 1.2836e-01,  2.0714e-01,  1.0228e-01,
 1.4647e-02,  5.7609e-02, -1.6728e-02,
 2.1212e-01,  3.2673e-01,  4.5670e-02,
-6.0844e-02, -1.1768e-01, -1.1233e-01,
 5.0123e-04,  6.3947e-02, -1.8356e-01,
 1.4091e-01, -2.1568e-02,  8.5933e-02,
-3.9406e-02,  8.2921e-02, -1.0601e-01,
 4.1284e-02, -7.3138e-02,  1.7264e-01,
 2.5883e-02,  5.2945e-01,  2.4510e-01,
 2.7291e-03,  4.0173e-02,  7.8221e-03,
-3.5795e-02, -4.8631e-03, -2.2715e-01,
 1.2330e-01,  7.1739e-01, -4.1725e-01,
 7.5106e-02,  2.5267e-02, -2.8655e-01,
-7.8731e-02, -7.5747e-03, -5.5601e-02,
 7.9764e-02,  1.0524e-01,  8.6742e-03,
 2.1791e-02,  3.7304e-02, -1.1534e-01,
-1.2011e-01, -7.5160e-02,  1.3737e-02,
-2.9470e-01,  2.6613e-01, -2.3740e-02,
 1.2957e-01,  1.4752e-01, -9.3655e-02,
 2.9828e-02,  2.0664e-01,  1.9731e-02,
-8.0378e-02, -3.9481e-01, -1.5395e-01,
-5.7944e-02, -8.6343e-02, -5.4324e-02,
 7.1664e-02,  1.5294e-01, -1.2112e-02,
 2.1023e-02,  1.1945e-01, -7.2998e-02,
-1.1693e-02, -1.8818e-01, -9.8693e-02,
-6.7017e-02,  6.9767e-02, -5.0268e-02,
-9.1106e-03,  2.4267e-01,  6.0277e-02,
 3.5269e-02,  7.7376e-02,  1.6642e-02,
-5.2600e-02, -1.8864e-01, -1.1195e-01,
 3.2119e-01, -9.7913e-02,  1.4734e-01,
 8.6988e-02, -5.3563e-03, -2.6136e-03,
-9.1528e-03,  2.8186e-01, -1.5933e-01,
 4.8499e-02,  4.5189e-01, -1.6399e-01,
 5.8164e-02,  6.3251e-02, -2.8738e-02,
 2.0424e-01, -7.2819e-02,  2.1903e-02,
-3.5630e-01,  1.3171e-01, -7.6749e-02,
 3.8848e-02,  1.7902e-01, -1.1902e-01,
-4.4221e-02,  1.5032e-02,  2.9078e-02,
-1.9738e-01, -1.4878e-02,  1.3315e-02,
 1.3956e-02,  1.2856e-01,  7.0688e-02,
 2.0933e-01,  1.7286e-01,  6.7601e-02,
 5.5136e-01,  4.6866e-01,  1.8402e-01,
 2.2362e-01,  2.4124e-01,  1.3167e-01
);

const float biasL[4] = float[4]
(
 9.3774e-04, -2.9944e-02, -1.1156e-03, -7.5635e-02
);

vec4 hook()
{
    vec4 tl1 = L1_1_texOff(vec2(-1,-1));
    vec4 tc1 = L1_1_texOff(vec2(0,-1));
    vec4 tr1 = L1_1_texOff(vec2(1,-1));
    vec4 ml1 = L1_1_texOff(vec2(-1,0));
    vec4 mc1 = L1_1_texOff(vec2(0,0));
    vec4 mr1 = L1_1_texOff(vec2(1,0));
    vec4 bl1 = L1_1_texOff(vec2(-1,1));
    vec4 bc1 = L1_1_texOff(vec2(0,1));
    vec4 br1 = L1_1_texOff(vec2(1,1));

    vec4 tl2 = L1_2_texOff(vec2(-1,-1));
    vec4 tc2 = L1_2_texOff(vec2(0,-1));
    vec4 tr2 = L1_2_texOff(vec2(1,-1));
    vec4 ml2 = L1_2_texOff(vec2(-1,0));
    vec4 mc2 = L1_2_texOff(vec2(0,0));
    vec4 mr2 = L1_2_texOff(vec2(1,0));
    vec4 bl2 = L1_2_texOff(vec2(-1,1));
    vec4 bc2 = L1_2_texOff(vec2(0,1));
    vec4 br2 = L1_2_texOff(vec2(1,1));

    vec4 c5678 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c5678;
}

//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L3
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-5.2308e-12, -5.4024e-12, -5.0039e-12,
-5.4553e-12, -5.6928e-12, -5.2812e-12,
-5.0230e-12, -5.2150e-12, -4.9133e-12,
 5.7994e-02,  1.0051e-01, -1.0618e-01,
 6.8090e-02,  1.2789e-01,  1.1380e-01,
-1.5882e-01,  8.2323e-03, -9.1424e-02,
 2.0132e-07,  2.0907e-07,  2.1344e-07,
 2.1179e-07,  2.2018e-07,  2.2381e-07,
 2.1095e-07,  2.1920e-07,  2.2150e-07,
 2.9336e-02,  5.4427e-02, -1.2082e-01,
 5.8399e-02,  2.2261e-01,  1.1165e-01,
-9.6098e-02,  8.3175e-02, -6.5909e-02,
 1.2007e-01,  1.9776e-01,  7.7464e-02,
 6.7018e-02,  3.6536e-01,  1.3796e-01,
 6.0724e-02,  4.6161e-02,  2.3740e-01,
-2.1117e-02, -2.0200e-02,  9.3703e-02,
-4.6932e-02, -1.5910e-01,  8.8094e-02,
-5.6641e-02, -1.7146e-01, -1.0502e-01,
-2.5624e-01,  1.6049e-01, -3.3267e-02,
-2.3248e-01,  5.4036e-01,  1.0027e-01,
-2.1680e-01, -7.0096e-03, -1.0692e-01,
-4.8357e-02,  2.5107e-01,  4.8323e-02,
 9.7245e-02,  5.5015e-01, -3.4641e-01,
 1.2458e-02, -1.3626e-01, -4.1992e-01,
-2.1359e-40, -1.4250e-40, -4.7123e-40,
-5.9433e-41,  1.9903e-41, -1.7701e-40,
-5.9941e-40, -5.8562e-40, -5.0226e-40,
-2.6581e-40,  1.3006e-40, -1.4201e-40,
 5.4264e-40,  2.3848e-40,  5.6412e-40,
-2.6378e-41, -5.7132e-40, -4.1343e-40,
-3.2848e-22, -3.6697e-22, -3.4147e-22,
-3.5780e-22, -3.9435e-22, -3.5989e-22,
-3.1212e-22, -3.4305e-22, -3.0670e-22,
-1.1749e-08, -1.1602e-08, -1.1494e-08,
-1.2125e-08, -1.1918e-08, -1.1718e-08,
-1.1779e-08, -1.1623e-08, -1.1559e-08,
-5.0237e-07, -4.9179e-07, -4.6744e-07,
-5.1967e-07, -5.0826e-07, -4.8421e-07,
-5.0226e-07, -4.9668e-07, -4.8019e-07,
 5.6433e-41, -3.0514e-40, -5.4526e-40,
 1.1125e-41,  2.9485e-40,  5.5282e-40,
 3.0229e-40,  1.5915e-40,  5.3759e-40,
-6.1144e-27, -9.2380e-26, -2.4302e-25,
-9.3834e-25, -1.0289e-23, -1.9513e-23,
-4.3746e-24, -4.4359e-23, -7.0505e-23,
-8.1604e-36, -3.2928e-37, -2.2994e-40,
-3.9543e-37, -9.9513e-39,  7.4616e-41,
-4.0044e-39,  4.4392e-40,  4.8856e-40,
-3.3447e-40, -3.9935e-40,  2.4649e-40,
 2.0207e-40, -3.0245e-40, -7.1986e-41,
 6.2938e-40, -3.6922e-40,  1.5296e-40,
-6.4982e-41,  5.0849e-41,  5.7873e-40,
 1.4327e-40, -4.2163e-40,  1.3807e-40,
 2.8569e-40,  1.9139e-40,  3.2985e-40,
-5.4410e-40,  2.3070e-40,  2.1690e-40,
-1.5964e-40, -2.2781e-40,  5.6766e-40,
 2.2533e-42, -2.5532e-40, -5.5822e-40,
 5.7249e-40,  5.3555e-40, -4.9107e-41,
 1.7538e-40, -1.2312e-40,  5.0077e-40,
 6.1500e-40,  1.9980e-40,  6.2953e-40,
-7.5314e-23, -9.4299e-23, -7.1342e-23,
-8.5139e-23, -1.1237e-22, -9.0478e-23,
-6.2038e-23, -8.5180e-23, -7.3015e-23,
 5.0613e-40,  1.5224e-40, -1.8977e-40,
 2.4108e-41, -5.1771e-40,  6.2317e-40,
 1.0465e-40,  2.8816e-41,  6.2500e-40,
 3.5727e-40,  4.2717e-40, -3.5900e-40,
-4.4831e-40,  3.4260e-40, -4.8293e-40,
-2.4133e-40,  3.1140e-40, -2.0777e-40,
-2.2906e-41,  3.5923e-40, -4.4443e-40,
-4.6615e-40, -2.1123e-40,  4.5700e-40,
-4.6360e-40, -3.6052e-40, -3.4319e-40,
-3.6575e-40, -3.5707e-40, -3.0530e-41,
 4.2531e-40, -1.2255e-40, -3.9607e-40,
 3.5903e-40, -5.4630e-40, -3.1460e-40,
 2.8820e-40,  4.9460e-40,  6.1461e-40,
 8.9118e-41, -4.6579e-40, -2.4172e-40,
-5.5474e-40, -8.1848e-41, -1.6910e-40,
-1.6272e-25, -1.8802e-25, -1.7229e-25,
-1.7850e-25, -2.0338e-25, -1.8235e-25,
-1.4715e-25, -1.6733e-25, -1.4681e-25,
-5.5471e-09, -5.6862e-09, -5.7043e-09,
-5.8727e-09, -5.9823e-09, -5.8983e-09,
-5.8040e-09, -5.8670e-09, -5.7388e-09,
-9.7253e-07, -9.7248e-07, -9.4623e-07,
-1.0149e-06, -1.0042e-06, -9.6709e-07,
-1.0139e-06, -9.9930e-07, -9.5295e-07,
-4.5042e-40,  2.6725e-40,  2.3181e-40,
-4.6274e-41, -1.1799e-40,  5.0685e-40,
-1.0765e-40,  3.3322e-40, -6.1905e-40,
-1.3653e-34, -3.4690e-33, -1.1578e-32,
-1.4444e-31, -2.1995e-30, -4.8668e-30,
-1.2965e-30, -2.0189e-29, -3.3962e-29,
-2.5057e-40,  7.2876e-41,  4.5731e-41,
-1.6525e-40,  5.0987e-40, -5.4683e-40,
 8.1836e-41,  6.2722e-40, -3.1057e-40
);

const float biasL[4] = float[4]
(
-1.7701e-01, -1.3417e-06, -3.0706e-40, -1.9022e-06
);

vec4 hook()
{
    vec4 tl1 = L2_1_texOff(vec2(-1,-1));
    vec4 tc1 = L2_1_texOff(vec2(0,-1));
    vec4 tr1 = L2_1_texOff(vec2(1,-1));
    vec4 ml1 = L2_1_texOff(vec2(-1,0));
    vec4 mc1 = L2_1_texOff(vec2(0,0));
    vec4 mr1 = L2_1_texOff(vec2(1,0));
    vec4 bl1 = L2_1_texOff(vec2(-1,1));
    vec4 bc1 = L2_1_texOff(vec2(0,1));
    vec4 br1 = L2_1_texOff(vec2(1,1));

    vec4 tl2 = L2_2_texOff(vec2(-1,-1));
    vec4 tc2 = L2_2_texOff(vec2(0,-1));
    vec4 tr2 = L2_2_texOff(vec2(1,-1));
    vec4 ml2 = L2_2_texOff(vec2(-1,0));
    vec4 mc2 = L2_2_texOff(vec2(0,0));
    vec4 mr2 = L2_2_texOff(vec2(1,0));
    vec4 bl2 = L2_2_texOff(vec2(-1,1));
    vec4 bc2 = L2_2_texOff(vec2(0,1));
    vec4 br2 = L2_2_texOff(vec2(1,1));

    vec4 c1234 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c1234;
}


//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L3
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 4.0987e-40,  3.5941e-40,  5.1680e-40,
 5.5563e-40,  3.1011e-40,  4.7068e-40,
 1.0426e-40, -1.0803e-40,  4.4867e-40,
-4.9675e-03,  1.5412e-01, -4.1930e-03,
-6.1089e-02,  2.0405e-01,  1.9587e-01,
 3.8772e-02,  1.6894e-01, -2.6163e-02,
 1.0839e-30,  1.8608e-30,  1.1386e-30,
 1.4863e-29,  1.9422e-29,  1.1639e-29,
 1.7504e-29,  2.2177e-29,  1.3629e-29,
 6.4484e-02,  6.6296e-02,  2.2838e-01,
-1.0213e-01,  7.5883e-02, -1.7531e-01,
-1.4869e-01,  1.0736e-01,  1.4129e-01,
-2.8235e-02, -2.9232e-02, -9.3912e-02,
 5.1317e-02,  9.0256e-02, -2.4669e-02,
-3.2465e-02,  5.8099e-02,  9.8402e-02,
-2.3135e-01, -1.3786e-01,  2.8581e-01,
-3.2410e-01, -2.6623e-01,  6.1583e-02,
 1.8696e-01,  4.7251e-02, -2.3520e-01,
 2.5630e-02, -1.2358e-01, -1.5735e-01,
-1.2198e-01,  5.1970e-01,  1.9976e-01,
-1.2515e-01,  9.8768e-02,  5.8917e-02,
-3.8569e-02, -9.2729e-02, -1.8982e-01,
 1.1378e-01,  5.7195e-01, -1.8265e-01,
-3.5724e-02, -2.1379e-01, -2.2129e-01,
-5.1198e-40, -3.4709e-40,  6.2940e-40,
-2.2134e-41, -3.6133e-40, -2.7075e-40,
-5.9664e-40, -2.3937e-40,  3.0876e-40,
 9.1814e-41,  9.5898e-41, -3.1892e-40,
 3.1093e-40,  2.7935e-40,  1.7966e-40,
-2.3967e-40,  4.0806e-40,  6.2012e-40,
 5.3771e-41,  6.1000e-40, -4.6695e-40,
 5.9474e-41, -4.9675e-40,  5.7403e-41,
 4.7091e-40, -5.0751e-41,  3.9864e-41,
-9.7756e-41,  2.7978e-40, -5.0791e-40,
-3.4321e-40, -7.0774e-41, -5.2651e-40,
 2.8034e-40, -3.3452e-40,  1.9535e-40,
-6.2300e-40, -1.8372e-40, -1.9038e-40,
-5.6564e-40, -6.1257e-40, -1.0338e-40,
-1.7191e-41, -1.2843e-41,  5.0707e-40,
-4.4587e-40,  2.7128e-40, -1.4155e-40,
-5.7475e-40, -3.4612e-40, -4.7424e-40,
 1.7235e-40, -6.0028e-40, -1.6342e-40,
-5.1072e-40, -2.4721e-40, -2.8477e-41,
 2.6598e-40, -4.4078e-40,  4.1763e-40,
-3.3947e-40, -5.5626e-40,  4.9713e-40,
 2.1733e-40, -2.9024e-40, -4.5514e-42,
-3.4873e-40, -1.0737e-40, -1.4297e-40,
 2.8514e-40,  2.6283e-40,  2.2827e-40,
 3.8908e-40, -4.2140e-40,  6.1433e-40,
-4.7825e-40, -3.0140e-40, -5.9563e-40,
 1.5280e-40,  2.6156e-40,  5.0361e-40,
 1.9497e-01,  2.3140e-01, -3.5244e-02,
 1.6876e-01, -1.7646e-02, -2.0413e-01,
 9.8052e-02, -6.7906e-02, -3.9834e-02,
-5.9252e-15, -6.7431e-15, -8.1865e-15,
-5.7350e-15, -6.6893e-15, -8.9833e-15,
-8.4106e-15, -1.0631e-14, -1.5948e-14,
 8.9389e-02,  6.6460e-02,  6.8477e-02,
 6.1099e-03, -8.7536e-02,  1.1792e-01,
-1.0079e-01,  1.5293e-01,  4.3945e-02,
 1.0168e-01,  1.0281e-01, -7.9173e-02,
 2.0855e-01,  1.7537e-01, -7.1000e-02,
-1.4157e-01, -3.8478e-02, -2.7478e-01,
 2.2156e-01, -6.4262e-02, -7.2841e-02,
-3.2334e-01,  6.5591e-02,  1.1163e-01,
 7.2151e-02, -1.6943e-01,  5.9049e-02,
-1.4813e-01, -2.0904e-01, -8.8010e-02,
-2.7215e-01,  5.7668e-01,  1.7618e-02,
-7.1365e-02,  1.2976e-01, -1.0169e-01,
-8.9229e-02,  3.3971e-02,  1.8295e-01,
 1.7204e-01,  3.8082e-01,  3.7415e-02,
 5.9309e-02, -4.9550e-04,  5.1555e-01,
-5.1006e-18, -5.6038e-18, -5.8724e-18,
-5.8910e-18, -5.8379e-18, -5.6311e-18,
-5.2596e-18, -5.1835e-18, -4.6300e-18,
 6.4067e-02,  1.8889e-02, -1.0634e-01,
 1.7316e-04,  1.9935e-01, -1.1854e-02,
-9.3669e-02, -1.1924e-01, -1.8981e-02,
 1.7465e-08,  1.7340e-08,  1.7565e-08,
 1.8234e-08,  1.8008e-08,  1.8017e-08,
 1.9226e-08,  1.8956e-08,  1.8651e-08,
-1.7294e-01, -1.2200e-01, -4.9577e-02,
-3.5087e-02, -1.2526e-01,  9.3445e-03,
-7.4374e-02, -1.1350e-01,  2.7510e-03,
 8.5153e-02,  4.2080e-02, -5.0111e-02,
 1.2845e-01,  1.9630e-01,  1.0542e-01,
-1.0095e-01,  6.2631e-02,  8.8734e-02,
 3.4836e-01,  5.4389e-01, -2.2360e-01,
 5.1721e-01,  5.7094e-01, -6.7491e-02,
-3.5972e-02,  1.0590e-01, -2.2984e-01,
-1.5483e-01, -5.1271e-03,  4.9780e-02,
-1.3184e-01,  2.8028e-01, -1.1427e-02,
-3.4093e-02, -6.7622e-02, -1.2359e-02,
 1.3184e-02,  1.2125e-01, -1.2502e-02,
 9.2730e-02, -6.5974e-02, -1.6519e-01,
 1.9546e-01, -1.5188e-01, -8.1752e-02
);

const float biasL[4] = float[4]
(
-1.2965e-02, -6.6444e-40,  1.4699e-02,  2.6082e-02
);

vec4 hook()
{
    vec4 tl1 = L2_1_texOff(vec2(-1,-1));
    vec4 tc1 = L2_1_texOff(vec2(0,-1));
    vec4 tr1 = L2_1_texOff(vec2(1,-1));
    vec4 ml1 = L2_1_texOff(vec2(-1,0));
    vec4 mc1 = L2_1_texOff(vec2(0,0));
    vec4 mr1 = L2_1_texOff(vec2(1,0));
    vec4 bl1 = L2_1_texOff(vec2(-1,1));
    vec4 bc1 = L2_1_texOff(vec2(0,1));
    vec4 br1 = L2_1_texOff(vec2(1,1));

    vec4 tl2 = L2_2_texOff(vec2(-1,-1));
    vec4 tc2 = L2_2_texOff(vec2(0,-1));
    vec4 tr2 = L2_2_texOff(vec2(1,-1));
    vec4 ml2 = L2_2_texOff(vec2(-1,0));
    vec4 mc2 = L2_2_texOff(vec2(0,0));
    vec4 mr2 = L2_2_texOff(vec2(1,0));
    vec4 bl2 = L2_2_texOff(vec2(-1,1));
    vec4 bc2 = L2_2_texOff(vec2(0,1));
    vec4 br2 = L2_2_texOff(vec2(1,1));

    vec4 c5678 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c5678;
}

//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L4
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-3.4905e-04, -3.5739e-04, -3.2920e-04,
-3.8506e-04, -3.9121e-04, -3.5635e-04,
-3.7303e-04, -3.7698e-04, -3.4190e-04,
 2.8622e-41, -1.2033e-41,  1.2609e-40,
-4.9379e-40, -5.1047e-40,  5.5085e-41,
-4.7002e-40, -5.0136e-40, -4.5629e-40,
-5.1095e-40,  1.8741e-40,  1.8435e-40,
 4.1851e-40, -8.9558e-41, -9.6681e-41,
-1.8244e-40,  2.7992e-40,  1.8116e-40,
 2.8655e-40, -3.0193e-40,  2.2293e-40,
 1.6805e-40,  3.3049e-40,  6.9542e-41,
-3.3329e-40,  4.2212e-40, -1.3453e-40,
-8.4502e-15, -1.1099e-14, -9.4174e-15,
-9.8778e-15, -1.1768e-14, -9.4875e-15,
-6.7805e-15, -7.4561e-15, -5.8023e-15,
 6.0452e-40,  6.9262e-41,  2.9300e-40,
-6.1511e-40, -4.1269e-40,  4.4012e-40,
 1.3340e-42, -2.9020e-40, -4.5529e-40,
-1.2289e-22, -1.3972e-21, -5.5694e-21,
-1.7854e-21, -1.7743e-20, -5.6749e-20,
-6.8510e-21, -6.2353e-20, -1.6203e-19,
-5.0003e-07, -5.1950e-07, -4.7654e-07,
-5.5510e-07, -5.7995e-07, -5.2753e-07,
-5.3262e-07, -5.5802e-07, -5.0971e-07,
-1.4922e-02, -1.1926e-01, -1.9067e-02,
-2.6298e-03,  2.1756e-01,  3.0148e-02,
 1.4372e-01,  3.5066e-02, -1.0184e-02,
-4.1698e-12, -4.8798e-12, -6.4033e-12,
-2.3169e-12, -2.7879e-12, -3.7276e-12,
-1.6177e-12, -2.0021e-12, -2.6440e-12,
-5.9514e-40, -4.4339e-40, -3.0315e-40,
 3.5756e-40,  2.5390e-40, -1.2253e-40,
 2.1417e-40,  4.0569e-40,  5.3962e-40,
-5.5825e-13, -6.8528e-13, -9.3486e-13,
-2.9163e-13, -3.6959e-13, -5.1183e-13,
-1.8703e-13, -2.4740e-13, -3.4019e-13,
-2.7137e-01, -4.5025e-01,  2.6405e-02,
-7.9580e-02,  5.0698e-01, -7.8794e-02,
-3.7540e-02, -7.1115e-03, -3.9741e-01,
-5.9910e-40, -5.5101e-40,  3.1274e-41,
-6.9384e-41, -4.9294e-40, -1.0818e-40,
-3.5484e-40, -4.7965e-41, -5.2508e-41,
 4.1917e-01, -1.6207e-02, -6.8506e-02,
-2.7060e-02,  5.6162e-01,  1.6696e-01,
-1.7677e-03,  1.8842e-01, -6.0493e-02,
-3.0696e-01, -1.7293e-01, -8.7143e-02,
-1.6740e-01,  1.8861e-02, -1.7112e-01,
 8.6594e-02,  3.0025e-01, -7.6141e-02,
 1.1317e-02,  1.0678e-01, -5.1283e-02,
-1.2872e-01,  4.2580e-01,  4.9678e-02,
-2.8372e-01, -1.3479e-01, -7.3813e-02,
-1.7038e-15, -1.1156e-15, -7.3385e-16,
-2.6350e-15, -1.6234e-15, -1.0598e-15,
-7.7860e-15, -4.6981e-15, -3.0030e-15,
-3.0246e-40, -4.1596e-40,  2.9013e-40,
 8.5195e-41, -2.2396e-40, -2.0322e-40,
-5.6200e-40,  2.4820e-40,  3.1309e-40,
-3.1822e-17, -1.6585e-17, -8.8616e-18,
-5.9907e-17, -2.9812e-17, -1.6126e-17,
-2.4410e-16, -1.2541e-16, -6.7867e-17,
 1.5795e-01, -1.4429e-01, -6.0501e-02,
 5.9113e-02,  3.4391e-01,  1.4165e-01,
 5.2564e-02, -1.8209e-01, -6.8176e-02,
-7.7363e-41,  5.9969e-40,  5.9290e-40,
-7.4888e-41, -7.0945e-41,  5.3120e-40,
 1.3612e-40, -4.6718e-40, -1.0677e-40,
-1.1498e-01, -1.2925e-02,  2.6735e-02,
-8.1469e-02,  2.9678e-01,  1.8971e-01,
 2.0149e-02,  2.4207e-03, -1.2549e-01,
-6.6799e-02, -3.5900e-02, -5.6111e-02,
 9.5181e-02,  2.1216e-02,  2.0477e-01,
 8.5923e-03,  6.8615e-03,  3.8252e-02,
 4.5098e-03,  2.1321e-01,  3.4612e-03,
 3.5662e-01,  4.7532e-02,  2.5319e-01,
 4.1275e-02,  1.7951e-01,  3.2239e-02,
-2.6628e-21, -7.7165e-22, -4.9086e-22,
-1.4320e-21, -2.7134e-22, -1.2712e-22,
-1.9648e-21, -3.4172e-22, -1.3895e-22,
-2.2836e-40,  3.2091e-40, -4.4396e-40,
 2.9048e-40,  6.0866e-40,  3.7804e-40,
-3.0676e-40, -2.4897e-40,  4.9891e-40,
-1.8955e-28, -3.4994e-29, -1.2914e-29,
-4.7737e-29, -3.5212e-30, -6.4003e-31,
-8.2908e-29, -3.1692e-30, -3.6909e-31,
-9.3327e-02,  1.5314e-01,  1.0676e-01,
 2.5979e-01, -6.6826e-01,  2.3727e-01,
 1.4855e-01,  1.9205e-01,  8.8246e-02,
-5.5197e-40,  5.3162e-41, -5.2933e-40,
 1.0846e-41, -5.8128e-40, -3.1273e-40,
-2.8408e-40,  1.6989e-40,  4.8221e-41,
 7.8403e-02,  1.6407e-01,  7.9932e-02,
 3.2253e-01, -2.6036e-01, -8.9727e-02,
-7.5145e-02,  1.5536e-02, -8.2710e-02,
-2.1608e-01, -4.4619e-01, -4.4470e-02,
-3.9430e-01, -8.2373e-01, -7.0646e-01,
-6.9004e-03, -4.9697e-01, -1.4212e-01
);

const float biasL[4] = float[4]
(
-3.7577e-07,  4.4550e-03, -8.1266e-04,  3.2408e-01
);

vec4 hook()
{
    vec4 tl1 = L1_1_texOff(vec2(-1,-1));
    vec4 tc1 = L1_1_texOff(vec2(0,-1));
    vec4 tr1 = L1_1_texOff(vec2(1,-1));
    vec4 ml1 = L1_1_texOff(vec2(-1,0));
    vec4 mc1 = L1_1_texOff(vec2(0,0));
    vec4 mr1 = L1_1_texOff(vec2(1,0));
    vec4 bl1 = L1_1_texOff(vec2(-1,1));
    vec4 bc1 = L1_1_texOff(vec2(0,1));
    vec4 br1 = L1_1_texOff(vec2(1,1));

    vec4 tl2 = L1_2_texOff(vec2(-1,-1));
    vec4 tc2 = L1_2_texOff(vec2(0,-1));
    vec4 tr2 = L1_2_texOff(vec2(1,-1));
    vec4 ml2 = L1_2_texOff(vec2(-1,0));
    vec4 mc2 = L1_2_texOff(vec2(0,0));
    vec4 mr2 = L1_2_texOff(vec2(1,0));
    vec4 bl2 = L1_2_texOff(vec2(-1,1));
    vec4 bc2 = L1_2_texOff(vec2(0,1));
    vec4 br2 = L1_2_texOff(vec2(1,1));

    vec4 c1234 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c1234;
}


//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L4
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-1.8932e-06, -1.8356e-06, -1.6373e-06,
-1.9427e-06, -1.9113e-06, -1.7028e-06,
-1.8843e-06, -1.8616e-06, -1.6818e-06,
-4.7452e-29, -4.4894e-29, -2.5364e-29,
-5.6268e-29, -5.4363e-29, -3.0876e-29,
-4.3808e-29, -4.2767e-29, -2.4573e-29,
 3.8855e-40,  3.5152e-40, -4.8707e-40,
 4.3606e-41, -1.7886e-40,  5.1970e-40,
 6.2864e-40,  5.9972e-40,  2.2197e-40,
-2.1903e-37, -1.9174e-37, -7.0785e-38,
-2.7149e-37, -2.4810e-37, -9.5619e-38,
-1.8463e-37, -1.7136e-37, -6.7163e-38,
-2.9062e-30, -3.1324e-30, -1.0876e-30,
-2.7434e-30, -3.7036e-30, -1.2821e-30,
-6.8828e-31, -9.8708e-31, -3.7930e-31,
-6.3329e-41, -3.8604e-41, -2.8272e-40,
-3.3350e-40, -1.5210e-40, -4.2620e-41,
-1.7669e-41,  5.2291e-40, -3.3205e-40,
-3.0738e-25, -8.2305e-24, -2.1451e-23,
-1.4470e-24, -4.5131e-23, -1.2177e-22,
-4.2841e-24, -1.3077e-22, -3.5946e-22,
-8.5637e-08, -8.4715e-08, -7.7597e-08,
-8.7326e-08, -8.7480e-08, -8.0290e-08,
-8.4525e-08, -8.4963e-08, -7.8582e-08,
-5.8581e-27, -8.8483e-27, -8.1150e-27,
-7.4336e-27, -1.2036e-26, -1.1909e-26,
-6.6006e-27, -1.0685e-26, -1.0809e-26,
-5.6355e-40, -2.3469e-40, -3.5885e-40,
-2.0755e-40,  2.0377e-40,  3.2259e-40,
-5.3947e-40,  4.2747e-41,  4.8967e-41,
 4.5073e-41,  5.0069e-40,  2.6114e-40,
-4.8225e-40, -4.8317e-40, -5.4316e-40,
-5.4335e-40, -5.2994e-40,  2.6295e-40,
-1.1702e-40, -2.3137e-41, -4.5405e-40,
-4.6797e-40,  6.5582e-41,  1.8111e-40,
 6.1477e-40, -1.6827e-40, -2.0288e-40,
-2.4220e-41,  4.7774e-40,  5.1050e-40,
 4.9844e-40,  5.6437e-41,  4.7749e-40,
-6.8037e-41, -5.5944e-41, -5.2248e-40,
-2.9382e-40,  2.3800e-41,  1.5850e-40,
-4.5290e-40, -5.2260e-41,  2.3726e-40,
-1.9232e-40, -2.3502e-40, -2.9736e-40,
-2.8081e-40, -5.2929e-40, -4.0786e-40,
-3.0303e-41,  3.1336e-40, -5.8450e-40,
-1.5091e-40, -2.7371e-40, -4.5927e-40,
-4.0985e-38, -6.9102e-38, -5.4450e-38,
-6.2744e-38, -1.1526e-37, -9.9374e-38,
-4.8587e-38, -9.1819e-38, -8.0593e-38,
-2.9266e-29, -4.5005e-29, -3.9891e-29,
-3.8505e-29, -6.3370e-29, -6.0017e-29,
-3.2761e-29, -5.4145e-29, -5.1812e-29,
 3.3692e-40,  1.0044e-40, -6.6821e-41,
 9.2910e-41,  6.2137e-40, -3.5625e-40,
 1.8601e-40,  3.1653e-40, -1.1506e-40,
 1.2093e-40, -5.7191e-40,  5.6828e-40,
-2.3177e-40, -2.1648e-40,  5.3642e-40,
 4.8826e-40,  5.2760e-40, -4.9059e-40,
-2.0721e-40,  2.0122e-40, -5.9485e-40,
 3.8843e-40, -6.0861e-41, -4.0542e-40,
-3.4308e-40, -4.2822e-40, -3.9605e-40,
-5.7429e-40,  4.9242e-40, -5.9141e-40,
 4.6267e-40, -2.4953e-40, -2.9300e-40,
 5.3466e-40, -5.2403e-40,  3.5178e-40,
-1.8309e-40,  2.9157e-40, -7.7367e-41,
-5.8922e-40,  3.2359e-40, -6.1293e-40,
 6.1138e-40,  2.2121e-40, -5.0657e-42,
 4.7910e-40, -1.4080e-40,  1.9220e-40,
-3.5670e-40,  3.4204e-40, -5.0215e-40,
 1.1877e-41,  2.3114e-40, -4.7794e-40,
-3.6520e-40,  4.3222e-40, -5.2866e-40,
-6.0703e-40, -4.0896e-40, -1.2521e-40,
-4.1981e-40,  5.4404e-41,  3.3337e-40,
 1.3733e-01,  1.8485e-01,  7.6179e-02,
 8.1719e-02,  3.3343e-01,  2.9857e-02,
-4.2753e-03,  2.0957e-01,  1.8582e-02,
 2.9948e-07,  3.3403e-07,  3.7619e-07,
 3.4854e-07,  3.8224e-07,  4.1507e-07,
 3.7511e-07,  4.0398e-07,  4.3743e-07,
-1.7150e-41, -2.4088e-41, -1.5593e-40,
 6.3817e-41,  4.8004e-41, -1.1053e-40,
-2.5225e-40, -2.7111e-40, -4.2970e-40,
 1.0496e-06,  1.0916e-06,  1.1376e-06,
 1.1364e-06,  1.1756e-06,  1.2051e-06,
 1.1762e-06,  1.2105e-06,  1.2358e-06,
 1.0037e-02,  1.4957e-01, -4.9010e-02,
 2.6877e-02,  1.9067e-01, -1.9339e-03,
-2.2081e-02, -1.5137e-01, -1.6088e-01,
 1.6880e-41, -2.0352e-41, -4.1857e-42,
 2.0926e-40, -2.1394e-41, -5.4341e-40,
 4.6824e-40,  6.2682e-40,  4.9865e-40,
-3.2967e-01, -2.5981e-01, -1.3016e-01,
-2.6507e-01,  3.2282e-01,  4.3204e-01,
-7.0936e-02,  1.9800e-01,  9.4916e-02,
-1.0122e-02,  7.4127e-02, -7.1554e-02,
 7.7869e-02,  1.5734e-01,  1.3287e-01,
-9.5431e-02,  1.0984e-01, -7.6759e-02
);

const float biasL[4] = float[4]
(
-1.1321e-07, -1.8907e-23, -1.9770e-25, -3.2394e-02
);

vec4 hook()
{
    vec4 tl1 = L1_1_texOff(vec2(-1,-1));
    vec4 tc1 = L1_1_texOff(vec2(0,-1));
    vec4 tr1 = L1_1_texOff(vec2(1,-1));
    vec4 ml1 = L1_1_texOff(vec2(-1,0));
    vec4 mc1 = L1_1_texOff(vec2(0,0));
    vec4 mr1 = L1_1_texOff(vec2(1,0));
    vec4 bl1 = L1_1_texOff(vec2(-1,1));
    vec4 bc1 = L1_1_texOff(vec2(0,1));
    vec4 br1 = L1_1_texOff(vec2(1,1));

    vec4 tl2 = L1_2_texOff(vec2(-1,-1));
    vec4 tc2 = L1_2_texOff(vec2(0,-1));
    vec4 tr2 = L1_2_texOff(vec2(1,-1));
    vec4 ml2 = L1_2_texOff(vec2(-1,0));
    vec4 mc2 = L1_2_texOff(vec2(0,0));
    vec4 mr2 = L1_2_texOff(vec2(1,0));
    vec4 bl2 = L1_2_texOff(vec2(-1,1));
    vec4 bc2 = L1_2_texOff(vec2(0,1));
    vec4 br2 = L1_2_texOff(vec2(1,1));

    vec4 c5678 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c5678;
}

//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L5
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-5.5262e-40,  3.7699e-40, -1.4920e-40,
 4.0064e-40, -2.0632e-40, -4.4801e-41,
-3.6749e-40,  5.9043e-40, -1.5942e-40,
-5.9219e-42, -4.1286e-40, -1.6920e-40,
-2.5927e-40, -4.5458e-41,  2.0990e-40,
-4.6860e-40,  5.0483e-40,  2.8004e-40,
-4.0641e-40,  6.0770e-40, -3.8297e-42,
 5.7537e-40,  5.7772e-40, -1.0048e-40,
 1.5945e-40,  3.9582e-40, -2.6190e-40,
-5.1046e-40, -5.5028e-40,  5.8786e-40,
-3.5033e-40, -1.2031e-40, -3.4156e-40,
 3.0058e-40,  4.3043e-40,  5.9825e-40,
 4.9197e-40,  2.5974e-40, -4.3461e-41,
-4.1935e-40, -1.6383e-41, -1.4680e-40,
-5.3501e-40, -2.6348e-40,  3.0631e-40,
-5.2019e-40, -4.4123e-40,  2.3984e-40,
-4.4682e-41, -4.6000e-40, -5.0418e-40,
-4.1263e-40,  4.5391e-40,  2.8844e-40,
 5.2179e-40, -1.3188e-40,  5.1600e-40,
-2.2913e-40, -3.1127e-40,  5.4478e-40,
 2.3395e-41,  5.4758e-40,  2.0998e-40,
-1.9914e-10, -2.0700e-10, -1.9815e-10,
-2.1098e-10, -2.1989e-10, -2.1131e-10,
-2.0797e-10, -2.1693e-10, -2.0860e-10,
-2.1061e-40, -2.1208e-40, -3.3698e-40,
 3.2370e-40,  2.9276e-40, -3.6860e-40,
 3.4752e-40, -2.0660e-40, -3.8183e-40,
-8.0136e-02,  1.3809e-02,  1.6846e-03,
 3.7960e-02,  8.7557e-02, -3.5498e-01,
 9.8165e-03,  9.8384e-02,  1.2395e-01,
-2.8751e-02,  9.9172e-02,  5.5841e-02,
-4.0383e-02,  1.0856e-01, -5.4339e-01,
 1.3245e-02, -4.7642e-02, -1.0427e-01,
-7.4696e-03,  5.0806e-02, -1.7179e-01,
 5.0303e-02, -4.0322e-01,  7.4760e-01,
-9.2342e-02,  1.1958e-01, -1.8871e-01,
 3.7044e-40, -4.6951e-40, -1.9873e-40,
 5.3289e-41,  2.7689e-40, -4.6994e-41,
-3.1404e-40, -5.9106e-40,  6.0436e-40,
-6.0294e-40, -3.6565e-40, -1.1884e-40,
 5.5933e-40, -9.5741e-41,  4.4736e-40,
 4.3267e-40, -4.9583e-40,  3.4437e-40,
-1.7432e-40,  1.4518e-40,  2.1033e-40,
-3.4667e-40,  1.7222e-40, -2.5651e-40,
-5.2517e-40,  2.8983e-41, -1.3832e-40,
-1.4153e-01,  9.4023e-02, -9.8526e-02,
 2.0678e-01,  4.0842e-01, -1.1853e-01,
-1.4108e-01, -1.1005e-01, -8.1274e-02,
 3.4336e-41,  1.5625e-40,  2.7213e-40,
-5.3447e-40, -3.7330e-40, -3.3637e-40,
-4.3563e-40, -3.7094e-40,  1.2820e-41,
-8.1700e-02, -1.8215e-01, -1.6011e-01,
-1.4203e-01,  5.3791e-02, -3.7663e-02,
-1.1705e-01, -1.2604e-01, -8.4890e-03,
-6.1578e-02, -3.3907e-01,  2.2344e-03,
 1.5060e-01, -1.9199e-01, -5.5274e-02,
 6.2300e-02,  9.1084e-02,  1.3788e-02,
 4.9025e-02,  3.3738e-01, -1.8104e-01,
-2.5051e-01,  8.2363e-02,  2.0325e-01,
 5.6988e-02, -1.5118e-01,  6.8897e-02,
-4.6233e-40,  1.2244e-40, -3.9802e-40,
 5.8530e-40, -2.4162e-40,  4.6793e-40,
-4.8362e-40,  3.3071e-40,  1.7094e-40,
 3.5249e-40, -4.8579e-40,  1.9374e-40,
 6.2372e-42,  5.8402e-41,  3.2851e-40,
 6.1488e-40,  1.8086e-40, -5.2451e-40,
-3.0723e-40, -5.6704e-40, -5.9899e-40,
-3.5975e-40, -1.3818e-40, -2.7285e-40,
 2.4468e-40,  8.3606e-41,  1.8818e-40,
-2.3749e-01, -2.7008e-01, -1.5222e-03,
 1.4806e-01,  9.0783e-02,  2.7170e-02,
 1.8706e-01,  1.8162e-01, -1.1799e-01,
-1.9852e-40, -4.8879e-40, -3.1971e-40,
-1.0245e-40,  9.1421e-41,  5.3018e-40,
 2.2240e-40, -1.4666e-40, -4.4259e-40,
 1.1835e-01, -2.7624e-01,  1.1446e-01,
 1.3574e-01,  4.3109e-01,  1.3227e-01,
 3.2554e-02,  1.7139e-01, -1.1988e-01,
 3.5376e-02,  8.9191e-02,  6.7643e-02,
-8.2716e-02,  2.4178e-01,  6.0818e-02,
-6.7722e-02, -3.3712e-02,  3.0664e-02,
-6.6948e-02,  2.2886e-01,  1.8143e-01,
 1.8636e-01, -2.4800e-01,  1.7185e-01,
-6.5479e-03,  1.8828e-01, -7.4464e-02,
-2.8281e-30, -5.8969e-31, -2.3180e-31,
-1.6163e-30, -3.8426e-31, -1.6788e-31,
-1.9412e-30, -4.1995e-31, -1.7651e-31,
-2.0525e-40,  4.6680e-40,  5.9108e-41,
 1.0336e-40, -5.7226e-41, -6.1906e-40,
-1.8693e-40,  5.5777e-40,  6.0898e-40,
-3.4735e-41, -3.2674e-40, -2.3864e-41,
-3.3596e-40,  3.3107e-40,  1.0843e-40,
 5.1103e-40,  6.0598e-40, -3.6267e-40,
-4.5583e-03, -1.0635e-01, -7.4962e-02,
-1.2741e-01,  2.7234e-01,  1.0508e-01,
-2.1207e-01,  9.6720e-02,  3.4641e-02
);

const float biasL[4] = float[4]
(
-2.1525e-14, -1.4130e-02, -1.9410e-02, -1.8703e-02
);

vec4 hook()
{
    vec4 tl1 = L2_1_texOff(vec2(-1,-1));
    vec4 tc1 = L2_1_texOff(vec2(0,-1));
    vec4 tr1 = L2_1_texOff(vec2(1,-1));
    vec4 ml1 = L2_1_texOff(vec2(-1,0));
    vec4 mc1 = L2_1_texOff(vec2(0,0));
    vec4 mr1 = L2_1_texOff(vec2(1,0));
    vec4 bl1 = L2_1_texOff(vec2(-1,1));
    vec4 bc1 = L2_1_texOff(vec2(0,1));
    vec4 br1 = L2_1_texOff(vec2(1,1));

    vec4 tl2 = L2_2_texOff(vec2(-1,-1));
    vec4 tc2 = L2_2_texOff(vec2(0,-1));
    vec4 tr2 = L2_2_texOff(vec2(1,-1));
    vec4 ml2 = L2_2_texOff(vec2(-1,0));
    vec4 mc2 = L2_2_texOff(vec2(0,0));
    vec4 mr2 = L2_2_texOff(vec2(1,0));
    vec4 bl2 = L2_2_texOff(vec2(-1,1));
    vec4 bc2 = L2_2_texOff(vec2(0,1));
    vec4 br2 = L2_2_texOff(vec2(1,1));

    vec4 c1234 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c1234;
}


//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L5
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 1.1304e-12,  1.1614e-12,  9.7086e-13,
 1.3361e-12,  1.3697e-12,  1.1286e-12,
 1.2620e-12,  1.2938e-12,  1.0680e-12,
-8.4197e-02,  6.3834e-02,  2.3157e-02,
-2.1280e-02,  2.9074e-01,  8.5883e-02,
-1.3695e-01, -1.6047e-01, -4.5834e-02,
-1.3848e-01, -6.6090e-02, -7.7201e-02,
-5.1963e-02,  6.0643e-02, -4.9932e-02,
 1.1779e-01,  1.7521e-01,  3.0366e-02,
 4.7601e-03,  4.3941e-02, -3.5985e-02,
 1.7692e-02, -2.3705e-01,  2.1062e-01,
 7.7174e-02, -7.6616e-02,  2.0102e-02,
-3.6353e-06, -3.5534e-06, -3.2461e-06,
-3.6813e-06, -3.6196e-06, -3.3222e-06,
-3.5581e-06, -3.5179e-06, -3.2504e-06,
-7.3892e-11, -7.2930e-11, -6.8104e-11,
-7.9244e-11, -7.7770e-11, -7.2319e-11,
-7.7297e-11, -7.5673e-11, -7.0195e-11,
-1.5180e-10, -1.5027e-10, -1.4244e-10,
-1.6013e-10, -1.5761e-10, -1.4940e-10,
-1.5682e-10, -1.5395e-10, -1.4553e-10,
-9.1167e-02,  1.2374e-01, -3.8304e-02,
 2.2641e-01,  2.4855e-01, -4.3174e-02,
 1.4364e-01,  1.8438e-01,  1.1617e-02,
 6.1925e-40,  3.3333e-40,  1.8962e-40,
 3.2481e-40, -1.7566e-40, -3.0456e-40,
 2.7654e-40,  3.8422e-41,  4.9191e-40,
 7.5657e-02, -1.0697e-03,  3.0319e-02,
-4.7642e-02, -9.4454e-02, -2.6543e-02,
-5.3129e-02, -1.9667e-01, -1.0851e-01,
-8.5909e-03,  1.2177e-01,  2.6434e-01,
 2.4468e-02,  5.0484e-02,  3.4698e-01,
-1.4764e-03,  3.7374e-02,  1.2658e-01,
 2.0602e-02, -2.4624e-02,  1.3741e-01,
 1.8641e-02,  4.0484e-01,  3.2976e-01,
-4.4809e-01, -3.2104e-03,  1.6290e-03,
 8.1306e-41,  2.0311e-40,  2.9683e-40,
-5.7636e-40,  4.4291e-40,  4.3356e-40,
-7.1797e-41,  4.5366e-40,  3.9953e-40,
-4.5418e-40,  4.1805e-40, -3.2458e-41,
-9.4881e-41, -8.6365e-41, -1.9294e-40,
 7.1954e-41, -9.8565e-41, -5.5540e-40,
-5.3769e-40,  1.4094e-40, -1.5355e-40,
 8.8038e-41, -3.6848e-40, -1.2237e-40,
-2.8267e-41, -1.7583e-40, -5.9647e-40,
 1.0929e-01,  2.9895e-02, -1.4923e-01,
-1.1234e-01, -1.0514e-01, -1.3280e-02,
 2.2255e-01,  6.4152e-03, -1.6309e-02,
-1.5899e-40, -7.2549e-41, -2.6734e-40,
-3.3842e-40,  3.3255e-40,  4.2694e-40,
 5.2940e-40,  3.2455e-40, -3.7081e-40,
 6.3639e-02, -3.3720e-02, -2.3453e-02,
 1.9477e-01,  5.2267e-02,  1.8565e-02,
 1.6048e-01,  2.7636e-01,  1.5930e-02,
 1.7673e-03,  6.3646e-02, -1.5127e-02,
-3.7787e-02, -1.4037e-01, -3.6231e-02,
-1.5636e-02, -7.8742e-02, -2.4137e-02,
-5.0748e-02,  6.5641e-02, -2.5353e-03,
 8.4955e-02,  7.4231e-01,  1.3795e-01,
-1.4552e-01,  2.0869e-01,  4.0739e-02,
-2.0015e-41,  5.2988e-40,  2.7578e-40,
 4.1051e-40,  1.2834e-40, -3.4898e-40,
-1.1975e-40,  4.2374e-40, -3.0404e-41,
-6.3014e-40,  4.6330e-40, -4.4141e-41,
 2.5442e-41,  5.7456e-40,  2.3848e-40,
-1.0788e-40, -5.0563e-40, -5.3638e-41,
 3.5728e-40,  1.9752e-40,  6.1004e-40,
 2.8189e-41, -6.2151e-40,  1.1807e-41,
 6.5305e-41,  5.2028e-40,  1.3692e-40,
 6.4391e-02, -1.3079e-01, -3.7980e-02,
-3.2362e-01, -3.7239e-01, -8.0182e-02,
-2.6787e-01, -3.1240e-01, -1.2798e-02,
-1.2072e-40,  5.3996e-40, -3.4352e-40,
-8.0996e-41, -3.0208e-40,  3.1848e-40,
-5.6407e-40,  2.4674e-41, -2.1055e-40,
-9.2897e-02,  1.8040e-01, -4.3269e-01,
-7.6669e-02,  4.3554e-01, -4.4870e-02,
-2.3249e-02, -1.1805e-01,  1.0507e-01,
-5.2540e-02, -3.6856e-01,  1.1246e-01,
-2.3632e-02,  1.3165e-01, -1.5380e-02,
-1.1467e-02, -5.3754e-02, -4.1619e-02,
-1.5635e-01,  3.8584e-01, -1.4434e-01,
 1.7523e-01,  3.7253e-02,  4.9784e-01,
 5.8484e-02, -8.4711e-02, -7.7498e-02,
-1.6956e-40,  5.4293e-41, -2.5140e-40,
-3.1995e-40, -4.8337e-40,  2.5539e-40,
-1.1449e-40,  1.9503e-40, -1.7368e-40,
 5.4753e-40,  5.9720e-40, -4.7821e-40,
 3.8830e-40, -3.1984e-40, -2.7163e-40,
-5.3411e-40,  7.2638e-41,  4.3186e-40,
 4.6654e-40, -5.9540e-40, -2.8155e-40,
-1.4801e-40, -1.6945e-40,  1.9723e-40,
 5.8380e-40, -6.1587e-40,  3.3667e-40,
-2.9327e-02, -4.2746e-02, -1.5018e-01,
 8.6354e-02,  2.8140e-01,  1.2970e-02,
-2.0755e-01,  6.7548e-02, -3.6049e-02
);

const float biasL[4] = float[4]
(
-2.9177e-02, -4.0635e-02,  7.8097e-02, -1.1643e-01
);

vec4 hook()
{
    vec4 tl1 = L2_1_texOff(vec2(-1,-1));
    vec4 tc1 = L2_1_texOff(vec2(0,-1));
    vec4 tr1 = L2_1_texOff(vec2(1,-1));
    vec4 ml1 = L2_1_texOff(vec2(-1,0));
    vec4 mc1 = L2_1_texOff(vec2(0,0));
    vec4 mr1 = L2_1_texOff(vec2(1,0));
    vec4 bl1 = L2_1_texOff(vec2(-1,1));
    vec4 bc1 = L2_1_texOff(vec2(0,1));
    vec4 br1 = L2_1_texOff(vec2(1,1));

    vec4 tl2 = L2_2_texOff(vec2(-1,-1));
    vec4 tc2 = L2_2_texOff(vec2(0,-1));
    vec4 tr2 = L2_2_texOff(vec2(1,-1));
    vec4 ml2 = L2_2_texOff(vec2(-1,0));
    vec4 mc2 = L2_2_texOff(vec2(0,0));
    vec4 mr2 = L2_2_texOff(vec2(1,0));
    vec4 bl2 = L2_2_texOff(vec2(-1,1));
    vec4 bc2 = L2_2_texOff(vec2(0,1));
    vec4 br2 = L2_2_texOff(vec2(1,1));

    vec4 c5678 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c5678;
}

//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L6
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 9.5728e-41,  5.3991e-40, -1.3764e-40,
-2.0389e-40,  2.4254e-40,  3.3492e-40,
 6.5289e-41, -3.0842e-40,  5.5850e-40,
 7.7599e-02,  2.5043e-02, -1.4099e-02,
-3.3184e-02,  5.6863e-01, -2.7001e-02,
-5.2659e-02,  5.4713e-02,  2.3991e-03,
 2.2010e-02, -3.9120e-02, -1.1558e-01,
 9.1633e-02,  1.3070e-01,  1.2489e-01,
-4.4040e-02, -1.6324e-02, -4.9631e-02,
-7.3548e-02, -2.0492e-01,  1.4043e-01,
-6.0411e-02,  5.7710e-02, -3.6840e-02,
 1.3173e-02,  2.3215e-03,  1.1820e-02,
 2.5772e-02, -1.3436e-01, -5.9285e-02,
-9.3983e-02,  1.1545e-01,  1.1602e-01,
-1.8505e-02,  6.1498e-02, -1.3097e-02,
 9.8690e-03, -2.1338e-02, -1.2175e-01,
 1.7936e-02, -2.7811e-02,  6.7037e-02,
-5.1401e-03,  7.6421e-02, -1.0794e-01,
 4.6409e-02,  3.4701e-01,  2.6587e-02,
 8.4175e-02,  5.2712e-01,  6.8999e-02,
-8.0756e-02,  1.9648e-01, -8.4639e-02,
 1.2818e-01,  4.0660e-02,  7.6715e-02,
 8.7991e-02,  4.6556e-01, -4.0025e-02,
 2.1251e-03, -8.3784e-03,  5.9859e-02,
 1.9835e-40, -3.4675e-40, -7.9692e-41,
-1.4304e-40,  2.3927e-40, -5.9796e-40,
 3.8209e-40, -6.3260e-41, -9.2501e-41,
 3.2007e-01,  1.5800e-01, -1.9594e-02,
-4.5315e-02,  1.0536e-01, -8.0692e-02,
 2.1185e-01, -3.1418e-01, -1.5257e-01,
 8.6294e-02, -1.3398e-01, -1.0694e-01,
 8.6084e-02, -1.2393e-03,  1.7549e-02,
-1.5504e-01, -1.3112e-01, -3.5905e-02,
-3.8190e-01,  3.8393e-01,  1.6587e-02,
 1.5002e-01,  1.9586e-01, -2.6260e-01,
-4.0159e-02, -8.2891e-02, -1.7761e-01,
-1.8611e-01, -1.1241e-02, -4.2538e-02,
-5.7898e-02,  2.4583e-01,  4.1590e-02,
 2.4890e-02,  7.9409e-03, -2.7418e-02,
 6.6194e-03, -4.2441e-02, -1.1167e-01,
-1.3236e-01, -7.9642e-02, -6.0623e-02,
-4.7198e-03,  5.6904e-02,  1.2651e-01,
 1.2925e-01, -5.9162e-02, -9.1949e-04,
 1.8668e-02, -2.6361e-02, -7.1042e-03,
-4.3178e-02,  2.6050e-04,  4.4799e-02,
 7.9674e-02,  2.7656e-02,  7.1211e-03,
 1.1463e-01,  1.0765e-01,  7.6066e-02,
-8.0780e-02, -5.4875e-02,  1.5209e-02,
-3.7365e-13, -3.7819e-13, -3.5929e-13,
-4.0298e-13, -4.0881e-13, -3.9033e-13,
-3.9409e-13, -3.9950e-13, -3.8277e-13,
-1.7847e-02, -1.7537e-02, -3.7313e-03,
 2.6531e-02,  7.5951e-02, -4.0134e-03,
 1.7387e-02,  6.0044e-02, -9.0211e-02,
 2.7091e-02,  8.8333e-02,  1.0619e-01,
 5.0470e-02,  1.2406e-02,  1.5503e-01,
-1.5936e-02, -2.2422e-01, -2.4640e-02,
-8.2430e-03, -1.4097e-02, -6.2474e-02,
 8.0534e-02,  1.8603e-01, -3.1725e-02,
-3.1621e-03,  2.0362e-03, -1.4002e-01,
-7.3799e-03,  1.5881e-01,  6.7195e-02,
 4.5946e-02,  2.4358e-01,  1.4677e-01,
-7.4788e-02,  6.7297e-02,  9.0735e-02,
-8.4553e-03, -1.1877e-02,  4.4209e-02,
-1.4281e-02, -6.8849e-02, -4.1386e-03,
 3.2286e-02,  4.7128e-02, -1.2988e-02,
-2.2990e-02, -8.9265e-02,  6.4050e-02,
-2.3354e-02,  1.3846e-01, -1.6256e-01,
-6.5661e-02, -2.8983e-02, -4.3497e-02,
 1.0597e-02, -2.3534e-02, -2.6068e-02,
-7.8812e-02,  1.9502e-01,  6.8938e-03,
 3.2025e-02,  2.3353e-02,  4.9225e-02,
-5.0273e-40,  1.2403e-41,  5.8127e-40,
 3.2777e-40, -3.5740e-40,  4.9781e-40,
-2.4198e-40, -4.6311e-40,  1.3330e-40,
-3.0803e-01,  1.7804e-01,  1.0604e-01,
 4.1405e-01,  1.9740e-01, -5.3067e-02,
 2.3738e-01, -1.6828e-01,  1.5338e-01,
 6.6857e-03,  1.8623e-01, -1.2126e-01,
-1.6323e-01, -1.2719e-02, -1.7743e-01,
-1.3612e-01, -3.4442e-02, -1.0552e-01,
-1.4560e-01,  1.8771e-01,  8.4508e-02,
 5.8732e-02, -2.2378e-01,  1.2673e-01,
 3.0455e-03,  3.8438e-02, -6.2235e-02,
 1.9951e-02,  2.6963e-01, -1.8594e-01,
-8.6550e-02, -1.3097e-01, -3.5032e-02,
 2.0423e-02, -9.0499e-02,  1.7130e-01,
-1.8592e-01,  6.6808e-02, -1.5768e-01,
-6.4402e-02, -1.2265e-01,  6.8487e-02,
 1.9899e-02,  9.3376e-02,  7.8577e-02,
-1.3384e-01, -7.6429e-02,  1.7142e-02,
-1.2385e-01, -1.1821e-01, -1.2716e-03,
 5.3770e-02,  1.4973e-01,  1.4762e-01,
-4.7688e-02, -1.1733e-01, -1.5032e-01,
-2.0699e-01, -9.4949e-02, -2.6374e-02,
 4.4489e-02,  1.8376e-02, -7.6844e-02
);

const float biasL[4] = float[4]
(
-2.6309e-02, -2.2238e-02,  6.8700e-03, -1.7973e-02
);

vec4 hook()
{
    vec4 tl1 = L1_1_texOff(vec2(-1,-1));
    vec4 tc1 = L1_1_texOff(vec2(0,-1));
    vec4 tr1 = L1_1_texOff(vec2(1,-1));
    vec4 ml1 = L1_1_texOff(vec2(-1,0));
    vec4 mc1 = L1_1_texOff(vec2(0,0));
    vec4 mr1 = L1_1_texOff(vec2(1,0));
    vec4 bl1 = L1_1_texOff(vec2(-1,1));
    vec4 bc1 = L1_1_texOff(vec2(0,1));
    vec4 br1 = L1_1_texOff(vec2(1,1));

    vec4 tl2 = L1_2_texOff(vec2(-1,-1));
    vec4 tc2 = L1_2_texOff(vec2(0,-1));
    vec4 tr2 = L1_2_texOff(vec2(1,-1));
    vec4 ml2 = L1_2_texOff(vec2(-1,0));
    vec4 mc2 = L1_2_texOff(vec2(0,0));
    vec4 mr2 = L1_2_texOff(vec2(1,0));
    vec4 bl2 = L1_2_texOff(vec2(-1,1));
    vec4 bc2 = L1_2_texOff(vec2(0,1));
    vec4 br2 = L1_2_texOff(vec2(1,1));

    vec4 c1234 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c1234;
}


//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L6
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 1.8831e-40, -2.6056e-40, -4.7602e-40,
-3.4079e-40,  1.5054e-40,  1.2387e-40,
 2.3040e-40,  1.4644e-40,  5.6365e-40,
-2.0809e-02,  5.3674e-03,  1.7057e-03,
 2.4160e-01,  4.1348e-01,  3.5215e-02,
 8.2154e-02,  2.0431e-01,  1.0366e-01,
-1.5149e-02,  1.0521e-01, -4.1706e-02,
-5.0651e-02,  2.3615e-02, -9.3860e-02,
-1.0823e-01, -6.3645e-02, -1.1573e-01,
-2.4116e-02,  1.3546e-02, -1.0298e-03,
 1.2102e-02,  2.2630e-02,  1.1375e-01,
 1.3966e-02,  1.0754e-01,  1.6621e-01,
 1.6213e-02,  2.0816e-01,  8.9441e-02,
-7.5452e-02,  3.4580e-03, -3.3317e-01,
 5.0917e-02,  1.3898e-01, -1.0723e-01,
 6.0473e-03,  8.9741e-02, -6.8206e-02,
-7.1770e-02, -3.5661e-01, -2.8935e-01,
-1.6324e-02,  2.5728e-02, -1.1281e-02,
-1.3390e-01, -9.3090e-02,  4.3366e-02,
 4.8620e-02,  1.4917e-01,  1.6295e-01,
 2.4123e-03, -7.6347e-02, -8.0226e-02,
 6.0740e-03,  3.7065e-02,  4.5518e-04,
-1.3793e-01,  2.3848e-01, -1.1199e-01,
 1.0422e-01,  1.1214e-01,  3.3457e-02,
-3.2827e-40,  5.9135e-40,  3.3773e-40,
-5.8903e-40, -5.9439e-41,  1.9973e-40,
-3.6141e-40, -4.7563e-40, -1.0222e-40,
 7.3457e-02, -8.2031e-02, -2.9504e-02,
-5.3420e-02,  4.9697e-02,  7.6779e-03,
 2.1180e-02,  1.1069e-02, -1.1940e-02,
 1.7302e-02,  9.9063e-02,  4.8847e-02,
 4.9513e-02,  2.4240e-01,  2.7174e-01,
 2.7487e-01,  1.9410e-01,  3.1165e-01,
-6.7532e-03, -1.1608e-01, -5.0876e-02,
 1.2107e-01,  3.1073e-01,  7.1681e-02,
-1.1411e-01, -1.7902e-01,  7.8898e-02,
-2.0117e-02,  3.6394e-01,  1.4546e-01,
-8.0861e-03, -4.3956e-02, -1.3473e-01,
 5.1519e-02, -3.1122e-01, -4.6847e-02,
 5.0405e-02, -1.0611e-02, -1.0557e-01,
-4.4346e-02, -1.4505e-01,  5.3977e-02,
-2.6288e-01,  1.8247e-02, -1.1606e-01,
 1.0706e-01, -9.3675e-02,  1.1757e-01,
-5.0440e-02, -1.1784e-01, -4.0599e-02,
 1.9618e-01,  9.9370e-02,  8.2258e-02,
 2.6762e-02, -5.0740e-02, -1.8302e-02,
 5.3340e-02,  6.5710e-02,  6.1552e-03,
-7.2158e-02, -3.5563e-02,  8.2140e-02,
 3.1534e-40,  3.6427e-40,  3.0437e-40,
 4.2856e-41, -4.7870e-40,  5.6317e-40,
-2.4673e-40, -6.9736e-41,  8.1050e-41,
 1.4544e-01,  8.2490e-02, -9.2349e-03,
 2.6124e-01,  2.7494e-01, -5.4946e-02,
 1.8233e-01,  1.2428e-01, -6.7498e-03,
 9.7639e-02, -6.2085e-03,  4.8154e-02,
 2.7379e-02, -1.8443e-01,  4.0402e-02,
 1.8893e-03, -5.2282e-03,  6.7548e-03,
-1.6559e-01,  9.7901e-02, -1.1869e-01,
-2.1287e-01,  4.1023e-01, -9.7379e-02,
-1.3767e-03, -1.6343e-01, -9.5059e-02,
-1.3547e-01,  2.0094e-01,  1.0102e-01,
-2.1311e-01, -1.5088e-01,  1.8175e-01,
 4.6946e-02, -1.3963e-01,  1.0220e-01,
 1.7536e-01, -2.4758e-01, -1.1481e-02,
 6.1596e-02, -4.0352e-01, -1.4348e-01,
 3.1690e-02,  1.7240e-01,  7.0780e-02,
 9.9953e-02, -1.4154e-01, -8.3038e-02,
 1.4527e-01, -2.1430e-01, -7.5840e-02,
 1.6146e-01,  3.7508e-02,  5.3833e-02,
 1.6723e-01,  1.7113e-01, -4.8512e-02,
 2.1319e-01,  4.7031e-01,  1.1570e-01,
 2.0330e-01,  2.4636e-01,  6.9924e-02,
-2.1165e-40, -1.9259e-40, -5.0990e-41,
-7.1298e-42, -4.2590e-41,  3.1709e-40,
 4.1065e-40, -4.2585e-41,  3.4243e-40,
-1.0338e-40,  4.6039e-40, -3.3818e-40,
-3.9589e-41,  5.9574e-40, -5.8014e-41,
 1.4505e-41, -3.5326e-40, -3.9806e-40,
 4.2423e-40, -1.7055e-40, -4.9666e-40,
 2.2853e-40, -2.4684e-40, -1.3794e-40,
-5.6764e-40, -1.7905e-40, -5.8915e-40,
-1.4755e-27, -2.0405e-28, -4.8677e-30,
-7.1151e-28, -9.7603e-29, -3.5264e-30,
-2.7455e-29, -5.7734e-30, -2.8633e-31,
-5.9960e-06, -5.9595e-06, -5.8686e-06,
-6.0381e-06, -6.0191e-06, -5.9605e-06,
-5.9849e-06, -5.9981e-06, -5.9654e-06,
-4.8277e-22, -7.0529e-22, -8.7179e-22,
-4.6334e-22, -6.3505e-22, -8.8438e-22,
-3.3883e-22, -4.2421e-22, -5.9002e-22,
-2.9574e-40,  4.0860e-40, -1.5966e-40,
-6.7527e-41,  7.6661e-41, -5.9491e-40,
 3.0843e-40,  8.1079e-41, -2.5140e-40,
-3.7315e-40,  9.4787e-41,  4.6794e-40,
 1.9383e-40,  5.0336e-41,  3.0561e-40,
-5.4286e-40,  5.5999e-40, -4.6977e-40
);

const float biasL[4] = float[4]
(
-1.0893e-02, -1.1888e-02, -4.9598e-03, -6.3663e-06
);

vec4 hook()
{
    vec4 tl1 = L1_1_texOff(vec2(-1,-1));
    vec4 tc1 = L1_1_texOff(vec2(0,-1));
    vec4 tr1 = L1_1_texOff(vec2(1,-1));
    vec4 ml1 = L1_1_texOff(vec2(-1,0));
    vec4 mc1 = L1_1_texOff(vec2(0,0));
    vec4 mr1 = L1_1_texOff(vec2(1,0));
    vec4 bl1 = L1_1_texOff(vec2(-1,1));
    vec4 bc1 = L1_1_texOff(vec2(0,1));
    vec4 br1 = L1_1_texOff(vec2(1,1));

    vec4 tl2 = L1_2_texOff(vec2(-1,-1));
    vec4 tc2 = L1_2_texOff(vec2(0,-1));
    vec4 tr2 = L1_2_texOff(vec2(1,-1));
    vec4 ml2 = L1_2_texOff(vec2(-1,0));
    vec4 mc2 = L1_2_texOff(vec2(0,0));
    vec4 mr2 = L1_2_texOff(vec2(1,0));
    vec4 bl2 = L1_2_texOff(vec2(-1,1));
    vec4 bc2 = L1_2_texOff(vec2(0,1));
    vec4 br2 = L1_2_texOff(vec2(1,1));

    vec4 c5678 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c5678;
}

//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L7
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-1.7778e-01,  5.2351e-03,  1.6035e-02,
-9.7482e-02, -1.1056e-02, -5.0999e-02,
 1.7460e-01, -4.0005e-02, -5.0911e-02,
-9.3843e-02,  1.2640e-01, -1.5016e-02,
-5.2880e-01,  1.9469e-01, -9.0037e-02,
-8.9136e-02,  9.8632e-02, -1.5009e-01,
-1.8080e-01,  1.1396e-01, -2.6178e-02,
-1.6689e-02,  1.4132e-01, -6.7769e-03,
-2.1120e-02,  6.8616e-02, -7.8209e-02,
 4.8237e-02, -2.5303e-02,  1.7882e-02,
-4.2852e-02, -1.5071e-02, -3.3818e-02,
 1.3635e-01,  4.5330e-01,  2.1489e-01,
 2.7362e-02, -7.4152e-02,  2.3185e-03,
 1.8771e-01, -2.0827e-02, -7.5581e-02,
 1.4675e-01, -6.5552e-02,  4.2292e-02,
 1.3990e-01, -4.1598e-01,  2.1609e-03,
 1.5997e-01,  1.1375e-01, -1.8272e-02,
 1.9045e-02, -4.2702e-02, -2.5602e-02,
 1.6432e-01, -1.2783e-01, -1.8285e-03,
 2.9414e-01,  1.7401e-01, -2.6321e-01,
-1.0125e-01,  1.3565e-01,  1.5894e-02,
-3.7351e-40,  6.3010e-40, -1.2071e-40,
-4.6380e-40,  1.8442e-40, -3.5994e-40,
-2.1459e-40, -4.3455e-40, -6.1978e-41,
-2.3638e-40, -4.6965e-40, -3.4232e-40,
-1.6517e-40,  4.7178e-40, -1.6757e-40,
 6.7890e-41, -4.3000e-40,  1.8323e-40,
 4.5416e-40, -2.9010e-40, -1.5200e-40,
-3.5533e-40, -8.7351e-41,  6.5595e-42,
 5.1625e-40, -6.0418e-40, -2.7846e-40,
-2.1861e-10, -2.2422e-10, -2.1298e-10,
-2.2653e-10, -2.3500e-10, -2.2512e-10,
-2.1802e-10, -2.2681e-10, -2.1608e-10,
-3.2862e-40,  3.4241e-40, -1.3264e-40,
 2.8762e-40,  1.3843e-40,  3.0949e-40,
-3.7702e-40,  2.6194e-40,  2.1451e-40,
-3.2283e-40, -5.5487e-40,  5.8744e-40,
 1.6124e-40,  3.3512e-40,  3.1454e-40,
-3.5417e-40, -5.7692e-40,  5.5184e-40,
 3.5641e-40, -4.3187e-40, -3.5314e-40,
 4.9246e-40,  5.9593e-40,  8.3132e-41,
-2.3841e-40, -5.6196e-40, -3.2230e-41,
 4.3824e-40, -3.8344e-40, -9.9086e-42,
-2.9323e-40,  2.1916e-40,  4.4739e-40,
 5.6837e-41,  5.1796e-41, -2.4338e-40,
-2.2853e-40, -3.8920e-40,  6.1587e-40,
-2.9474e-41,  4.6214e-40, -3.6292e-40,
-1.4928e-40, -3.6708e-41,  5.2020e-40,
-1.2983e-12, -2.6539e-12, -1.9817e-12,
-6.5613e-12, -1.0255e-11, -6.6919e-12,
-8.3217e-12, -1.7832e-11, -1.1086e-11,
-4.9138e-40, -9.0061e-42,  4.6251e-40,
-2.9970e-41, -2.5468e-40, -3.5660e-40,
 2.5450e-40, -9.5634e-38, -3.2369e-32,
-1.0233e-06, -8.2108e-07, -1.1668e-06,
-5.9592e-07, -3.9529e-07, -5.7435e-07,
-6.0253e-07, -3.8785e-07, -4.9365e-07,
-8.9372e-37, -2.1590e-36, -2.1060e-40,
-1.5666e-35, -1.1466e-38, -2.3366e-40,
-5.4077e-38,  5.0487e-40, -3.3736e-40,
-1.5357e-13, -8.4607e-14, -1.9206e-16,
-5.5373e-13, -3.0787e-13, -1.0513e-15,
-1.0468e-13, -8.6069e-14, -2.2453e-16,
-4.7501e-14, -1.3426e-13, -1.1133e-13,
-1.3801e-14, -2.4024e-14, -3.5120e-14,
-1.9817e-17, -1.3229e-17, -3.2854e-17,
-1.4365e-18, -4.1143e-15, -9.2614e-14,
-1.1174e-19, -1.6235e-15, -1.5600e-13,
-1.2643e-21, -3.9578e-17, -1.2038e-14,
-2.9789e-40, -4.6452e-40,  1.5649e-40,
-1.8445e-40, -5.2942e-40,  2.5130e-40,
 6.2269e-40,  3.9166e-41, -2.4197e-40,
 9.0835e-02, -5.2035e-03, -2.5980e-02,
-1.0090e-01, -7.4167e-02,  1.3364e-01,
 1.0302e-01, -1.5250e-01,  1.2417e-01,
 4.7205e-02, -2.3839e-01, -1.4983e-02,
 5.6824e-02, -1.8259e-02,  9.6426e-02,
 5.9740e-03, -1.4198e-01, -2.1076e-01,
-1.5837e-01,  6.4749e-02, -2.1417e-01,
-3.4048e-02,  4.9638e-01,  2.0984e-03,
-1.4335e-01,  4.8295e-02, -9.2209e-02,
 1.9450e-01, -1.3603e-01,  1.2008e-01,
 1.6803e-01,  5.6805e-02,  1.1518e-01,
 5.9320e-02, -3.8200e-02, -1.1340e-01,
-8.6877e-02,  1.1533e-01, -4.9870e-02,
-7.2811e-03,  2.5730e-01, -1.8536e-01,
-6.4965e-02,  1.0364e-01,  1.3706e-02,
 4.6974e-02, -1.0049e-01, -1.7460e-01,
-1.7910e-01,  3.0771e-01, -2.5757e-01,
-2.2846e-02, -3.7491e-03, -5.2171e-03,
-4.7762e-02, -4.7776e-02,  5.1125e-01,
-2.0210e-01,  6.4815e-02, -6.1606e-02,
 7.3686e-04, -1.6226e-01, -3.0327e-02,
 5.6501e-40,  5.2828e-40, -5.9773e-40,
-4.3530e-40, -1.1658e-40,  4.9705e-41,
 4.8101e-40,  5.0236e-40,  2.0476e-40
);

const float biasL[4] = float[4]
(
-1.2406e-03, -2.4901e-12, -9.7265e-07,  6.3490e-03
);

vec4 hook()
{
    vec4 tl1 = L2_1_texOff(vec2(-1,-1));
    vec4 tc1 = L2_1_texOff(vec2(0,-1));
    vec4 tr1 = L2_1_texOff(vec2(1,-1));
    vec4 ml1 = L2_1_texOff(vec2(-1,0));
    vec4 mc1 = L2_1_texOff(vec2(0,0));
    vec4 mr1 = L2_1_texOff(vec2(1,0));
    vec4 bl1 = L2_1_texOff(vec2(-1,1));
    vec4 bc1 = L2_1_texOff(vec2(0,1));
    vec4 br1 = L2_1_texOff(vec2(1,1));

    vec4 tl2 = L2_2_texOff(vec2(-1,-1));
    vec4 tc2 = L2_2_texOff(vec2(0,-1));
    vec4 tr2 = L2_2_texOff(vec2(1,-1));
    vec4 ml2 = L2_2_texOff(vec2(-1,0));
    vec4 mc2 = L2_2_texOff(vec2(0,0));
    vec4 mr2 = L2_2_texOff(vec2(1,0));
    vec4 bl2 = L2_2_texOff(vec2(-1,1));
    vec4 bc2 = L2_2_texOff(vec2(0,1));
    vec4 br2 = L2_2_texOff(vec2(1,1));

    vec4 c1234 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c1234;
}


//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L7
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-1.1412e-01,  1.3391e-01, -1.2279e-01,
 1.4370e-01,  3.7617e-01,  7.1407e-02,
 6.9661e-02,  3.1963e-01, -1.7089e-02,
-4.7530e-02,  6.5411e-02, -2.4915e-02,
 3.3429e-02, -1.3899e-01, -3.3875e-02,
-1.9261e-02, -1.3162e-01,  1.1415e-01,
 2.0599e-02, -3.8667e-02, -7.2190e-02,
-2.1112e-01, -1.6525e-01, -2.3430e-02,
-1.2287e-02, -2.6637e-01,  1.0859e-03,
-2.8564e-02,  4.8846e-02,  4.2412e-02,
 1.4632e-01,  1.5974e-02, -1.0699e-01,
 5.5661e-02, -2.0952e-01,  2.4151e-02,
-2.3510e-02, -5.0570e-02,  1.0799e-01,
 1.7495e-01, -1.5788e-03, -1.6447e-02,
 7.7642e-02, -9.3888e-02,  1.3891e-03,
 2.2658e-02,  1.4058e-01,  1.0639e-01,
-5.5626e-02, -3.0794e-01, -5.7160e-02,
 1.0874e-01, -8.3907e-02,  4.2106e-02,
 1.7688e-02,  1.8090e-01, -2.1718e-03,
-1.0659e-02, -2.1302e-01,  1.0056e-01,
-6.0693e-02, -2.3624e-02,  6.3688e-03,
-2.7320e-40, -1.3336e-40,  2.4202e-41,
-7.1225e-41,  1.2848e-40,  1.5426e-40,
-4.2798e-40,  6.5075e-41,  6.2629e-40,
 1.6905e-01, -1.7379e-01, -2.1360e-02,
-2.9396e-01,  1.1782e-01,  7.9111e-02,
-6.4767e-03, -1.9949e-01,  5.4243e-02,
-3.2753e-02, -1.5810e-01,  5.2257e-02,
-1.8133e-02,  2.0548e-01, -2.8071e-01,
-5.3725e-02,  8.4067e-02, -7.4639e-02,
 8.9137e-02, -2.3078e-01, -1.9626e-01,
 3.1276e-01,  1.5332e-01, -1.9590e-01,
-1.8318e-02,  6.8460e-02,  9.1476e-03,
 8.2398e-02,  8.5883e-03,  7.6830e-02,
-1.4580e-01,  4.6253e-01, -3.1900e-01,
-1.1051e-01,  6.3807e-02, -2.5130e-02,
-1.2029e-01, -3.8982e-03,  2.1654e-02,
-3.2017e-01,  2.0265e-01, -1.7311e-01,
-1.3229e-02,  1.3805e-01, -6.2689e-02,
-3.6619e-02, -1.9366e-01,  2.7177e-01,
 5.5937e-02,  7.9713e-02, -2.3872e-01,
-3.9690e-02,  2.2914e-02, -1.7779e-02,
 1.1110e-01,  1.6618e-01,  3.6139e-01,
 7.9777e-02,  4.3655e-01,  3.0597e-01,
-5.5125e-02,  6.1229e-02,  1.2414e-01,
 2.1644e-40,  7.2343e-41,  5.5580e-40,
-4.3927e-40,  5.0561e-40, -1.5560e-41,
-3.2783e-40, -8.8219e-41,  5.4415e-40,
-6.7176e-02, -3.4930e-02, -2.7087e-02,
 1.0489e-01,  2.1178e-01, -1.6752e-01,
-1.2627e-01, -2.4207e-01, -7.4667e-02,
-3.1470e-02, -1.3365e-02,  8.7742e-02,
-2.2809e-02, -4.7991e-01,  2.4740e-02,
 6.4418e-02,  3.4818e-02, -2.9275e-01,
-2.8830e-01, -7.0458e-02,  7.8922e-02,
-1.4436e-01,  4.1068e-02,  6.2896e-02,
 4.1061e-03,  2.1844e-01,  9.0488e-02,
-1.1085e-01,  8.3761e-02,  3.2634e-02,
 3.2470e-01, -2.7760e-01,  4.1235e-02,
 8.6625e-02,  2.6816e-01, -1.3560e-01,
 3.8789e-01,  3.2406e-01,  1.0631e-01,
 7.5131e-02, -2.0206e-01,  1.3027e-01,
 4.0382e-02,  2.4350e-01, -3.6042e-03,
-1.0063e-01,  1.9418e-01, -7.7039e-02,
 9.4531e-03,  7.1605e-02,  1.4004e-01,
-2.0591e-02,  4.5944e-02, -2.6721e-03,
-3.4665e-03,  2.2560e-01, -8.2930e-02,
-1.5507e-01,  2.7206e-01, -2.8665e-02,
-3.4909e-03,  1.7696e-02, -8.5492e-02,
 2.1541e-40, -3.3029e-40,  1.7678e-40,
-3.9857e-40, -1.1965e-40, -8.6754e-41,
-4.0721e-40,  2.2073e-41,  4.2728e-40,
-1.0496e-02,  5.4120e-02, -1.6498e-02,
-5.9387e-02,  2.3757e-01, -8.0381e-02,
 2.3739e-02, -1.3715e-01, -3.0906e-02,
-8.5760e-03,  2.4518e-02, -6.9090e-02,
 2.1623e-02,  8.9641e-02,  9.9031e-02,
-1.0052e-02,  4.6506e-02, -1.5756e-01,
 8.5003e-02, -3.6434e-03,  1.3816e-02,
 9.0532e-02,  2.3661e-01,  1.8077e-01,
 2.8120e-02,  4.3753e-02,  2.2981e-02,
 3.5830e-02,  5.7995e-02, -5.6879e-03,
 3.7708e-02, -2.6373e-01,  2.0886e-01,
-4.0632e-02,  1.6891e-01, -6.8996e-02,
-1.1972e-01, -4.3628e-02,  2.0278e-02,
-1.4818e-01,  4.0844e-02,  1.5917e-01,
-4.5684e-02,  1.4075e-01, -2.0784e-02,
-1.1533e-03, -2.7897e-01, -8.8707e-02,
-1.7907e-02,  1.8400e-01,  1.1026e-01,
-2.3183e-03,  6.3875e-02, -4.2394e-03,
 3.2021e-02, -8.8955e-02, -2.2298e-02,
 8.1353e-02,  3.3079e-01, -2.0616e-01,
-3.5802e-02,  4.9804e-02, -9.2712e-02,
-1.5940e-07, -1.6158e-07, -1.5812e-07,
-1.6273e-07, -1.6555e-07, -1.6260e-07,
-1.5867e-07, -1.6192e-07, -1.5975e-07
);

const float biasL[4] = float[4]
(
 1.3495e-01, -3.8411e-03, -6.6630e-03, -7.3614e-03
);

vec4 hook()
{
    vec4 tl1 = L2_1_texOff(vec2(-1,-1));
    vec4 tc1 = L2_1_texOff(vec2(0,-1));
    vec4 tr1 = L2_1_texOff(vec2(1,-1));
    vec4 ml1 = L2_1_texOff(vec2(-1,0));
    vec4 mc1 = L2_1_texOff(vec2(0,0));
    vec4 mr1 = L2_1_texOff(vec2(1,0));
    vec4 bl1 = L2_1_texOff(vec2(-1,1));
    vec4 bc1 = L2_1_texOff(vec2(0,1));
    vec4 br1 = L2_1_texOff(vec2(1,1));

    vec4 tl2 = L2_2_texOff(vec2(-1,-1));
    vec4 tc2 = L2_2_texOff(vec2(0,-1));
    vec4 tr2 = L2_2_texOff(vec2(1,-1));
    vec4 ml2 = L2_2_texOff(vec2(-1,0));
    vec4 mc2 = L2_2_texOff(vec2(0,0));
    vec4 mr2 = L2_2_texOff(vec2(1,0));
    vec4 bl2 = L2_2_texOff(vec2(-1,1));
    vec4 bc2 = L2_2_texOff(vec2(0,1));
    vec4 br2 = L2_2_texOff(vec2(1,1));

    vec4 c5678 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c5678;
}

//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L8
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-1.5080e-02,  1.1294e-01,  7.1187e-02,
 1.1628e-02, -8.4938e-01,  8.5457e-02,
-3.9642e-02, -2.3879e-02,  1.0029e-02,
 2.6648e-40,  9.1590e-41,  3.3285e-40,
-3.3445e-40, -2.5194e-40, -2.0946e-40,
 3.6800e-40, -1.1584e-40,  6.2195e-40,
-1.3560e-41, -8.0151e-41,  4.4048e-40,
-4.1209e-40,  2.7411e-40,  3.2419e-40,
 5.8333e-40,  1.1503e-40, -5.0783e-40,
-5.5301e-02, -2.4971e-02,  4.9251e-02,
-2.5589e-01,  1.6560e-01, -8.0956e-02,
 4.0518e-01,  3.1320e-02, -1.4262e-01,
 1.2250e-02,  5.1989e-02,  3.0706e-03,
-7.9534e-02, -1.9801e-01, -2.7791e-02,
 2.1768e-01,  6.9978e-02, -4.2325e-02,
-1.9165e-02, -2.1179e-02, -2.1558e-02,
 3.6816e-01, -5.2929e-02,  9.5790e-02,
 2.8095e-01, -1.4731e-01,  3.4182e-02,
 2.3702e-02,  4.0764e-02,  3.5767e-02,
-8.4586e-02,  1.9025e-01, -1.6794e-01,
-1.0273e-02,  3.2259e-01, -1.5841e-01,
 2.6794e-01,  5.2084e-02,  1.2761e-02,
-1.1169e-01, -1.7808e-01,  1.1363e-01,
-1.3808e-01, -1.7764e-02, -1.7420e-02,
 1.5840e-02, -2.3405e-01,  7.6361e-03,
-6.6082e-02,  7.9778e-02, -2.0423e-01,
-1.9594e-02, -6.3370e-02,  3.3351e-02,
-2.0396e-40, -3.0207e-40, -3.2364e-40,
 2.3575e-40,  5.8301e-41, -3.7432e-40,
-3.6291e-40,  3.3441e-40,  1.4574e-40,
-4.3792e-40, -2.5814e-40, -3.4986e-41,
-3.4920e-40, -4.4757e-40,  3.2192e-40,
 4.7222e-40, -7.3197e-41, -3.4635e-40,
 5.1495e-02,  7.8843e-02,  4.2243e-02,
-2.1245e-01,  1.9568e-01,  7.9369e-03,
 2.2795e-02,  2.2801e-02,  7.6895e-02,
 3.0044e-01, -1.4041e-01, -2.3677e-02,
-1.1656e-01, -7.5113e-02,  1.0625e-02,
-1.2133e-02,  5.0658e-02, -7.2944e-02,
-3.3652e-02, -2.0452e-01, -4.1048e-02,
 2.8531e-01,  1.2116e-01, -2.1526e-02,
-2.4564e-01, -4.1870e-02, -5.5819e-02,
-2.3157e-01, -2.5594e-02,  1.1154e-01,
 2.1234e-01,  3.2762e-01, -2.9000e-01,
 1.8591e-02, -5.9820e-02, -9.0807e-02,
-3.0027e-01, -1.8370e-01,  1.2086e-02,
 2.1178e-02,  2.9559e-01,  1.2966e-01,
 6.8542e-02,  7.7710e-03, -6.0304e-02,
 3.3019e-03, -1.9135e-02,  9.3227e-03,
-9.9003e-03, -1.0101e-01, -3.3513e-01,
-8.4091e-03, -1.5918e-02, -3.4323e-02,
 3.8770e-40, -2.8639e-40,  4.6953e-40,
 4.2631e-40,  6.2568e-41, -5.3500e-40,
-2.1987e-40,  1.3435e-40,  4.4101e-40,
-3.9973e-40,  6.3046e-40,  1.6046e-40,
 4.4338e-40,  1.6940e-41,  4.1598e-40,
 2.6132e-40, -2.9888e-40, -7.5708e-41,
-1.5991e-02,  8.2749e-02, -6.3776e-02,
-3.2220e-03,  4.1443e-02, -8.1219e-02,
-1.1231e-01,  6.7586e-01, -1.7600e-01,
-4.0371e-02, -7.9044e-02,  1.2451e-01,
 4.1907e-02, -8.8159e-02, -1.1229e-01,
-4.0654e-03, -4.4087e-03,  1.2942e-01,
 9.3318e-03, -6.5085e-02,  1.0165e-02,
-2.8758e-02, -4.9997e-02,  4.6069e-02,
 4.2107e-04,  2.1718e-01,  3.1080e-03,
-9.1277e-03, -2.8568e-02,  1.6202e-02,
-8.2490e-03,  1.2888e-01, -1.3159e-01,
 1.6065e-02,  4.0143e-02,  2.7043e-01,
-3.4809e-02, -8.1302e-03,  6.0786e-02,
 5.1845e-02,  4.6995e-01, -1.0392e-02,
 2.3359e-02, -1.8364e-01, -3.7343e-01,
-8.2996e-02,  9.7724e-02, -6.1012e-02,
 2.8225e-02,  8.8706e-02,  1.3443e-02,
 3.7515e-03,  1.7772e-02,  6.5945e-03,
-7.3847e-12, -7.5629e-12, -6.9337e-12,
-7.6292e-12, -7.8624e-12, -7.2877e-12,
-7.0582e-12, -7.3197e-12, -6.8467e-12,
 1.5445e-11,  2.0754e-11,  2.0524e-11,
 2.1239e-11,  2.5909e-11,  2.5983e-11,
 2.0986e-11,  2.5190e-11,  2.2478e-11,
-4.7164e-02, -2.4754e-02, -1.8256e-02,
 1.0526e-01, -4.6010e-03, -2.2784e-02,
-5.2028e-02, -1.6408e-01,  7.9112e-03,
-8.1863e-02,  4.2772e-02, -9.9446e-04,
-5.5521e-02, -1.1264e-01, -4.5782e-02,
-1.1026e-01,  2.1443e-02, -4.5120e-02,
-1.4141e-02, -2.8116e-03,  2.6990e-02,
-2.0201e-01,  4.3214e-01,  2.9373e-02,
-2.1768e-01, -2.7230e-02,  5.5396e-03,
 5.0196e-02,  1.5506e-01, -5.7328e-02,
 4.8323e-02,  3.8243e-02, -1.3533e-01,
-9.8862e-03, -5.6971e-02, -7.1500e-02,
 1.0272e-01,  7.4686e-02,  7.4732e-02,
 8.3744e-02,  1.5834e-01,  2.9221e-02,
 6.5641e-02,  7.7697e-02,  3.5746e-02
);

const float biasL[4] = float[4]
(
-2.7729e-03, -4.8174e-03, -6.3012e-03,  2.0491e-01
);

vec4 hook()
{
    vec4 tl1 = L1_1_texOff(vec2(-1,-1));
    vec4 tc1 = L1_1_texOff(vec2(0,-1));
    vec4 tr1 = L1_1_texOff(vec2(1,-1));
    vec4 ml1 = L1_1_texOff(vec2(-1,0));
    vec4 mc1 = L1_1_texOff(vec2(0,0));
    vec4 mr1 = L1_1_texOff(vec2(1,0));
    vec4 bl1 = L1_1_texOff(vec2(-1,1));
    vec4 bc1 = L1_1_texOff(vec2(0,1));
    vec4 br1 = L1_1_texOff(vec2(1,1));

    vec4 tl2 = L1_2_texOff(vec2(-1,-1));
    vec4 tc2 = L1_2_texOff(vec2(0,-1));
    vec4 tr2 = L1_2_texOff(vec2(1,-1));
    vec4 ml2 = L1_2_texOff(vec2(-1,0));
    vec4 mc2 = L1_2_texOff(vec2(0,0));
    vec4 mr2 = L1_2_texOff(vec2(1,0));
    vec4 bl2 = L1_2_texOff(vec2(-1,1));
    vec4 bc2 = L1_2_texOff(vec2(0,1));
    vec4 br2 = L1_2_texOff(vec2(1,1));

    vec4 c1234 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c1234;
}


//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L8
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-1.6614e-01, -2.3128e-01,  4.4691e-02,
 6.3546e-02, -3.8105e-01,  3.4110e-02,
-3.5022e-02, -2.3782e-02,  2.8664e-02,
-3.8813e-41, -2.8626e-40, -9.0218e-41,
 4.1216e-40, -4.4215e-40,  3.1198e-40,
 5.6281e-40,  2.0477e-40,  2.7797e-40,
-4.4903e-40, -6.2574e-41,  4.9971e-40,
 5.0135e-40, -3.1945e-40, -2.4694e-40,
 2.6587e-40, -4.9583e-40, -4.9771e-40,
 3.7139e-02,  5.2936e-04, -2.3658e-02,
-3.6199e-01, -5.1912e-02, -5.1969e-02,
 2.5415e-01,  2.4109e-01,  9.8721e-03,
 5.5061e-02, -4.7469e-02,  3.0045e-02,
 2.1565e-03, -2.3866e-02, -2.3496e-02,
 6.0892e-02, -4.6442e-04, -5.0200e-02,
 5.4971e-02, -1.7234e-02, -3.2759e-03,
 4.8225e-01, -1.1234e-01,  3.8257e-02,
 5.2105e-02, -2.8473e-03, -1.0355e-02,
-9.5654e-03, -1.8751e-01,  1.7079e-02,
 7.0133e-02,  7.6363e-01, -8.7388e-02,
-5.6536e-02, -1.9152e-01, -1.6043e-01,
 2.0359e-01,  7.4214e-02,  3.1970e-02,
-1.8199e-01, -1.9386e-01, -2.5967e-03,
-3.4609e-02,  3.3870e-02,  5.8835e-02,
 8.8220e-02,  9.9265e-02,  7.1240e-03,
-9.1395e-02, -3.1699e-01, -2.9120e-02,
-1.8436e-02, -2.1432e-02, -4.5465e-02,
-3.2013e-40,  3.2019e-40,  4.8747e-41,
 2.6585e-40,  6.1463e-40,  1.4176e-40,
-1.5286e-40,  3.0543e-40,  7.2032e-41,
-6.0758e-40, -3.6200e-40,  1.2123e-40,
 1.3627e-40,  3.2983e-40,  3.6171e-40,
-4.2148e-40,  1.1102e-40,  3.2714e-40,
-3.4763e-02, -3.1632e-02,  3.0044e-02,
-2.0935e-01,  1.3533e-01, -9.1607e-03,
-1.5931e-01,  1.0771e-01, -6.6518e-02,
 2.4399e-02,  2.2923e-03,  5.1575e-02,
-1.4154e-01, -1.0013e-02, -7.5696e-02,
 1.0849e-01,  1.2575e-01, -7.3161e-02,
-1.5217e-02, -2.7659e-02, -3.1401e-02,
 3.4960e-01,  7.2390e-02,  2.0722e-02,
 3.9440e-01,  9.1821e-04,  1.7842e-02,
-1.5670e-02,  5.3020e-02,  6.0536e-02,
-1.8853e-01,  2.7532e-01, -1.9681e-01,
 8.3258e-02,  9.4285e-02, -1.2695e-01,
 2.7593e-01,  1.1456e-01,  1.6048e-02,
-5.1675e-01,  1.4727e-01,  7.5170e-02,
-6.9143e-02, -9.2948e-02,  3.4687e-02,
 1.4128e-02, -7.9962e-02,  8.0446e-02,
 3.7011e-02, -1.3400e-01, -2.0725e-02,
-6.4981e-03,  7.0724e-02,  6.6167e-02,
-4.5940e-41,  2.5437e-40, -3.3111e-40,
 5.9661e-40,  6.2521e-40,  5.6418e-40,
 1.9187e-40, -5.8872e-40,  5.5747e-40,
-1.6402e-11, -2.2097e-11, -1.7224e-11,
-2.2755e-11, -2.9977e-11, -2.1231e-11,
-1.3688e-11, -1.7479e-11, -1.3081e-11,
 6.4790e-03, -3.8464e-03, -1.0008e-02,
-2.6001e-02, -7.9483e-02,  3.3711e-02,
 2.6659e-03, -3.2634e-02,  1.0767e-02,
 4.9939e-03,  1.4064e-02, -3.4294e-02,
 4.8529e-02,  6.3386e-01, -3.6805e-02,
-1.3703e-01,  2.5878e-02, -4.8617e-02,
 3.2186e-02,  6.6382e-02,  1.9305e-02,
 7.0196e-02, -1.6892e-01, -2.8980e-02,
 9.7762e-02,  9.7998e-03, -5.1620e-03,
 5.0753e-02, -4.5071e-03, -3.9836e-02,
-6.0381e-02, -9.2016e-02,  9.5433e-02,
-1.0045e-02,  8.7955e-03,  4.9429e-02,
-1.8363e-02, -1.1912e-01,  9.7347e-03,
-1.5657e-01, -2.1035e-01, -4.9737e-02,
-3.0025e-02, -6.4959e-02, -5.6107e-02,
 3.2927e-40,  5.7263e-40,  6.2889e-40,
-6.0716e-39,  5.3050e-41, -1.7152e-40,
-3.2493e-38, -1.5841e-40, -1.9343e-40,
 4.9763e-40,  5.5142e-40, -4.3462e-40,
-2.2649e-40,  1.4321e-40, -2.6779e-40,
 2.3072e-41,  5.4080e-40, -6.4200e-41,
 2.2827e-40, -5.4515e-41, -4.1768e-40,
 3.9033e-40,  6.1988e-41,  5.9877e-40,
-4.3355e-41, -5.1088e-40,  5.9845e-40,
-4.8238e-40, -1.8586e-40,  4.8699e-40,
-9.7225e-41,  4.3387e-40, -4.3683e-40,
-7.9278e-41, -5.3614e-40,  2.1911e-40,
-3.3982e-40, -5.3335e-40,  3.8540e-40,
 1.9051e-40, -2.0840e-40,  2.2868e-40,
-3.5020e-40, -3.4276e-40,  2.7395e-42,
 3.9197e-40,  6.1843e-40, -1.5888e-40,
 4.3516e-40, -6.1852e-40, -5.3692e-40,
-4.3268e-40,  3.5154e-40,  3.4477e-40,
-4.8414e-40,  2.2647e-40, -2.5591e-40,
 4.6326e-40, -3.0462e-40,  4.7817e-40,
-4.9853e-40, -5.3425e-40, -2.9848e-40,
-1.3329e-07, -1.3784e-07, -1.3049e-07,
-1.3376e-07, -1.3905e-07, -1.3204e-07,
-1.2479e-07, -1.2994e-07, -1.2410e-07
);

const float biasL[4] = float[4]
(
-2.0110e-03, -3.0974e-03,  5.1407e-01, -3.5016e-08
);

vec4 hook()
{
    vec4 tl1 = L1_1_texOff(vec2(-1,-1));
    vec4 tc1 = L1_1_texOff(vec2(0,-1));
    vec4 tr1 = L1_1_texOff(vec2(1,-1));
    vec4 ml1 = L1_1_texOff(vec2(-1,0));
    vec4 mc1 = L1_1_texOff(vec2(0,0));
    vec4 mr1 = L1_1_texOff(vec2(1,0));
    vec4 bl1 = L1_1_texOff(vec2(-1,1));
    vec4 bc1 = L1_1_texOff(vec2(0,1));
    vec4 br1 = L1_1_texOff(vec2(1,1));

    vec4 tl2 = L1_2_texOff(vec2(-1,-1));
    vec4 tc2 = L1_2_texOff(vec2(0,-1));
    vec4 tr2 = L1_2_texOff(vec2(1,-1));
    vec4 ml2 = L1_2_texOff(vec2(-1,0));
    vec4 mc2 = L1_2_texOff(vec2(0,0));
    vec4 mr2 = L1_2_texOff(vec2(1,0));
    vec4 bl2 = L1_2_texOff(vec2(-1,1));
    vec4 bc2 = L1_2_texOff(vec2(0,1));
    vec4 br2 = L1_2_texOff(vec2(1,1));

    vec4 c5678 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c5678;
}

//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L9
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-2.5964e-02,  2.9670e-02,  1.2100e-01,
-3.0371e-02, -1.5277e-02, -1.8589e-01,
-1.8650e-02, -1.2852e-01, -6.6297e-02,
 9.7934e-04, -5.1835e-02, -1.0278e-03,
-1.2336e-02,  2.2130e-01, -1.2373e-01,
-2.3451e-02,  3.4217e-02, -1.0118e-02,
-3.0558e-01, -8.5390e-02, -1.4360e-02,
 1.2473e-01, -1.7005e-02, -3.6816e-02,
-8.9125e-02, -6.1400e-02, -2.0623e-02,
 1.3736e-02,  1.2441e-02, -4.3491e-02,
 6.4806e-02,  3.7012e-01,  3.8064e-02,
-1.3731e-02, -2.4859e-01, -2.5450e-01,
-6.5111e-03, -1.4271e-01, -5.0481e-02,
 5.3240e-02, -3.4843e-02, -2.2703e-02,
 3.7414e-02,  1.0334e-01, -7.2237e-02,
 1.4216e-02,  3.4231e-02, -2.0890e-02,
 2.7879e-02,  1.3717e-01,  4.5864e-03,
 3.0460e-03, -1.1734e-01,  4.4439e-02,
 6.4825e-03,  1.6324e-02,  1.4928e-02,
-8.8420e-02, -1.0779e-01, -9.0653e-02,
 3.1086e-02, -2.9067e-02, -8.8488e-02,
-1.6779e-40, -6.3646e-41, -6.2486e-40,
 2.3154e-40,  2.8049e-40,  3.7718e-40,
-3.3950e-40, -3.1501e-40,  5.8709e-40,
 2.1435e-02, -4.3732e-01,  1.5520e-02,
 3.4080e-02,  1.9912e-01, -8.1413e-02,
-3.2816e-02,  5.7844e-02,  8.9258e-03,
-1.1662e-02, -1.1721e-02,  4.3033e-02,
 5.2135e-02, -2.2503e-01,  2.3941e-01,
 3.8400e-02,  1.8075e-01, -1.4776e-01,
 2.6784e-01,  2.2817e-01, -3.0553e-03,
-6.7998e-02, -1.2050e-01,  1.4714e-02,
 2.4045e-02, -1.4329e-02, -1.6705e-02,
-1.1421e-02,  4.2139e-02,  4.2944e-02,
 1.8809e-02, -2.5221e-01,  9.7562e-02,
-4.1600e-02,  4.0069e-03,  7.5290e-02,
-2.0092e-02,  2.3537e-01,  2.4356e-02,
 3.1957e-02, -4.8573e-02,  2.9379e-02,
 6.4562e-03, -1.1527e-01, -9.1223e-02,
-2.3432e-02,  5.2881e-02, -7.3239e-02,
-3.7048e-02, -2.1481e-01,  5.9801e-05,
-4.2646e-02, -1.8366e-02, -1.0681e-01,
-1.3366e-01, -1.7123e-01, -3.5629e-02,
 1.1216e-01,  1.1479e-01,  9.5297e-02,
 2.4728e-02, -7.3135e-03, -3.4373e-02,
-2.3917e-40, -4.1869e-41,  3.7775e-41,
 2.8931e-40, -9.4850e-41,  2.5694e-40,
 3.3549e-40, -2.4334e-40, -5.5933e-41,
-2.0900e-02,  2.1203e-02, -4.7169e-02,
 2.3632e-02, -7.1148e-01,  4.9722e-02,
-7.8963e-03,  5.0689e-02,  2.2619e-02,
-4.7364e-03,  3.2037e-02,  1.1004e-02,
-4.3001e-03,  2.5245e-01,  5.9112e-02,
 2.8932e-02, -1.1267e-01, -2.3739e-01,
-6.5379e-02,  5.2462e-03, -1.6807e-02,
 1.0960e-01,  1.7943e-01, -6.3043e-03,
 9.3102e-02,  7.3103e-02,  2.5259e-02,
 5.6835e-02,  4.0467e-02,  2.5447e-03,
 9.4599e-02,  2.5222e-01,  6.9855e-02,
 4.4758e-02,  1.8073e-01,  1.5075e-01,
 2.0329e-02, -4.9412e-02,  2.0663e-02,
-7.1648e-03,  1.4986e-01,  2.1212e-01,
 2.7657e-02, -6.8660e-02,  1.7321e-02,
 1.0629e-02, -1.0722e-02,  2.8247e-02,
-1.1303e-02,  1.0076e-01, -4.0592e-01,
 2.6744e-02,  7.3650e-02,  5.7966e-02,
 2.8122e-02, -7.5961e-02, -9.4797e-03,
-1.3010e-01, -5.4184e-01, -1.3619e-01,
-1.8661e-03, -1.4357e-01,  7.9520e-03,
-1.3538e-09, -1.6580e-09, -1.7289e-09,
-1.2386e-09, -1.5132e-09, -1.5987e-09,
-1.1157e-09, -1.3420e-09, -1.4090e-09,
 1.5441e-02, -1.8142e-01, -8.6802e-02,
-4.0983e-02,  2.4351e-01, -5.8181e-02,
-2.9568e-02,  3.9561e-03,  3.4181e-02,
-2.9210e-02,  2.5403e-02,  9.1331e-02,
 2.3621e-02,  2.3954e-01,  5.2487e-02,
 1.6509e-02, -6.2728e-02,  1.3448e-02,
 1.2855e-01,  1.1892e-02, -1.3356e-02,
 1.0810e-01,  1.6760e-01, -3.2040e-02,
 6.2209e-02,  4.0682e-02,  3.9772e-02,
-6.1711e-03,  5.0588e-02, -1.0811e-01,
 1.5744e-02,  1.6091e-01, -6.1739e-02,
-5.6717e-02, -1.0657e-02, -3.7943e-02,
-4.0595e-02,  8.0149e-02,  2.0216e-02,
 3.8838e-02, -6.3586e-01,  2.3785e-01,
-1.0472e-02,  6.3899e-02, -8.2184e-02,
-1.9137e-02,  8.1163e-02,  6.7065e-02,
-2.2377e-03,  1.1860e-01,  3.4122e-02,
 1.0501e-02,  2.9851e-02,  7.5841e-02,
 5.8970e-02, -1.2188e-01,  7.7982e-02,
-2.6516e-02, -4.1289e-01,  2.1471e-02,
 3.3957e-02,  3.5762e-02, -5.7857e-02,
-2.7357e-30, -3.4780e-30, -3.0306e-30,
-1.5188e-30, -1.9888e-30, -1.8755e-30,
-7.7431e-31, -9.7571e-31, -9.7402e-31
);

const float biasL[4] = float[4]
(
0.0324, 0.0140, 0.6750, 0.2661
);

vec4 hook()
{
    vec4 tl1 = L2_1_texOff(vec2(-1,-1));
    vec4 tc1 = L2_1_texOff(vec2(0,-1));
    vec4 tr1 = L2_1_texOff(vec2(1,-1));
    vec4 ml1 = L2_1_texOff(vec2(-1,0));
    vec4 mc1 = L2_1_texOff(vec2(0,0));
    vec4 mr1 = L2_1_texOff(vec2(1,0));
    vec4 bl1 = L2_1_texOff(vec2(-1,1));
    vec4 bc1 = L2_1_texOff(vec2(0,1));
    vec4 br1 = L2_1_texOff(vec2(1,1));

    vec4 tl2 = L2_2_texOff(vec2(-1,-1));
    vec4 tc2 = L2_2_texOff(vec2(0,-1));
    vec4 tr2 = L2_2_texOff(vec2(1,-1));
    vec4 ml2 = L2_2_texOff(vec2(-1,0));
    vec4 mc2 = L2_2_texOff(vec2(0,0));
    vec4 mr2 = L2_2_texOff(vec2(1,0));
    vec4 bl2 = L2_2_texOff(vec2(-1,1));
    vec4 bc2 = L2_2_texOff(vec2(0,1));
    vec4 br2 = L2_2_texOff(vec2(1,1));

    vec4 c1234 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c1234;
}


//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L9
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-1.8497e-02, -2.4554e-02,  1.4428e-01,
 1.4217e-02, -2.3647e-01,  8.4097e-02,
-1.0251e-02, -4.2137e-03,  6.0831e-03,
 1.7742e-03,  2.1487e-02,  3.3147e-02,
-1.0971e-02,  3.0162e-01,  5.2391e-02,
 1.8341e-02, -1.3390e-01,  9.4303e-02,
-1.5685e-01,  9.8434e-02, -1.2502e-03,
 3.1370e-01, -2.8879e-02,  2.6313e-03,
 1.7548e-02,  6.6741e-03, -1.7681e-03,
 5.2062e-02,  6.6914e-02,  7.5256e-03,
 2.4966e-02,  2.8081e-01,  2.9815e-02,
 2.2375e-02,  1.4257e-03, -7.4702e-02,
 1.5372e-02,  3.9587e-02,  4.6909e-02,
-2.2911e-02, -1.4568e-01, -3.8964e-01,
 2.2850e-02, -4.2297e-02,  6.5736e-02,
-6.9905e-03, -6.3972e-02, -1.8430e-01,
 4.4453e-03,  2.0687e-01,  3.0032e-01,
 1.7243e-02,  9.8548e-03, -9.7476e-02,
-7.9682e-04, -2.1199e-01, -4.3461e-02,
-4.2929e-02, -2.8227e-01,  2.8997e-02,
-1.8741e-03,  1.1166e-02,  1.8381e-03,
-5.6725e-16, -1.0368e-15, -1.1480e-15,
-5.5537e-16, -9.9929e-16, -1.1499e-15,
-3.8787e-16, -6.4019e-16, -7.7595e-16,
 4.4505e-02,  8.8803e-02,  1.1384e-02,
-3.9434e-02,  1.9319e-01, -1.2016e-02,
-4.6072e-02,  1.1769e-01,  7.4816e-03,
-3.7856e-02, -1.7147e-02,  1.5984e-01,
-2.6459e-02,  1.7469e-01,  1.2584e-01,
 1.6387e-02,  1.7370e-01, -1.7350e-01,
-3.0008e-01,  2.1485e-01, -5.4302e-02,
 5.7724e-02,  3.2168e-01, -2.5261e-02,
 6.9277e-02,  7.5035e-02,  6.3485e-02,
-1.1688e-01,  2.6068e-02, -1.3490e-01,
-1.6085e-01,  1.9409e-01,  1.1434e-01,
-7.3819e-02, -7.7880e-02,  7.3699e-03,
-9.9972e-02,  1.3554e-01,  2.1656e-02,
-8.8303e-02,  5.4435e-01, -4.0582e-02,
-3.4805e-02, -1.5291e-01, -3.6917e-02,
-3.4377e-02, -3.3086e-02, -9.5097e-02,
-7.4538e-03,  2.2545e-01, -2.6380e-02,
 1.4440e-02,  1.3205e-01,  1.6164e-01,
 9.2164e-02, -8.4307e-02,  7.8922e-02,
 1.2519e-01, -6.1809e-01, -1.0895e-01,
 6.2744e-02, -4.4951e-02, -3.2548e-02,
-2.5422e-21, -6.3849e-21, -9.5560e-21,
-1.9248e-21, -4.7107e-21, -6.4244e-21,
-1.4638e-21, -3.1947e-21, -3.7663e-21,
-8.6113e-03, -7.0987e-02,  5.8265e-02,
-1.3148e-02,  5.6371e-01,  5.0580e-02,
 1.1741e-02, -3.5614e-02, -6.1265e-02,
 1.4758e-03,  3.3349e-02, -1.0867e-02,
-4.0234e-02,  1.9894e-01,  1.3972e-01,
-1.9167e-02, -4.1723e-02, -1.9982e-01,
-3.0756e-01,  2.6284e-02, -1.9058e-02,
-7.9349e-04,  1.2644e-01,  2.9567e-02,
-3.9274e-02,  1.1030e-02, -9.4885e-03,
 1.3541e-02,  1.7044e-01,  8.9626e-02,
 6.6814e-02,  2.6430e-01,  1.7409e-01,
-6.1034e-04,  1.7569e-02,  1.3090e-01,
-4.1941e-03,  8.9599e-02, -3.3684e-02,
-1.1310e-02, -4.3731e-01,  5.7177e-02,
-4.5718e-04,  1.0175e-01,  4.1211e-02,
 2.9756e-02, -1.1601e-01, -7.3171e-02,
 2.7939e-02,  2.1334e-01, -4.0210e-01,
-8.6847e-03,  8.1829e-02,  4.4225e-02,
-1.1411e-01, -1.7697e-01, -5.8087e-02,
 7.9613e-02, -4.2814e-01, -1.0814e-01,
-3.0610e-02,  1.1342e-03, -2.2322e-03,
-1.1254e-10, -1.4207e-10, -1.5402e-10,
-9.9123e-11, -1.2394e-10, -1.3338e-10,
-8.8840e-11, -1.0857e-10, -1.1463e-10,
 3.0283e-02, -5.6191e-02, -1.0447e-01,
-1.4578e-02, -2.8745e-01,  1.9089e-01,
-2.7251e-02,  9.8069e-02, -1.4580e-02,
-3.0276e-02,  1.4366e-02,  2.6363e-02,
-8.4962e-02,  7.8998e-02, -4.7717e-02,
-3.2004e-02, -2.1579e-02,  1.1247e-02,
 1.3895e-01, -3.3900e-01,  7.7998e-03,
 2.4769e-01, -1.8506e-01, -2.3116e-03,
 3.1361e-02, -1.1718e-02, -1.8286e-02,
-1.3020e-01,  1.4334e-01, -5.5700e-02,
-3.5386e-02,  1.0992e-01, -8.0235e-02,
-5.8978e-03,  7.7039e-02, -7.4619e-02,
-8.1603e-02,  1.2982e-01, -7.3193e-02,
-6.1469e-02,  1.7131e-01,  4.0255e-01,
-6.4582e-03, -8.2741e-02, -2.2220e-02,
 1.6876e-02, -3.2590e-02,  5.5645e-02,
 2.5231e-02,  2.9984e-01, -3.6995e-02,
 9.3322e-03,  2.0758e-01, -2.1986e-02,
-4.9568e-02,  2.1857e-03,  8.6127e-02,
 8.6593e-02, -5.8134e-01,  3.4507e-01,
 4.8855e-02, -1.0506e-01,  4.1584e-02,
 2.5428e-40, -4.4558e-40, -2.2090e-40,
-2.9727e-40, -4.8454e-40,  3.0397e-40,
 1.1696e-40, -3.3028e-40, -2.2959e-40
);

const float biasL[4] = float[4]
(
 0.3646, 0.3591, 0.5597, 0.0816
);

vec4 hook()
{
    vec4 tl1 = L2_1_texOff(vec2(-1,-1));
    vec4 tc1 = L2_1_texOff(vec2(0,-1));
    vec4 tr1 = L2_1_texOff(vec2(1,-1));
    vec4 ml1 = L2_1_texOff(vec2(-1,0));
    vec4 mc1 = L2_1_texOff(vec2(0,0));
    vec4 mr1 = L2_1_texOff(vec2(1,0));
    vec4 bl1 = L2_1_texOff(vec2(-1,1));
    vec4 bc1 = L2_1_texOff(vec2(0,1));
    vec4 br1 = L2_1_texOff(vec2(1,1));

    vec4 tl2 = L2_2_texOff(vec2(-1,-1));
    vec4 tc2 = L2_2_texOff(vec2(0,-1));
    vec4 tr2 = L2_2_texOff(vec2(1,-1));
    vec4 ml2 = L2_2_texOff(vec2(-1,0));
    vec4 mc2 = L2_2_texOff(vec2(0,0));
    vec4 mr2 = L2_2_texOff(vec2(1,0));
    vec4 bl2 = L2_2_texOff(vec2(-1,1));
    vec4 bc2 = L2_2_texOff(vec2(0,1));
    vec4 br2 = L2_2_texOff(vec2(1,1));

    vec4 c5678 = RELU(vec4(
        tl1.x * kernelsL[0*72+0*9+0] + tc1.x * kernelsL[0*72+0*9+1] + tr1.x * kernelsL[0*72+0*9+2] +
        ml1.x * kernelsL[0*72+0*9+3] + mc1.x * kernelsL[0*72+0*9+4] + mr1.x * kernelsL[0*72+0*9+5] +
        bl1.x * kernelsL[0*72+0*9+6] + bc1.x * kernelsL[0*72+0*9+7] + br1.x * kernelsL[0*72+0*9+8] + 

        tl1.y * kernelsL[0*72+1*9+0] + tc1.y * kernelsL[0*72+1*9+1] + tr1.y * kernelsL[0*72+1*9+2] +
        ml1.y * kernelsL[0*72+1*9+3] + mc1.y * kernelsL[0*72+1*9+4] + mr1.y * kernelsL[0*72+1*9+5] +
        bl1.y * kernelsL[0*72+1*9+6] + bc1.y * kernelsL[0*72+1*9+7] + br1.y * kernelsL[0*72+1*9+8] + 

        tl1.z * kernelsL[0*72+2*9+0] + tc1.z * kernelsL[0*72+2*9+1] + tr1.z * kernelsL[0*72+2*9+2] +
        ml1.z * kernelsL[0*72+2*9+3] + mc1.z * kernelsL[0*72+2*9+4] + mr1.z * kernelsL[0*72+2*9+5] +
        bl1.z * kernelsL[0*72+2*9+6] + bc1.z * kernelsL[0*72+2*9+7] + br1.z * kernelsL[0*72+2*9+8] + 

        tl1.w * kernelsL[0*72+3*9+0] + tc1.w * kernelsL[0*72+3*9+1] + tr1.w * kernelsL[0*72+3*9+2] +
        ml1.w * kernelsL[0*72+3*9+3] + mc1.w * kernelsL[0*72+3*9+4] + mr1.w * kernelsL[0*72+3*9+5] +
        bl1.w * kernelsL[0*72+3*9+6] + bc1.w * kernelsL[0*72+3*9+7] + br1.w * kernelsL[0*72+3*9+8] +

        tl2.x * kernelsL[0*72+4*9+0] + tc2.x * kernelsL[0*72+4*9+1] + tr2.x * kernelsL[0*72+4*9+2] +
        ml2.x * kernelsL[0*72+4*9+3] + mc2.x * kernelsL[0*72+4*9+4] + mr2.x * kernelsL[0*72+4*9+5] +
        bl2.x * kernelsL[0*72+4*9+6] + bc2.x * kernelsL[0*72+4*9+7] + br2.x * kernelsL[0*72+4*9+8] + 

        tl2.y * kernelsL[0*72+5*9+0] + tc2.y * kernelsL[0*72+5*9+1] + tr2.y * kernelsL[0*72+5*9+2] +
        ml2.y * kernelsL[0*72+5*9+3] + mc2.y * kernelsL[0*72+5*9+4] + mr2.y * kernelsL[0*72+5*9+5] +
        bl2.y * kernelsL[0*72+5*9+6] + bc2.y * kernelsL[0*72+5*9+7] + br2.y * kernelsL[0*72+5*9+8] + 

        tl2.z * kernelsL[0*72+6*9+0] + tc2.z * kernelsL[0*72+6*9+1] + tr2.z * kernelsL[0*72+6*9+2] +
        ml2.z * kernelsL[0*72+6*9+3] + mc2.z * kernelsL[0*72+6*9+4] + mr2.z * kernelsL[0*72+6*9+5] +
        bl2.z * kernelsL[0*72+6*9+6] + bc2.z * kernelsL[0*72+6*9+7] + br2.z * kernelsL[0*72+6*9+8] + 

        tl2.w * kernelsL[0*72+7*9+0] + tc2.w * kernelsL[0*72+7*9+1] + tr2.w * kernelsL[0*72+7*9+2] +
        ml2.w * kernelsL[0*72+7*9+3] + mc2.w * kernelsL[0*72+7*9+4] + mr2.w * kernelsL[0*72+7*9+5] +
        bl2.w * kernelsL[0*72+7*9+6] + bc2.w * kernelsL[0*72+7*9+7] + br2.w * kernelsL[0*72+7*9+8] + biasL[0]
        ,
        tl1.x * kernelsL[1*72+0*9+0] + tc1.x * kernelsL[1*72+0*9+1] + tr1.x * kernelsL[1*72+0*9+2] +
        ml1.x * kernelsL[1*72+0*9+3] + mc1.x * kernelsL[1*72+0*9+4] + mr1.x * kernelsL[1*72+0*9+5] +
        bl1.x * kernelsL[1*72+0*9+6] + bc1.x * kernelsL[1*72+0*9+7] + br1.x * kernelsL[1*72+0*9+8] + 

        tl1.y * kernelsL[1*72+1*9+0] + tc1.y * kernelsL[1*72+1*9+1] + tr1.y * kernelsL[1*72+1*9+2] +
        ml1.y * kernelsL[1*72+1*9+3] + mc1.y * kernelsL[1*72+1*9+4] + mr1.y * kernelsL[1*72+1*9+5] +
        bl1.y * kernelsL[1*72+1*9+6] + bc1.y * kernelsL[1*72+1*9+7] + br1.y * kernelsL[1*72+1*9+8] + 

        tl1.z * kernelsL[1*72+2*9+0] + tc1.z * kernelsL[1*72+2*9+1] + tr1.z * kernelsL[1*72+2*9+2] +
        ml1.z * kernelsL[1*72+2*9+3] + mc1.z * kernelsL[1*72+2*9+4] + mr1.z * kernelsL[1*72+2*9+5] +
        bl1.z * kernelsL[1*72+2*9+6] + bc1.z * kernelsL[1*72+2*9+7] + br1.z * kernelsL[1*72+2*9+8] + 

        tl1.w * kernelsL[1*72+3*9+0] + tc1.w * kernelsL[1*72+3*9+1] + tr1.w * kernelsL[1*72+3*9+2] +
        ml1.w * kernelsL[1*72+3*9+3] + mc1.w * kernelsL[1*72+3*9+4] + mr1.w * kernelsL[1*72+3*9+5] +
        bl1.w * kernelsL[1*72+3*9+6] + bc1.w * kernelsL[1*72+3*9+7] + br1.w * kernelsL[1*72+3*9+8] +

        tl2.x * kernelsL[1*72+4*9+0] + tc2.x * kernelsL[1*72+4*9+1] + tr2.x * kernelsL[1*72+4*9+2] +
        ml2.x * kernelsL[1*72+4*9+3] + mc2.x * kernelsL[1*72+4*9+4] + mr2.x * kernelsL[1*72+4*9+5] +
        bl2.x * kernelsL[1*72+4*9+6] + bc2.x * kernelsL[1*72+4*9+7] + br2.x * kernelsL[1*72+4*9+8] + 

        tl2.y * kernelsL[1*72+5*9+0] + tc2.y * kernelsL[1*72+5*9+1] + tr2.y * kernelsL[1*72+5*9+2] +
        ml2.y * kernelsL[1*72+5*9+3] + mc2.y * kernelsL[1*72+5*9+4] + mr2.y * kernelsL[1*72+5*9+5] +
        bl2.y * kernelsL[1*72+5*9+6] + bc2.y * kernelsL[1*72+5*9+7] + br2.y * kernelsL[1*72+5*9+8] + 

        tl2.z * kernelsL[1*72+6*9+0] + tc2.z * kernelsL[1*72+6*9+1] + tr2.z * kernelsL[1*72+6*9+2] +
        ml2.z * kernelsL[1*72+6*9+3] + mc2.z * kernelsL[1*72+6*9+4] + mr2.z * kernelsL[1*72+6*9+5] +
        bl2.z * kernelsL[1*72+6*9+6] + bc2.z * kernelsL[1*72+6*9+7] + br2.z * kernelsL[1*72+6*9+8] + 

        tl2.w * kernelsL[1*72+7*9+0] + tc2.w * kernelsL[1*72+7*9+1] + tr2.w * kernelsL[1*72+7*9+2] +
        ml2.w * kernelsL[1*72+7*9+3] + mc2.w * kernelsL[1*72+7*9+4] + mr2.w * kernelsL[1*72+7*9+5] +
        bl2.w * kernelsL[1*72+7*9+6] + bc2.w * kernelsL[1*72+7*9+7] + br2.w * kernelsL[1*72+7*9+8] + biasL[1]
        ,
        tl1.x * kernelsL[2*72+0*9+0] + tc1.x * kernelsL[2*72+0*9+1] + tr1.x * kernelsL[2*72+0*9+2] +
        ml1.x * kernelsL[2*72+0*9+3] + mc1.x * kernelsL[2*72+0*9+4] + mr1.x * kernelsL[2*72+0*9+5] +
        bl1.x * kernelsL[2*72+0*9+6] + bc1.x * kernelsL[2*72+0*9+7] + br1.x * kernelsL[2*72+0*9+8] + 

        tl1.y * kernelsL[2*72+1*9+0] + tc1.y * kernelsL[2*72+1*9+1] + tr1.y * kernelsL[2*72+1*9+2] +
        ml1.y * kernelsL[2*72+1*9+3] + mc1.y * kernelsL[2*72+1*9+4] + mr1.y * kernelsL[2*72+1*9+5] +
        bl1.y * kernelsL[2*72+1*9+6] + bc1.y * kernelsL[2*72+1*9+7] + br1.y * kernelsL[2*72+1*9+8] + 

        tl1.z * kernelsL[2*72+2*9+0] + tc1.z * kernelsL[2*72+2*9+1] + tr1.z * kernelsL[2*72+2*9+2] +
        ml1.z * kernelsL[2*72+2*9+3] + mc1.z * kernelsL[2*72+2*9+4] + mr1.z * kernelsL[2*72+2*9+5] +
        bl1.z * kernelsL[2*72+2*9+6] + bc1.z * kernelsL[2*72+2*9+7] + br1.z * kernelsL[2*72+2*9+8] + 

        tl1.w * kernelsL[2*72+3*9+0] + tc1.w * kernelsL[2*72+3*9+1] + tr1.w * kernelsL[2*72+3*9+2] +
        ml1.w * kernelsL[2*72+3*9+3] + mc1.w * kernelsL[2*72+3*9+4] + mr1.w * kernelsL[2*72+3*9+5] +
        bl1.w * kernelsL[2*72+3*9+6] + bc1.w * kernelsL[2*72+3*9+7] + br1.w * kernelsL[2*72+3*9+8] +

        tl2.x * kernelsL[2*72+4*9+0] + tc2.x * kernelsL[2*72+4*9+1] + tr2.x * kernelsL[2*72+4*9+2] +
        ml2.x * kernelsL[2*72+4*9+3] + mc2.x * kernelsL[2*72+4*9+4] + mr2.x * kernelsL[2*72+4*9+5] +
        bl2.x * kernelsL[2*72+4*9+6] + bc2.x * kernelsL[2*72+4*9+7] + br2.x * kernelsL[2*72+4*9+8] + 

        tl2.y * kernelsL[2*72+5*9+0] + tc2.y * kernelsL[2*72+5*9+1] + tr2.y * kernelsL[2*72+5*9+2] +
        ml2.y * kernelsL[2*72+5*9+3] + mc2.y * kernelsL[2*72+5*9+4] + mr2.y * kernelsL[2*72+5*9+5] +
        bl2.y * kernelsL[2*72+5*9+6] + bc2.y * kernelsL[2*72+5*9+7] + br2.y * kernelsL[2*72+5*9+8] + 

        tl2.z * kernelsL[2*72+6*9+0] + tc2.z * kernelsL[2*72+6*9+1] + tr2.z * kernelsL[2*72+6*9+2] +
        ml2.z * kernelsL[2*72+6*9+3] + mc2.z * kernelsL[2*72+6*9+4] + mr2.z * kernelsL[2*72+6*9+5] +
        bl2.z * kernelsL[2*72+6*9+6] + bc2.z * kernelsL[2*72+6*9+7] + br2.z * kernelsL[2*72+6*9+8] + 

        tl2.w * kernelsL[2*72+7*9+0] + tc2.w * kernelsL[2*72+7*9+1] + tr2.w * kernelsL[2*72+7*9+2] +
        ml2.w * kernelsL[2*72+7*9+3] + mc2.w * kernelsL[2*72+7*9+4] + mr2.w * kernelsL[2*72+7*9+5] +
        bl2.w * kernelsL[2*72+7*9+6] + bc2.w * kernelsL[2*72+7*9+7] + br2.w * kernelsL[2*72+7*9+8] + biasL[2]
        ,
        tl1.x * kernelsL[3*72+0*9+0] + tc1.x * kernelsL[3*72+0*9+1] + tr1.x * kernelsL[3*72+0*9+2] +
        ml1.x * kernelsL[3*72+0*9+3] + mc1.x * kernelsL[3*72+0*9+4] + mr1.x * kernelsL[3*72+0*9+5] +
        bl1.x * kernelsL[3*72+0*9+6] + bc1.x * kernelsL[3*72+0*9+7] + br1.x * kernelsL[3*72+0*9+8] + 

        tl1.y * kernelsL[3*72+1*9+0] + tc1.y * kernelsL[3*72+1*9+1] + tr1.y * kernelsL[3*72+1*9+2] +
        ml1.y * kernelsL[3*72+1*9+3] + mc1.y * kernelsL[3*72+1*9+4] + mr1.y * kernelsL[3*72+1*9+5] +
        bl1.y * kernelsL[3*72+1*9+6] + bc1.y * kernelsL[3*72+1*9+7] + br1.y * kernelsL[3*72+1*9+8] + 

        tl1.z * kernelsL[3*72+2*9+0] + tc1.z * kernelsL[3*72+2*9+1] + tr1.z * kernelsL[3*72+2*9+2] +
        ml1.z * kernelsL[3*72+2*9+3] + mc1.z * kernelsL[3*72+2*9+4] + mr1.z * kernelsL[3*72+2*9+5] +
        bl1.z * kernelsL[3*72+2*9+6] + bc1.z * kernelsL[3*72+2*9+7] + br1.z * kernelsL[3*72+2*9+8] + 

        tl1.w * kernelsL[3*72+3*9+0] + tc1.w * kernelsL[3*72+3*9+1] + tr1.w * kernelsL[3*72+3*9+2] +
        ml1.w * kernelsL[3*72+3*9+3] + mc1.w * kernelsL[3*72+3*9+4] + mr1.w * kernelsL[3*72+3*9+5] +
        bl1.w * kernelsL[3*72+3*9+6] + bc1.w * kernelsL[3*72+3*9+7] + br1.w * kernelsL[3*72+3*9+8] +

        tl2.x * kernelsL[3*72+4*9+0] + tc2.x * kernelsL[3*72+4*9+1] + tr2.x * kernelsL[3*72+4*9+2] +
        ml2.x * kernelsL[3*72+4*9+3] + mc2.x * kernelsL[3*72+4*9+4] + mr2.x * kernelsL[3*72+4*9+5] +
        bl2.x * kernelsL[3*72+4*9+6] + bc2.x * kernelsL[3*72+4*9+7] + br2.x * kernelsL[3*72+4*9+8] + 

        tl2.y * kernelsL[3*72+5*9+0] + tc2.y * kernelsL[3*72+5*9+1] + tr2.y * kernelsL[3*72+5*9+2] +
        ml2.y * kernelsL[3*72+5*9+3] + mc2.y * kernelsL[3*72+5*9+4] + mr2.y * kernelsL[3*72+5*9+5] +
        bl2.y * kernelsL[3*72+5*9+6] + bc2.y * kernelsL[3*72+5*9+7] + br2.y * kernelsL[3*72+5*9+8] + 

        tl2.z * kernelsL[3*72+6*9+0] + tc2.z * kernelsL[3*72+6*9+1] + tr2.z * kernelsL[3*72+6*9+2] +
        ml2.z * kernelsL[3*72+6*9+3] + mc2.z * kernelsL[3*72+6*9+4] + mr2.z * kernelsL[3*72+6*9+5] +
        bl2.z * kernelsL[3*72+6*9+6] + bc2.z * kernelsL[3*72+6*9+7] + br2.z * kernelsL[3*72+6*9+8] + 

        tl2.w * kernelsL[3*72+7*9+0] + tc2.w * kernelsL[3*72+7*9+1] + tr2.w * kernelsL[3*72+7*9+2] +
        ml2.w * kernelsL[3*72+7*9+3] + mc2.w * kernelsL[3*72+7*9+4] + mr2.w * kernelsL[3*72+7*9+5] +
        bl2.w * kernelsL[3*72+7*9+6] + bc2.w * kernelsL[3*72+7*9+7] + br2.w * kernelsL[3*72+7*9+8] + biasL[3]
    ));


    return c5678;
}

//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 1 L10
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!BIND L1_1
//!BIND L1_2

const float kernelsL10[4 * 8] = float[4 * 8]
(
 0.0882,  0.0422,
 0.3775,  0.4754,
-0.3209, -0.4870,
-0.0384,  0.0530,
 0.1034,  0.0173,
 0.5011,  0.3900,
 0.3621, -0.1645,
-0.1304,  0.0013,
 0.2230,  0.3026,
 0.1618, -0.4514,
-0.2097,  0.1894,
-0.0326,  0.1434,
 0.2421,  0.3363,
-0.0938,  0.3156,
 0.1137, -0.2165,
 0.2273, -0.1284
);

vec4 hook()
{
    vec2 fcoord = fract(L1_1_pos * L1_1_size);
    vec2 pos = L1_1_pos + (vec2(0.5) - fcoord) * L1_1_pt;

    ivec2 icoord = ivec2(fcoord * vec2(2));
    int inedx = icoord.y * 2 + icoord.x;

    vec4 mc1 = L1_1_tex(pos);
    vec4 mc2 = L1_2_tex(pos);

    float luma = clamp(
        mc1.x * kernelsL10[0 + inedx] +
        mc1.y * kernelsL10[4 + inedx] +
        mc1.z * kernelsL10[8 + inedx] +
        mc1.w * kernelsL10[12 + inedx] +
        mc2.x * kernelsL10[16 + inedx] +
        mc2.y * kernelsL10[20 + inedx] +
        mc2.z * kernelsL10[24 + inedx] +
        mc2.w * kernelsL10[28 + inedx], 0.0f, 1.0f);
    
    return vec4(luma, 0.0f, 0.0f, 1.0f);
}