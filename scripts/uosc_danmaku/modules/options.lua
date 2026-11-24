local opt = require("mp.options")

-- 选项
options = {
    -- 指定弹幕服务器地址，自定义服务需兼容 dandanplay 的 api
    -- 可指定多个用逗号分隔的有序 api_server 列表
    -- 支持每项使用 '|' 或 '#' 分隔备注，例如: "https://a.example.com|备用A" 或 "https://b.example.com#备用B"
    api_server = "https://danmaku-api.152468.xyz",
    -- 指定 b 站和爱腾优的弹幕获取的兜底服务器地址，主要用于获取非动画弹幕
    -- 可用： https://dmku.hls.one
    fallback_server = "https://dmku.hls.one",
    -- 设置 tmdb 的 API Key，用于获取非动画条目的中文信息(当搜索内容非中文时)
    -- 可以在 https://www.themoviedb.org 注册后去个人账号设置界面获取
    -- 注意：自定义此参数时还需要对获取到的 API Key 进行 base64 编码
    tmdb_api_key = "NmJmYjIxOTZkNzIyN2UyMTIzMGM3Y2YzZjQ4MDNkZGM=",
    -- 自动加载弹幕开关
    auto_load = false,
    -- 自动加载可能支持的 url 视频文件实现弹幕关联记忆和继承，配合播放列表食用效果最佳
    autoload_for_url = false,
    -- 当自动弹幕加载失败时，自动弹出搜索框让用户手动搜索
    auto_fallback_search = false,
    -- 自动加载播放文件同目录下同名的 xml 格式的弹幕文件
    autoload_local_danmaku = false,
    -- 播放结束时自动保存弹幕为xml文件
    save_danmaku = false,
    -- 指定弹幕保存目录。为空时保存到视频同目录；目录需要用户提前创建
    save_danmaku_path = "",
    -- 指定 save_danmaku_path 的应用范围：local / url / all
    save_danmaku_path_mode = "local",
    -- 向 HTTP 请求时使用的 User Agent
    user_agent = "mpv_danmaku/1.0",
    -- 可选：向 HTTP 请求时使用的代理，默认禁用
    proxy = "",
    -- 可选：向 HTTP 请求传递 cookie.txt 文件路径
    cookie_file = "",
    -- 使用 fps 视频滤镜，大幅提升弹幕平滑度。默认禁用
    vf_fps = false,
    -- 设置要使用的 fps 滤镜参数
    fps = "60/1.001",
    -- 指定合并重复弹幕的时间间隔的容差值，单位为秒。默认值: -1，表示禁用
    merge_tolerance = -1,
    -- 同类刷屏弹幕在几秒内合成一条. 设为负数时按普通弹幕处理, merge_tolerance 为负数时关闭所有合并
    merge_reaction_tolerance = -1,
    merge_count_threshold = 3,
    -- 合并重复弹幕时是否强制合并类型和颜色不同的弹幕。默认值: false，表示仅合并类型和颜色相同的弹幕
    merge_without_style = false,
    -- 合并弹幕字号的对数增长系数，必须为正整数
    merge_fontsize_growth = 8,
    -- 合并弹幕允许使用的最大字号
    merge_fontsize_max = 100,
    -- 指定弹幕关联历史记录文件的路径，支持绝对路径和相对路径
    history_path = "~~/danmaku-history.json",
    -- 指定弹幕搜索历史记录文件的路径，支持绝对路径和相对路径。留空禁用搜索历史功能
    search_history_path = "~~/danmaku-search-history.json",
    -- 搜索历史最多保留的条数，小于 1 表示不限制
    search_history_size = 15,
    -- 自定义插件快捷键，若 mpv.conf 里设置 input-default-bindings=no 将禁用以下两个选项
    open_search_danmaku_menu_key = "Ctrl+d",
    show_danmaku_keyboard_key = "j",
    -- 中文简繁转换。0-不转换，1-转换为简体，2-转换为繁体
    chConvert = 0,
    --滚动弹幕的显示时间
    scrolltime = 15,
    --固定弹幕的显示时间
    fixtime = 5,
    --字体
    fontname = "sans-serif",
    --字体大小 
    fontsize = 50,
    -- 滚动弹幕太挤时, 缩小刚出现的弹幕
    crowd_shrink = false,
    crowd_shrink_scale_medium = 0.90,
    crowd_shrink_scale_high = 0.80,
    crowd_shrink_threshold_medium = 0.60,
    crowd_shrink_threshold_high = 0.80,
    --字体阴影
    shadow = 0,
    --字体粗体
    bold = true,
    -- 透明度：0（完全透明）到 1（不透明）
    opacity = 0.7,
    --全部弹幕的显示范围(0.0-1.0)
    displayarea = 0.85,
    --描边 0-4
    outline = 1.0,
    -- 限制屏幕中同时显示的最大弹幕数量，0 表示不限制
    max_screen_danmaku = 0,
    --指定弹幕屏蔽词文件路径(black.txt)，支持绝对路径和相对路径。文件内容以换行分隔
    --支持 lua 的正则表达式写法
    blacklist_path = "",
    --指定脚本相关消息显示的消息的对齐方式
    message_alignment = 7,
    --指定脚本相关消息显示的消息的x轴坐标
    message_x = 30,
    --指定脚本相关消息显示的消息的y轴坐标
    message_y = 30,
    -- 自定义标题解析中的额外替换规则，内容格式为 JSON 字符串，替换模式为 lua 的 string.gsub 函数
    -- 同时支持 JSON 规则文件路径（如 ~~/script-opts/title_replace.json ），文件内容格式与示例字符串规则相同
    --! 注意：由于 mpv 的 lua 版本限制，自定义规则只支持形如 %n 的捕获组写法，即示例用法，不支持直接替换字符的写法
    title_replace = [[
       [{ 
           "rules": [{ "^〔(.-)〕": "%1"},{ "^.*《(.-)》": "%1" }],
       }]
    ]],
    -- 指定哈希匹配中需忽略的共享盘（挂载盘）的路径/目录。支持绝对路径和相对路径，多个路径用逗号分隔
    -- 示例：["X:", "Z:", "F:/Download/", "Download"]
    excluded_path = [[
        []
    ]],
}

opt.read_options(options, mp.get_script_name(), function() end)
