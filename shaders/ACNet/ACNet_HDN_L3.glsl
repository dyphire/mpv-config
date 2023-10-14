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
  description: Anime4KCPP Net HDN Level 3 GLSL
  Author: TianZerL
*/

//!HOOK LUMA
//!WHEN OUTPUT.w LUMA.w / 1.200 > OUTPUT.h LUMA.h / 1.200 > *
//!DESC ACNet HDN Level 3 L1
//!BIND LUMA
//!SAVE L1_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL1[9 * 4] = float[9 * 4]
(
-0.0461,  0.1274,  0.2976,
-0.0393, -0.1251,  0.2527,
 0.0791,  0.0600, -0.0303,
-0.0520, -0.5039, -0.3305,
-0.0115,  0.0456,  0.4370,
 0.0601,  0.0780,  0.3106,
-0.0017, -0.0018, -0.0017,
-0.0017, -0.0018, -0.0018,
-0.0017, -0.0017, -0.0017,
 0.2666,  0.1687,  0.2303,
-0.1901,  0.3825,  0.3024,
 0.1811,  0.0581,  0.2080
);

const float biasL1[4] = float[4]
(
-0.1329, -0.0431, -0.0031, -0.0129
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
//!DESC ACNet HDN Level 3 L1
//!BIND LUMA
//!SAVE L1_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL1[9 * 4] = float[9 * 4]
(
-0.1246,  0.0155, -0.4075,
 0.1156,  0.5929,  0.1449,
-0.1080, -0.0171, -0.0516,
-0.0817,  0.2247,  0.0472,
 0.0394,  0.1085,  0.1435,
-0.0480, -0.0135, -0.0606,
-0.0083,  0.2045,  0.1056,
-0.2239,  0.2823, -0.1926,
 0.2581,  0.1362, -0.1914,
-0.0833,  0.0702,  0.0234,
 0.3616,  0.3789, -0.1840,
 0.0128,  0.1347, -0.0187
);

const float biasL1[4] = float[4]
(
 0.2294, -0.2595, -0.2370, -0.0499
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
//!DESC ACNet HDN Level 3 L2
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 1.4090e-01, -1.8985e-02, -6.8589e-02,
 6.6491e-02,  1.4360e-02,  8.5223e-02,
 1.8782e-01,  9.8042e-02, -3.4558e-02,
 2.5606e-01,  2.2027e-01,  2.7603e-01,
 1.9424e-01,  3.4537e-02,  9.5975e-02,
 1.1223e-02, -4.3377e-01, -1.4760e-01,
-3.4293e-40, -5.5421e-40, -4.4763e-41,
-6.3322e-40, -3.1495e-40, -7.8264e-41,
-1.5375e-40, -3.3656e-40,  5.2441e-40,
 1.2413e-01,  1.5682e-01,  1.1465e-01,
 1.6683e-02,  7.8382e-02,  1.0110e-01,
 1.4902e-01,  1.3608e-01,  1.1674e-01,
-6.5160e-02,  7.7748e-02,  2.1773e-02,
 2.0652e-02,  2.7245e-01,  1.0297e-01,
-2.0953e-02,  6.1685e-02,  4.4128e-02,
 6.1538e-02, -1.9746e-02, -1.2785e-02,
 2.5931e-02,  1.2740e-01,  9.0033e-02,
 8.6448e-02,  2.0684e-01,  9.8063e-02,
-7.8384e-03,  6.3277e-02,  7.6751e-03,
 3.5956e-02,  1.0555e-01,  4.2728e-02,
 7.1578e-02,  1.3253e-01,  1.1171e-01,
-2.7538e-02,  1.5836e-01,  1.0014e-01,
-4.9113e-02,  1.6911e-01,  2.7329e-01,
 7.9170e-03,  9.5440e-02,  1.3922e-01,
 8.0151e-02,  4.3438e-02,  5.5314e-02,
 3.4896e-02,  1.6816e-01, -4.5783e-03,
-1.4579e-03,  2.0493e-01,  2.6238e-02,
 2.6499e-02,  3.9490e-01, -1.1582e-02,
 3.5790e-01,  1.4317e-01, -2.1775e-01,
 4.1794e-03, -3.2513e-01, -1.6729e-01,
 3.4040e-41, -6.2960e-42, -1.0067e-40,
 5.5978e-41, -1.2353e-40, -1.1347e-40,
 5.4572e-40, -6.4384e-40, -4.1234e-40,
-9.3690e-02,  1.7765e-01,  1.1275e-01,
 9.1159e-03,  1.7375e-01,  1.1427e-01,
-7.8385e-02,  1.5658e-01, -3.8399e-02,
-1.0756e-01,  5.9943e-02, -6.7273e-02,
-1.1117e-01,  1.5267e-01,  1.1563e-01,
-1.2964e-01, -3.8604e-02, -2.4532e-02,
 1.6324e-02,  1.3112e-01,  6.1679e-03,
-7.7703e-03,  2.6311e-01,  8.9427e-02,
-2.8948e-02,  1.9341e-01,  4.4339e-02,
 6.4559e-03, -6.8885e-02,  1.1481e-01,
-1.0665e-01,  3.8613e-02,  7.0410e-02,
-6.1680e-02, -1.7374e-02,  9.5475e-03,
-4.0081e-02, -3.1549e-02,  2.8311e-01,
-1.2178e-01, -1.3848e-01,  1.7416e-01,
-8.1756e-02, -1.7718e-01,  7.9533e-02,
-3.1299e-03, -3.2305e-03, -3.2094e-03,
-3.1548e-03, -3.2553e-03, -3.2453e-03,
-3.1459e-03, -3.2278e-03, -3.2076e-03,
-3.6554e-05, -3.6715e-05, -3.1284e-05,
-1.4927e-05, -1.4357e-05, -1.2185e-05,
-1.5771e-09, -1.1439e-09, -6.4952e-10,
 3.7723e-40,  4.9166e-40, -2.1946e-40,
-4.7599e-40, -4.3356e-40, -8.3928e-41,
 2.6127e-40,  4.8634e-40,  2.7720e-40,
-5.4972e-03, -5.6409e-03, -5.6919e-03,
-5.5818e-03, -5.7079e-03, -5.7542e-03,
-5.6338e-03, -5.7437e-03, -5.7600e-03,
-3.7940e-03, -3.8853e-03, -3.8693e-03,
-3.8995e-03, -3.9616e-03, -3.8945e-03,
-3.8438e-03, -3.9156e-03, -3.8269e-03,
-7.2342e-05, -7.8682e-05, -4.7701e-05,
-1.1126e-04, -1.1918e-04, -7.8931e-05,
-1.1644e-04, -1.2418e-04, -8.2350e-05,
-2.3881e-04, -3.7971e-04, -3.9448e-04,
-2.4112e-04, -3.8395e-04, -4.0189e-04,
-2.3451e-04, -3.7525e-04, -3.9222e-04,
-3.9853e-03, -4.0748e-03, -4.1134e-03,
-4.0685e-03, -4.1456e-03, -4.1548e-03,
-4.0547e-03, -4.1388e-03, -4.1357e-03,
 5.3008e-02,  2.2252e-02, -7.1158e-02,
-6.6411e-02, -3.0015e-02, -2.2526e-02,
 1.2259e-01, -6.2488e-02,  5.6190e-02,
 1.5981e-02, -7.6832e-02,  1.7908e-02,
 2.7618e-01,  5.4054e-02,  8.7282e-02,
 1.5212e-02, -1.1097e-01, -2.2265e-02,
-6.8532e-41, -6.0539e-40,  4.6269e-40,
-2.9221e-40, -3.8468e-40, -4.6656e-40,
 6.4572e-40, -6.1625e-40,  6.4545e-40,
 3.5920e-02,  9.0955e-02, -1.7626e-02,
 4.7826e-02,  1.8832e-01, -4.4043e-02,
-3.8405e-02,  5.9176e-02,  6.8182e-02,
 3.7657e-03,  2.6441e-02, -2.5585e-01,
 1.0969e-01,  2.3914e-01,  3.5120e-02,
-1.6252e-01,  3.4371e-02, -2.7501e-01,
 4.9289e-02,  2.2088e-02, -1.4588e-02,
 1.6384e-01, -8.1421e-03, -6.9613e-02,
 1.0820e-01,  1.1137e-01,  7.2648e-03,
 1.5243e-01,  1.3659e-01,  2.7553e-02,
 1.3966e-01,  1.1019e-01,  1.9817e-02,
 1.1420e-01, -5.1386e-03,  6.8617e-03,
-1.3264e-02,  2.1508e-01,  4.8430e-02,
 5.1149e-02,  2.9165e-01,  2.8077e-01,
 2.9288e-03,  9.0611e-02,  8.1538e-02
);

const float biasL[4] = float[4]
(
-0.1175, -0.0258, -0.0053, -0.0437
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
//!DESC ACNet HDN Level 3 L2
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-1.1812e-01,  1.5603e-02,  1.1571e-01,
-3.4958e-02, -1.6688e-03, -4.6619e-02,
-1.0417e-02, -3.1802e-02,  1.8357e-02,
 1.1064e-01,  1.8397e-01,  4.8449e-02,
-8.3336e-03,  1.6029e-01,  3.9490e-02,
-4.0959e-01, -2.6134e-01,  2.0766e-02,
 6.6073e-41, -6.7490e-40, -5.1131e-41,
-4.3320e-41, -3.7194e-40,  2.0674e-40,
-5.2359e-40, -3.4006e-40, -4.9257e-40,
-4.7260e-02,  2.8518e-03, -2.7764e-01,
 6.9182e-03,  1.3938e-01, -1.3162e-01,
-6.0901e-03,  1.0339e-01,  6.0419e-02,
-1.4449e-01, -3.2043e-02, -9.1466e-02,
-1.4022e-02,  3.1703e-01,  5.8166e-02,
-1.5243e-02,  1.4521e-01,  2.0790e-04,
-1.0255e-01, -7.8766e-02, -1.2395e-01,
 7.9894e-03,  3.7079e-03, -3.2134e-02,
 1.1663e-01,  1.4808e-01,  2.0431e-01,
 7.4026e-02,  6.9632e-02,  1.7156e-01,
-3.0385e-02,  2.3218e-01,  7.3855e-02,
-8.8530e-02, -5.9224e-02,  2.3431e-02,
 1.4596e-02,  3.2442e-02, -1.1308e-01,
-6.3734e-02,  2.5270e-01,  7.8081e-02,
 1.0468e-02,  1.5473e-01,  3.8676e-02,
-1.0842e-01,  8.6778e-03,  1.4985e-01,
 8.1757e-03, -8.2109e-02,  8.5471e-02,
-2.1437e-01, -6.1173e-02,  4.8163e-02,
 2.8965e-01,  1.9748e-01,  4.2651e-02,
 1.8196e-01,  3.3932e-01,  3.9594e-01,
 3.9657e-01,  4.2167e-01,  2.9290e-01,
 7.4011e-41,  6.5220e-40, -5.9885e-40,
 7.4011e-41,  6.2047e-40, -7.1533e-40,
 4.1950e-40, -1.1886e-40, -5.9922e-40,
 1.9662e-01,  2.1402e-01,  3.1041e-02,
-1.1079e-01,  1.3361e-01, -2.1608e-01,
-1.7962e-01, -8.0576e-02, -3.1277e-01,
 1.0620e-02,  2.4024e-01,  1.0657e-01,
-7.9906e-05,  2.8760e-01,  4.1231e-02,
-1.3261e-02, -1.0868e-01, -1.1267e-01,
-1.0659e-02, -2.6051e-02, -4.5389e-02,
 5.8261e-02,  4.0288e-02,  6.7050e-02,
-2.6462e-01, -1.7846e-01, -1.0002e-01,
-6.2904e-02,  1.5275e-01,  4.4282e-03,
 1.4446e-01,  1.1814e-01, -8.0349e-02,
 2.0331e-02,  3.3014e-02,  1.2710e-01,
 1.6084e-01,  3.8819e-01,  1.0854e-01,
-6.8126e-03,  3.5673e-01,  1.8938e-01,
-1.1660e-01, -5.7694e-02, -2.9194e-01,
 1.2775e-02, -3.2769e-02,  1.7228e-02,
 1.8324e-01,  1.1983e-01, -1.6944e-02,
 1.0593e-01,  1.3451e-01,  5.2536e-02,
 1.9147e-01,  1.3875e-01,  1.0298e-01,
-2.0871e-01, -1.7197e-01,  1.1342e-01,
-1.7581e-01,  4.0972e-02,  2.9796e-01,
 3.2588e-40, -4.3663e-40, -2.6518e-40,
 3.2588e-40, -4.3663e-40, -2.6518e-40,
 4.1600e-40, -4.4350e-40, -4.8744e-41,
 3.7289e-02,  8.1769e-03,  1.7059e-02,
 3.7735e-02,  6.6571e-02, -6.6137e-02,
-5.8890e-02, -7.7019e-03, -6.2128e-02,
-4.0751e-02,  1.1710e-01, -1.1586e-01,
-1.2999e-01, -1.6384e-02, -2.1858e-01,
-2.8028e-01, -6.0443e-02, -1.1880e-01,
 1.8152e-01,  1.5364e-01,  1.1781e-01,
 2.9010e-01,  2.4612e-01,  1.3170e-01,
 1.9022e-01,  1.8117e-01,  1.6483e-01,
 9.3342e-02,  2.6607e-01,  1.4679e-01,
 1.6729e-01,  2.5374e-01,  1.1954e-01,
 6.3258e-02,  1.0557e-01,  6.7221e-02,
-5.2017e-02,  1.9628e-01,  1.7243e-01,
-3.2667e-02,  1.5756e-01,  1.9347e-01,
-9.5252e-02, -3.7525e-02, -3.4543e-04,
-4.9759e-02,  4.0383e-02, -2.0231e-02,
-1.1776e-01,  3.4182e-02,  3.6720e-02,
-1.4822e-02, -4.1658e-02, -1.3729e-02,
-1.9215e-02,  2.4427e-02, -9.0638e-02,
-1.4438e-01, -2.1785e-01, -5.1789e-02,
-2.0279e-01, -3.3918e-01, -1.6871e-01,
 6.1262e-41,  2.4066e-40,  6.6851e-40,
 5.3430e-40, -3.2335e-40, -3.7400e-40,
-6.3256e-40, -4.7491e-40,  2.2854e-40,
-6.8701e-03, -1.4849e-02,  8.6332e-02,
 1.1686e-01,  1.8346e-01,  1.8797e-01,
-2.3251e-02,  7.3973e-02,  1.0532e-01,
-6.1838e-02,  5.6667e-02,  8.1584e-02,
-3.8900e-02,  7.0927e-02,  9.5606e-02,
-4.5098e-02, -1.0829e-01, -1.2224e-01,
 3.5047e-03,  3.2898e-02,  3.5622e-02,
 1.6170e-02,  4.3721e-02,  9.7496e-02,
 2.3445e-03,  6.0417e-02,  1.3482e-01,
 6.0570e-02, -5.7139e-03, -1.0883e-03,
 2.2701e-02, -2.9113e-02,  7.9178e-03,
 8.1214e-02, -4.1408e-02,  1.3616e-02,
-4.7985e-02,  1.0304e-02, -3.3236e-02,
-1.6334e-02, -8.1538e-02,  1.8629e-02,
-9.3720e-02, -1.2920e-01, -4.0836e-02
);

const float biasL[4] = float[4]
(
-0.0563, -0.1047, -0.3449,  0.0568
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
//!DESC ACNet HDN Level 3 L3
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 1.0443e-01,  1.5461e-01, -1.4743e-01,
 1.6716e-01,  1.0532e-01, -2.3088e-01,
 1.0218e-01,  1.2393e-01, -9.6646e-02,
 1.7659e-01, -7.3279e-02,  1.9627e-02,
 1.7721e-01, -1.4329e-01, -1.2533e-01,
 1.6551e-01, -3.4616e-01,  9.5618e-02,
 4.5827e-09,  9.3413e-09,  1.7015e-08,
 1.2245e-08,  9.9727e-09,  6.7108e-09,
 1.9612e-07,  3.9479e-08,  1.1537e-09,
 2.2127e-02,  9.2715e-02, -1.2150e-01,
 7.5652e-02,  1.1548e-01, -1.2420e-01,
-1.0693e-03, -7.2839e-02, -1.9664e-01,
 1.4466e-01, -1.8552e-03, -1.3575e-01,
 2.0699e-01,  8.0396e-02, -1.9651e-01,
-4.7075e-02, -5.1259e-02, -8.2593e-02,
-2.2385e-01,  3.0066e-03, -2.2659e-02,
 6.1827e-02,  2.5331e-02, -5.3898e-02,
 2.7091e-01,  1.0991e-01, -3.3600e-01,
-8.9499e-02, -9.3821e-03,  2.2675e-02,
 1.1213e-01,  1.3276e-01,  2.0368e-02,
 6.5408e-02,  4.1598e-02, -4.7917e-02,
 6.0740e-03,  1.2236e-04, -1.0659e-01,
-1.8072e-02, -9.1082e-02, -9.0414e-02,
 4.9052e-02, -1.4298e-01, -3.9721e-02,
 1.1840e-01,  2.2503e-01,  2.4587e-02,
 9.3023e-02,  6.9650e-02,  1.6798e-01,
-1.5640e-03,  1.6300e-02,  6.3585e-02,
 1.4431e-01,  3.7885e-02,  1.6692e-02,
 1.7345e-01,  7.2315e-02,  1.8942e-02,
 1.1081e-01,  8.2973e-02, -9.7717e-02,
-5.2264e-03, -5.2641e-03, -5.2727e-03,
-5.2809e-03, -5.3125e-03, -5.3153e-03,
-5.2915e-03, -5.3251e-03, -5.3231e-03,
 6.0008e-02,  2.0268e-01,  1.3396e-01,
-2.5202e-03, -1.7750e-02, -1.2019e-02,
 1.1806e-01, -2.2306e-02,  3.6464e-02,
 7.9324e-02,  3.1883e-02,  1.5483e-02,
-4.3537e-02,  1.2204e-02,  1.8905e-02,
-8.1581e-02, -1.1307e-01, -6.0718e-02,
-2.4865e-01, -1.0199e-01,  1.9886e-02,
-1.0519e-02,  6.9972e-02,  4.8012e-02,
-1.5282e-02,  1.1979e-01,  8.7968e-02,
-3.6752e-02,  1.9523e-02,  7.1321e-02,
-5.8295e-02,  5.3242e-02,  1.2773e-01,
-7.9671e-02,  8.3249e-04,  7.4904e-02,
 1.1792e-01,  2.2135e-03, -9.0963e-03,
-2.8356e-03, -4.2661e-02,  6.9497e-02,
 9.3561e-02,  1.0475e-01,  5.4745e-02,
-8.5901e-02, -2.1969e-01, -1.5572e-01,
 3.6473e-02,  1.1097e-01, -2.6830e-02,
 1.2199e-02,  1.8917e-01,  1.1906e-01,
 1.0664e-01, -2.7005e-01,  1.5492e-01,
-4.1771e-02, -1.6580e-01,  2.9234e-02,
-1.9854e-02,  2.1436e-01, -1.1100e-01,
 4.5382e-04,  4.2085e-04,  5.6852e-04,
 3.4951e-04,  3.7354e-04,  3.2786e-04,
 2.0790e-04,  2.8606e-04,  3.2415e-04,
-1.5500e-02,  2.2865e-02, -3.0070e-01,
 1.8467e-01,  2.4899e-01,  1.4812e-02,
-1.2318e-01,  2.3175e-01,  7.2244e-02,
 1.6713e-01,  1.9089e-02, -2.7494e-01,
 1.0202e-01,  2.9200e-01, -3.6055e-03,
 1.3265e-01,  2.2551e-01,  1.9897e-01,
-3.9474e-02,  1.6262e-01,  1.6726e-01,
-8.6222e-02,  2.0573e-01, -7.3247e-01,
-9.5391e-02,  3.8933e-01,  1.5861e-01,
-1.2202e-01, -6.4735e-02, -1.1762e-01,
-2.2427e-02, -1.9171e-01, -1.6092e-01,
 3.2356e-01, -2.2234e-01, -1.3743e-01,
-1.1493e-01, -2.4936e-02,  2.9212e-02,
-9.8112e-02, -1.8021e-02, -1.0507e-01,
-1.0168e-01,  1.1759e-01, -9.8203e-02,
-2.8871e-02,  1.3249e-01,  7.8378e-02,
-1.1012e-01, -4.0596e-02,  5.4202e-02,
 4.9022e-02, -1.1744e-01,  9.8888e-02,
 1.3343e-02,  1.4358e-01, -8.7142e-02,
 1.9952e-01,  3.3708e-02,  2.0721e-02,
 2.6527e-02, -2.3822e-01,  2.4706e-01,
-3.2750e-04, -2.8475e-04, -6.3494e-05,
-2.2378e-04, -1.8046e-04, -1.9242e-05,
-4.2124e-05, -2.2062e-05,  4.5500e-07,
 1.1692e-01,  4.0366e-01, -1.8709e-02,
 8.2700e-02,  1.7884e-01, -1.3520e-01,
 3.7758e-02,  3.7048e-02, -2.8109e-01,
-2.3438e-01,  5.9423e-02, -1.7300e-01,
 1.0343e-02,  7.2307e-02, -4.3852e-01,
-5.7429e-02, -4.9136e-02, -8.0327e-02,
 8.1094e-02,  2.9118e-02,  1.6677e-01,
 1.2155e-01,  6.5358e-01,  2.4544e-01,
 3.1163e-02,  3.7463e-02, -2.6613e-01,
 1.2723e-01,  1.2541e-01,  1.4319e-02,
 1.9055e-01, -5.7441e-02,  1.1146e-01,
-1.0690e-02, -1.7567e-01, -1.2238e-01,
-2.0879e-01, -6.5278e-02, -7.9327e-02,
-1.6564e-01, -1.3659e-01, -2.6231e-01,
-3.1916e-01, -2.6553e-01, -9.8647e-02
);

const float biasL[4] = float[4]
(
 0.0339, -0.1738,  0.0061,  0.1565
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
//!DESC ACNet HDN Level 3 L3
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-1.0617e-01,  1.2782e-01, -2.1053e-02,
-1.2329e-01,  1.4952e-01, -1.7466e-02,
-1.6969e-01,  3.6980e-02, -6.7732e-02,
-3.1220e-02,  4.0615e-02, -1.5251e-01,
-2.0017e-01,  2.2421e-01, -2.5682e-02,
-6.5873e-02,  1.8346e-01,  1.2982e-02,
 1.4021e-06, -1.6929e-05, -8.4696e-05,
 1.9580e-05,  2.9943e-06,  3.0084e-06,
 2.0769e-04,  1.4661e-05,  2.9503e-06,
-1.4485e-01,  1.8841e-01, -1.7954e-01,
 2.1551e-01,  2.2601e-01, -8.6689e-03,
 8.6926e-02, -6.8989e-02, -1.2683e-01,
-8.7712e-02,  6.3176e-02,  1.1983e-01,
 1.0790e-01,  6.6418e-02,  6.5849e-02,
 1.2483e-01,  1.2428e-01,  4.4994e-02,
 1.5139e-01, -1.2116e-01, -3.5497e-01,
-6.1889e-02,  3.4088e-01,  1.3148e-01,
-1.6478e-01,  4.4477e-02, -1.1979e-01,
 3.8343e-02,  1.7992e-01,  3.6790e-01,
 3.0426e-01,  1.1235e-01,  4.9815e-01,
 2.6290e-01,  1.9703e-01,  1.5881e-01,
-6.4678e-03,  2.4401e-01,  1.9266e-01,
-1.4089e-01,  1.2323e-01,  4.4340e-02,
-8.8856e-02,  8.4036e-02, -9.8488e-02,
-1.7377e-03, -1.7654e-03, -1.7223e-03,
-1.7651e-03, -1.7919e-03, -1.7491e-03,
-1.7172e-03, -1.7446e-03, -1.7041e-03,
-3.0384e-04, -2.9297e-04, -2.4838e-04,
-3.2961e-04, -3.1678e-04, -2.7009e-04,
-3.1665e-04, -3.0492e-04, -2.6122e-04,
 3.7109e-40, -3.7915e-40, -5.2536e-40,
 5.8286e-41, -5.6108e-40,  4.3331e-40,
-3.0184e-42, -4.8987e-40, -5.1788e-40,
-4.0457e-04, -4.3257e-04, -4.1616e-04,
-4.2268e-04, -4.5118e-04, -4.3407e-04,
-3.9446e-04, -4.2199e-04, -4.0650e-04,
-1.1253e-16, -1.1328e-14, -2.0489e-14,
-3.0346e-19, -1.7189e-16, -4.5141e-16,
-2.4957e-30, -1.8191e-23, -3.5882e-22,
-3.1610e-36, -1.7544e-24, -2.2187e-21,
-4.2887e-19, -1.5526e-15, -1.5160e-14,
-1.7750e-16, -6.8066e-14, -3.3764e-13,
-6.9570e-24, -5.1139e-23, -2.9335e-23,
-1.9091e-22, -1.0323e-21, -4.5931e-22,
-2.0010e-22, -9.3710e-22, -3.5622e-22,
-2.9470e-04, -2.9081e-04, -2.5958e-04,
-3.2290e-04, -3.1810e-04, -2.8461e-04,
-3.1795e-04, -3.1356e-04, -2.8121e-04,
 6.1623e-02,  1.7057e-01,  8.0478e-02,
 1.2624e-01,  1.8468e-01,  2.1901e-02,
 7.6033e-02,  1.3455e-01,  8.4037e-02,
 8.4434e-02, -1.7069e-02, -7.8318e-02,
 4.9244e-02,  4.4782e-02, -6.9747e-02,
 1.2915e-01,  1.1453e-01, -6.5243e-02,
-5.0985e-03, -5.1407e-03, -5.1687e-03,
-5.1185e-03, -5.1511e-03, -5.1712e-03,
-5.0986e-03, -5.1272e-03, -5.1409e-03,
-1.8186e-02,  6.2680e-02,  3.3235e-02,
 1.3398e-02,  1.6497e-01,  4.3523e-02,
-2.4101e-02,  1.3316e-01,  1.8373e-02,
-6.2677e-04,  6.5026e-03,  2.5948e-02,
 6.6542e-02,  1.2352e-01,  1.5155e-02,
-8.6237e-02, -2.0907e-02,  1.0237e-02,
-1.7807e-01, -8.6196e-02, -3.2408e-02,
-8.1946e-03, -1.3957e-02, -1.6733e-01,
 2.6269e-02,  1.6817e-01,  9.4029e-02,
 3.4005e-02, -1.2833e-02, -1.2038e-01,
-4.8950e-02,  3.9857e-02,  1.4048e-02,
-6.4758e-02,  9.9603e-02,  1.0748e-01,
-1.0850e-02,  9.8875e-02, -4.4439e-02,
 9.1219e-02,  6.6400e-02, -6.7693e-02,
 5.3318e-02,  1.1838e-02, -1.5164e-01,
-5.8568e-02,  1.1249e-01, -3.8286e-02,
-7.1122e-02,  9.5799e-02,  3.8521e-02,
-1.3846e-01,  1.4167e-01, -3.5500e-03,
-1.0343e-01, -3.3025e-02,  3.7186e-02,
-2.0769e-03,  1.3558e-01, -1.3009e-01,
 1.0167e-02,  1.5358e-02, -9.8009e-02,
 2.4123e-05, -1.1800e-05, -1.4180e-04,
 3.5217e-05, -6.3838e-06, -1.2243e-04,
 8.5525e-05,  2.1599e-06, -5.3290e-05,
-1.4471e-01,  2.0111e-02, -1.2449e-01,
 5.3368e-02,  3.2918e-01,  1.4034e-01,
-1.1833e-01, -1.9225e-02, -1.2658e-01,
-2.6966e-01,  1.1751e-01,  9.7072e-02,
-1.9929e-01,  9.7986e-02, -5.1240e-02,
-9.5073e-02, -6.8070e-02, -2.1318e-01,
 9.5305e-02, -4.0551e-02, -1.0936e-01,
 5.2687e-02,  4.5340e-01,  2.3531e-01,
-1.3385e-02,  1.5922e-01, -1.8371e-01,
-1.2203e-01, -7.2567e-02, -3.0000e-01,
-3.4356e-02, -1.3471e-01, -9.0995e-02,
-2.5230e-01, -2.4846e-01, -1.8529e-01,
-1.6962e-01,  1.0905e-01,  1.1557e-01,
-1.4405e-01,  8.9191e-02,  1.1715e-01,
-1.3237e-01,  5.2092e-02, -1.2227e-01
);

const float biasL[4] = float[4]
(
-0.0316, -0.0016, -0.0032, -0.0554
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
//!DESC ACNet HDN Level 3 L4
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 2.0013e-01,  2.2105e-01,  1.9196e-01,
 6.8158e-02,  1.7154e-01, -8.6677e-02,
 9.2652e-02,  1.0789e-01,  1.6745e-01,
-2.9254e-01, -7.6815e-02,  5.8812e-02,
-4.6466e-02,  1.3941e-02,  2.3353e-01,
-1.5033e-01,  7.5167e-02,  1.4433e-01,
 2.8008e-02,  3.1625e-01,  3.2877e-02,
-5.8835e-02, -1.7305e-01, -6.1558e-02,
-1.2227e-01,  3.9931e-02,  3.0300e-02,
 2.3004e-01,  4.1834e-02, -5.7790e-02,
-2.2861e-01,  2.9314e-01,  1.6884e-01,
-2.8009e-02,  4.7550e-02, -4.4542e-02,
-2.4674e-01, -1.5483e-01,  3.2653e-02,
-2.1574e-01,  3.1083e-01, -1.4025e-03,
 1.7354e-02,  5.6417e-02,  1.0844e-01,
-4.2681e-40,  4.5893e-42, -7.4234e-40,
 1.7665e-40,  4.0151e-40,  4.6269e-40,
 2.5452e-40, -7.0179e-40, -1.2338e-40,
-1.4957e-01, -1.9087e-02,  7.1170e-02,
-1.4435e-01,  8.9560e-02,  1.3879e-01,
-3.6992e-02,  5.9822e-02,  1.9241e-02,
-2.4402e-03,  1.5097e-01,  6.3958e-02,
-1.7630e-01,  3.6009e-01, -2.0383e-01,
-8.5106e-03,  4.0863e-03, -2.7575e-02,
 7.8942e-02, -1.8640e-01, -6.7715e-02,
 7.2777e-02, -1.3804e-01, -7.0332e-02,
 1.5185e-01, -4.3530e-02,  1.4502e-01,
-3.2928e-02, -3.0583e-02,  9.2061e-02,
 1.2493e-01,  1.0400e-01,  1.3780e-01,
 1.4438e-01,  8.2051e-02,  1.6159e-02,
 2.7478e-02,  1.7768e-01,  2.5945e-01,
-3.4662e-01,  2.0330e-03,  8.8118e-02,
-2.9628e-01, -1.3212e-01, -1.8145e-02,
-1.9330e-01,  3.9238e-02, -4.6944e-02,
-1.5668e-01, -5.7104e-02,  1.9558e-01,
 6.5305e-02,  5.9933e-02,  7.7337e-02,
-2.4906e-02, -1.1235e-01,  1.3822e-02,
-3.9988e-02, -9.1882e-03,  1.9204e-02,
 1.0504e-01,  4.6820e-03, -2.1836e-02,
-2.6953e-40,  2.5334e-40, -1.3028e-40,
 1.4110e-41,  5.6841e-40,  3.6368e-40,
-1.1746e-41, -7.0658e-41, -3.9413e-40,
 1.5025e-02,  7.4419e-02,  9.5652e-02,
 5.0297e-02,  6.6704e-02,  5.7316e-02,
 2.5102e-02,  1.1985e-01,  2.6043e-02,
 3.3297e-02, -7.7374e-02, -1.1114e-01,
-7.5586e-02, -1.9338e-02, -1.3739e-02,
 4.5616e-02, -6.4946e-02, -6.9372e-02,
-7.5874e-03, -1.1141e-01, -2.9135e-02,
-6.9436e-03, -1.4418e-02,  1.6436e-03,
-1.3051e-01, -1.3324e-01, -9.3934e-02,
 1.2184e-01,  1.9386e-01,  1.7995e-01,
-2.7452e-02,  9.9736e-02,  1.0020e-01,
-6.3290e-02, -2.1447e-02, -1.7005e-01,
 1.3857e-01,  2.3338e-01,  2.5410e-01,
 2.3002e-01,  1.9551e-01,  1.4452e-01,
 4.7040e-01,  2.2647e-01,  1.5215e-01,
 2.6927e-02, -2.1304e-01, -1.4762e-01,
-5.6998e-02,  2.9064e-01,  1.8085e-01,
 8.9393e-02, -1.7463e-01, -2.7095e-01,
 3.8434e-02,  1.7198e-01, -1.8122e-02,
-1.3857e-01,  1.9418e-01,  1.5019e-01,
-5.6337e-02, -5.3265e-01,  3.2122e-01,
-2.4484e-40, -5.3707e-40,  1.5854e-41,
 5.1791e-40, -4.1875e-41,  5.6732e-40,
 1.3048e-40,  1.6452e-40, -4.5028e-40,
-3.0692e-02,  1.8569e-01,  2.0327e-01,
-7.4756e-02, -5.1765e-02,  4.2475e-02,
-9.0675e-02, -3.0438e-01, -3.5088e-01,
-1.9129e-02, -1.5663e-03,  4.9895e-02,
-1.9441e-02,  9.3237e-02,  1.2910e-01,
-2.3919e-02, -4.0539e-01,  2.8167e-02,
 2.0203e-01,  3.3424e-02,  1.7927e-02,
 4.1923e-02, -1.6967e-01,  2.5656e-02,
-1.5869e-01, -1.8727e-01,  2.7860e-03,
-4.0276e-02, -6.7792e-03,  3.3699e-02,
-6.7044e-03,  1.7686e-02,  2.9786e-02,
-1.5623e-02,  3.7904e-02,  2.4737e-02,
-1.2282e-01, -3.6563e-02,  4.1976e-02,
-9.9622e-03,  8.8981e-02,  2.1364e-02,
-8.5668e-02, -1.6803e-01, -4.4974e-02,
 1.3164e-01,  4.1294e-01,  1.8897e-01,
 2.1991e-01,  1.6247e-02,  1.1569e-01,
-3.0142e-02,  1.4069e-02,  3.6646e-02,
-2.6816e-02, -3.9767e-02,  1.4061e-01,
-1.3603e-01, -2.0649e-01,  7.5837e-02,
-1.6984e-02, -8.3800e-03,  2.3652e-04,
 1.5049e-40,  4.6504e-40,  1.3625e-40,
-7.5358e-40, -3.4257e-40,  9.9763e-41,
 4.7243e-40,  7.4890e-40, -7.9440e-42,
-5.9692e-02, -2.8047e-02,  2.3795e-02,
-3.5284e-02,  1.1448e-02,  5.0302e-04,
-3.5066e-02,  4.6185e-02,  1.2167e-02,
 3.7583e-02, -3.6598e-02,  1.0206e-01,
-9.6229e-02, -1.5977e-01,  4.9157e-02,
 3.7293e-02,  5.8766e-02,  1.0448e-02
);

const float biasL[4] = float[4]
(
-0.0508, -0.0609,  0.0347, -0.0802
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
//!DESC ACNet HDN Level 3 L4
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 1.1490e-01,  1.4459e-01,  8.6936e-02,
 2.8609e-01, -4.8108e-02,  9.0023e-02,
 6.7941e-02, -5.7148e-03,  1.0021e-01,
 7.3816e-02,  7.3794e-02,  8.0970e-03,
 2.8307e-02,  3.6635e-03, -1.1769e-01,
 4.1374e-02,  3.9933e-02, -4.4292e-02,
 5.9423e-02,  1.9009e-01, -2.3735e-01,
-2.6670e-01,  5.8789e-01, -2.0048e-01,
-3.7082e-01,  1.8045e-01,  5.4820e-02,
-6.3567e-01,  2.0098e-01,  1.0653e-01,
-2.5056e-01,  6.5065e-01, -4.0471e-01,
 5.4715e-02,  2.4375e-01, -2.7402e-01,
 1.5982e-01,  1.0923e-01,  2.1566e-01,
 2.0239e-01, -9.0221e-02, -4.4606e-01,
 1.0550e-01,  5.4666e-02, -2.7134e-01,
-4.6424e-40,  2.9137e-40,  7.4968e-41,
 1.2376e-41, -5.6213e-40, -6.3457e-40,
 2.5404e-40,  2.0013e-40,  3.5611e-40,
 5.5423e-02,  3.9843e-02, -1.7509e-01,
 5.4480e-02,  5.0331e-02, -1.6793e-01,
 6.6093e-02,  3.0163e-02, -8.2023e-02,
-1.5490e-01,  1.7457e-01,  2.7832e-01,
 1.1482e-01,  2.5759e-01, -2.4199e-01,
-9.3891e-02,  9.1921e-02, -6.4480e-03,
 1.9266e-01,  5.2907e-02,  7.0289e-02,
 1.3582e-01,  6.4246e-02,  1.4989e-01,
 6.2013e-03, -6.8884e-02,  6.8734e-02,
-1.0483e-01, -7.7134e-02, -3.6204e-02,
 1.7590e-02,  5.0844e-02,  1.4234e-01,
 7.2913e-02,  6.0726e-02,  6.4414e-02,
-8.5021e-02, -1.0621e-03,  5.5851e-02,
 2.4666e-01,  6.5652e-02, -1.8180e-02,
 1.5225e-01,  1.2928e-01,  3.1578e-03,
 1.1468e-01,  1.9544e-01,  6.6637e-02,
 6.3430e-02,  2.0542e-01,  7.0876e-02,
 3.4779e-02,  1.0037e-02, -2.2134e-02,
-6.9304e-02,  1.1184e-01, -3.7015e-02,
-1.7634e-01,  1.2475e-01,  9.1947e-02,
-6.0550e-02, -1.3904e-01,  7.5192e-02,
-2.2871e-40,  4.7367e-41, -1.0711e-40,
-2.8662e-40,  4.0542e-41,  3.3067e-40,
-4.4395e-41, -7.2684e-41,  1.8695e-40,
-1.6702e-01, -2.6654e-01,  8.7902e-03,
-2.0108e-01, -3.8093e-01, -8.3700e-02,
-7.5433e-02, -2.0689e-01,  2.7951e-02,
 2.9938e-03,  1.1378e-01,  7.1598e-02,
-1.6031e-01,  1.3475e-01,  1.5800e-01,
-7.2019e-02, -1.1663e-01,  8.0692e-02,
 1.0610e-01,  1.1163e-02, -1.4959e-01,
-1.1576e-01, -8.5645e-02,  4.0414e-02,
 5.6245e-02,  1.7056e-01,  2.5734e-01,
-6.1086e-02, -7.0851e-02,  7.6851e-02,
-2.7595e-02, -6.0890e-02,  4.7472e-02,
 7.1059e-03,  6.0942e-05,  7.4915e-02,
 1.9350e-01, -1.8458e-02, -2.3040e-02,
 6.3477e-02,  1.1923e-01,  9.9319e-02,
 6.4839e-02,  2.7973e-01,  1.2902e-01,
-1.7829e-01,  5.7083e-03, -6.1680e-03,
-1.1256e-01, -2.7951e-02, -2.1544e-01,
-2.1614e-02, -7.1468e-02, -2.2054e-02,
-8.7543e-02, -1.2982e-01,  1.9386e-01,
-5.7157e-03, -1.0108e-01,  1.4467e-01,
-6.5742e-02, -7.2054e-02,  1.7924e-01,
 7.5418e-40,  6.3043e-40,  4.9815e-40,
-1.0952e-40,  3.0327e-40, -2.3848e-40,
 4.1302e-40,  2.0150e-40, -1.6509e-40,
-1.3985e-02, -1.0550e-01,  5.8772e-02,
-1.7108e-02, -7.3644e-02,  3.3014e-02,
-1.8224e-03,  2.8931e-03,  9.2762e-02,
 4.1531e-02, -1.5139e-01, -1.7773e-01,
 9.6548e-02, -1.1914e-01, -4.6536e-02,
 8.6754e-02, -4.0057e-03,  1.8983e-01,
 1.6545e-01, -4.7311e-02, -7.2455e-03,
 3.7567e-01,  1.8883e-01, -7.4325e-02,
-5.8252e-02, -1.3811e-02, -7.0470e-02,
-3.2943e-02, -7.0770e-02, -1.4700e-01,
 1.7043e-02,  9.4331e-02,  4.2857e-03,
 4.1247e-03,  1.6690e-01,  4.2146e-02,
 1.1420e-01, -7.4456e-02, -3.8763e-02,
 1.6807e-01,  9.3636e-03, -1.1796e-01,
 1.7703e-01,  1.1386e-03, -6.8707e-02,
 1.0259e-01, -1.8918e-02,  6.5902e-03,
 1.2421e-02, -7.8960e-02,  2.1766e-02,
 1.3062e-01,  4.6001e-02,  2.4199e-01,
-1.2955e-02, -1.9329e-01,  5.2074e-03,
 5.9446e-02,  1.8832e-01,  2.2094e-01,
-1.0954e-01, -8.1867e-02, -4.3324e-02,
-3.9596e-41,  2.8677e-40, -6.5843e-40,
 4.2812e-41, -3.5323e-40,  4.8298e-40,
 7.6351e-40, -2.4759e-40,  7.3030e-40,
-1.1284e-01, -8.4171e-02, -1.5935e-01,
-3.2299e-02,  1.5427e-01,  8.9029e-02,
-3.8815e-02,  1.3098e-01, -4.3065e-02,
-2.5276e-01, -1.7018e-01,  9.7901e-02,
 1.4218e-01,  3.1236e-01,  2.9636e-01,
-2.3613e-02, -5.5258e-02, -2.0550e-01
);

const float biasL[4] = float[4]
(
-0.0438,  0.2512, -0.0491, -0.0259
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
//!DESC ACNet HDN Level 3 L5
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 0.0333,  0.1145, -0.0922,
 0.1185,  0.4533, -0.2015,
-0.0774,  0.1759, -0.0496,
 0.0954, -0.0499,  0.0824,
 0.1059,  0.0173, -0.0586,
-0.0666, -0.0287, -0.0652,
-0.0558, -0.1362,  0.0015,
 0.1277,  0.1020, -0.1369,
 0.0020, -0.0103, -0.0804,
 0.0507,  0.1404, -0.0241,
 0.0520,  0.1239,  0.0633,
-0.0268,  0.0335,  0.0883,
-0.0549, -0.1022, -0.0515,
-0.0163, -0.1167, -0.0442,
 0.0858, -0.0804, -0.0014,
 0.0354, -0.0666, -0.2105,
-0.0950,  0.1578, -0.0920,
-0.1303,  0.0299, -0.0195,
-0.0281, -0.1993, -0.0154,
 0.0796,  0.0503,  0.0954,
 0.0540,  0.0212,  0.0389,
-0.1387,  0.1091, -0.1212,
 0.1556,  0.3573,  0.0976,
-0.0587, -0.2070,  0.2067,
 0.0138,  0.0051, -0.1008,
 0.2877,  0.1079, -0.0681,
 0.0953, -0.0739, -0.2349,
 0.1482,  0.0657,  0.0480,
 0.1590, -0.0009,  0.1402,
 0.0700,  0.0435,  0.1190,
 0.0957,  0.0117, -0.1010,
 0.1790, -0.0200, -0.0765,
 0.0797,  0.1455, -0.0340,
 0.0008, -0.0267,  0.0089,
 0.0644,  0.0647,  0.0397,
 0.0463, -0.0116, -0.0771,
 0.2237,  0.0324,  0.0192,
-0.0082, -0.0345,  0.0294,
 0.0719, -0.0185,  0.1008,
-0.0307,  0.0134, -0.0747,
 0.0776, -0.1485,  0.0135,
 0.0965, -0.0665, -0.1263,
-0.0101, -0.0097, -0.0144,
-0.0022, -0.0083,  0.0277,
 0.0136, -0.0076,  0.0314,
-0.0008,  0.0722, -0.0704,
 0.0053,  0.0767,  0.0368,
-0.0189, -0.1354,  0.0231,
-0.1416,  0.1945, -0.1756,
 0.2058,  0.0401, -0.1348,
-0.0945, -0.2530, -0.3082,
-0.0096,  0.0871,  0.0699,
-0.0092,  0.0423,  0.0995,
-0.0914, -0.0570, -0.0718,
-0.0739, -0.2749, -0.2320,
 0.1488, -0.2698, -0.1977,
 0.1445, -0.1655, -0.0758,
 0.2035, -0.0138,  0.0332,
 0.0282, -0.2247, -0.0945,
-0.0614, -0.2484, -0.0595,
-0.1174, -0.1252,  0.1969,
-0.1101, -0.2950, -0.2164,
-0.0348, -0.0891,  0.1250,
 0.0195,  0.0050,  0.0300,
-0.0508, -0.0316, -0.0194,
 0.0199,  0.0345,  0.0444,
-0.0022, -0.0529,  0.1604,
 0.0756, -0.2015, -0.2117,
-0.0837, -0.1270,  0.1330,
 0.0286,  0.0952,  0.1082,
 0.0724, -0.0446, -0.1156,
 0.0545,  0.0444, -0.0291,
 0.0759,  0.1110,  0.0944,
 0.1615,  0.4302, -0.1060,
 0.0418, -0.0281, -0.1378,
-0.0757, -0.0527, -0.1578,
 0.0123, -0.0427,  0.1504,
 0.0694,  0.0690,  0.0203,
 0.2132, -0.3449,  0.0936,
 0.2491,  0.0279, -0.0884,
-0.0447,  0.1589, -0.0054,
-0.0246,  0.1247,  0.0403,
 0.0513, -0.0541, -0.1141,
 0.0712, -0.1174, -0.0051,
 0.2304,  0.2431, -0.0517,
-0.1548, -0.0401,  0.2032,
-0.0087, -0.1676, -0.0600,
 0.1094, -0.0329,  0.0530,
-0.0580,  0.1499, -0.0806,
-0.0086, -0.1400, -0.0636,
 0.0708, -0.1003, -0.1113,
-0.0732, -0.1199,  0.0060,
-0.0534, -0.0011,  0.0965,
-0.0268,  0.0116, -0.1161,
 0.0787,  0.3925, -0.0819,
-0.0041, -0.0892, -0.2063
);

const float biasL[4] = float[4]
(
 0.0655,  0.0255,  0.0228, -0.0027
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
//!DESC ACNet HDN Level 3 L5
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-0.1296,  0.0924, -0.0079,
 0.5625,  0.4013,  0.1645,
-0.0137, -0.1935,  0.2714,
 0.0980,  0.0016, -0.1461,
 0.1576,  0.0305, -0.1450,
 0.1503, -0.0303, -0.1403,
 0.0262, -0.0077,  0.0459,
 0.2718,  0.0754,  0.2404,
 0.1381, -0.1499,  0.0016,
 0.1454, -0.1278, -0.0085,
 0.1674, -0.0834,  0.1993,
 0.0874, -0.0598, -0.0188,
 0.2003,  0.3296,  0.0153,
-0.0154,  0.5550, -0.0945,
 0.0489,  0.0415, -0.0940,
 0.0164,  0.0791,  0.1077,
-0.0893,  0.1231,  0.0473,
-0.0319,  0.1444,  0.1690,
-0.0518, -0.1404, -0.1778,
-0.0170,  0.1395, -0.0234,
 0.0128, -0.0112, -0.0472,
 0.1039,  0.1982, -0.0272,
 0.0282, -0.1199, -0.2622,
-0.0449,  0.0239, -0.1030,
-0.0840, -0.1044, -0.0646,
 0.0588,  0.1937, -0.2494,
 0.0180,  0.0747,  0.1530,
 0.0500,  0.1756,  0.0491,
-0.1113, -0.0079,  0.0854,
-0.1493, -0.0559, -0.0373,
 0.1972, -0.3158, -0.0500,
 0.1932,  0.3177, -0.0018,
-0.0516, -0.1144,  0.0686,
 0.0175,  0.0598,  0.0345,
-0.0667, -0.1078,  0.0384,
 0.0897,  0.2198, -0.0531,
-0.2596, -0.1997,  0.0195,
 0.0332,  0.4098,  0.1381,
 0.1985, -0.0669, -0.1275,
-0.0751, -0.2388, -0.0672,
 0.0090,  0.0891, -0.0362,
 0.1392, -0.0518,  0.2039,
 0.2079, -0.1202,  0.0707,
 0.0498, -0.1237, -0.0665,
-0.0398, -0.1557, -0.0928,
 0.0505,  0.1220,  0.0352,
-0.0674, -0.1159,  0.0724,
-0.0331, -0.1751,  0.0766,
 0.0992, -0.0763,  0.0090,
-0.1223,  0.2621, -0.2029,
 0.0509, -0.0279, -0.1061,
 0.0598,  0.0353, -0.1610,
 0.0165,  0.0835,  0.0704,
-0.0079, -0.0982,  0.0187,
 0.2331, -0.1929,  0.0684,
-0.0507,  0.1476, -0.0886,
-0.0275,  0.1658,  0.0697,
-0.1123, -0.0069, -0.0851,
-0.0377, -0.0917, -0.0629,
-0.0420,  0.0506,  0.1111,
 0.1086,  0.1351, -0.0851,
 0.0466,  0.2750,  0.0185,
-0.0208,  0.2090,  0.0271,
 0.0217, -0.0548,  0.0078,
-0.0609,  0.1029, -0.1641,
 0.1392,  0.0115,  0.0317,
-0.0570,  0.1060,  0.1814,
-0.2015, -0.1301,  0.1082,
 0.2452, -0.1815, -0.0046,
 0.0103, -0.0466, -0.0895,
 0.0158, -0.0594, -0.1386,
-0.0073, -0.0719, -0.0716,
 0.1308, -0.0206,  0.0511,
-0.0437, -0.0763,  0.0287,
 0.0493, -0.1239,  0.0219,
-0.0041,  0.0373,  0.0262,
 0.0078, -0.0249, -0.0284,
 0.0598, -0.0205, -0.0276,
 0.0115, -0.1778, -0.0395,
 0.1673, -0.0036,  0.2334,
 0.0706, -0.0694,  0.0177,
 0.1123, -0.0043,  0.0716,
-0.0894, -0.1609,  0.0334,
-0.0046, -0.2006, -0.0977,
-0.0127,  0.1198, -0.0339,
-0.0283,  0.1354,  0.1637,
-0.1696,  0.0187, -0.2621,
 0.0496,  0.2834,  0.0423,
 0.1126,  0.3962,  0.1660,
-0.0750,  0.1955,  0.0590,
-0.1088, -0.1146, -0.1219,
 0.1360,  0.1524,  0.0498,
-0.1151,  0.0219, -0.0063,
-0.0821,  0.0247, -0.1065,
 0.1153,  0.2085,  0.0618,
-0.0383,  0.0527, -0.2067
);

const float biasL[4] = float[4]
(
-0.0155, -0.0163, -0.0174, -0.1095
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
//!DESC ACNet HDN Level 3 L6
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 1.8014e-01,  2.1908e-01, -2.1088e-03,
 1.7345e-01,  2.7654e-01,  1.3607e-02,
 1.1363e-01,  9.9105e-02, -6.5730e-02,
-3.5679e-02,  9.6072e-03,  4.0721e-02,
-1.8771e-02, -2.3484e-04, -1.0230e-02,
 1.6965e-02, -1.3032e-02, -6.3906e-02,
-4.5686e-02, -3.6733e-02, -4.8873e-02,
 4.0752e-02,  2.1615e-02, -1.4822e-02,
 1.1689e-01,  3.0153e-02, -5.0163e-04,
-7.0394e-03, -1.2387e-01, -8.9243e-02,
-1.8312e-01, -1.3868e-01, -6.2618e-02,
-8.1627e-02, -2.0480e-01, -3.0740e-01,
 4.4296e-02,  3.8572e-02,  4.3754e-02,
 1.7538e-01,  5.3284e-02, -7.5663e-03,
 1.9670e-01, -1.2397e-01, -1.6266e-01,
 1.4575e-01, -5.7771e-02,  2.7619e-02,
 2.2757e-02, -4.8910e-01, -2.6201e-01,
 3.6513e-02, -2.0704e-01, -1.3225e-01,
-6.7533e-02,  1.1289e-02,  7.1316e-02,
-7.6847e-02,  6.8128e-02,  7.4717e-02,
 1.1269e-01,  2.9978e-02,  3.2132e-02,
-5.4557e-02, -4.4599e-02,  4.1835e-02,
 5.7964e-02, -2.1246e-03,  1.5007e-01,
 1.8432e-01,  1.1463e-01,  2.2691e-01,
 9.6166e-02,  4.7887e-02, -3.8399e-02,
 5.8153e-02, -2.0255e-02, -1.1362e-01,
 2.6402e-02,  2.5562e-02,  1.9096e-02,
 1.1588e-01,  1.4540e-01,  1.1948e-01,
 1.0360e-01,  5.9083e-02,  1.9263e-01,
 1.6953e-01,  2.7390e-02,  9.7883e-02,
 1.5059e-01,  6.7593e-02, -4.5843e-03,
 8.7031e-02, -2.0926e-03, -6.3056e-02,
-6.6960e-02, -5.2056e-02, -7.3570e-02,
 1.4361e-02,  1.1059e-01, -4.9720e-02,
 4.4270e-02,  3.9995e-02,  4.3101e-03,
-1.1042e-01,  4.5028e-02, -8.9124e-02,
-1.2906e-01, -7.6972e-02, -6.5449e-03,
-1.9269e-01,  2.8349e-01,  1.1573e-01,
-1.7983e-01,  9.7615e-02,  9.4003e-03,
-4.7802e-02, -1.5889e-01, -1.2693e-01,
 7.4717e-02,  2.8655e-01, -7.2637e-02,
 1.5837e-02,  8.7125e-02, -1.2198e-01,
-1.7754e-02, -5.6443e-02, -9.8661e-03,
 6.3040e-02,  2.0249e-02, -3.5368e-02,
 9.7756e-03,  2.6760e-02, -5.5172e-02,
-1.0406e-02,  4.8313e-02,  2.4717e-02,
-5.2851e-02,  6.8496e-02, -2.5933e-02,
 4.5932e-02,  5.9892e-02,  1.9200e-02,
-5.1316e-40, -5.1811e-40, -1.5144e-40,
-6.7758e-38, -5.4608e-40, -3.9680e-40,
-1.9155e-39,  2.0423e-41,  1.5256e-41,
-2.5559e-08, -3.2461e-08, -2.6821e-08,
-3.6885e-08, -4.6896e-08, -3.9086e-08,
-3.4305e-08, -4.4160e-08, -3.7187e-08,
-3.7416e-40,  3.6550e-40,  5.0727e-40,
-1.6722e-40,  3.9228e-40,  5.4548e-40,
-5.7512e-40, -2.8156e-40,  9.4571e-41,
-4.7040e-40, -1.6974e-40,  6.3849e-40,
-3.7322e-40,  2.6014e-40,  2.3080e-40,
-2.8395e-40, -3.7116e-40,  4.4393e-40,
 1.1597e-40,  4.3291e-40,  3.8219e-40,
 3.3393e-40,  3.1747e-40, -1.8400e-36,
-5.5215e-40,  1.7648e-40, -1.6540e-35,
-3.0953e-40,  5.3063e-40, -1.6454e-40,
 2.1341e-40,  2.0790e-40, -3.0226e-40,
-2.6807e-40, -1.6601e-40,  5.1829e-40,
-1.8897e-40, -4.5956e-41,  5.3784e-40,
-2.5661e-40, -2.1726e-40,  1.2010e-40,
 1.8263e-41,  1.1214e-40, -3.7693e-40,
-4.2596e-40,  1.8854e-40,  5.5010e-40,
-6.6262e-40, -4.8808e-40,  3.3123e-40,
 5.9379e-41,  2.3249e-40,  4.4504e-40,
-8.4836e-04, -8.4397e-04, -5.8640e-04,
-8.3506e-04, -8.0192e-04, -5.3901e-04,
-8.3539e-04, -7.8069e-04, -4.8720e-04,
-3.4706e-04, -4.4640e-04, -5.2353e-04,
-4.4518e-04, -5.3374e-04, -5.2734e-04,
-5.8780e-04, -5.8730e-04, -5.4362e-04,
-5.2452e-04, -5.4578e-04, -5.6266e-04,
-4.2387e-04, -4.4643e-04, -4.8936e-04,
-3.5880e-04, -3.7886e-04, -4.1998e-04,
-2.4479e-04, -4.0736e-04, -3.1189e-04,
-3.4922e-04, -4.0173e-04, -2.5042e-04,
-5.7091e-04, -5.2665e-04, -2.3293e-04,
-2.8505e-04,  9.7283e-05,  3.1209e-04,
-2.7463e-04,  1.8704e-04,  4.4351e-04,
-9.1436e-05,  3.2602e-04,  5.7573e-04,
-4.0112e-04, -4.2566e-04, -2.4300e-04,
-9.9362e-05, -6.5499e-05,  3.2872e-05,
 1.1584e-04,  2.3417e-04,  3.4427e-04,
-7.5767e-05,  3.9768e-06,  6.2201e-05,
 2.3151e-05,  2.5595e-04,  3.4038e-04,
-1.3871e-05,  3.0295e-04,  4.4170e-04,
-1.7802e-04, -4.5376e-04, -5.1847e-04,
-5.0687e-04, -5.5837e-04, -2.5917e-04,
-5.3992e-04, -7.1375e-04, -4.8728e-04
);

const float biasL[4] = float[4]
(
 4.9947e-03,  5.3372e-03, -4.5286e-09, -1.3756e-03
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
//!DESC ACNet HDN Level 3 L6
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-1.7543e-01, -3.4151e-01, -3.2619e-02,
-1.9701e-02, -1.5494e-01, -1.6534e-01,
 3.5632e-02, -1.0897e-01, -3.8379e-02,
-6.1420e-02, -1.0735e-01,  1.4730e-01,
 7.4386e-02, -1.0487e-01,  7.9646e-02,
 1.7130e-02,  4.4391e-02, -5.1959e-03,
 4.5682e-02, -1.1543e-01,  9.4035e-03,
-3.4376e-01, -1.1961e-01,  1.0099e-01,
 1.1335e-01,  7.5840e-02,  1.0675e-01,
 4.9539e-02,  8.7406e-02,  4.4951e-02,
 1.8111e-01,  2.6406e-01, -1.5924e-02,
-1.1464e-01,  8.4579e-04, -6.6811e-02,
-8.9635e-03,  1.8236e-03,  3.6561e-02,
-7.0281e-02,  2.9717e-01,  3.1836e-02,
-1.3647e-01, -6.5627e-02,  9.3063e-02,
-2.1851e-01, -6.0226e-02, -1.0326e-01,
 5.3441e-02,  1.9103e-01, -5.7999e-02,
-3.3512e-02,  1.5496e-01, -1.1111e-01,
 2.3256e-03, -1.5004e-01, -9.1248e-02,
-9.7706e-02,  1.9549e-01, -1.5403e-01,
-1.5327e-01,  8.3335e-02,  5.6111e-03,
-1.5707e-01,  8.0277e-03, -7.3955e-02,
-1.4111e-01, -1.3548e-01, -1.0563e-01,
 2.3054e-01, -2.1822e-02, -6.6938e-03,
-1.0259e-01,  4.3577e-02, -1.7630e-01,
 1.6484e-01,  4.2413e-01,  6.9475e-02,
-2.4705e-01,  2.5757e-01, -9.5611e-02,
 1.0236e-01, -3.4820e-02, -6.8818e-03,
-1.1434e-01, -3.1800e-01,  2.1337e-02,
-1.9939e-01, -2.6532e-01,  7.3361e-02,
 6.5939e-02,  9.5812e-02, -7.0156e-02,
-1.6249e-02, -1.5927e-02, -1.1189e-01,
-9.3936e-03, -1.0933e-01, -2.9399e-02,
-2.8752e-02, -4.5613e-02, -1.2718e-02,
 3.8781e-01,  2.6776e-01, -1.0373e-02,
-2.3927e-02, -6.4398e-02,  9.9117e-02,
-6.0732e-02, -5.5917e-03,  5.1716e-02,
-1.4168e-01,  1.7661e-01, -5.5893e-02,
-3.0419e-01, -3.5537e-01,  2.1978e-01,
-1.8610e-01, -5.7743e-03,  3.2649e-02,
 1.9975e-01,  1.6508e-01,  1.3808e-02,
 1.0733e-01,  1.4722e-01,  5.8671e-02,
 6.4940e-02,  1.6114e-01,  3.9697e-02,
 1.1530e-01,  2.4021e-01, -2.1669e-01,
 6.0220e-02,  2.0257e-01, -1.5227e-01,
-6.1096e-02,  6.6511e-02, -1.3858e-01,
-6.5275e-02,  1.0891e-01,  8.2048e-02,
-6.7907e-02,  2.2863e-02, -1.0322e-01,
 1.6542e-01, -1.4436e-01,  6.4125e-02,
-1.0378e-01, -3.2346e-01, -1.5123e-02,
 3.8758e-03,  1.1006e-01, -4.4325e-02,
-1.0102e-01, -3.7699e-02,  9.2472e-02,
-6.8972e-02, -1.2308e-02,  1.6478e-01,
 3.4351e-02, -1.7461e-02,  1.0301e-01,
-2.7125e-01, -5.6730e-02, -2.5989e-01,
-3.0163e-01, -1.4826e-01, -3.4955e-01,
-1.6259e-01, -1.6708e-01, -2.7964e-01,
-6.7134e-02, -2.2385e-01,  2.1776e-01,
-1.1351e-02, -3.7861e-01,  1.8687e-01,
 4.0551e-02,  8.1943e-02,  1.0866e-01,
 1.0273e-01,  1.1844e-01, -1.1852e-01,
 2.6758e-02, -8.5806e-02,  5.9444e-02,
-5.1627e-02,  7.1636e-02,  2.2841e-01,
-3.7242e-03,  2.9723e-01,  1.1918e-01,
 8.4994e-02, -3.5747e-01,  3.6148e-02,
 9.9705e-02, -1.3736e-01, -6.0080e-02,
 1.2370e-01,  5.0668e-02, -6.0246e-02,
 6.0562e-02, -3.5068e-01, -3.2645e-01,
 9.1020e-04,  6.6203e-02, -1.0770e-01,
 1.9434e-02,  3.0018e-01,  2.8018e-01,
 1.4021e-01,  2.7481e-01,  2.2868e-01,
 4.8540e-02,  1.7719e-01, -4.5834e-02,
-9.6349e-02, -2.3008e-02, -1.4497e-01,
 4.3053e-02, -1.0161e-01,  2.8750e-02,
-1.2594e-01, -1.0388e-02, -4.3966e-02,
 7.5993e-02, -7.1609e-02,  1.4624e-02,
 4.1110e-02,  7.1258e-02, -2.9109e-02,
-5.8698e-03,  1.2389e-01,  4.7648e-02,
-6.1585e-04, -4.4556e-02, -2.3373e-02,
-4.4883e-02, -7.7722e-02, -7.3635e-02,
-2.7750e-02, -1.5117e-03, -8.7368e-02,
 2.5113e-02,  7.7490e-02,  2.9024e-02,
 1.5426e-01,  2.5472e-01,  4.8057e-02,
-1.1969e-01, -1.1487e-01, -1.1802e-01,
-4.7392e-02, -4.2226e-02,  3.1968e-02,
-2.6717e-01, -5.0206e-02,  8.1946e-04,
-4.0426e-02,  1.4373e-01, -3.3121e-03,
-4.5292e-02, -2.4538e-02,  1.0377e-01,
-1.7780e-02,  2.0058e-01, -2.4343e-02,
-1.1714e-02,  1.5984e-01, -1.2638e-01,
 6.4655e-02,  3.7703e-02,  3.7970e-02,
 9.1864e-03,  1.1468e-01, -6.2760e-04,
-1.4812e-01,  6.5670e-03,  1.0765e-01,
 1.5023e-01, -7.0594e-02, -1.3924e-01,
 3.6016e-02, -3.9078e-02, -3.8950e-02,
 1.8735e-02, -1.5573e-01, -1.2456e-01
);

const float biasL[4] = float[4]
(
 3.8858e-03, -4.4197e-02,  3.3970e-02,  2.8411e-02
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
//!DESC ACNet HDN Level 3 L7
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 4.8634e-02, -1.3617e-01,  6.1231e-02,
-7.0235e-02, -6.4110e-01,  1.5985e-01,
 8.6151e-02,  1.1847e-01,  1.3819e-01,
-3.6017e-04, -3.2273e-02, -8.5485e-02,
-7.0804e-03,  2.1751e-01,  7.2575e-03,
-8.3606e-02, -1.4885e-01, -1.2702e-01,
 4.0848e-41,  8.0934e-40, -1.8889e-40,
-3.9103e-40, -7.4709e-40,  3.8377e-40,
-2.4159e-40, -4.7610e-40,  7.7359e-40,
-8.6217e-05, -5.9763e-05, -4.0558e-05,
-7.4966e-05, -4.7074e-05, -3.1656e-05,
-9.8390e-05, -6.6833e-05, -4.7669e-05,
 3.5375e-02,  2.8660e-02,  4.1277e-02,
 1.6289e-01, -3.2199e-01, -1.7845e-02,
 2.4659e-01, -3.9618e-02,  4.1065e-03,
 2.7267e-02,  8.6819e-02,  9.5070e-02,
-7.2700e-02, -2.8826e-01,  1.1750e-03,
 2.5259e-02,  2.4681e-03,  6.4737e-02,
 7.3023e-03,  2.9631e-02,  1.0820e-02,
-2.1400e-02,  5.4244e-01,  1.5639e-01,
-1.7561e-01,  4.8947e-01, -8.8305e-02,
 6.5073e-02,  3.4922e-01,  1.3483e-01,
 1.4506e-01, -2.5472e-01, -7.2894e-02,
 4.5945e-02,  1.4040e-01,  1.2148e-01,
-2.6932e-01, -1.1518e-01, -9.3158e-03,
-2.3961e-01, -1.2479e-01, -8.9796e-02,
 1.8688e-02, -4.9267e-02,  7.7189e-02,
-7.3691e-02,  7.8186e-03,  1.3761e-02,
-1.5689e-01,  3.1138e-02,  3.9231e-02,
-4.3607e-03,  2.0813e-01,  5.5635e-02,
-6.7000e-41,  9.8995e-41,  3.0043e-40,
 6.7190e-40,  4.0827e-40,  7.6057e-40,
 4.2208e-40,  8.1141e-40, -3.3569e-40,
 1.0179e-03,  5.1543e-04,  3.8076e-04,
 7.3507e-04,  4.5432e-04,  3.7410e-04,
 9.3014e-04,  6.7365e-04,  6.0051e-04,
-5.1998e-02,  6.5768e-02,  3.1603e-02,
-3.0198e-02, -3.1692e-02, -6.9299e-02,
 1.7672e-02,  2.3766e-01,  5.7877e-02,
-5.7944e-02,  1.2624e-01, -1.4396e-01,
-4.1542e-02,  6.5110e-01,  1.0942e-01,
-1.3133e-01,  5.0538e-02, -2.7371e-02,
-3.7515e-02,  2.8703e-02,  1.2382e-03,
 3.8542e-01, -2.2754e-02,  3.4459e-02,
 3.0545e-01, -5.3817e-01, -2.1389e-03,
 1.3888e-02, -2.2775e-01, -6.3692e-02,
-1.8430e-01,  5.8452e-02,  4.5764e-02,
-8.5045e-02, -1.7060e-01, -1.8565e-02,
-2.0384e-02, -3.3018e-02, -5.1135e-02,
-4.5789e-02, -1.8105e-01,  3.5419e-02,
-5.0081e-02,  8.7719e-02,  1.0373e-01,
-1.0033e-02,  7.0530e-02, -7.8012e-03,
 8.4042e-02,  1.1982e-01, -9.6046e-02,
-6.4009e-02, -1.0711e-01, -1.3523e-01,
 1.8868e-41, -7.0039e-40, -7.2568e-40,
 1.7408e-40, -7.8143e-40, -6.8130e-40,
-6.3142e-40, -6.2560e-40, -7.4238e-40,
 2.6297e-04,  7.0014e-05, -4.0981e-04,
 2.6263e-04,  4.2811e-05, -4.9950e-04,
 3.9795e-04,  1.2615e-04, -4.7660e-04,
 7.5933e-02,  2.6295e-02,  2.7984e-02,
-5.5914e-03, -8.7981e-02, -9.2618e-02,
 4.2725e-02, -3.1210e-01,  1.3412e-01,
 5.2683e-02,  3.9891e-01,  2.9150e-02,
-6.6090e-02,  2.9455e-01, -1.9710e-01,
 1.4546e-02, -2.5572e-02,  8.1125e-02,
 1.2271e-01,  1.6097e-01,  4.5644e-02,
 3.6101e-02, -1.7174e-02,  6.6110e-02,
 1.5078e-01,  4.5180e-01,  7.7154e-02,
-5.9725e-02,  1.0185e-01,  1.1363e-03,
 6.7791e-02,  1.7696e-02,  5.2638e-02,
 3.3051e-02, -8.4049e-02,  1.4380e-01,
 1.8744e-02, -2.0940e-01, -2.1424e-01,
-2.1329e-01, -1.3154e-01, -3.2572e-01,
 1.1292e-01,  1.2361e-02, -1.5506e-01,
-1.0362e-02,  1.9955e-02,  4.2639e-02,
-2.1952e-02, -2.4682e-02, -2.4453e-02,
-2.5606e-02, -3.3580e-02, -3.6340e-02,
-5.0830e-40,  6.3797e-40, -5.2775e-40,
-7.7988e-40, -7.4579e-40, -5.1901e-40,
-3.8275e-41, -5.7607e-40, -1.3656e-40,
 2.7164e-04,  5.9977e-04,  8.6886e-04,
 3.0116e-04,  7.0106e-04,  1.0248e-03,
 2.9177e-04,  6.4748e-04,  9.4825e-04,
 6.6310e-02,  1.5240e-02, -5.3044e-02,
 1.2545e-01,  5.0582e-02,  2.7358e-02,
 1.9338e-01,  1.1377e-01,  4.6110e-02,
-3.1997e-02,  1.5171e-02, -4.9372e-02,
 5.4615e-04,  1.7262e-01, -2.2081e-01,
 8.4871e-02,  1.7824e-02, -3.6429e-02,
 4.2821e-02, -1.0055e-01,  4.8927e-02,
 1.2524e-01,  5.8859e-02, -2.0980e-02,
 2.2897e-01,  1.7594e-01,  3.4239e-02,
 1.0915e-01,  1.2088e-01,  1.0151e-01,
 6.8449e-03, -1.5546e-01,  1.2024e-01,
 4.9036e-02, -1.2245e-01,  4.6713e-02
);

const float biasL[4] = float[4]
(
-0.0396,  0.0007,  0.1735,  0.0109
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
//!DESC ACNet HDN Level 3 L7
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 7.5083e-03, -4.8084e-02,  9.7731e-03,
 4.8779e-02,  3.1848e-02, -9.3517e-02,
 6.4595e-02,  3.9337e-02, -7.2343e-02,
 3.9519e-02,  4.1867e-02, -5.0485e-02,
 2.5257e-02,  1.4071e-01,  1.3606e-01,
 1.7481e-01,  2.0210e-01,  1.7241e-01,
-7.6295e-40, -7.8460e-40, -4.1806e-41,
-7.9994e-40, -7.3271e-40, -6.2665e-40,
-7.9602e-40, -7.0226e-40, -7.4131e-40,
-4.5544e-04, -5.2379e-04, -7.0755e-04,
-3.3807e-04, -3.8123e-04, -5.3222e-04,
-3.1771e-04, -3.4586e-04, -4.8784e-04,
-3.5257e-02, -1.1866e-02,  1.9717e-02,
-6.0777e-02, -7.3127e-03, -3.2825e-02,
-1.4952e-01,  3.2117e-01, -6.3786e-02,
-1.0255e-02,  1.2961e-01, -8.6823e-02,
 1.6994e-01,  4.7491e-01,  2.7135e-01,
 2.8538e-03,  1.5572e-01, -3.3736e-02,
 8.5996e-02, -1.0176e-02,  2.6629e-02,
 7.3362e-02, -7.7525e-03,  5.6261e-02,
 1.0819e-01, -2.5863e-01, -5.7146e-03,
-7.1781e-02,  2.8376e-03,  7.8298e-02,
 1.3183e-01,  2.7149e-02, -9.9786e-02,
 9.0491e-02,  8.7938e-02, -2.1882e-02,
 4.1396e-03, -4.5816e-02, -7.8892e-02,
-6.3855e-03,  1.7502e-01,  1.2053e-01,
 1.2492e-01,  6.1258e-02, -4.0516e-02,
-4.5409e-02, -4.5877e-02, -7.6414e-02,
-1.0573e-02, -1.2517e-01, -4.3991e-02,
-2.6447e-02, -9.5478e-02, -2.4735e-02,
-4.6548e-41, -1.6443e-40, -3.1221e-40,
-3.2675e-40, -2.7265e-40, -3.1190e-40,
-2.2065e-40, -2.5407e-40, -6.9511e-40,
-1.2727e-04, -2.6585e-04, -3.5516e-04,
 3.4272e-05, -1.6810e-04, -3.1677e-04,
-5.5355e-05, -2.9924e-04, -4.3692e-04,
-5.6428e-02,  1.0771e-01,  1.0185e-01,
 2.2948e-01, -7.8744e-02,  6.0768e-04,
-2.2355e-03, -2.0128e-03, -5.7317e-03,
-7.1232e-03,  1.0297e-01,  1.6872e-01,
 1.9194e-01, -1.1578e-01,  1.0732e-01,
-8.6952e-02,  3.2901e-02, -6.6658e-03,
 7.3979e-02,  8.3875e-02, -7.6372e-03,
 1.9577e-01,  2.7391e-01,  4.5275e-02,
 1.5610e-01,  2.3802e-01,  1.6555e-02,
 1.3814e-01,  1.2870e-01,  9.1626e-02,
-4.6890e-02, -8.8734e-02,  7.8866e-02,
 1.0027e-01,  2.2139e-01,  1.0050e-01,
-6.5845e-02, -1.0990e-01, -6.9896e-02,
 4.1687e-02,  3.0631e-02, -8.8441e-02,
-1.1868e-01,  1.0836e-02,  2.5873e-02,
-1.7114e-02,  7.6295e-02,  1.5439e-02,
-2.4271e-02,  5.8538e-02,  9.8190e-02,
 4.9742e-02,  8.7807e-02,  6.5871e-02,
-7.2669e-40, -7.5936e-41, -7.4975e-40,
-1.6984e-42, -1.7334e-40, -8.4954e-41,
-2.1556e-41, -1.5374e-40, -1.5515e-40,
-6.2626e-04, -7.2727e-04, -8.1665e-04,
-5.6584e-04, -6.1190e-04, -6.9584e-04,
-5.6278e-04, -5.8554e-04, -6.3554e-04,
 8.1550e-02, -4.1817e-03,  1.2301e-02,
-4.5800e-02,  4.6708e-02, -8.7972e-02,
-2.9880e-01,  2.6456e-01,  3.9363e-03,
-3.0939e-02, -1.9921e-01, -3.8689e-03,
-8.6803e-02,  3.4857e-01, -1.0201e-01,
 2.1597e-02,  1.4380e-02,  4.3448e-02,
 7.1195e-02,  1.4980e-01,  3.8079e-02,
-1.2678e-01, -8.1274e-02, -4.3445e-02,
 5.2482e-02, -1.8763e-01,  1.1557e-01,
-9.4614e-02,  5.4415e-02, -3.1485e-02,
-3.6451e-02,  1.4379e-01,  5.2291e-02,
-9.2069e-02,  9.5675e-02, -5.8433e-02,
 7.5768e-03, -7.1280e-02, -1.4576e-01,
-1.4671e-01, -1.2446e-01, -1.5207e-01,
-5.4368e-02,  3.8303e-02, -8.1794e-02,
 2.0492e-02,  4.0910e-02,  1.1379e-02,
 3.1582e-02,  3.6039e-02, -4.4040e-03,
 1.7540e-02,  1.4097e-04, -6.4367e-02,
-7.9553e-40, -5.3941e-40, -7.1912e-40,
-5.8099e-40, -6.8315e-40, -6.6012e-40,
-7.6242e-40, -5.4784e-40, -7.0267e-40,
-2.9197e-04, -2.1994e-04, -1.9501e-04,
-2.6516e-05, -1.2642e-05, -8.4345e-05,
 1.6763e-04,  1.1268e-04, -5.4516e-05,
-3.8007e-03, -6.8765e-02, -9.5716e-02,
 6.3091e-02, -8.1971e-02, -9.2895e-02,
-6.8353e-03,  7.3639e-02,  1.3505e-01,
 9.0083e-02,  2.4352e-01,  3.9708e-02,
-5.4051e-02, -6.8748e-02, -1.8937e-01,
-1.9808e-03, -7.1337e-02, -2.8316e-02,
 8.1504e-02,  8.3226e-03,  6.9013e-03,
 9.4393e-02,  5.9322e-02,  5.5023e-02,
 1.0236e-01, -4.0205e-02,  3.5172e-02,
 6.5381e-02,  4.9075e-02, -5.3931e-02,
 4.3961e-02,  9.0223e-03, -4.1678e-02,
-6.4262e-02, -5.0304e-02, -9.3597e-02
);

const float biasL[4] = float[4]
(
 0.1177,  0.0919,  0.0567, -0.0005
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
//!DESC ACNet HDN Level 3 L8
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 3.8496e-01,  1.4287e-01,  3.4530e-02,
-5.5398e-01, -6.0381e-02,  1.2078e-02,
 7.9983e-02,  2.1478e-01, -5.7915e-02,
-1.4020e-01, -2.6914e-02,  1.5915e-02,
 1.2371e-01,  2.5496e-01, -2.9867e-02,
 1.3269e-02, -9.9596e-02, -2.3173e-01,
 5.1471e-02, -4.5507e-01, -7.7620e-02,
-5.1328e-02, -1.9808e-02, -4.7051e-02,
 3.0573e-02,  7.8762e-02, -7.2627e-02,
 6.8690e-02, -4.0125e-02,  5.6657e-02,
 8.0208e-02, -2.0075e-02,  1.4019e-01,
-5.7959e-02, -7.3152e-02,  2.0202e-02,
-8.8702e-02, -1.9911e-01, -1.5570e-01,
 2.8401e-02,  5.8802e-02,  1.3050e-01,
 2.1905e-02, -3.4298e-02,  4.0447e-02,
 1.0184e-01, -9.0101e-02, -9.2770e-02,
 1.1713e-02, -3.2514e-01,  1.9393e-01,
-9.4227e-02,  2.7053e-01, -9.7233e-02,
-1.0478e-01,  6.0652e-02,  8.3399e-02,
 1.1104e-01,  2.9008e-01,  4.9208e-02,
-1.5414e-02,  3.1718e-02, -7.9083e-02,
-5.2358e-03,  9.0101e-02,  5.2973e-02,
 5.5527e-02, -1.6599e-02, -8.5167e-02,
-5.1018e-02,  7.2243e-03, -9.5684e-02,
-5.0608e-02, -6.7864e-02, -8.9496e-02,
-2.4348e-01,  2.7477e-01, -1.7588e-01,
 1.3927e-01,  5.5502e-02, -1.3370e-02,
-4.3509e-02, -2.1511e-01, -5.9070e-02,
 1.0293e-01,  4.2678e-01, -8.7527e-02,
-6.8546e-02, -5.6296e-02, -8.7962e-02,
-8.6130e-02,  9.2069e-02,  7.2303e-02,
 2.4365e-02,  2.1988e-01, -7.9408e-03,
-3.0063e-02,  1.1554e-01, -5.0311e-02,
 1.0605e-02,  5.4598e-02,  1.3826e-02,
-1.4342e-02,  1.5353e-01, -5.3974e-03,
 1.5583e-01, -6.0889e-02, -1.5772e-02,
-2.5956e-02, -3.5285e-01, -2.0338e-01,
 2.6011e-01,  2.2737e-01, -1.4693e-01,
-7.7964e-02,  1.0053e-01, -5.4278e-02,
-3.0668e-02,  3.4556e-02, -3.4321e-02,
 7.8695e-02, -2.2357e-01,  9.5733e-02,
 1.7483e-01, -1.5153e-01, -1.8262e-03,
 4.7605e-02, -2.2834e-01,  4.6383e-02,
 1.5701e-01,  3.2264e-01,  1.0334e-02,
 6.3351e-02,  1.1340e-01,  8.3478e-02,
 6.4196e-02,  3.3460e-02,  8.8473e-02,
 5.4663e-02, -1.7665e-03, -4.1935e-02,
-6.1346e-03, -5.4463e-02, -6.2960e-02,
 2.8159e-02,  2.9903e-02,  9.2429e-03,
-3.0041e-02, -9.7783e-02, -4.9500e-02,
 9.5350e-02, -7.9143e-02, -1.3244e-01,
-6.5129e-02,  1.4568e-01,  6.6843e-02,
 1.5241e-01, -7.8736e-02,  1.0721e-01,
-5.9015e-02,  1.5320e-01,  3.0796e-01,
-5.4266e-03, -6.0804e-02,  3.7326e-02,
 7.4844e-02,  4.8340e-02,  1.5251e-01,
 3.8158e-02,  1.2087e-01, -8.9003e-02,
-5.8369e-02, -7.3813e-02,  1.2240e-02,
-4.5106e-03,  7.4580e-02,  1.2042e-01,
 4.1959e-02,  1.4529e-01,  5.3636e-03,
-4.9708e-03, -1.0775e-02, -5.9374e-02,
 1.5358e-02,  1.7277e-02, -1.5412e-01,
 8.1647e-02,  3.3503e-02, -8.1934e-02,
-1.5807e-02, -1.0001e-02, -1.0059e-02,
-9.0493e-03, -7.8954e-02,  4.3891e-02,
-9.3815e-03,  3.2241e-02,  4.7962e-02,
-7.2252e-03,  7.9324e-02,  2.0662e-02,
-5.7710e-02, -5.1142e-02, -1.4296e-01,
 2.1501e-02, -1.9518e-02, -2.7658e-02,
 1.4983e-01,  8.5447e-02,  7.2092e-04,
 1.1275e-01,  6.1131e-02,  5.7955e-02,
 1.5624e-02,  2.7225e-01,  1.1716e-01,
-1.6322e-04, -1.3368e-04, -1.5575e-04,
-1.0525e-04, -1.0765e-04, -1.5306e-04,
-8.9692e-05, -1.0857e-04, -1.7316e-04,
-1.8015e-03, -1.3733e-03, -3.9154e-04,
-1.8453e-03, -1.4238e-03, -4.4163e-04,
-1.5511e-03, -1.1131e-03, -2.0087e-04,
-2.4082e-03, -2.2576e-03, -1.9231e-03,
-2.4913e-03, -2.4136e-03, -2.1678e-03,
-2.5057e-03, -2.4650e-03, -2.2732e-03,
-2.3901e-05, -1.5870e-05, -5.8255e-06,
-1.5163e-05, -1.2370e-05, -6.0712e-06,
-1.3098e-05, -1.1132e-05, -5.7866e-06,
-5.9760e-03, -5.9998e-03, -6.0295e-03,
-5.9962e-03, -6.0100e-03, -6.0277e-03,
-6.0003e-03, -6.0059e-03, -6.0148e-03,
-3.2764e-05, -2.9574e-05, -2.8001e-05,
-1.0846e-05, -1.1569e-05, -1.4282e-05,
-1.6255e-06, -2.5666e-06, -4.7808e-06,
-5.1999e-03, -5.2334e-03, -5.2847e-03,
-5.2057e-03, -5.2283e-03, -5.2713e-03,
-5.2195e-03, -5.2321e-03, -5.2633e-03,
-3.0782e-06, -9.2118e-06, -1.6177e-05,
-1.6382e-06, -6.9559e-06, -1.4245e-05,
-1.1471e-06, -6.5984e-06, -1.4903e-05
);

const float biasL[4] = float[4]
(
 0.0127, -0.0688,  0.1102, -0.0052
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
//!DESC ACNet HDN Level 3 L8
//!BIND L1_1
//!BIND L1_2
//!SAVE L2_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
 7.7574e-02, -1.2866e-02,  4.1348e-03,
-6.7298e-02, -1.3691e-01,  6.4079e-02,
 3.7962e-02,  8.7737e-02, -4.1046e-02,
-2.8471e-02,  1.7647e-01,  6.4232e-02,
 1.2316e-01,  3.6800e-01, -1.5740e-01,
-6.0839e-02,  1.5449e-02, -1.0761e-01,
-6.6869e-02, -1.2867e-01, -4.0195e-02,
-4.9651e-02, -5.5500e-02, -2.5879e-02,
 2.0179e-02,  6.8467e-02,  2.6575e-02,
-6.7728e-04, -7.6269e-02,  2.3470e-02,
 7.1869e-02, -1.1855e-01, -2.1067e-02,
 1.3263e-01, -3.2957e-02, -3.4365e-03,
 8.1936e-02,  1.3073e-01,  1.1477e-01,
 1.2429e-01,  1.6129e-01,  1.6251e-01,
 1.5476e-02,  3.2862e-02,  2.1999e-02,
-2.9189e-02, -3.3615e-02,  5.5616e-04,
-2.4059e-02, -9.6181e-03, -4.1175e-02,
-6.3680e-04, -9.6559e-02, -9.1448e-02,
 3.0238e-02,  1.2534e-01,  1.5256e-02,
-4.2118e-02,  1.5723e-01,  2.6929e-03,
 1.9873e-02,  5.3050e-02, -1.0153e-03,
 2.0634e-02,  9.2825e-03, -6.8027e-03,
 3.1335e-03, -7.7443e-03, -1.8307e-02,
 7.9974e-03, -1.0283e-03, -6.2520e-03,
 4.5050e-02,  9.9504e-02, -1.3404e-01,
-6.7271e-01, -5.7290e-02,  2.6919e-02,
 2.3673e-01,  2.4688e-02, -2.0227e-02,
 5.1389e-02, -3.9810e-02, -8.9700e-02,
 2.8445e-02,  3.9136e-01, -1.1508e-01,
-1.0449e-01, -6.2005e-02,  6.5721e-02,
-1.9123e-01, -4.2613e-02,  3.5371e-02,
 1.9207e-01,  8.7916e-02,  4.8089e-02,
-5.7912e-02,  1.0014e-01, -9.4659e-02,
 1.1240e-02, -6.2254e-03,  1.3399e-01,
 1.6483e-01, -3.5079e-01,  1.1612e-02,
 2.9215e-01,  5.6875e-02,  6.9505e-02,
 1.3721e-02,  1.2607e-01,  2.6426e-02,
-2.0529e-01,  2.1768e-01,  2.1232e-01,
-6.3574e-02,  2.3504e-02, -1.0811e-01,
-1.3470e-02, -3.6446e-02, -5.4379e-02,
-1.3257e-01, -8.3412e-02,  3.7745e-02,
 5.8778e-02, -2.6060e-01,  3.8262e-02,
-4.3689e-03, -6.6703e-02, -2.2025e-01,
-9.0961e-02,  1.3855e-01,  3.4573e-04,
-2.9613e-01, -3.6138e-02, -1.3827e-01,
 4.5896e-02, -5.3871e-02, -1.0037e-01,
 1.8457e-01,  1.0338e-01, -5.7306e-02,
 5.5510e-02, -9.4938e-02, -5.6527e-05,
 1.6372e-01, -3.3854e-02,  5.6332e-02,
-4.0251e-01, -5.9428e-02, -9.1470e-02,
-1.5921e-02, -5.7948e-02,  8.1682e-03,
-3.7833e-03,  1.6293e-01,  5.3784e-02,
 1.1053e-01, -1.3867e-01,  2.6772e-02,
-1.3133e-02,  3.7614e-01,  3.6361e-03,
-1.4205e-01,  3.1312e-02, -9.9928e-02,
-1.5755e-01,  4.2016e-01,  9.4065e-02,
 2.7536e-02,  1.2620e-01, -1.4894e-01,
-4.2137e-02, -9.8700e-02, -1.7479e-01,
 4.5836e-02,  5.3893e-02, -1.0138e-01,
 8.3609e-02,  2.1849e-02, -1.0648e-01,
 7.4801e-02, -1.2671e-01, -1.5007e-02,
 2.7440e-01, -3.1351e-01,  6.5787e-02,
-6.7820e-02,  1.6312e-01, -1.3254e-02,
-2.5770e-02, -2.0041e-02,  5.8243e-02,
 1.6055e-02,  1.1971e-02, -4.6112e-02,
-1.6276e-01, -1.5313e-02, -7.9826e-03,
 9.1668e-02,  9.7722e-02,  1.3754e-01,
-7.4817e-02, -4.1923e-01, -1.2337e-01,
 1.3472e-01, -4.0745e-02, -5.4055e-02,
-1.2943e-02,  4.8796e-02,  4.2007e-02,
 9.4668e-02,  8.6149e-02,  1.2362e-01,
 7.0637e-02,  2.3565e-01,  1.4582e-01,
 5.6904e-02, -8.2166e-02,  1.0563e-01,
 9.3969e-02, -2.2909e-01,  4.6537e-02,
 6.5257e-02,  1.4804e-01, -6.2092e-02,
-1.5699e-02, -1.5303e-02,  1.6671e-01,
-6.1947e-03,  2.5749e-01,  1.5257e-01,
 3.2908e-02, -5.9907e-02,  1.1502e-01,
 7.5876e-02, -2.6699e-01, -1.5891e-02,
-8.0426e-02,  1.3406e-01, -1.9881e-02,
 3.5472e-02, -8.2140e-02,  1.6509e-02,
 8.3390e-03, -7.8291e-02, -2.0754e-01,
 3.4490e-02,  2.7913e-01,  5.9566e-02,
 2.5288e-02,  1.1725e-01, -1.0356e-01,
-5.0955e-02,  9.2093e-02, -5.8477e-02,
 4.4325e-02,  3.2973e-02, -1.9477e-01,
 3.9582e-02, -8.6877e-02, -1.1753e-01,
 3.0401e-02, -2.8757e-02, -2.5563e-02,
 5.0741e-02, -3.5056e-01, -2.5584e-01,
 9.1709e-02, -4.0932e-02,  2.3812e-01,
 5.0945e-02,  4.9246e-02,  1.2738e-01,
 5.1440e-03,  1.5703e-01,  5.5743e-02,
-3.9492e-02,  1.2114e-01,  2.0531e-02,
 8.0800e-02,  2.6680e-03, -1.6660e-02,
 1.0684e-01,  1.2308e-01,  1.7882e-02,
 1.8280e-02,  1.0972e-01, -5.2912e-03
);

const float biasL[4] = float[4]
(
 0.1602, -0.0191, -0.0322,  0.0311
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
//!DESC ACNet HDN Level 3 L9
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_1
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-1.3812e-02, -4.6271e-02,  7.3790e-02,
-6.3801e-02, -3.6817e-01, -1.7880e-02,
 5.2986e-02,  1.8626e-01,  1.5645e-03,
 1.2367e-02, -6.2923e-02,  3.0844e-02,
 9.3623e-02,  1.9527e-01, -2.6366e-02,
-2.0837e-02, -3.4424e-02,  4.0256e-02,
 4.1482e-02,  6.1795e-02, -1.1293e-02,
-8.9944e-02, -1.3608e-01,  1.8067e-02,
 3.6974e-02,  5.2530e-03, -2.7474e-02,
 1.1872e-05,  1.9000e-05,  2.0729e-05,
 1.0139e-05,  1.6832e-05,  1.9392e-05,
 6.5445e-06,  1.0973e-05,  1.3521e-05,
-5.3340e-02,  1.3108e-03,  4.0436e-02,
 5.7068e-02, -2.7923e-02, -5.4781e-02,
-2.9293e-02,  2.7145e-02,  2.7340e-02,
 5.3520e-03,  1.8766e-02,  4.0297e-01,
 2.6473e-02, -3.4675e-02, -1.1783e-01,
-2.5038e-02, -1.7702e-02, -3.4908e-02,
 1.4847e-02,  2.3237e-01, -6.3687e-02,
-6.5672e-02, -2.1888e-01, -1.7233e-02,
 4.0608e-02, -6.9580e-02, -2.2200e-02,
 5.8163e-02,  1.3695e-01, -2.6257e-02,
-1.3328e-01, -3.5730e-01,  2.4507e-02,
-4.5611e-03,  2.0424e-01, -3.9821e-02,
 5.5300e-02, -1.6006e-01,  1.1717e-01,
-2.6107e-02, -8.6995e-02,  8.3720e-02,
 7.5494e-02,  3.2189e-01,  1.5527e-01,
-6.6869e-02,  1.4469e-01,  5.1805e-02,
 9.8760e-02, -1.6759e-01, -1.2350e-01,
 5.7005e-02,  8.4904e-02,  8.9713e-02,
-1.4263e-02,  2.8914e-02,  3.2239e-02,
-2.4871e-02,  5.6014e-02, -4.4469e-02,
 3.1209e-02,  1.3677e-02, -2.1052e-02,
-1.6548e-03, -1.8796e-03, -1.9883e-03,
-1.6186e-03, -1.8494e-03, -1.9670e-03,
-1.5841e-03, -1.8173e-03, -1.9345e-03,
 3.5726e-02,  1.8013e-01,  1.6913e-02,
-1.2168e-01, -6.3848e-02,  3.0555e-02,
 3.0269e-02, -1.0260e-01, -1.5259e-02,
-4.7375e-03,  5.5115e-02,  6.2642e-01,
 9.9776e-03, -2.1988e-01, -2.0984e-01,
 7.0470e-03,  6.3178e-02, -1.3607e-02,
 1.1918e-01, -2.4081e-01,  1.7889e-01,
-1.0514e-01,  2.9220e-01, -1.3263e-01,
 5.6091e-03, -4.1623e-02,  2.5589e-02,
-1.8496e-01,  2.7698e-02, -6.5768e-02,
 2.9677e-01,  4.4163e-02,  5.8530e-02,
-1.1010e-01, -7.6787e-02,  3.9844e-02,
 5.2113e-03, -1.8202e-02,  1.4129e-03,
-6.1402e-03, -2.7222e-01,  7.4690e-02,
 1.9131e-02,  2.2753e-01,  1.9587e-02,
-2.7391e-02,  6.7917e-03,  2.0496e-03,
 6.7333e-02,  7.8262e-02,  2.1110e-03,
-5.4519e-02,  3.0763e-02,  1.5628e-02,
 9.5055e-02,  3.8855e-02,  1.2446e-02,
-1.5152e-01,  7.8124e-02, -1.2616e-02,
 9.3100e-03, -1.6528e-02, -1.2873e-02,
-1.8377e-03, -1.9231e-03, -1.8930e-03,
-1.8058e-03, -1.8841e-03, -1.8678e-03,
-1.7387e-03, -1.7966e-03, -1.7781e-03,
-4.5122e-02,  1.7027e-03, -3.5534e-03,
 8.5222e-03,  1.0130e-01,  4.7893e-02,
 6.5574e-02,  7.2150e-03, -2.1820e-03,
-5.5105e-03, -1.8990e-01,  2.6527e-02,
 6.6140e-03,  2.1537e-01, -2.2183e-02,
-8.0628e-03,  6.8398e-03,  9.4474e-03,
 1.2239e-01, -1.3337e-01,  7.3391e-02,
-1.2205e-01,  1.3145e-01, -2.0063e-02,
 2.2168e-02,  3.6097e-03,  2.7146e-02,
 4.6717e-02,  2.1122e-02,  1.5491e-02,
-1.3077e-01,  1.1635e-01,  1.0849e-02,
 8.0113e-02, -8.4028e-02,  1.2863e-03,
-2.9796e-02, -8.4537e-02, -2.6766e-03,
-7.7771e-03, -2.4274e-03,  8.6274e-02,
-2.0354e-02,  4.1245e-02,  8.4227e-02,
 5.5894e-02,  1.0706e-01,  5.2965e-02,
-7.8731e-03,  5.5825e-01,  1.0373e-01,
-1.1975e-01, -2.0071e-02, -2.5286e-02,
-7.7477e-02,  5.3589e-02, -1.5710e-03,
-1.2753e-01,  2.5166e-01,  8.2205e-03,
-9.8349e-02, -4.9539e-02, -5.4941e-02,
-4.9916e-03, -4.9986e-03, -5.0660e-03,
-4.9770e-03, -4.9840e-03, -5.0543e-03,
-4.9997e-03, -5.0114e-03, -5.0809e-03,
 6.1819e-02,  1.5061e-01,  1.1984e-02,
 1.2905e-01,  2.5921e-01,  1.4768e-01,
 4.5548e-02,  1.4902e-01, -4.8961e-03,
-1.3605e-02,  8.2896e-02, -4.1931e-01,
-2.2657e-02,  2.4768e-01,  2.6528e-01,
-1.1566e-02, -8.7819e-03,  4.3618e-02,
-3.4332e-02, -1.8392e-01,  4.4471e-02,
-3.7073e-02, -5.4620e-02,  1.0899e-01,
 3.7891e-02,  9.9487e-02,  3.2383e-02,
-6.3628e-02, -5.0303e-03,  5.4617e-02,
-8.7802e-02,  2.1977e-01, -6.0249e-03,
 6.3554e-02, -5.4291e-02, -2.6709e-02
);

const float biasL[4] = float[4]
(
 0.0063, 0.0093, 0.0729, 0.3734
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
//!DESC ACNet HDN Level 3 L9
//!BIND L2_1
//!BIND L2_2
//!SAVE L1_2
//!COMPONENTS 4

#define RELU(x) max(x, vec4(0.0f))

const float kernelsL[9 * 8 * 4] = float[9 * 8 * 4]
(
-1.5505e-02, -6.7104e-02,  3.8607e-02,
-1.1427e-01, -3.2524e-01,  4.0077e-02,
-6.5144e-03,  1.2313e-01, -2.7924e-02,
 1.4265e-02, -3.8338e-02,  8.6780e-02,
 1.5341e-01,  1.2174e-01, -7.3160e-02,
 2.6326e-04,  7.3690e-02,  5.2187e-02,
-3.3114e-02, -3.6588e-02,  1.1635e-02,
-3.3521e-02,  1.0767e-01, -8.9125e-03,
-2.2431e-02, -4.5655e-03,  7.5531e-03,
 6.7227e-04,  7.2856e-04,  7.3907e-04,
 6.5335e-04,  7.0702e-04,  7.1233e-04,
 6.1540e-04,  6.7286e-04,  6.7797e-04,
-3.1496e-02,  6.0514e-02,  4.2013e-02,
-2.8617e-02,  1.4846e-02,  4.0016e-03,
 4.7006e-03, -4.0017e-02, -3.0411e-02,
-9.6037e-03,  8.8522e-02,  9.8616e-02,
 4.1297e-02, -3.2645e-01, -7.6144e-03,
-1.0711e-02,  3.9324e-02,  4.0144e-02,
 5.2899e-02, -7.8668e-02, -5.4798e-02,
-2.0428e-01,  5.7238e-02, -3.6937e-02,
-3.6103e-02, -8.2683e-02, -2.8101e-02,
 8.2479e-02,  5.7766e-02, -1.2019e-01,
-3.8373e-01,  6.8272e-02, -1.1758e-02,
 5.1129e-02, -2.7931e-01,  4.5608e-02,
-2.5151e-02, -5.0816e-02,  1.7231e-02,
-3.6376e-02,  1.5916e-01,  2.9192e-02,
-4.1947e-02,  5.3183e-02, -9.7289e-02,
 4.6138e-02,  7.0842e-02,  1.6673e-02,
-1.7243e-03,  2.7203e-01,  3.8262e-02,
-1.4000e-01, -7.3793e-02, -2.0050e-02,
-1.8750e-02, -8.5319e-02, -3.0858e-02,
-5.9981e-02,  1.2729e-01,  1.4094e-02,
-5.4088e-02, -2.3694e-02, -9.7485e-03,
-4.7840e-03, -4.8359e-03, -4.8727e-03,
-4.7882e-03, -4.8380e-03, -4.8755e-03,
-4.7859e-03, -4.8321e-03, -4.8633e-03,
 4.9511e-02,  1.0935e-01, -3.7430e-03,
 1.1834e-01,  7.7243e-02,  4.3074e-02,
 6.7446e-02,  2.9734e-02, -1.1276e-02,
-2.0080e-02,  1.3561e-01, -1.3455e-01,
-1.4505e-02,  2.2100e-01,  4.9635e-02,
-1.0040e-02,  3.4560e-02, -7.4607e-03,
-6.8873e-02, -5.6221e-02,  1.2255e-02,
-2.9198e-02,  7.1612e-02,  2.9402e-02,
 4.1036e-02,  4.6417e-02,  6.0284e-03,
-6.5261e-02,  2.1426e-03,  2.4192e-02,
-1.6073e-03, -6.2222e-03, -1.8295e-02,
 2.4952e-04, -2.0623e-02, -3.3064e-03,
 5.9188e-02, -4.8839e-02,  7.9840e-02,
-6.7952e-02, -4.7191e-01,  1.5117e-01,
 1.5668e-01,  2.4733e-01,  1.1354e-01,
 1.7742e-02, -4.4059e-02,  9.5374e-03,
 3.2049e-01, -1.3779e-01,  9.6608e-02,
 8.4580e-02,  1.4293e-01,  6.1574e-02,
 2.8777e-03,  7.8795e-02, -5.1902e-02,
 1.2212e-01,  1.0321e-01,  3.2360e-02,
-9.6617e-02,  7.8941e-03, -7.0876e-02,
 3.5869e-03,  3.5891e-03,  3.5923e-03,
 3.5746e-03,  3.5840e-03,  3.5967e-03,
 3.5785e-03,  3.5932e-03,  3.6080e-03,
 1.5454e-03,  3.0582e-03,  4.3737e-02,
-5.9833e-02, -1.1247e-01,  4.4380e-02,
-1.3206e-01,  8.2778e-03,  4.7963e-02,
-4.3720e-02, -7.5722e-03,  2.0510e-01,
 3.0133e-02, -4.0506e-01,  2.7867e-01,
 5.5586e-02,  2.8926e-02,  1.3360e-03,
 1.9490e-05,  3.3326e-01, -7.7241e-02,
-1.5648e-01,  1.5195e-01, -1.3995e-01,
 8.6519e-02,  1.0447e-01, -4.1413e-02,
-3.8667e-03,  1.6159e-01,  1.1627e-01,
-2.2646e-01, -3.4758e-02, -6.7956e-03,
-3.2689e-01,  1.9606e-01, -9.1523e-02,
 1.1238e-02,  1.5084e-03,  4.2113e-02,
-1.1154e-02, -3.6596e-01, -7.2252e-02,
 6.6621e-02,  1.0188e-01,  4.1032e-01,
 3.5892e-02, -4.8304e-02,  6.6142e-03,
 1.3374e-01,  2.2720e-01, -7.1224e-02,
 6.8952e-02,  2.0467e-01,  5.0251e-02,
-6.2016e-02,  2.2175e-01, -1.7764e-02,
 2.7542e-02,  1.4905e-01,  3.6637e-02,
-7.2231e-02,  5.0271e-03, -7.1823e-02,
 3.5760e-03,  3.5540e-03,  3.5692e-03,
 3.5664e-03,  3.5490e-03,  3.5689e-03,
 3.5671e-03,  3.5619e-03,  3.5864e-03,
 2.7470e-02, -3.9752e-02,  4.1063e-02,
-2.4985e-02, -1.7969e-01,  8.2186e-02,
-5.4251e-02, -5.9651e-03,  2.5079e-02,
-2.1197e-02,  2.5426e-02,  1.3585e-01,
-1.3460e-02, -1.1377e-01,  1.2278e-01,
 3.6533e-02,  1.2843e-02,  5.6219e-02,
 5.8141e-04,  2.8354e-01, -6.2016e-02,
-1.0289e-01,  1.8724e-01, -9.9475e-02,
 5.1193e-02,  7.5986e-02, -1.2951e-03,
-8.2587e-02,  1.8498e-01,  1.0891e-01,
 1.3538e-01, -4.7728e-01,  1.0868e-01,
-8.6415e-02, -1.7061e-01,  1.0457e-02
);

const float biasL[4] = float[4]
(
 0.0006, 0.1915, 0.3186, 0.2636
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
//!DESC ACNet HDN Level 3 L10
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!BIND L1_1
//!BIND L1_2

const float kernelsL10[4 * 8] = float[4 * 8]
(
-0.0967, -0.3094,
 0.3537,  0.5705,
 0.2547,  0.3360,
-0.0718, -0.0700,
-0.3013, -0.1602,
 0.4520,  0.0495,
 0.1564,  0.3773,
-0.0216,  0.4367,
-0.4855, -0.1972,
-0.2026, -0.4390,
 0.3743, -0.1156,
 0.4408, -0.3123,
-0.3577,  0.0753,
-0.3396,  0.0336,
 0.1052, -0.4180,
 0.0799, -0.3587
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