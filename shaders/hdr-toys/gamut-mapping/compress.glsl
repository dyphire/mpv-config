// Compress highly chromatic source colorimetry into a smaller gamut
// https://github.com/jedypod/gamut-compress
// https://github.com/ampas/aces-dev/blob/dev/transforms/ctl/lmt/LMT.Academy.ReferenceGamutCompress.ctl

// The parameters are calculated by the following script, but I'm not sure if the process is correct
/*
const { max, abs } = Math;

function multiplyMatrices(A, B) {
  let m = A.length;

  if (!Array.isArray(A[0])) {
    // A is vector, convert to [[a, b, c, ...]]
    A = [A];
  }

  if (!Array.isArray(B[0])) {
    // B is vector, convert to [[a], [b], [c], ...]]
    B = B.map((x) => [x]);
  }

  let p = B[0].length;
  let B_cols = B[0].map((_, i) => B.map((x) => x[i])); // transpose B
  let product = A.map((row) =>
    B_cols.map((col) => {
      let ret = 0;

      if (!Array.isArray(row)) {
        for (let c of col) {
          ret += row * c;
        }

        return ret;
      }

      for (let i = 0; i < row.length; i++) {
        ret += row[i] * (col[i] || 0);
      }

      return ret;
    })
  );

  if (m === 1) {
    product = product[0]; // Avoid [[a, b, c, ...]]
  }

  if (p === 1) {
    return product.map((x) => x[0]); // Avoid [[a], [b], [c], ...]]
  }

  return product;
}

function RGB_2020_to_709(rgb) {
  const M = [
    [1.6605, -0.5876, -0.0728],
    [-0.1246, 1.1329, -0.0083],
    [-0.0182, -0.1006, 1.1187],
  ];
  return multiplyMatrices(M, rgb);
}

function XYZ_to_RGB_2020(X, Y, Z) {
  const M = [
    [1.7167, -0.3557, -0.2534],
    [-0.6667, 1.6165, 0.0158],
    [0.0176, -0.0428, 0.9421],
  ];
  return multiplyMatrices(M, [X, Y, Z]);
}

function xyY_to_XYZ(x, y, Y) {
  const X = (x * Y) / max(y, 1e-6);
  const Z = ((1.0 - x - y) * Y) / max(y, 1e-6);

  return [X, Y, Z];
}

function xyY_to_RGB_709(x, y, Y) {
  Y /= 100;
  const XYZ = xyY_to_XYZ(x, y, Y);
  const RGB2020 = XYZ_to_RGB_2020(...XYZ);
  const RGB709 = RGB_2020_to_709(RGB2020);
  return RGB709;

  //   const M = [
  //     [3.2404542, -1.5371385, -0.4985314],
  //     [-0.969266, 1.8760108, 0.041556],
  //     [0.0556434, -0.2040259, 1.0572252],
  //   ];
  //   return multiplyMatrices(M, XYZ);
}

function distance(rgb) {
  const ac = max(...rgb);

  if (ac === 0) {
    return [0, 0, 0];
  }

  const d = [
    ac - rgb[0] / abs(ac),
    ac - rgb[1] / abs(ac),
    ac - rgb[2] / abs(ac),
  ];

  return d;
}

const rgb = [
  distance(RGB_2020_to_709([1, 0, 0])),
  distance(RGB_2020_to_709([0, 1, 0])),
  distance(RGB_2020_to_709([0, 0, 1])),
];
const l = rgb.reduce((p, c) => [
  max(p[0], c[0]),
  max(p[1], c[1]),
  max(p[2], c[2]),
]);
console.log("limit", ...l);

const color_checker = [
  distance(xyY_to_RGB_709(0.4, 0.35, 10.1)),
  distance(xyY_to_RGB_709(0.377, 0.345, 35.8)),
  distance(xyY_to_RGB_709(0.247, 0.251, 19.3)),
  distance(xyY_to_RGB_709(0.337, 0.422, 13.3)),
  distance(xyY_to_RGB_709(0.265, 0.24, 24.3)),
  distance(xyY_to_RGB_709(0.261, 0.343, 43.1)),
  distance(xyY_to_RGB_709(0.506, 0.407, 30.1)),
  distance(xyY_to_RGB_709(0.211, 0.175, 12.0)),
  distance(xyY_to_RGB_709(0.453, 0.306, 19.8)),
  distance(xyY_to_RGB_709(0.285, 0.202, 6.6)),
  distance(xyY_to_RGB_709(0.38, 0.489, 44.3)),
  distance(xyY_to_RGB_709(0.473, 0.438, 43.1)),
  distance(xyY_to_RGB_709(0.187, 0.129, 6.1)),
  distance(xyY_to_RGB_709(0.305, 0.478, 23.4)),
  distance(xyY_to_RGB_709(0.539, 0.313, 12.0)),
  distance(xyY_to_RGB_709(0.448, 0.47, 59.1)),
  distance(xyY_to_RGB_709(0.364, 0.233, 19.8)),
  distance(xyY_to_RGB_709(0.196, 0.252, 19.8)),
  distance(xyY_to_RGB_709(0.31, 0.316, 90.0)),
  distance(xyY_to_RGB_709(0.31, 0.316, 59.1)),
  distance(xyY_to_RGB_709(0.31, 0.316, 36.2)),
  distance(xyY_to_RGB_709(0.31, 0.316, 19.8)),
  distance(xyY_to_RGB_709(0.31, 0.316, 9.0)),
  distance(xyY_to_RGB_709(0.31, 0.316, 3.1)),
];
const t = color_checker.reduce((p, c) => [
  max(p[0], c[0]),
  max(p[1], c[1]),
  max(p[2], c[2]),
]);
console.log("threshold", ...t);
*/

