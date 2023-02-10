# HDR Toys

Componentized Rec.2100 to Rec.709 color conversion shaders for mpv-player and libplacebo, include dynamic tone-mapping curve and uniform tone-mapping color space.

## How to use?

Put this in your `mpv.conf`.

```ini
vo=gpu-next

[bt.2100]
profile-cond=get("video-params/sig-peak") > 1
profile-restore=copy
target-trc=pq
target-prim=bt.2020
glsl-shader=~~/shaders/hdr-toys/utils/clip_both.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/pq_to_l.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/l_to_linear.glsl
glsl-shader=~~/shaders/hdr-toys/utils/crosstalk.glsl
glsl-shader=~~/shaders/hdr-toys/utils/chroma_correction.glsl
glsl-shader=~~/shaders/hdr-toys/tone-mapping/dynamic.glsl
glsl-shader=~~/shaders/hdr-toys/utils/crosstalk_inverse.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/compress.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/linear_to_bt1886.glsl
glsl-shader-opts-add=crosstalk/alpha=0
glsl-shader-opts-add=crosstalk_inverse/alpha=0
```

- `vo=gpu-next` is required, the minimum version of mpv required is v0.35.0.
- Dolby Vision Profile 5 is not tagged as HDR by mpv, so it wouldn't activate this auto-profile.

Also you can use it to get a better experience to play BT.2020 content.

```ini
[bt.2020]
profile-cond=get("video-params/primaries") == "bt.2020" and get("video-params/sig-peak") == 1
profile-restore=copy
target-prim=bt.2020
glsl-shader=~~/shaders/hdr-toys/transfer-function/bt1886_to_linear.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/compress.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/linear_to_bt1886.glsl
```

- If you use `gamut-mapping/matrix` here, you will see that the result is different from mpv (vo=gpu-next), this is due to the black point of BT.1886, I personally consider that the black point in color conversion is always 0.

## What are these? What are they for?

### Workflow

```mermaid
graph TD
    A[BT.2100-pq, BT.2100-hlg, HDR10+, Dolby Vision, etc.] -->|mpv --target-trc=pq --target-prim=bt.2020| B(BT.2100-pq)
    B -->|linearize and normalize| C(BT.2020 linear)
    C -->|tone mapping| D(BT.2020 linear - tone mapped)
    D -->|gamut mapping| E(BT.709 linear)
    E -->|bt1886| F[BT.709]
```

### Tone mapping

You can change the tone mapping operator by replacing this line.  
For example, use bt2446c instead of dynamic.

```diff
- glsl-shader=~~/shaders/hdr-toys/tone-mapping/dynamic.glsl
+ glsl-shader=~~/shaders/hdr-toys/tone-mapping/bt2446c.glsl
```

This table lists the features of operators.

- Operators below the blank row are for testing and should not be used for watching.

| Operator | Applied to | Conversion peak |
| -------- | ---------- | --------------- |
| dynamic  | JzCzhz     | Frame peak      |
| bt2390   | ICtCp      | HDR peak        |
| bt2446a  | YCbCr      | HDR peak        |
| bt2446c  | xyY        | 1000nit         |
| reinhard | YRGB       | HDR peak        |
| hable    | YRGB       | HDR peak        |
| hable2   | YRGB       | HDR peak        |
| suzuki   | YRGB       | 10000nit        |
| uchimura | YRGB       | 1000nit         |
| lottes   | maxRGB     | HDR peak        |
| hejl2015 | RGB        | HDR peak        |
|          |            |                 |
| clip     | RGB        | SDR peak        |
| linear   | YRGB       | HDR peak        |
| local    | YRGB       | Block peak      |
| heatmap  | Y          | 10000nit        |

