--此lua脚本由软件No1编写并提供支持
--This lua script is written by www.rjno1.com
--此脚本可以把osd中显示的文字信息切换为本地语言
-- This script can switch the text information displayed in osd to the local language
--此脚本不仅对MPV-EASY Player有效，对于mpv来说，此脚本可以较好和较完全的解决语言本地化问题
-- This script is not only valid for MPV-EASY Player. For mpv, this script can solve the language localization problem better and more completely.
--此脚本中重复的命令对MPV-EASY Player中的语言本地化并不会造成冲突,只会有轻微干扰或者无干扰，能成为有效的补充，比如你按下快捷键激发命令时。
--如果你发现有些命令会对使用会造成干扰，那么注释对应部分即可
--此脚本中有些命令默认就是注释状态，造成这个的原因有：
----1、命令可能不会产生效果 
----2、命令可能会对MPV-EASY Player造成较大的干扰，对mpv则没有 
----3、命令已经有了更好的写法
--如果你了解了这个脚本的功能，那么可以尝试取消这些注释，从而可以让播放器osd显示的语言本地化更加的完整。

local opts = require 'mp.options'
local osd_level_value = mp.get_property_osd("osd-level")

--默认设置
local settings = {
	language = "zh-cn" ,
}

--读取.conf设置文件中的设置
opts.read_options(settings, "local-language")



--loop-file的function
function loop_file_show_text(loop_file_fn, loop_file_fn_param)
	if (loop_file_fn_param == "yes" or loop_file_fn_param == "inf") then
			mp.command("show-text \"重复播放启用\"")
	elseif( loop_file_fn_param == "no") then
			mp.command("show-text \"重复播放禁用\"")
	else
			mp.command("show-text \"重复播放次数: ${loop-file}\"")
	end
end



--loop-playlist的function
function loop_playlist_show_text(loop_playlist_fn, loop_playlist_fn_param)
	if (loop_playlist_fn_param == "yes" or loop_playlist_fn_param == "inf") then
			mp.command("show-text \"循环播放启用\"")
	elseif( loop_playlist_fn_param == "no") then
			mp.command("show-text \"循环播放禁用\"")
	else
			mp.command("show-text \"循环播放次数: ${loop-playlist}\"")
	end
end



