> 原文地址 [hooke007.github.io](https://hooke007.github.io/mpv-lazy/[01]_%E7%AC%AC%E4%B8%89%E6%96%B9%E7%9D%80%E8%89%B2%E5%99%A8%E4%BB%8B%E7%BB%8D.html)

*ver.20220407*

我选择主设置文件夹下新建的 **shaders** 目录下放置第三方着色器，常见后缀名为 .glsl .hook 

通过编辑 **mpv.conf** / **input.conf** 自行决定自动 / 手动加载第三方着色器（语法见对应文件内示例） 

部分放大着色器有最小缩放倍数的触发限制条件，即 目标分辨率 ＞或＝ 源分辨率 x 最小触发倍数 

通常 AI 类缩放算法无特别说明，都只对源执行一次双倍放大，不足 / 超过目标分辨率的部分由 **mpv.conf** 中指定的 --scale/dscale 算法接力执行 

通过控制台 console(`) 和统计信息界面 stats(shift+i → 2) 共同检查着色器的工作状态

扩展阅读： 关于色度、亮度升频和缩放：[https://vcb-s.com/archives/2726](https://vcb-s.com/archives/2726) 关于影像瑕疵：[https://vcb-s.com/archives/4738](https://vcb-s.com/archives/4738) 

不同着色器 / 算法的比较参考：[https://artoriuz.github.io/blog/mpv_upscaling.html](https://artoriuz.github.io/blog/mpv_upscaling.html)

☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲

## 第三方着色器介绍

### Anime4K
-------

它是一组开源的高质量的实时动漫缩放 / 降噪算法。在 v1 之前是个纯粹的锐化滤镜，v2 引入人工智能卷积核，在 v3 之后进行了模块化改造，目前版本 v4 在局部场景下能达到 waifu2x 的效果。 A4k 不提供 cscale 色度升频类着色器。(v3.2-v4 不兼容 v3.1 及之前的版本，旧版与区别说明见 **附录** 部分)

S → M → L → VL → UL 性能要求逐渐提高（处理耗时大致加倍），处理结果越好

去模糊系列：（推荐 **Anime4K_Deblur_DoG.glsl** 变体）

 `Anime4K_Deblur_DoG.glsl` <br/> `Anime4K_Deblur_Original.glsl`

降噪系列： Mean → Mode → Median 速度逐渐变慢。（推荐 **Anime4K_Denoise_Bilateral_Mode.glsl** 变体）

 `Anime4K_Denoise_Bilateral_Mean.glsl` <br/> `Anime4K_Denoise_Bilateral_Mode.glsl` <br/> `Anime4K_Denoise_Bilateral_Median.glsl`

线条加深、变细系列： VeryFast → Fast → HQ 速度逐渐变慢。（推荐 **Anime4K_Darken_HQ.glsl** 和 **Anime4K_Thin_HQ.glsl** 变体）

 `Anime4K_Darken_VeryFast.glsl` <br/> `Anime4K_Darken_Fast.glsl` <br/> `Anime4K_Darken_HQ.glsl`

`Anime4K_Thin_VeryFast.glsl` <br/> `Anime4K_Thin_Fast.glsl` <br/> `Anime4K_Thin_HQ.glsl`

线条重建系列：开发者推荐在upscale之前使用，减少上采样后产生的伪影。  Soft  为更适合与downscale一起使用，可用于下采样抗锯齿。  GAN  变体使用生成型对抗网络，通常比  CNN  具有更高的质量。

 `Anime4K_Restore_CNN_S.glsl` <br/> `Anime4K_Restore_CNN_M.glsl` <br/> `Anime4K_Restore_CNN_L.glsl` <br/> `Anime4K_Restore_CNN_VL.glsl` <br/> `Anime4K_Restore_CNN_UL.glsl` <br/> `Anime4K_Restore_CNN_Soft_S.glsl` <br/> `Anime4K_Restore_CNN_Soft_M.glsl` <br/> `Anime4K_Restore_CNN_Soft_L.glsl` <br/> `Anime4K_Restore_CNN_Soft_VL.glsl` <br/> `Anime4K_Restore_CNN_Soft_UL.glsl` <br/>
`Anime4K_Restore_GAN_UL.glsl` <br/>
`Anime4K_Restore_GAN_UUL.glsl` <br/>

放大系列： CNN 变体最小缩放触发倍率为 1.2。 Original 变体始终执行二倍放大且无缩放触发倍率限制。

 `Anime4K_Upscale_CNN_x2_S.glsl` <br/> `Anime4K_Upscale_CNN_x2_M.glsl` <br/> `Anime4K_Upscale_CNN_x2_L.glsl` <br/> `Anime4K_Upscale_CNN_x2_VL.glsl` <br/> `Anime4K_Upscale_CNN_x2_UL.glsl` <br/> `Anime4K_Upscale_Original_x2.glsl`

放大为主的混合系列： 以下除 Deblur_Original （无限制）外，最小缩放触发倍率皆为 1.2。 

 `Anime4K_Upscale_DoG_x2.glsl` <br/> `Anime4K_Upscale_DTD_x2.glsl` <br/> `Anime4K_Upscale_Deblur_Original_x2.glsl` <br/> `Anime4K_Upscale_Deblur_DoG_x2.glsl` <br/> `Anime4K_Upscale_Denoise_CNN_x2_S.glsl` <br/> `Anime4K_Upscale_Denoise_CNN_x2_M.glsl` <br/> `Anime4K_Upscale_Denoise_CNN_x2_L.glsl` <br/> `Anime4K_Upscale_Denoise_CNN_x2_VL.glsl` <br/> `Anime4K_Upscale_Denoise_CNN_x2_UL.glsl`

其它系列： 

AutoDownscalePre 防止过度放大超越显示分辨率，避免额外一步的downscale处理。   

x2版常用于2k屏全屏观看1080p执行二倍放大过度（4k目标分辨率远超显示设备分辨率），也可用于4k屏两次放大720p视频。该着色器放在首个放大着色器之后。x4版放在两次放大着色器之间。

Clamp 主要用于钳制画面的高光，抗振铃和减少过冲。该着色器放在**所有**处理着色器之前或（推荐）之后。

3DGraphics 主要用于游戏类3d画面放大。AA为抗锯齿版本。（无缩放倍率限制）

`Anime4K_AutoDownscalePre_x2.glsl` <br/>
`Anime4K_AutoDownscalePre_x4.glsl` <br/>
`Anime4K_Clamp_Highlights.glsl` <br/>
`Anime4K_3DGraphics_Upscale_x2_US.glsl` <br/>
`Anime4K_3DGraphics_AA_Upscale_x2_US.glsl` <br/>

追加说明：对新版着色器的混合顺序为 Clamp → Restore → Upscale → AutoDownscalePre → Upscale ...（仅作为推荐，可自行调节删改） 通常仅需一个 **Anime4K_Restore_CNN_M.glsl** 模块即满足大多数人的口味（适度画面修复 + 弱感知强化 + 微量伪影引入）

☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲

### ACNet
-----

是 Anime4KCPP-Net 的缩写，设计用于高性能动画风格的图像和视频放大，它与 Asymmetric Convolution Net(缩写重名 ACNet) 无关，与现在的 Anime4k 也无太大关联。ACNet 是 Anime4KCPP 自己的基于 CNN 的算法。

🔺 启用将覆盖 **mpv.conf** 中指定的 --scale=xxxxx 算法 

🔺 最小缩放触发倍率为 1.2 

副作用： HDN 变体能更好的降噪，等级 1 → 2 → 3，越高降噪效果越好，但可能导致模糊和缺少细节。

相关列表：[https://github.com/TianZerL/ACNetGLSL](https://github.com/TianZerL/ACNetGLSL)

 `ACNet.glsl` <br/> `ACNet_HDN_L1.glsl` <br/> `ACNet_HDN_L2.glsl` <br/> `ACNet_HDN_L3.glsl`

☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲

### FSRCNNX
-------

由原始 SRCNN 发展而来，是 FSRCNN 的变体，较快速的通用型 AI 放大算法。

🔺 启用将覆盖 **mpv.conf** 中指定的 --scale=xxxxx 算法 

🔺 最小缩放触发倍率为 1.3 

LineArt 和 anime 变体更适合 2d 动画 

enhance 变体在去除伪影强度上更大

副作用： 16-0-4-1 变体用更多的能耗（更慢）换取更好的质量，但感知较弱。

相关列表：[https://github.com/igv/FSRCNN-TensorFlow](https://github.com/igv/FSRCNN-TensorFlow) 

 `FSRCNNX_x2_8-0-4-1.glsl` <br/> `FSRCNNX_x2_8-0-4-1_LineArt.glsl` <br/> `FSRCNNX_x2_16-0-4-1.glsl` <br/>

 相关列表：https://github.com/HelpSeeker/FSRCNN-TensorFlow

`FSRCNNX_x2_16-0-4-1_anime_enhance.glsl` <br/> `FSRCNNX_x2_16-0-4-1_enhance.glsl`

☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲

### Adaptive Sharpen

自适应锐化

### Krig

利用亮度信息进行高质量的色度升频 mpv 目前最好的色度升频着色器，可以与其他缩放（--scale/dscale）算法共同使用

🔺 启用将覆盖 **mpv.conf** 中指定的 --cscale=xxxxx 算法

### SSimDownscaler

基于感知的缩小算法增强

🔺 仅当 **mpv.conf** 中设定 --dscale=mitchell --linear-downscaling=no 时正常工作

### SSimSuperRes

该着色器的目的是对 mpv 内置 --scale=xxxxx 算法进行增强校正。

以上四项及 FSRCNNX 皆由同一开发者移植 

相关列表：[https://gist.github.com/igv](https://gist.github.com/igv) 

 `adaptive-sharpen.glsl` <br/> `KrigBilateral.glsl` <br/> `SSimDownscaler.glsl` <br/> `SSimSuperRes.glsl`

相关列表：MOD 

（变体  luma  仅作用于亮度通道） 

`adaptive-sharpen_luma.glsl`

☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲

### RAVU

(Rapid and Accurate Video Upscaling) 是一组受 RAISR（快速准确的图像超分辨率）启发的预分频器。 它具有不同的变体以适应不同的场景。 RAVU 整体的性能消耗设计上比 mpv 内置的 ewa 系缩放器只略高。

### NNEDI3

全称 Neural Network Edge Directed Interpolation，是一种超高质量的插值放大算法。nnedi3 版速度较快（即便如此相比其它算法依旧速度极慢，开销巨大）

### SuperXBR

一个经典的整数倍放大算法，消耗介于 NNEDI3 和 RAVU 之间。

以上三项由同一开发者移植，在项目中提供了更多说明： [https://github.com/bjin/mpv-prescalers](https://github.com/bjin/mpv-prescalers)

r2 → r3 → r4； nns16 → nns32 → nns64 → nns128 → nns256；win8x4 → win8x6 质量更好但性能大增 

开发者的 **\compute** 文件夹内（需要的显卡支持的 OpenGL 版本≥4.3）的版本比 **\gather** 内的（OpenGL≥4.0）更快，后者比 **主目录 \master** 的更快 **\vulkan** 内的需要 **mpv.conf** 内配置为 --gpu-api=d3d11 或 vulkan --fbo-format=rgba16hf

-3x 变体直接放大三倍，适用于超低清源。 ravu-r 和 -3x 变体的训练模型为动漫， -lite 和 -zoom 变体为通用模型。

🔺 除了 -chroma 变体（启用将覆盖 **mpv.conf** 中指定的 --cscale=xxxxx 算法），其它只处理 (YUV)luma 通道（启用将覆盖 **mpv.conf** 中指定的 --scale=xxxxx 算法） 

🔺 -lite 变体最快最锐利但无半像素偏移，可能产生锯齿和晕轮 / 振铃。 -rgb 和 -yuv 变体在 --cscale 执行完之后开始作用，但 -yuv 无法处理 rgb 的源（例如 png 图片） 

🔺 关于半像素偏移，除了 -lite 和 -chroma 变体，其它 ravu 和 nnedi3 和 sxbr 中都存在。可以用 **mpv.conf** 中的 --scaler-resizes-only=no 修正它，但是没必要（感知不强）

🔺 sxbr 没有触发倍率限制； ravu-r 和 -lite 变体的最小缩放触发倍率约为 1.414， ravu-3x-r 变体最小缩放触发倍率约为 2.121。 -zoom 变体直接放大到目标分辨率，触发倍率＞1；nnedi3 最小缩放触发倍率约为 1.414，对性能要求极高且瞬时加载易假死，建议使用（条件）配置预载而不是 **input.conf** 中的热键切换触发， -nns64 级别以上的因速度极慢而很难即时观看时使用。

懒人包内精简并保留的部分列表（已统一修改后缀格式名为 glsl）： 

来自 _*\vulkan\compute*_ 

 `ravu-3x-r2.glsl` <br/> `ravu-3x-r2-rgb.glsl` <br/> `ravu-3x-r2-yuv.glsl` <br/> `ravu-3x-r3.glsl` <br/> `ravu-3x-r3-rgb.glsl` <br/> `ravu-3x-r3-yuv.glsl` <br/> `ravu-3x-r4.glsl` <br/> `ravu-3x-r4-rgb.glsl` <br/> `ravu-3x-r4-yuv.glsl` <br/> `ravu-lite-r2.glsl` <br/> `ravu-lite-r3.glsl` <br/> `ravu-lite-r4.glsl` <br/> `ravu-r2.glsl` <br/> `ravu-r2-rgb.glsl` <br/> `ravu-r2-yuv.glsl` <br/> `ravu-r3.glsl` <br/> `ravu-r3-rgb.glsl` <br/> `ravu-r3-yuv.glsl` <br/> `ravu-r4.glsl` <br/> `ravu-r4-rgb.glsl` <br/> `ravu-r4-yuv.glsl` <br/> `ravu-zoom-r2.glsl` <br/> `ravu-zoom-r2-chroma.glsl` <br/> `ravu-zoom-r2-rgb.glsl` <br/> `ravu-zoom-r2-yuv.glsl` <br/> `ravu-zoom-r3.glsl` <br/> `ravu-zoom-r3-chroma.glsl` <br/> `ravu-zoom-r3-rgb.glsl` <br/> `ravu-zoom-r3-yuv.glsl` <br/> `ravu-zoom-r4.glsl` <br/> `ravu-zoom-r4-chroma.glsl` <br/> `ravu-zoom-r4-rgb.glsl` <br/> `ravu-zoom-r4-yuv.glsl`

来自 _*\compute*_ 

 `nnedi3-nns16-win8x4.glsl` <br/> `nnedi3-nns16-win8x6.glsl` <br/> `nnedi3-nns32-win8x4.glsl` <br/> `nnedi3-nns32-win8x6.glsl` <br/> `nnedi3-nns64-win8x4.glsl` <br/> `nnedi3-nns64-win8x6.glsl` <br/> `nnedi3-nns128-win8x4.glsl` <br/> `nnedi3-nns128-win8x6.glsl` <br/> `nnedi3-nns256-win8x4.glsl` <br/> `nnedi3-nns256-win8x6.glsl`

来自 _**_ 

 `superxbr.glsl` <br/> `superxbr-rgb.glsl` <br/> `superxbr-yuv.glsl`

☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲

### AMD-FSR

   移植自AMD FidelityFX Super Resolution (FSR)，原始设计用于游戏，是一种先执行常规放大后再进行对比度自适应锐化的改良算法。放大部分基于lanczos+bilinear，锐化部分基于cas

   相关列表：https://gist.github.com/agyild/82219c545228d70c5604f865ce0b0ce5 & https://gist.github.com/agyild/bbb4e58298b2f86aa24da3032a0d2ee6

（变体  scaled  功能完整，附带了缩放模块而非纯粹的锐化算法）

`AMD-FSR.glsl` <br/>

相关列表：MOD

（变体  rgb  没有放大倍率的上限；变体  EASU  分离自fsr的放大模块，用作纯粹的放大算法）

`AMD-FSR_rgb.glsl` <br/>
`AMD-FSR-EASU_rgb.glsl` <br/>

☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲

### Noise Static

优化静态（亮度 / 色度）噪点。本版略作修改 来源：[https://pastebin.com/yacMe6EZ](https://pastebin.com/yacMe6EZ) & [https://pastebin.com/15ZTaaUC](https://pastebin.com/15ZTaaUC) 

🔺 需要 **mpv.conf** 中设置为 --deband-grain=0 的前提下使用

相关列表：

`noise_static_luma.glsl` <br/> `noise_static_chroma.glsl`

☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲☲

### 其它

相关列表：
```yaml
antiring.glsl                      -- 抗振铃（对EWA类放大算法生效，对外部着色器无效）
color-alt_luma.glsl                -- 色彩黑白翻转（亮度通道）
colorlevels.glsl                   -- 色彩范围调整
colorlevel_expand.glsl             -- 色彩范围扩展
colorlevel_expand_chroma.glsl      -- 色彩范围扩展（色度通道）
colorlevel_expand_luma.glsl        -- 色彩范围扩展（亮度通道）
colorlevel_shrink.glsl             -- 色彩范围收缩
colorlevel_shrink_chroma.glsl      -- 色彩范围收缩（色度通道）
colorlevel_shrink_luma.glsl        -- 色彩范围收缩（亮度通道）
minblur-usm.glsl                   -- 通用锐化，程度细微
unsharp.glsl                       -- 通用锐化，程度轻微
unsharp-masking_blur.glsl          -- 通用糊化，强度1.0
unsharp-masking_sharpen.glsl       -- 通用锐化，强度1.0
```
## 实际工作顺序

着色器按工作插入位置可分为 “预处理” 与“后处理”两类，此由着色器本身决定，无法被配置文件更改。（在统计信息的第二页可直观查看） 如图，以 combining planes 为分界——之前的步骤为预处理， --cscale=xxxxx 也在此处（图中被 krig 替换）。之后的步骤为后处理， --scale/dscale=xxxxx 也在此处。 ![](https://hooke007.github.io/mpv-lazy/IMG/[01]%20stats-01.webp)
   因此，着色器的实际工作顺序，首选遵守该原则，其次才是用户指定的顺序。（此外在预处理与后处理中也有顺序限制，具体请自行测试)

- 预处理 <br/>

  所有_luma、 _chroma变体   ACNet   FSRCNNX   AiU   Krig   RAVU   NNEDI3   SXBR   CAS   NoiseS   minblur-usm

- 后处理 <br/>

  所有-yuv、-rgb变体   A4k   SSDS   SSSR   Adaptive   colorlevel   unsharp   unsharp-masking

## 叠加放大类着色器的注意点

前文已经讲了着色器加载顺序上的一些逻辑，这里补充放大类着色器的专属问题。

不同的放大类着色器对 “源” 尺寸的影响不一样： 直觉认识里，1080p 的视频不管怎么拉伸，源的大小始终是 1080p。符合这一逻辑的只有：Anime4k 中带有 _Original_x2 的变体。反直觉的是，经过上一级着色器放大后的源大小变成了放大后的尺寸。遵守这一规则的有：Anime4k 中的其它放大变体; ACNet;FSRCNNX;AviSynth AiUpscale;RAVU;NNEDI3

例一：在 1440p 显示器上打开一个 1080p 视频全屏，此时你（只要性能足够）可以无限叠加 n 个 `Anime4K_Upscale_Original_x2.glsl` 无障碍实现 2^n 倍放大。

例二：同上的硬件环境，720p 的视频先调用了 nnedi3 再调用 fsrcnnx 进行二次放大，你可能发现无法真实触发后者，原因在于 720p 的视频经过 nnedi3 第一次放大后被后方加载的 fsrcnnx 认为源是 (720x2=)1440p，此时 2k 的显示器在全屏模式的分辨率并不满足 fsrcnnx 的最小放大触发倍率

## 快捷键动态启用

适用于 **input.conf** 语法结构： 

`按键(组合) change-list glsl-shaders (不带"-"的)后缀 着色器(组合)`

[https://mpv.io/manual/master/#string-list-and-path-list-options](https://mpv.io/manual/master/#string-list-and-path-list-options)

<table><thead><tr><th>可用后缀</th><th>说明（不推荐的语法可能在将来被弃用）</th></tr></thead><tbody><tr><td>-set</td><td>设置着色器列表为一个或多个着色器（使用 <code>;</code> 分隔多个着色器，使用 <code>\</code> 作为转义符）</td></tr><tr><td>-append</td><td>追加一个着色器到着色器列表的后方</td></tr><tr><td>-add</td><td>追加一个或多个着色器到着色器列表的后方 (同 <code>-set</code> 的注意点)</td></tr><tr><td>-pre</td><td>增加一个或多个着色器到着色器列表的前方 (同 <code>-set</code> 的注意点)</td></tr><tr><td>-clr</td><td>清空着色器列表</td></tr><tr><td>-remove</td><td>移除一个列表中已存在的着色器</td></tr><tr><td>-del</td><td>移除一个或多个列表中已存在的着色器（不推荐）</td></tr><tr><td>-toggle</td><td>追加一个着色器到着色器列表的后方，如果已存在则移除它</td></tr></tbody></table>

支持使用 mpv 的相对路径（比如 `~~/` 指向主设置文件夹） 例如：

```yaml
CTRL+1 change-list glsl-shaders set "~~/shaders/KrigBilateral.glsl;~~/shaders/ravu-zoom-r3.glsl;~~/shaders/cas_luma.glsl"
```

其它示例参考懒人包内的 **input.conf** 即可。

## 速度的对比参考

🔺 （信息可能已过时）

使用个别着色器进行 2x 放大，计算每秒所能生成的最大帧数。数据可能过时，数值越大说明速度越快，越适合实际观看时使用，数值低于视频原始帧率即完全不可用。 

实际速度**极大**取决于视频的质量、缩放倍率和你的显卡性能，因此两表中同一个 fsrcnnx16 的性能差异不符合常理也不要奇怪，数据仅供大概参考。

_数据来源 GitHub@Alexkral(NVIDIA GTX 1080)_

<table><thead><tr><th>着 色 器</th><th>mpv_2x : 1080p → 2160p</th></tr></thead><tbody><tr><td>A4k M</td><td>407</td></tr><tr><td>A4k L</td><td>287</td></tr><tr><td>FSRCNNX 8</td><td>256</td></tr><tr><td>AiU Fast</td><td>145</td></tr><tr><td>FSRCNNX 16</td><td>93</td></tr><tr><td>A4k UL</td><td>75</td></tr><tr><td>AiU M</td><td>51</td></tr><tr><td>AiU HQ</td><td>26</td></tr></tbody></table>

_数据来源 GitHub@Artoriuz_

<table><thead><tr><th>算法 &amp; 着色器</th><th>mpv_2x : 720p → 1440p</th></tr></thead><tbody><tr><td>bilinear</td><td>468</td></tr><tr><td>spline36</td><td>383</td></tr><tr><td>ewa_lanczossharp</td><td>338</td></tr><tr><td>RAVU lite r4</td><td>307</td></tr><tr><td>RAVU r4</td><td>238</td></tr><tr><td>NNEDI3 16 8x4</td><td>210</td></tr><tr><td>SSSR</td><td>169</td></tr><tr><td>NNEDI3 32 8x4</td><td>156</td></tr><tr><td>RAVU zoom r4</td><td>138</td></tr><tr><td>NNEDI3 64 8x4</td><td>99</td></tr><tr><td>NNEDI3 128 8x4</td><td>55</td></tr><tr><td>FSRCNNX 16</td><td>52</td></tr><tr><td>NNEDI3 256 8x4</td><td>30</td></tr></tbody></table>

## 附录

### Anime4k v3-v3.1

这里是旧版 a4k 的说明。 旧版工作在 luma 通道，新版工作在 RGB 空间。 RA Upscale+Deblur_CNN Deblur_CNN 这些变体在 v4 中合并在 Restore 模块中 

🔺 新旧版本的模块混用可能产生 bug

M → L → UL 性能要求逐渐提高，处理结果越好 多种模块组合使用的大致顺序推荐：降噪 → 去模糊 → 加深线条 → 细化线条 → 放大（→ 额外 → 二次放大）→ 抗重采样伪影 文件数量众多，完整详情直接见文档 [https://github.com/bloc97/Anime4K/wiki](https://github.com/bloc97/Anime4K/wiki)

去模糊系列：图像尺寸保持不变，以超分辨率的方式进行去模糊。 副作用： CNN_M  和 CNN_L 变体可能引入棋盘伪影 开发者推荐模块为 **Anime4K_Deblur_DoG.glsl** 相关列表：         

 `Anime4K_Deblur_DoG.glsl` <br/> `Anime4K_Deblur_Original.glsl` <br/> `Anime4K_Deblur_CNN_M.glsl` <br/> `Anime4K_Deblur_CNN_L.glsl`

降噪系列：Mean → Mode → Median → Heavy 速度逐渐变慢。 副作用： Mean 可能引入模糊， Mode 可能引入锯齿， Median 可能引入色带伪影 开发者推荐模块为 **Anime4K_Denoise_Bilateral_Mode.glsl** 相关列表：

 `Anime4K_Denoise_Bilateral_Mode.glsl` <br/> `Anime4K_Denoise_Bilateral_Median.glsl` <br/> `Anime4K_Denoise_Bilateral_Mean.glsl` <br/> `Anime4K_Denoise_Heavy_CNN_L.glsl`

线条加深系列：使线条更暗，增加感知对比度。 副作用：对线条的误识别可能引起细小图形变暗。 Fast 和 VeryFast 变体虽然显著提升速度但牺牲了细节质量 开发者推荐模块为 **Anime4K_DarkLines_HQ.glsl** 相关列表：

 `Anime4K_DarkLines_VeryFast.glsl` <br/> `Anime4K_DarkLines_Fast.glsl` <br/> `Anime4K_DarkLines_HQ.glsl`

线条细化系列：特别适合老旧动漫 副作用：细节变糊。对线条的误识别可能引起细小图形变形。 Fast 和 VeryFast 变体的问题参考同前。在高分辨率源（≥1440p）上 HQ 变体速度可能过慢。 开发者推荐模块为 **Anime4K_ThinLines_HQ.glsl** 相关列表：

 `Anime4K_ThinLines_VeryFast.glsl` <br/> `Anime4K_ThinLines_Fast.glsl` <br/> `Anime4K_ThinLines_HQ.glsl`

线条重建系列：（v4 版 Restore 模块的预览版） 个人推荐模块为 **Anime4K_Line_Reconstruction_Heavy_L.glsl** 相关列表：

 `Anime4K_DeRing.glsl` <br/> `Anime4K_Line_Reconstruction_Light_L.glsl` <br/> `Anime4K_Line_Reconstruction_Medium_L.glsl` <br/> `Anime4K_Line_Reconstruction_Heavy_L.glsl`

抗重采样伪影系列：尝试减少由非线性重采样引起的重采样伪影（振铃 / 锯齿） 高分辨率源（≥1080p）使用 DoG 变体可在不影响质量前提下显著提升速度

副作用： CNN_M 和 CNN_L 变体的问题参考同前。 相关列表： 

`Anime4K_RA_CNN_M.glsl` <br/> `Anime4K_RA_CNN_L.glsl` <br/> `Anime4K_RA_CNN_UL.glsl` <br/> `Anime4K_RA_DoG.glsl`

放大（混合）系列：不同变体组合可执行 x4 甚至 x8 倍放大。

 🔺 启用将覆盖 **mpv.conf** 中指定的 --scale=xxxxx 算法 

🔺 CNN 和 DoG_x2 变体最小缩放触发倍率为 1.2， DTD_x2 和 Original_x2 变体无限制条件但即使缩小也工作 (bug?)

其中 DTD 即 Darken-Thin-Deblur 三个着色组合成，通过使线条变暗，细化然后去模糊来提升源图像中线条的感知质量。也可以通过 Anime4K_DarkLines + Anime4K_ThinLines + (Anime4K_Deblur or Anime4K_Upscale_Deblur) 自行组合拼接 DoG_x2 和 Original_x2 变体在高分辨率源（≥1080p）不影响质量前提下显著提升速度。

副作用： CNN 虽然质量好但速度较慢。 CNN_M 和 CNN_L 变体的问题参考同前。注意组合顺序，当此类着色器先执行 x2 图像放大后，之后放置的其他着色器执行速度慢至少 4 倍。 相关列表： 

 `Anime4K_Upscale_CNN_M_x2.glsl` <br/> `Anime4K_Upscale_CNN_L_x2.glsl` <br/> `Anime4K_Upscale_CNN_UL_x2.glsl` <br/> `Anime4K_Upscale_DTD_x2.glsl` <br/> `Anime4K_Upscale_DoG_x2.glsl` <br/> `Anime4K_Upscale_Original_x2.glsl` 

放大为主的混合列表：

 `Anime4K_Upscale_CNN_M_x2_Deblur.glsl` <br/> `Anime4K_Upscale_CNN_M_x2_Denoise.glsl` <br/> `Anime4K_Upscale_CNN_L_x2_Deblur.glsl` <br/> `Anime4K_Upscale_CNN_L_x2_Denoise.glsl` <br/> `Anime4K_Upscale_CNN_UL_x2_Deblur.glsl` <br/> `Anime4K_Upscale_CNN_UL_x2_Denoise.glsl` <br/> `Anime4K_Upscale_DoG_x2_Deblur.glsl` <br/> `Anime4K_Upscale_Original_x2_Deblur_x2.glsl`

额外：可用于 1440p/4K 监视器的第一次和第二次放大，缩小中间图像的比例，以便第二次放大过程不会超出屏幕大小并浪费处理能力

 `Anime4K_Auto_Downscale_Pre_x4.glsl`

