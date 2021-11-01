**MPV config**

本项目为 windows 下 [mpv](https://github.com/mpv-player/mpv) 播放器的配置文件，应放入`mpv.exe`所在目录的`portable_config`文件夹内，

或 mpv 配置默认路径`%APPDATA%/mpv/`下，这种方式全局生效。

使用`portable_config`时会覆盖全局配置方案。

PS：自行编辑配置文件时，注意编码格式应为 UTF-8，换行符为 Unix，否则 MPV 可能无法识别

- 目前 mpv 没有官方发布的客户端，官网上有放一些推荐的第三方编译版：[https://mpv.io/installation](https://mpv.io/installation)
  - windows 上推荐使用 shinchiro 版： [shinchiro_mpv](https://sourceforge.net/projects/mpv-player-windows/files/64bit/)
  - 使用 Github Action 编译版：[zhongfly_mpv](https://github.com/zhongfly/mpv-build) [![releases](https://img.shields.io/github/v/release/zhongfly/mpv-build)](https://github.com/zhongfly/mpv-build/releases); [eko5624_mpv](https://github.com/eko5624/mpv-win64)
  - 基于个人修改的 [libass](https://github.com/dyphire/libass/tree/dev) 编译版：[dyphire_mpv](https://github.com/dyphire/mpv-winbuild) [![releases](https://img.shields.io/github/v/release/dyphire/mpv-winbuild)](https://github.com/dyphire/mpv-winbuild/releases)
    -  修复 libass 在 ass 字幕脚本比例和视频比例不匹配时导致的 PlayResX 缩放错误的问题
    -  仍有其他标签缩放比例问题待解决
- 目前比较成熟的 mpv/libmpv 前端推荐 ： [mpv.net](https://github.com/stax76/mpv.net) [![mpv.net](https://flat.badgen.net/github/last-commit/stax76/mpv.net?scale=1.0&cache=1800)](https://github.com/stax76/mpv.net) [![releases](https://img.shields.io/github/v/release/stax76/mpv.net)](https://github.com/stax76/mpv.net/releases)
	- 其汉化版： [mpv.net_CM](https://github.com/hooke007/mpv.net_CM) [![releases](https://img.shields.io/github/v/release/hooke007/mpv.net_CM)](https://github.com/hooke007/mpv.net_CM/releases)
	- 个人 Github Action 编译版: [mpv.net](https://github.com/dyphire/mpv.net) 
		- 实现自动 fork 上游更新并自动编译 mpvnet.exe 等组件，main 分支为汉化版
		- 下载更新见 [Action](https://github.com/dyphire/mpv.net/actions/workflows/mpvnet-build.yml) ，自行替换相应文件即可
	- 个人 mpv.net 配置文件参考：https://github.com/dyphire/MPV-own/tree/mpvnet 
-   浏览器调用 mpv 播放的方法推荐：[mpv-handler](https://github.com/akiirui/mpv-handler) 配合脚本 [play-with-mpv](https://greasyfork.org/zh-CN/scripts/416271-play-with-mpv)


参考：

* [mpv 原版官方的开发版手册（英文）](https://mpv.io/manual/master/)
* [hooke007 配置手册](https://hooke007.github.io/mpv-lazy/mpv.html)

