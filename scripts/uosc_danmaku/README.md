# uosc_danmaku

在MPV播放器中加载弹弹play弹幕，基于 uosc UI框架和弹弹play API的mpv弹幕扩展插件

> [!WARNING]
> Release1.2.0及Release1.2.0之前的发行版，都由于弹弹play接口使用政策改版，部分功能无法使用。如果发现插件功能异常，比如搜索弹幕总是显示无结果，请拉取或下载主分支最新源代码；或下载[最新发行版](https://github.com/Tony15246/uosc_danmaku/releases/latest)

> [!NOTE]
> 已添加对mpv内部 `mp.input`的支持，在uosc不可用时通过键绑定调用此方式渲染菜单
>
> 欲启用此支持mpv最低版本要求：0.39.0

## 项目简介

插件具体效果见演示视频：

<video width="902" src="https://github.com/user-attachments/assets/86717e75-9176-4f1a-88cd-71fa94da0c0e">
</video>

在未安装uosc框架时，调用mpv内部的 `mp.input`进行菜单渲染，具体效果见[此pr](https://github.com/Tony15246/uosc_danmaku/pull/24)

### 主要功能

<details open>

1. 从弹弹play或自定义服务的API获取剧集及弹幕数据，并根据用户选择的集数加载弹幕
2. 通过点击uosc control bar中的弹幕搜索按钮可以显示搜索菜单供用户选择需要的弹幕
3. 通过点击加入uosc control bar中的弹幕开关控件可以控制弹幕的开关
4. 通过点击加入uosc control bar中的[从源获取弹幕](#从弹幕源向当前弹幕添加新弹幕内容可选)按钮可以通过受支持的网络源或本地文件添加弹幕
5. 通过点击加入uosc control bar中的[弹幕样式](#实时修改弹幕样式可选)按钮可以打开uosc弹幕样式菜单供用户在视频播放时实时修改弹幕样式（注意⚠️：未安装uosc框架时该功能不可用）
6. 通过点击加入uosc control bar中的[弹幕设置](#弹幕设置总菜单可选)按钮可以打开多级功能复合菜单，包含了插件目前所有的图形化功能。
7. 通过点击加入uosc control bar中的[弹幕源延迟设置](#弹幕源延迟设置可选)按钮可以打开弹幕源延迟控制菜单，可以独立控制每个弹幕源的延迟（注意⚠️：未安装uosc框架时该功能不可用）
8. 记忆型全自动弹幕填装，在为某个文件夹下的某一集番剧加载过一次弹幕后，加载过的弹幕会自动关联到该集；之后每次重新播放该文件就会自动加载弹幕，同时该文件对应的文件夹下的所有其他集数的文件都会在播放时自动加载弹幕，无需再重复手动输入番剧名进行搜索（注意⚠️：全自动弹幕填装默认关闭，如需开启请阅读[auto_load配置项说明](#auto_load)）
9. 在没有手动加载过弹幕，没有填装自动弹幕记忆之前，通过文件哈希匹配的方式自动添加弹幕（~仅限本地文件~，现已支持网络视频），对于能够哈希匹配关联的文件不再需要手动搜索关联，实现全自动加载弹幕并添加记忆。该功能随记忆型全自动弹幕填装功能一起开启（哈希匹配自动加载准确率较低，如关联到错误的剧集请手动加载正确的剧集）

   > 哈希匹配功能需要 mpv 基于 LuaJIT 或 Lua 5.2 构建，不支持 Lua 5.1
   >
10. 通过打开配置项load_more_danmaku可以爬取所有可用弹幕源，获取更多弹幕（注意⚠️：爬取所有可用弹幕源默认关闭，如需开启请阅读[load_more_danmaku配置项说明](#load_more_danmaku)）
11. 自动记忆弹幕开关情况，播放视频时保持上次关闭时的弹幕开关状态
12. 自定义默认播放弹幕样式（具体设置方法详见[自定义弹幕样式](#自定义弹幕样式相关配置)）
13. 在使用如[Play-With-MPV](https://github.com/LuckyPuppy514/Play-With-MPV)或[ff2mpv](https://github.com/woodruffw/ff2mpv)等网络播放手段时，自动加载弹幕（注意⚠️：目前支持自动加载bilibili和巴哈姆特这两个网站的弹幕，具体说明查看[autoload_for_url配置项说明](#autoload_for_url)）
14. 保存当前弹幕到本地（详细功能说明见[save_danmaku配置项说明](#save_danmaku)）
15. 可以合并一定时间段内同时出现的大量重复弹幕（具体设置方法详见[merge_tolerance配置项说明](#merge_tolerance)）
16. 弹幕简体字繁体字转换，解决弹幕简繁混杂问题（具体设置方法详见[chConvert配置项说明](#chConvert)）
17. 自定义插件相关提示的显示位置，可以自由调节距离画面左上角的两个维度的距离（具体设置方法详见[message_x配置项说明](#message_x)和[message_y配置项说明](#message_y)）

无需亲自下载整合弹幕文件资源，无需亲自处理文件格式转换，在mpv播放器中一键加载包含了哔哩哔哩、巴哈姆特等弹幕网站弹幕的弹弹play的动画弹幕。

插件本身支持Linux和Windows平台。项目依赖于[uosc UI框架](https://github.com/tomasklaen/uosc)。欲使用本插件强烈建议为mpv播放器中安装uosc。uosc的安装步骤可以参考其[官方安装教程](https://github.com/tomasklaen/uosc?tab=readme-ov-file#install)。当然，如果使用[MPV_lazy](https://github.com/hooke007/MPV_lazy)等内置了uosc的懒人包则只需安装本插件即可。

</details>

## 安装

### 下载

一般的mpv配置目录结构大致如下

```
~/.config/mpv
├── fonts
├── input.conf
├── mplayer-input.conf
├── mpv.conf
├── script-opts
└── scripts
```

想要使用本插件，请将本插件完整地[下载](https://github.com/Tony15246/uosc_danmaku/releases)或者克隆到 `scripts`目录下即可使用，文件结构参阅下方

> [!IMPORTANT]
>
> 1. scripts目录下放置本插件的文件夹名称必须为uosc_danmaku，否则必须参照uosc控件配置部分[修改uosc控件](#修改uosc控件可选)
> 2. 记得给bin文件夹下的文件赋予可执行权限

<details>
<summary>文件结构</summary>

```
~/.config/mpv/scripts
└── uosc_danmaku
    ├── apis
    │   ├── dandanplay.lua
    │   └── extra.lua
    ├── LICENSE
    ├── main.lua
    ├── modules
    │   ├── base64.lua
    │   ├── guess.lua
    │   ├── md5.lua
    │   ├── menu.lua
    │   ├── options.lua
    │   ├── render.lua
    │   └── utils.lua
    └── README.md
```

</details>

## 基本配置

#### uosc控件配置

这一步非常重要，不添加控件，弹幕搜索按钮和弹幕开关就不会显示在进度条上方的控件条中。若没有控件，则只能通过[绑定快捷键](#绑定快捷键可选)调用弹幕搜索和弹幕开关功能

想要添加uosc控件，需要修改mpv配置文件夹下的 `script-opts`中的 `uosc.conf`文件。如果已经安装了uosc，但是 `script-opts`文件夹下没有 `uosc.conf`文件，可以去[uosc项目地址](https://github.com/tomasklaen/uosc)下载官方的 `uosc.conf`文件，并按照后面的配置步骤进行配置。

由于uosc最近才更新了部分接口和控件代码，导致老旧版本的uosc和新版的uosc配置有所不同。如果是下载的最新git版uosc或者一直保持更新的用户按照 `最新版uosc的控件配置步骤` 配置即可。如果不确定自己的uosc版本，或者在使用诸如[MPV_lazy](https://github.com/hooke007/MPV_lazy)等由第三方管理uosc版本的用户，可以按照兼容新版和旧版uosc的 `旧版uosc控件配置步骤` 配置。

<details>
<summary>最新版uosc的控件配置步骤</summary>

找到 `uosc.conf`文件中的 `controls`配置项，uosc官方默认的配置可能如下：

```
controls=menu,gap,subtitles,<has_many_audio>audio,<has_many_video>video,<has_many_edition>editions,<stream>stream-quality,gap,space,speed,space,shuffle,loop-playlist,loop-file,gap,prev,items,next,gap,fullscreen
```

在 `controls`控件配置项中添加 `button:danmaku`的弹幕搜索按钮和 `cycle:toggle_on:show_danmaku@uosc_danmaku:on=toggle_on/off=toggle_off?弹幕开关`的弹幕开关。放置的位置就是实际会在在进度条上方的控件条中显示的位置，可以放在自己喜欢的位置。我个人把这两个控件放在了 `<stream>stream-quality`画质选择控件后边。添加完控件的配置大概如下：

```
controls=menu,gap,subtitles,<has_many_audio>audio,<has_many_video>video,<has_many_edition>editions,<stream>stream-quality,button:danmaku,cycle:toggle_on:show_danmaku@uosc_danmaku:on=toggle_on/off=toggle_off?弹幕开关,gap,space,speed,space,shuffle,loop-playlist,loop-file,gap,prev,items,next,gap,fullscreen
```

</details>

<details>
<summary>旧版uosc控件配置步骤</summary>

找到 `uosc.conf`文件中的 `controls`配置项，uosc官方默认的配置可能如下：

```
controls=menu,gap,subtitles,<has_many_audio>audio,<has_many_video>video,<has_many_edition>editions,<stream>stream-quality,gap,space,speed,space,shuffle,loop-playlist,loop-file,gap,prev,items,next,gap,fullscreen
```

在 `controls`控件配置项中添加 `command:search:script-message open_search_danmaku_menu?搜索弹幕`的弹幕搜索按钮和 `cycle:toggle_on:show_danmaku@uosc_danmaku:on=toggle_on/off=toggle_off?弹幕开关`的弹幕开关。放置的位置就是实际会在在进度条上方的控件条中显示的位置，可以放在自己喜欢的位置。我个人把这两个控件放在了 `<stream>stream-quality`画质选择控件后边。添加完控件的配置大概如下：

```
controls=menu,gap,subtitles,<has_many_audio>audio,<has_many_video>video,<has_many_edition>editions,<stream>stream-quality,command:search:script-message open_search_danmaku_menu?搜索弹幕,cycle:toggle_on:show_danmaku@uosc_danmaku:on=toggle_on/off=toggle_off?弹幕开关,gap,space,speed,space,shuffle,loop-playlist,loop-file,gap,prev,items,next,gap,fullscreen
```

</details>

<details>
<summary>修改uosc控件（可选）</summary>

如果出于重名等各种原因，无法将本插件所放置的文件夹命名为 `uosc_danmaku`的话，需要修改 `cycle:toggle_on:show_danmaku@uosc_danmaku:on=toggle_on/off=toggle_off?弹幕开关`的弹幕开关配置中的 `uosc_danmaku`为放置本插件的文件夹的名称。假如将本插件放置在 `my_folder`文件夹下，那么弹幕开关配置就要修改为 `cycle:toggle_on:show_danmaku@my_folder:on=toggle_on/off=toggle_off?弹幕开关`

</details>

#### 绑定快捷键（可选）

对于坚定的键盘爱好者和不使用鼠标主义者，可以选择通过快捷键调用弹幕搜索和弹幕开关功能

快捷键已经进行了默认绑定。默认情况下弹幕搜索功能绑定“Ctrl+d”；弹幕开关功能绑定“j”

弹幕搜索功能绑定的脚本消息为 `open_search_danmaku_menu`，弹幕开关功能绑定的脚本消息为 `show_danmaku_keyboard`

如需配置快捷键，只需在 `input.conf`中添加如下行即可，快捷键可以改为自己喜欢的按键组合。

```
Ctrl+d script-message open_search_danmaku_menu
j script-message show_danmaku_keyboard
```

> 根据[此issue中的需求](https://github.com/Tony15246/uosc_danmaku/issues/6)，添加了通过uosc_danmaku.conf绑定快捷键的功能。（请注意，最高优先级仍然是input.conf中设置的快捷键）
> 想要在uosc_danmaku.conf中自定义快捷键，可以像下面这样更改默认快捷键。

```
open_search_danmaku_menu_key=Ctrl+i
show_danmaku_keyboard_key=i
```

## 拓展功能（可选）

本插件针对弹幕有全方面的拓展功能

---

**带控件的功能**

<details>
<summary>从弹幕源向当前弹幕添加新弹幕内容（从网络url或本地添加弹幕）</summary>

> #### 从弹幕源向当前弹幕添加新弹幕内容（可选）

从弹幕源添加弹幕。在已经在播放弹幕的情况下会将添加的弹幕追加到现有弹幕中。

可添加的弹幕源如哔哩哔哩上任意视频通过video路径加BV号，或者巴哈姆特上的视频地址等。比如说以下地址均可作为有效弹幕源被添加：

```
https://www.bilibili.com/video/BV1kx411o7Yo
https://ani.gamer.com.tw/animeVideo.php?sn=36843
```

此功能通过调用弹弹Play的extcomment接口实现获取第三方弹幕站（如A/B/C站）上指定网址对应的弹幕。想要启用此功能，需要参照[uosc控件配置](#uosc控件配置)，根据uosc版本添加 `button:danmaku_source`或 `command:add_box:script-message open_add_source_menu?从源添加弹幕`到 `uosc.conf`的controls配置项中。

想要通过快捷键使用此功能，请添加类似下面的配置到 `input.conf`中。从源添加弹幕功能对应的脚本消息为 `open_add_source_menu`。

```
key script-message open_add_source_menu
```

现已添加了对加载本地弹幕文件的支持，输入本地弹幕文件的绝对路径即可使用本插件加载弹幕。加载出来的弹幕样式同在本插件中设置的弹幕样式。支持的文件格式有ass文件和xml文件。具体可参见[此issue](https://github.com/Tony15246/uosc_danmaku/issues/26)

```
#Linux下示例
/home/tony/Downloads/example.xml
#Windows下示例
C:\Users\Tony\Downloads\example.xml
```

现已更新增强了此菜单。现在在该菜单内可以可视化地控制所有弹幕源，删除或者屏蔽任何不想要的弹幕源。对于自己手动添加的弹幕源，可以进行移除。对于来自弹弹play的弹幕源，无法进行移除，但是可以进行屏蔽，将不会再从屏蔽过的弹幕源获取弹幕。当然，也可以解除对来自弹弹play的弹幕源的屏蔽。另外需要注意在菜单内对于弹幕源的可视化操作都需要下次打开视频，或者重新用弹幕搜索功能加载一次弹幕才会生效。

</details>

<details>
<summary>弹幕源延迟设置</summary>

> #### 弹幕源延迟设置（可选）

可以独立控制每个弹幕源的延迟，延迟支持两种输入模式。第一种模式为输入数字（最高可精确到小数点后两位），单位为秒；第二种输入模式为输入形如 `14m15s`格式的字符串，代表延迟的分钟数和秒数。

想要启用此功能，需要参照[uosc控件配置](#uosc控件配置)，根据uosc版本添加 `button:danmaku_delay`或 `command:more_time:script-message open_source_delay_menu?弹幕源延迟设置`到 `uosc.conf`的controls配置项中。

想要通过快捷键使用此功能，请添加类似下面的配置到 `input.conf`中。弹幕源延迟设置功能对应的脚本消息为 `open_source_delay_menu`。

```
key script-message open_source_delay_menu
```

</details>

<details>
<summary> 实时修改弹幕样式</summary>

> #### 实时修改弹幕样式（可选）

依赖于[uosc UI框架](https://github.com/tomasklaen/uosc)实现**弹幕样式实时修改**，将打开弹幕样式修改图形化菜单供用户手动修改，该功能目前仅依靠 uosc 实现（uosc不可用时无法使用此功能，并默认使用[自定义弹幕样式](#自定义弹幕样式相关配置)里的样式配置）。想要启用此功能，需要参照[uosc控件配置](#uosc控件配置)，根据uosc版本添加 `button:danmaku_styles`或 `command:palette:script-message open_setup_danmaku_menu?弹幕样式`到 `uosc.conf`的controls配置项中。

想要通过快捷键使用此功能，请添加类似下面的配置到 `input.conf`中。实时修改弹幕样式功能对应的脚本消息为 `open_setup_danmaku_menu`。

```
key script-message open_setup_danmaku_menu
```

</details>

<details>
<summary> 弹幕设置总菜单</summary>

> #### 弹幕设置总菜单（可选）

打开多级功能复合菜单，包含了插件目前所有的图形化功能。想要启用此功能，需要参照[uosc控件配置](#uosc控件配置)，根据uosc版本添加 `button:danmaku_menu`或 `command:grid_view:script-message open_add_total_menu?弹幕设置`到 `uosc.conf`的controls配置项中。

想要通过快捷键使用此功能，请添加类似下面的配置到 `input.conf`中。从源添加弹幕功能对应的脚本消息为 `open_add_total_menu`。

```
key script-message open_add_total_menu
```

</details>

---

**仅快捷键的功能**

<details>
<summary>设置弹幕延迟</summary>

> #### 设置弹幕延迟（可选）

可以通过快捷键绑定以下命令来调整弹幕延迟，单位：秒。秒数的含义为在当前弹幕延迟的基础上叠加新设置的延迟秒数进行调整，可以设置为负数。另外，设置为0时为特殊情况，会将弹幕延迟重置为0，回到初始状态。

```
# 设置整体弹幕延迟
key script-message danmaku-delay <seconds>
# 设置当前播放时间点的弹幕延迟
key script-message danmaku-delay <seconds> ${=time-pos}
```

> 当前弹幕延迟的值可以从 `user-data/uosc_danmaku/danmaku-delay`属性中获取到，具体用法可以参考[此issue](https://github.com/Tony15246/uosc_danmaku/issues/77)

</details>

<details>
<summary>保存当前视频弹幕</summary>

> #### 保存当前视频弹幕（可选）

在视频播放时手动保存弹幕至视频所在文件夹，保存格式为 `xml`（注：此功能将保存为视频同名弹幕，若视频文件夹下存在同名文件将不会执行该功能）

想要通过快捷键使用此功能，请添加类似下面的配置到 `input.conf`中。从源添加弹幕功能对应的脚本消息为 `immediately_save_danmaku`。

```
key script-message immediately_save_danmaku
```

</details>

<details>
<summary>清空当前视频关联的弹幕源</summary>

> #### 清空当前视频关联的弹幕源（可选）

可以清空当前视频中，用户通过[从源获取弹幕](#从弹幕源向当前弹幕添加新弹幕内容可选)菜单手动添加的所有弹幕源（注意该功能不会删除来源于弹幕服务器的弹幕，此类弹幕只能屏蔽或者手动重新匹配新弹幕库）。清空过弹幕源之后，下次播放该视频，就不会再加载之前手动添加过的弹幕源，可以重新添加弹幕源。

想要通过快捷键使用此功能，请添加类似下面的配置到 `input.conf`中。从源添加弹幕功能对应的脚本消息为 `clear-source`。

```
key script-message clear-source
```

</details>

<details>
<summary>检查脚本更新</summary>

> #### 检查脚本更新（可选）

可以通过绑定以下脚本命令来实现检查并自动更新脚本

> 只会检查 `Releases`中发布的更新

```
key script-message check-update
```

</details>

---

## 可配置选项（可选）

本插件可以在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件自定义下例配置开启额外功能或自定义功能细节

### 弹幕加载相关

<!--  下列是弹幕加载相关  -->

<details>
<summary>
load_more_danmaku

> 开关全量弹幕源加载

</summary>

### load_more_danmaku

#### 功能说明

由于弹弹Play默认对于弹幕较多的番剧加载并且整合弹幕的上限大约每集7000条，而这7000条弹幕也不是均匀分配，例如有时弹幕基本只来自于哔哩哔哩，有时弹幕又只来自于巴哈姆特。这样的话弹幕观看体验就和直接在哔哩哔哩或者巴哈姆特观看没有区别了，失去了弹弹Play整合全平台弹幕的优势。

因此，本人添加了配置选项 `load_more_danmaku`，用来将从弹弹Play获取弹幕的逻辑更改为逐一搜索所有弹幕源下的全部弹幕，并由本脚本整合加载。开启此选项可以获取到所有可用弹幕源下的所有弹幕。但是对于一些热门番剧来说，弹幕数量可能破万，如果接受不了屏幕上弹幕太多，请不要开启此选项。（嘛，不过本人看视频从来只会觉得弹幕多多益善）

#### 使用方法

想要开启此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并添加如下内容：

```
load_more_danmaku=yes
```

</details>

---

<details>
<summary>
excluded_platforms

> 排除指定平台的弹幕源

</summary>

### excluded_platforms

#### 功能说明

排除指定平台的弹幕源，支持域名关键词匹配。多个平台用逗号分隔。

当启用 `load_more_danmaku` 选项时，脚本会从弹弹play API 获取所有相关弹幕源。此选项允许你过滤掉不想要的平台弹幕。

#### 常见平台

- `bilibili.com` - B站
- `gamer.com.tw` - 巴哈姆特
- `acfun.cn` - A站
- `iqiyi.com` - 爱奇艺
- `qq.com` - 腾讯视频
- `youku.com` - 优酷

#### 使用示例

想要开启此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并添加如下内容：

```
excluded_platforms=["bilibili.com", "gamer.com.tw", "iqiyi.com"]
```

注意⚠️：
- 此选项仅在 `load_more_danmaku=yes` 时生效
- 使用 JSON 数组格式，注意保留方括号和引号
- 支持域名关键词匹配，不需要精确匹配完整URL

</details>

---

<details>
<summary>
auto_load

> 开关全自动弹幕填装

</summary>

### auto_load

#### 功能说明

该选项控制是否开启全自动弹幕填装功能。该功能会在为某个文件夹下的某一集番剧加载过一次弹幕后，把加载过的弹幕会自动关联到该集。之后每次重新播放该文件就会自动加载对应的弹幕，同时该文件对应的文件夹下的所有其他集数的文件都会在播放时自动加载弹幕。

举个例子，比如说有一个文件夹结构如下

```
败犬女主太多了
├── KitaujiSub_Make_Heroine_ga_Oosugiru!_01WebRipHEVC_AACCHS_JP.mp4
├── KitaujiSub_Make_Heroine_ga_Oosugiru!_02WebRipHEVC_AACCHS_JP.mp4
├── KitaujiSub_Make_Heroine_ga_Oosugiru!_03WebRipHEVC_AACCHS_JP.mp4
├── KitaujiSub_Make_Heroine_ga_Oosugiru!_04WebRipHEVC_AACCHS_JP.mp4
├── KitaujiSub_Make_Heroine_ga_Oosugiru!_05WebRipHEVC_AACCHS_JP.mp4
├── KitaujiSub_Make_Heroine_ga_Oosugiru!_06WebRipHEVC_AACCHS_JP.mp4
├── KitaujiSub_Make_Heroine_ga_Oosugiru!_07v2WebRipHEVC_AACCHS_JP.mp4
└── KitaujiSub_Make_Heroine_ga_Oosugiru!_08WebRipHEVC_AACCHS_JP.mp4
```

只要在播放第一集 `KitaujiSub_Make_Heroine_ga_Oosugiru!_01WebRipHEVC_AACCHS_JP.mp4`的时候手动搜索并且加载过一次弹幕，那么打开第二集时就会直接自动加载第二集的弹幕，打开第三集时就会直接加载第三集的弹幕，以此类推，不用再手动搜索

#### 使用方法

想要开启此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并添加如下内容：

```
auto_load=yes
```

注意⚠️： 一个文件夹下有且仅有一同部番剧的若干视频文件才会生效。下面这种情况下，如果手动搜索并且加载过一次《少女歌剧》第一集的弹幕，《哭泣少女乐队》第二集必须重新手动识别，但这样会破坏《少女歌剧》的弹幕记录

```
少女歌剧
├── 少女歌剧1.mp4
├── 少女歌剧2.mp4
├── 少女歌剧3.mp4
├── 少女歌剧4.mp4
└── 哭泣少女乐队2.mp4
```

</details>

---

<details>
<summary>
autoload_for_url

> 开关url播放场景自动加载弹幕与关联继承

</summary>

### autoload_for_url

#### 功能说明

开启此选项后，会为可能支持的 url 视频文件实现弹幕关联记忆和继承，配合播放列表食用效果最佳。目前兼容在使用[embyToLocalPlayer](https://github.com/kjtsune/embyToLocalPlayer)、[mpv-torrserver](https://github.com/dyphire/mpv-config/blob/master/scripts/mpv-torrserver.lua)、[tsukimi](https://github.com/tsukinaha/tsukimi)等场景时进行弹幕关联记忆和继承。

目前的具体支持情况和实现效果可以参考[此pr](https://github.com/Tony15246/uosc_danmaku/pull/16)

另外，开启此选项后还会在网络播放bilibili以及巴哈姆特的视频时自动加载对应视频的弹幕，可配合[Play-With-MPV](https://github.com/LuckyPuppy514/Play-With-MPV)或[ff2mpv](https://github.com/woodruffw/ff2mpv)等网络播放手段使用。（播放巴哈姆特的视频时弹幕自动加载如果失败，请检查[proxy](#proxy)选项配置是否正确）

#### 使用方法

想要开启此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并添加如下内容：

```
autoload_for_url=yes
```

</details>

---

<details>
<summary>
autoload_local_danmaku

> 开关自动加载同目录下的xml格式弹幕文件

</summary>

### autoload_local_danmaku

#### 功能说明

自动加载播放文件同目录下同名的 xml 格式的弹幕文件

#### 使用方法

想要开启此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并添加如下内容：

```
autoload_local_danmaku=yes
```

</details>

---

<details>
<summary>
save_danmaku

> 开关自动保存弹幕文件（xml格式）至视频同目录

</summary>

### save_danmaku

#### 功能说明

当文件关闭时自动保存弹幕文件（xml格式）至视频同目录，保存的弹幕文件名与对应的视频文件名相同。配合[autoload_local_danmaku选项](#autoload_local_danmaku)可以实现弹幕自动保存到本地并且下次播放时自动加载本地保存的弹幕。此功能默认禁用。

> **⚠️NOTE！**
>
> 当开启[autoload_local_danmaku选项](#autoload_local_danmaku)时，会自动加载播放文件同目录下同名的 xml 格式的弹幕文件，优先级高于一切其他自动加载弹幕功能。如果不希望每次播放都加载之前保存的本地弹幕，则请关闭[autoload_local_danmaku选项](#autoload_local_danmaku)；或者在保存完弹幕之后转移弹幕文件至其他路径并关闭 `save_danmaku`选项。
>
> `save_danmaku`选项的打开和关闭可以运行时实时更新。在 `input.conf`中添加如下内容，可通过快捷键实时控制 `save_danmaku`选项的打开和关闭
>
> ```
> key cycle-values script-opts uosc_danmaku-save_danmaku=yes uosc_danmaku-save_danmaku=no
> ```

#### 使用方法

想要启用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并指定如下内容：

```
save_danmaku=yes
```

</details>

---

<details>
<summary>

~~add_from_source~~

> ~~开关记录通过 从弹幕源向当前弹幕添加新弹幕内容 关联过的弹幕源并自动加载（已废除）~~

</summary>

### add_from_source

> **⚠️NOTE！**
>
> 该可选配置项在Release v1.2.0之后已废除。现在通过 `从弹幕源向当前弹幕添加新弹幕内容`功能关联过的弹幕源被记录，并且下次播放同一个视频的时候自动关联并加载所有添加过的弹幕源，这样的行为已经成为了插件的默认行为，不需要再通过 `add_from_source`来开启。在[从源获取弹幕](#从弹幕源向当前弹幕添加新弹幕内容可选)菜单中可以可视化地管理所有添加过的弹幕源。

#### 功能说明

开启此选项后，通过 `从弹幕源向当前弹幕添加新弹幕内容`功能关联过的弹幕源会被记录，并且下次播放同一个视频的时候会自动关联并加载添加过的弹幕源。

#### 使用方法

想要开启此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并添加如下内容：

```
add_from_source=yes
```

</details>

---

### 弹幕显示相关

(如果需要更细节的弹幕样式修改请看[自定义弹幕样式](#自定义弹幕样式相关配置))

<!--  下列是弹幕显示相关  -->

<details>
<summary>
opacity

> 自定义弹幕的透明度

</summary>

### opacity

#### 功能说明

自定义弹幕的透明度，0（完全透明）到1（不透明）。默认值：0.7

#### 使用方法

想要使用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并自定义如下内容：

```
opacity=0.7
```

</details>

---

<details>
<summary>
chConvert

> 开关中文简繁转换

</summary>

### chConvert

#### 功能说明

中文简繁转换。0-不转换，1-转换为简体，2-转换为繁体。默认值: 0，不转换简繁字体，按照弹幕源原本字体显示

#### 使用方法

想要使用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并自定义如下内容：

```
chConvert=0
```

</details>

---

<details>
<summary>
merge_tolerance

> 开关合并重复弹幕并设置容差值

</summary>

### merge_tolerance

#### 功能说明

指定合并重复弹幕的时间间隔的容差值，单位为秒。默认值: -1，表示禁用

当值设为0时会合并同一时间相同内容的弹幕，值大于0时会合并指定秒数误差内的相同内容的弹幕

#### 使用方法

想要使用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并自定义如下内容：

```
merge_tolerance=1
```

</details>

---
<details>
<summary>
max_screen_danmaku

> 限制屏幕中同时显示的弹幕数量

</summary>

### max_screen_danmaku

#### 功能说明

当该值大于0时，脚本会在解析弹幕时丢弃部分弹幕，确保任意时刻屏幕中显示的弹幕不超过设定值。

#### 使用方法

在 `script-opts` 目录下创建 `uosc_danmaku.conf` 并添加如下内容：

```
max_screen_danmaku=60
```

</details>

---

<details>
<summary>
vf_fps

> 开关使用fps视频滤镜提升弹幕平滑度（帧数）

</summary>

### vf_fps

#### 功能说明

指定是否使用 fps 视频滤镜 `@danmaku:fps=fps=60/1.001`，可大幅提升弹幕平滑度。默认禁用

注意该视频滤镜的性能开销较大，需在确保设备性能足够的前提下开启

启用选项后仅在视频帧率小于 60 及显示器刷新率大于等于 60 时生效

#### 使用方法

想要使用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并指定如下内容：

```
vf_fps=yes
```

</details>

---

<details>
<summary>
fps

> 自定义fps滤镜参数适配不同显示器刷新率

</summary>

### fps

#### 功能说明

指定要使用的 fps 滤镜参数，例如如果设置fps为 `60/1.001`，则实际生效的视频滤镜参数为 `@danmaku:fps=fps=60/1.001`

使用这个选项，可以根据自己显示器的刷新率调整要使用的视频滤镜参数

#### 使用方法

想要使用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并指定如下内容：

```
fps=60/1.001
```

</details>

---

### 弹幕解析服务相关

<!--  下列是弹幕解析服务相关  -->

<details>
<summary>
api_server

> 自定义弹幕API

</summary>

### api_server

#### 功能说明

允许自定义弹幕 API 的服务地址

> **⚠️NOTE！**
>
> 请确保自定义服务的 API 与弹弹play 的兼容，已知兼容：[misaka_danmu_server](https://github.com/l429609201/misaka_danmu_server)，[danmu_api](https://github.com/huangxd-/danmu_api)

#### 使用方法

想要使用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并自定义如下内容：

```
api_server=https://api.dandanplay.net
```

</details>

---

<details>
<summary>
fallback_server

> 自定义b站和爱腾优的弹幕获取的兜底服务器地址

</summary>

### fallback_server

#### 功能说明

自定义 b 站和爱腾优的弹幕获取的兜底服务器地址，主要用于获取非动画弹幕，只有在弹弹play无法解析视频源对应弹幕的情况下才会使用此处设置的服务器进行解析。兜底弹幕服务器可以自托管，具体方法请参考此仓库：https://github.com/lyz05/danmaku

> **⚠️NOTE！**
>
> 不设置此选项的情况下默认使用 `https://fc.lyz05.cn`作为兜底服务器，除非你自行部署了弹幕服务器，否则不建议自定义此选项。

#### 使用方法

想要使用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并自定义如下内容：

```
fallback_server=https://fc.lyz05.cn
```

</details>

---

<details>
<summary>
tmdb_api_key

> 自定义 tmdb 的 API Key获取非动画条目的中文信息

</summary>

### tmdb_api_key

#### 功能说明

设置 tmdb 的 API Key，用于获取非动画条目的中文信息(当搜索内容非中文时)。可以在 https://www.themoviedb.org 注册后去个人账号设置界面获取个人的tmdb 的 API Key。

> **⚠️NOTE！**
>
> 不设置此选项的情况下默认使用专为本项目申请的API Key。另外，自定义此选项时还需要对获取到的 API Key 进行 base64 编码。

#### 使用方法

想要使用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并自定义如下内容：

```
tmdb_api_key=NmJmYjIxOTZkNzIyN2UyMTIzMGM3Y2YzZjQ4MDNkZGM=
```

</details>

---

### 插件配置相关

<details>
<summary>
user_agent

> 自定义请求时的User Agent

</summary>

### user_agent

#### 功能说明

自定义 `curl`发送网络请求时使用的 User Agent，默认值是 `mpv_danmaku/1.0`

#### 使用方法

想要使用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并自定义如下内容（不可为空）：

> **⚠️NOTE！**
>
> User-Agent格式必须符合弹弹play的标准，否则无法成功请求。具体格式要求见[弹弹play官方文档](https://github.com/kaedei/dandanplay-libraryindex/blob/master/api/OpenPlatform.md#5user-agent)
>
> 若想提高URL播放的哈希匹配成功率，可以将此项设为 `mpv`或浏览器的User-Agent

```
user_agent=mpv_danmaku/1.0
```

</details>

---

<details>
<summary>
proxy

> 自定义请求时的代理

</summary>

### proxy

#### 功能说明

自定义 `curl`发送网络请求时使用的代理，默认禁用

#### 使用方法

想要使用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并自定义如下内容：

```
proxy=127.0.0.1:7890
```

</details>

---

<details>
<summary>
message_x

> 自定义插件相关提示的显示位置（x轴）

</summary>

### message_x

#### 功能说明

自定义插件相关提示的显示位置，距离屏幕左上角的x轴的距离

#### 使用方法

想要使用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并自定义如下内容：

```
message_x=30
```

</details>

---

<details>
<summary>
message_y

> 自定义插件相关提示的显示位置（y轴）

</summary>

### message_y

#### 功能说明

自定义插件相关提示的显示位置，距离屏幕左上角的y轴的距离

#### 使用方法

想要使用此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并自定义如下内容：

```
message_y=30
```

</details>

---

<details>
<summary>
title_replace

> 自定义文件标题解析中的额外替换规则

</summary>

### title_replace

自定义标题解析中的额外替换规则，内容格式为 JSON 字符串，替换模式为 lua 的 string.gsub 函数

注意⚠️：由于 mpv 的 lua 版本限制，自定义规则只支持形如 %n 的捕获组写法，即示例用法，不支持直接替换字符的写法

用法示例：

```
title_replace=[{"rules":[{ "^〔(.-)〕": "%1"},{ "^.*《(.-)》": "%1" }]}]
```

</details>

---

<details>
<summary>
excluded_path

> 指定哈希匹配中需忽略的共享盘（挂载盘）的路径/目录

</summary>

### excluded_path

指定哈希匹配中需忽略的共享盘（挂载盘）的路径/目录。支持绝对路径和相对路径，多个路径用逗号分隔

用法示例：

```
excluded_path=["X:", "Z:", "F:/Download/", "Download"]
```

</details>

---

<details>
<summary>
history_path

> 指定弹幕关联历史记录文件路径

</summary>

### history_path

#### 功能说明

指定弹幕关联历史记录文件的路径，支持绝对路径和相对路径。默认值是 `~~/danmaku-history.json`也就是mpv配置文件夹的根目录下

#### 使用示例

想要配置此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并添加类似如下内容：

> **⚠️IMPORTANT**
> 不要直接复制这里的配置，这只是一个示例，路径要写成真实存在的路径。此选项可以不配置，脚本会默认放在mpv配置文件夹的根目录下。

```
history_path=/path/to/your/danmaku-history.json
```

</details>

---

### 自定义弹幕样式相关配置

默认配置如下，可根据需求更改并自定义弹幕样式

想要配置此选项，请在mpv配置文件夹下的 `script-opts`中创建 `uosc_danmaku.conf`文件并添加类似如下内容：

```
#滚动弹幕的显示时间
scrolltime=15
#固定弹幕的显示时间
fixtime=5
#字体(名称两边不需要使用引号""括住)
fontname=sans-serif
#大小
fontsize=50
#阴影
shadow=0
#粗体
bold=yes
#全部弹幕的显示范围(0.0-1.0)
displayarea=0.85
#描边 0-4
outline=1
#指定弹幕屏蔽词文件路径(black.txt)，支持绝对路径和相对路径。文件内容以换行分隔
##支持 lua 的正则表达式写法
blacklist_path=
```
## 插件自定义属性

- `user-data/uosc_danmaku/danmaku-delay`


    从 `user-data/uosc_danmaku/danmaku-delay`属性中可以获取到当前弹幕延迟的值，具体用法可以参考[此issue](https://github.com/Tony15246/uosc_danmaku/issues/77)

- `user-data/uosc_danmaku/has-danmaku`

    从`user-data/uosc_danmaku/has-danmaku`属性中可以获取到表示当前是否有弹幕在显示的布尔值，具体用法可以参考[此pr](https://github.com/Tony15246/uosc_danmaku/pull/276)

## 常见问题

### 来自弹弹play的弹幕源问题如何从根源进行调整解决

本插件动画弹幕均来自[弹弹play api](https://github.com/kaedei/dandanplay-libraryindex/blob/master/api/OpenPlatform.md)，所以你可能会遇到 `部分动画没有弹幕`和 `弹幕时间轴对不上`这类问题，虽然你可以使用本插件的 [从源获取弹幕](#从弹幕源向当前弹幕添加新弹幕内容可选) 和 [弹幕源延迟设置](#弹幕源延迟设置可选) 这两个功能解决，但你如果想为弹幕源做贡献从根源解决帮所有用户解决这类问题，可以参考下列教程:

1.下载[弹弹play pc端](https://www.dandanplay.com)

2.使用弹弹play `播放任意视频文件`并 `绑定你想要调整的动画弹幕库`

3.然后就可以参考下方详细教程对弹幕源进行操作并使所有用户同步操作内容了

**为动画添加弹幕源**

如果你想为一部动画添加弹幕可以使用 `视频设置菜单`-→`弹幕列表`-→`添加更多弹幕` 这项功能添加对应的弹幕

> [!NOTE]
> 如果想使API（本插件）弹幕同步操作内容请将链接重复添加三次（弹弹play投票抉择机制）

**为动画弹幕源调整延迟**

如果你想为动画弹幕源修改延迟，请在 `视频设置菜单`-→`编辑弹幕来源`中复制下你要编辑的弹幕源的具体网址，然后点击删除，然后使用 `视频设置菜单`-→`弹幕列表`-→`添加更多弹幕` 这项功能进行重新添加，添加时在下方 `已选弹幕`中更改 `弹幕偏移`（单位为秒）调整延迟，然后依旧是重复添加三次就能使API弹幕同步了

另外，弹弹play的弹幕源一直是人工维护人工绑定制，感谢所有用此方式做贡献的人

## 特别感谢

感谢以下项目为本项目提供了实现参考或者外部依赖

- 弹幕api：[弹弹play](https://github.com/kaedei/dandanplay-libraryindex/blob/master/api/OpenPlatform.md)
- 菜单api：[uosc](https://github.com/tomasklaen/uosc)
- 弹幕格式解析转换：[DanmakuConvert](https://github.com/timerring/DanmakuConvert)
- 简繁转换：[OpenCC](https://github.com/BYVoid/OpenCC)
- lua原生md5计算实现：https://github.com/rkscv/danmaku
- b站在线播放弹幕获取实现参考：[MPV-Play-BiliBili-Comments](https://github.com/itKelis/MPV-Play-BiliBili-Comments)
- 巴哈姆特在线播放弹幕获取实现参考：[MPV-Play-BAHA-Comments](https://github.com/s594569321/MPV-Play-BAHA-Comments)

## 相关项目

- [slqy123/uosc_danmaku](https://github.com/slqy123/uosc_danmaku) 本项目的fork版本，实现了通过dandanplay api发送弹幕的功能，由于版本的兼容性以及功能的易用性问题未被合并，具体讨论请参阅 [#220](https://github.com/Tony15246/uosc_danmaku/pull/220)
- [Loukyuu1120/uosc_danmaku](https://github.com/Loukyuu1120/uosc_danmaku) 本项目的fork版本，实现了自定义多个 api_servers 与 弹幕来源选择菜单 功能，具体讨论请参阅 [#282](https://github.com/Tony15246/uosc_danmaku/issues/282)