Typical representation of the same curve applied to different color spaces.
| RGB | YRGB | maxRGB | Hybrid in JzCzhz |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/216764535-6bd0b74e-9b60-4743-9b25-dc7988fd0a8a.png) | ![image](https://user-images.githubusercontent.com/50797982/216764516-0cce4ddc-a414-47f1-9d9e-0b10aacee78b.png) | ![image](https://user-images.githubusercontent.com/50797982/216764500-24bf11c5-a480-44a5-99c7-853ebaa63744.png) | ![image](https://user-images.githubusercontent.com/50797982/216764489-0fe2cff9-cbb9-4f81-a9de-de3b333a5860.png) |

Typical representation of static and dynamic curves applied to the same color space.
| bt.2446c | dynamic |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/216832251-abf05c55-bc97-48e4-97c8-a9b06240f235.png) | ![image](https://user-images.githubusercontent.com/50797982/216832261-93d7dcd4-7588-4086-a4dd-fb48d29c0ade.png) |
| ![image](https://user-images.githubusercontent.com/50797982/216832312-9a3e1a9f-2dd0-4b28-abd0-b09b5aa45399.png) | ![image](https://user-images.githubusercontent.com/50797982/216832291-fbee6755-b028-4ede-a330-bccf0904a5b3.png) |
| ![image](https://user-images.githubusercontent.com/50797982/216901529-fa175d65-1fc8-4efe-a5e3-df7d63b4c800.png) | ![image](https://user-images.githubusercontent.com/50797982/216901584-93ffdbae-4f70-4b81-a978-d0fe69e06a39.png) |

- HDR peak defaults to 1000nit.  
  You can set it manually with `set glsl-shader-opts L_hdr=N`  
  [hdr-toys-helper.lua](https://github.com/natural-harmonia-gropius/mpv-config/blob/master/portable_config/scripts/hdr-toys-helper.lua) can get it automatically from the mpv's video-out-params/sig-peak.

- SDR peak defaults to 203nit.  
  You can set it manually with `set glsl-shader-opts L_sdr=N`  
  In some grading workflows it is 100nit, if so you'll get a dim result, unfortunately you have to guess the value and set it manually.

- That the BT.2390 EETF designed for display transform,  
  To get the desired result, you need to set reference white to your monitor's peak white by `set glsl-shader-opts L_sdr=N`.  
  To adapt the black point, you need to set the contrast to your monitor's contrast by `set glsl-shader-opts CONTRAST_sdr=N`.

### Chroma correction

This is a part of tone mapping, also known as "highlights desaturate".  
You can set the intensity of it by `set glsl-shader-opts sigma=N`.

In real world, the brighter the color, the less saturated it becomes, and eventually it turns white.

| `sigma=0`                                                                                                       | `sigma=0.2`                                                                                                     | `sigma=1`                                                                                                       |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/216247628-8647c010-ff70-488c-bc40-1d57612d1d9f.png) | ![image](https://user-images.githubusercontent.com/50797982/216247654-fc3066a1-098b-4f81-b4c5-a9c8eb6720cd.png) | ![image](https://user-images.githubusercontent.com/50797982/216247675-71c50982-2061-49b1-93b7-87ebe85951d6.png) |

### Crosstalk

This is a part of tone mapping, the screenshot below will show you how it works.  
You can set the intensity of it by `set glsl-shader-opts alpha=N`.

It makes the color less chromatic when tone mapping and the lightness between colors more even.  
And for non-perceptual conversions (e.g. hejl2015) it brings achromatically highlights.

| without crosstalk_inverse                                                                                       | heatmap, Y, alpha=0                                                                                             | heatmap, Y, alpha=0.3                                                                                           | hejl2015, RGB, alpha=0                                                                                          | hejl2015, RGB, alpha=0.3                                                                                        |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/213441412-7f43f19c-afc3-4b31-8b5c-55c1ac064ff7.png) | ![image](https://user-images.githubusercontent.com/50797982/213441611-fd6e6afa-e39b-4a44-82da-45a667dfe88a.png) | ![image](https://user-images.githubusercontent.com/50797982/213441631-3f87b965-8206-4e91-a8dd-d867c07cbf0d.png) | ![image](https://user-images.githubusercontent.com/50797982/213442007-411fd942-c930-4629-8dc1-88da8705639e.png) | ![image](https://user-images.githubusercontent.com/50797982/213442036-45e0a832-7d14-40f5-b4ca-1320ad59358d.png) |

### Gamut mapping

`matrix` is the exact conversion.  
`compress` restores the excess color by reducing the distance of the achromatic axis.  
`warning` shows the excess color after conversion as inverse color.

| matrix                                                                                                          | compress                                                                                                        | warning                                                                                                         |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/215457620-7920720a-c6a2-4f71-aa30-cc97bd8f03ea.png) | ![image](https://user-images.githubusercontent.com/50797982/215457533-802154a7-cfd0-442b-9882-35cce210308f.png) | ![image](https://user-images.githubusercontent.com/50797982/215457770-e1822c28-d1ac-4938-b3cc-48dcdee5738a.png) |