if settings.language =="zh-cn" and osd_level_value >= "1" then

		--视频打开后延迟一会在加载，防止有时候会出现文字很大的问题
		mp.add_timeout(2, function() 

			--注意mp.observe_property(name, type, fn)，type通常不建议使用string，建议使用none，因为：
			--If the type is none or nil, sporadic property change events are possible. This means the change
			--function fn can be called even if the property doesn't actually change.
			--比如：音量最大100%，当音量100%时，按下0，音量不变，依旧是100%，
			--如果是string，显示volume:100%,如果是none，依旧显示你修改后的
			mp.observe_property("contrast", "none", function() mp.command("show-text \"对比度: ${contrast}\"") end)
			mp.observe_property("brightness", "none", function() mp.command("show-text \"亮度: ${brightness}\"") end)
			mp.observe_property("saturation", "none", function() mp.command("show-text \"饱和度: ${saturation}\"") end)
			mp.observe_property("gamma", "none", function() mp.command("show-text \"伽马值: ${gamma}\"") end)
			mp.observe_property("hue", "none", function() mp.command("show-text \"色相: ${hue}\"") end)

			--下面这条可能无效
			mp.observe_property("hwdec", "string", function() mp.command("show-text \"解码方式: ${hwdec}\"") end)	

			mp.observe_property("speed", "none", function() mp.command("show-text \"播放倍速: ${speed}\"") end)
			
			mp.observe_property("ontop", "none", function() mp.command("show-text \"置顶: ${ontop}\"") end)

			mp.observe_property("sub", "none", function() mp.command("show-text \"字幕切换为: ${sub}\"") end)

			mp.observe_property("Track", "none", function() mp.command("show-text \"轨道: ${Track}\"") end)

			mp.observe_property("Chapters", "none", function() mp.command("show-text \"章节列表: ${Chapters}\"") end)

			mp.observe_property("Chapter", "none", function() mp.command("show-text \"章节: ${Chapter}\"") end)

			mp.observe_property("audio", "string", function() mp.command("show-text \"音轨切换为: ${audio}\"") end)

			mp.observe_property("audio-channels", "none", function() mp.command("show-text \"音频通道: ${audio-channels}\"") end)
			
			mp.observe_property("mute", "string", function() mp.command("show-text \"静音: ${mute}\"") end)

			mp.observe_property("panscan", "none", function() mp.command("show-text \"视频画面缩放: ${panscan}\"") end)

			mp.observe_property("sub-scale", "none", function() mp.command("show-text \"字体缩放: ${sub-scale}\"") end)

			mp.observe_property("sub-delay", "none", function() mp.command("show-text \"字幕延迟: ${sub-delay}\"") end)	

			mp.observe_property("sub-pos", "none", function() mp.command("show-text \"字幕位置: ${sub-pos}\"") end)	

			mp.observe_property("sub-ass-force-style", "none", function() mp.command("show-text \"ass字幕样式: ${sub-ass-force-style}\"") end)	

			mp.observe_property("sub-font-provider", "none", function() mp.command("show-text \"字体渲染api: ${sub-font-provider}\"") end)	

			mp.observe_property("stretch-image-subs-to-screen", "none", function() mp.command("show-text \"pgs字幕窗口缩放: ${stretch-image-subs-to-screen}\"") end)	

			mp.observe_property("secondary-sid", "none", function() mp.command("show-text \"次字幕切换为: ${secondary-sid}\"") end)	

			mp.observe_property("deinterlace", "none", function() mp.command("show-text \"反交错: ${deinterlace}\"") end)

			mp.observe_property("deband", "none", function() mp.command("show-text \"去色带: ${deband}\"") end)	

			mp.observe_property("deband-iterations", "none", function() mp.command("show-text \"去色带次数: ${deband-iterations}\"") end)	

			mp.observe_property("deband-grain", "none", function() mp.command("show-text \"动态噪点: ${deband-grain}\"") end)

			mp.observe_property("deblock", "none", function() mp.command("show-text \"去色块: ${deblock}\"") end)			

			mp.observe_property("glsl-shaders", "none", function() mp.command("show-text \"着色器: ${glsl-shaders}\"") end)	

			mp.observe_property("tone-mapping", "none", function() mp.command("show-text \"hdr映射曲线: ${tone-mapping}\"") end)

			mp.observe_property("reset-on-next-file", "none", function() mp.command("show-text \"重置选项: ${reset-on-next-file}\"") end)				

			--下方3条会互相造成干扰， 解决方式：只开启其中一个或其中2个，或者改进这段代码
			--mp.observe_property("window-scale", "none", function() mp.command("show-text \"视频画面大小倍数 ${window-scale}\"") end)
			
			--使用string可以避免下面2条之间的干扰
			mp.observe_property("video-params/aspect", "string", function() mp.command("show-text \"画面宽高比例 ${video-params/aspect}\"") end)
			mp.observe_property("video-rotate", "none", function() mp.command("show-text \"画面旋转角度: ${video-rotate}\"") end)
			

			
			
			--mp.observe_property("loop-file", "string", loop_file_show_text)
			--下方这条和上方这条相同和一样有效，只是显示比较简单，上方这条要用string，不能用none
			mp.observe_property("loop-file", "none", function() mp.command("show-text \"重复播放: ${loop-file}\"") end)
			
			--mp.observe_property("loop-playlist", "string", loop_playlist_show_text)
			--下方这条和上方这条相同和一样有效，只是显示比较简单，上方这条要用string，不能用none
			mp.observe_property("loop-playlist", "none", function() mp.command("show-text \"循环播放: ${loop-playlist}\"") end)
			
			--注意：音量一定要写在最后一个，防止首次自动显示时出现非音量的文字信息，但有可能放在最后也不能解决问题
			mp.observe_property("volume", "string", function() mp.command("show-text \"音量:${volume}%\"") end)
		end)

end