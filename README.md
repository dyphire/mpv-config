**MPV config**

本项目为 windows 下 [mpv](https://github.com/mpv-player/mpv) 播放器的配置文件，应放入`mpv.exe`所在目录的`portable_config`文件夹内，

或 mpv 配置默认路径`%APPDATA%/mpv/`下，这种方式全局生效。

使用`portable_config`时会覆盖全局配置方案。

PS：自行编辑配置文件时，注意编码格式应为 UTF-8，换行符为 Unix，否则 MPV 可能无法识别

**mpv整合包下载**：[Releases](https://github.com/dyphire/mpv-config/releases)

- 目前 mpv 没有官方发布的客户端，官网上有放一些推荐的第三方编译版：[https://mpv.io/installation](https://mpv.io/installation)
  - windows 上推荐使用 shinchiro 版： [shinchiro_mpv](https://github.com/shinchiro/mpv-winbuild-cmake/releases) ![releases](https://img.shields.io/github/v/release/shinchiro/mpv-winbuild-cmake)
  - 每日构建版：[zhongfly_mpv](https://github.com/zhongfly/mpv-winbuild) [![releases](https://img.shields.io/github/v/release/zhongfly/mpv-winbuild)](https://github.com/zhongfly/mpv-winbuild/releases)
  - 基于个人修改版 [mpv](https://github.com/dyphire/mpv/tree/patch) 构建版：[dyphire_mpv](https://github.com/dyphire/mpv-winbuild) [![releases](https://img.shields.io/github/v/release/dyphire/mpv-winbuild)](https://github.com/dyphire/mpv-winbuild/releases)
    -  [修改版 mpv 相关说明](https://github.com/dyphire/mpv-config/discussions/7)
- ~~目前比较成熟的 mpv/libmpv 前端推荐 ： [mpv.net](https://github.com/mpvnet-player/mpv.net) [![mpv.net](https://flat.badgen.net/github/last-commit/mpvnet-player/mpv.net?scale=1.0&cache=1800)](https://github.com/mpvnet-player/mpv.net) [![releases](https://img.shields.io/github/v/release/mpvnet-player/mpv.net)](https://github.com/mpvnet-player/mpv.net/releases)~~
	- ~~其汉化版： [mpv.net_CM](https://github.com/hooke007/mpv.net_CM) [![releases](https://img.shields.io/github/v/release/hooke007/mpv.net_CM)](https://github.com/hooke007/mpv.net_CM/releases)~~
	- ~~个人 Github Action 编译版: [mpv.net](https://github.com/dyphire/mpv.net) [![releases](https://img.shields.io/github/v/release/dyphire/mpv.net)](https://github.com/dyphire/mpv.net/releases)~~
	  - ~~实现自动 fork 上游更新并自动编译 mpvnet.exe 等组件~~
	  - ~~main 分支为汉化版~~
	  - ~~下载：[mpv.net/releases](https://github.com/dyphire/mpv.net/releases) ，后续小版本更新见 [Actions](https://github.com/dyphire/mpv.net/actions/workflows/mpvnet-build.yml) ，自行替换相应文件即可~~
	- ~~个人 mpv.net 配置文件参考：https://github.com/dyphire/mpv-config/tree/mpvnet~~
	- mpv.net 说明：上游停止开发，不再维护。个人修改版就此归档
-   浏览器调用 mpv 播放的方法推荐
	- [mpv-handler](https://github.com/akiirui/mpv-handler) 配合脚本 [play-with-mpv](https://greasyfork.org/zh-CN/scripts/416271-play-with-mpv)
	- [Play-With-MPV](https://github.com/LuckyPuppy514/Play-With-MPV)


参考：

* [hooke007 配置手册](https://hooke007.github.io/mpv-lazy/mpv.html)
* [mpv 原版官方的开发版手册（英文）](https://mpv.io/manual/master/)
* [mpv 官方文档的汉化版-hooke007](https://github.com/hooke007/mpv_doc-CN)