//!PARAM cyan_limit
//!TYPE float
//!MINIMUM 1.001
//!MAXIMUM 2
1.6515689028157825

//!PARAM magenta_limit
//!TYPE float
//!MINIMUM 1.001
//!MAXIMUM 2
1.7355376392652817

//!PARAM yellow_limit
//!TYPE float
//!MINIMUM 1.001
//!MAXIMUM 2
1.671460554049985

//!PARAM cyan_threshold
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.4770771960073855

//!PARAM magenta_threshold
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.43305325213057494

//!PARAM yellow_threshold
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.8430686842640781

//!PARAM select
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.1

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (compress)

mat3 M = mat3(
     1.6605, -0.5876, -0.0728,
    -0.1246,  1.1329, -0.0083,
    -0.0182, -0.1006,  1.1187);

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    vec3 color_src = color.rgb;
    vec3 color_src_cliped = clamp(color_src, 0.0, 1.0);
    vec3 color_dst = color_src_cliped * M;

    vec3 rgb = color_dst;

    // Distance limit: How far beyond the gamut boundary to compress
    vec3 dl = vec3(cyan_limit, magenta_limit, yellow_limit);

    // Amount of outer gamut to affect
    vec3 th = vec3(cyan_threshold, magenta_threshold, yellow_threshold);

    // Achromatic axis
    float ac = max(rgb.x, max(rgb.y, rgb.z));

    // Inverse RGB Ratios: distance from achromatic axis
    vec3 d = ac == 0.0 ? vec3(0.0) : (ac - rgb) / abs(ac);

    // Calculate scale so compression function passes through distance limit: (x=dl, y=1)
    vec3 s;
    s.x = (1.0 - th.x) / sqrt(dl.x - 1.0);
    s.y = (1.0 - th.y) / sqrt(dl.y - 1.0);
    s.z = (1.0 - th.z) / sqrt(dl.z - 1.0);

    vec3 cd; // Compressed distance
    // Parabolic compression function: https://www.desmos.com/calculator/nvhp63hmtj
    cd.x = d.x < th.x ? d.x : s.x * sqrt(d.x - th.x + s.x * s.x / 4.0) - s.x * sqrt(s.x * s.x / 4.0) + th.x;
    cd.y = d.y < th.y ? d.y : s.y * sqrt(d.y - th.y + s.y * s.y / 4.0) - s.y * sqrt(s.y * s.y / 4.0) + th.y;
    cd.z = d.z < th.z ? d.z : s.z * sqrt(d.z - th.z + s.z * s.z / 4.0) - s.z * sqrt(s.z * s.z / 4.0) + th.z;

    // Inverse RGB Ratios to RGB
    vec3 crgb = ac - cd * abs(ac);

    color.rgb = mix(rgb, crgb, select);

    return color;
}
