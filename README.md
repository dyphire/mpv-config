MPV config

本项目为 windows 下[mpv 播放器](https://github.com/mpv-player/mpv)的配置文件，应放入`mpv.exe`所在目录下的`portable_config`文件夹内，

或 mpv 配置默认路径`C:/Users/你的用户名/AppData/Roaming/mpv/`下，这种方式全局生效。`portable_config`优先级最高，会覆盖这种全局配置方案。

PS：自行编辑配置文件时，注意编码格式应为 UTF-8，换行符为 Unix，否则 MPV 可能无法识别

- 目前 mpv 没有官方发布的客户端，官网上有放一些推荐的第三方编译版：[https://mpv.io/installation](https://mpv.io/installation)
  - windows 上推荐使用 shinchiro 版： [shinchiro__mpv](https://sourceforge.net/projects/mpv-player-windows/files/64bit/)
- 目前比较成熟的 mpv/libmpv 前端推荐 ： [mpv.net](https://github.com/stax76/mpv.net)，其汉化版： [mpv.net_CM](https://github.com/hooke007/mpv.net_CM)
  - 个人 mpv.net 配置文件参考：https://github.com/dyphire/MPV-own/tree/mpvnet 
-   浏览器调用 mpv 播放的方法推荐：[mpv-handler](https://github.com/akiirui/mpv-handler) 配合脚本 [play-with-mpv](https://greasyfork.org/zh-CN/scripts/416271-play-with-mpv)


参考：

* [mpv 原版官方的开发版手册（英文）](https://mpv.io/manual/master/)
* [hooke007 配置手册](https://hooke007.github.io/mpv-lazy/mpv.html)

