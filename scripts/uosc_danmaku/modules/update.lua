local msg = require('mp.msg')
local utils = require("mp.utils")

local repo = "Tony15246/uosc_danmaku"
local zip_file = utils.join_path(os.getenv("TEMP") or "/tmp/", "uosc_danmaku.zip")

local local_version = VERSION or "0.0.0"
local platform = mp.get_property("platform")

local function version_greater(v1, v2)
    local function parse(ver)
        local a, b, c = ver:match("v?(%d+)%.(%d+)%.(%d+)")
        return tonumber(a), tonumber(b), tonumber(c)
    end
    local a1, a2, a3 = parse(v1)
    local b1, b2, b3 = parse(v2)
    if a1 ~= b1 then return a1 > b1 end
    if a2 ~= b2 then return a2 > b2 end
    return a3 > b3
end

local function get_latest_release(repo)
    local url = "https://api.github.com/repos/" .. repo .. "/releases/latest"
    local cmd = { "curl", "-sL", url }
    local res = mp.command_native({
        name = "subprocess",
        args = cmd,
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
    })
    if not res or res.status ~= 0 then return nil end
    local tag = res.stdout:match([["tag_name"%s*:%s*"([^"]+)"]])
    local zip_url = res.stdout:match([["browser_download_url"%s*:%s*"([^"]+%.zip)"]])
    return tag, zip_url
end

local function escape_ps(str)
    return tostring(str):gsub("'", "''")
end

local function unzip_overwrite(zip_file)
    local outpath = mp.get_script_directory()
    -- 定义临时目录路径，用于安全更新
    local tmpdir = utils.join_path(
        (platform == "windows" and (os.getenv("TEMP") or "C:\\Windows\\Temp") or "/tmp"),
        "uosc_update_" .. tostring(os.time())
    )
    
    local cmd_unzip = {}

    msg.info("创建临时目录并解压: " .. tmpdir)

    if platform == "windows" then
        -- PowerShell: Expand-Archive (会自动创建目标目录)
        local ps_script = string.format(
            "Expand-Archive -LiteralPath '%s' -DestinationPath '%s' -Force",
            escape_ps(zip_file),
            escape_ps(tmpdir)
        )
        cmd_unzip = { "powershell", "-NoProfile", "-Command", ps_script }
    else
        -- Unix: unzip
        cmd_unzip = { "unzip", "-o", zip_file, "-d", tmpdir }
    end

    local res = mp.command_native({
        name = "subprocess",
        args = cmd_unzip,
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
    })

    if not res or res.status ~= 0 then
        msg.error("❌ 解压失败:\n" .. (res and (res.stdout .. res.stderr) or "未知错误"))
        -- 清理残留的临时目录
        if platform == "windows" then
            mp.command_native({
                name = "subprocess",
                args = {"powershell", "-NoProfile", "-Command", "Remove-Item -LiteralPath '"..escape_ps(tmpdir).."' -Recurse -Force"}
            })
        else
            os.execute("rm -rf \"" .. tmpdir .. "\"")
        end
        return false
    end

    msg.info("解压成功，准备替换旧目录...")

    local cmd_swap = {}
    
    if platform == "windows" then
        -- Windows: 在一个 PowerShell 实例中执行删除和移动
        local ps_swap = string.format(
            "Remove-Item -LiteralPath '%s' -Recurse -Force -ErrorAction SilentlyContinue; Move-Item -LiteralPath '%s' -Destination '%s' -Force",
            escape_ps(outpath),
            escape_ps(tmpdir),
            escape_ps(outpath)
        )
        cmd_swap = { "powershell", "-NoProfile", "-Command", ps_swap }
    else
        -- Unix: rm && mv
        cmd_swap = { "sh", "-c", string.format("rm -rf \"%s\" && mv \"%s\" \"%s\"", outpath, tmpdir, outpath) }
    end

    local res_swap = mp.command_native({
        name = "subprocess",
        args = cmd_swap,
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
    })

    if not res_swap or res_swap.status ~= 0 then
        msg.error("❌ 替换目录失败:\n" .. (res_swap and (res_swap.stdout .. res_swap.stderr) or ""))
        return false
    end

    msg.info("更新完成")
    return true
end

function check_for_update()
    local latest_version, download_url = get_latest_release(repo)
    if not latest_version or not download_url then
        show_message("❌ 无法获取最新版本信息")
        msg.warn("❌ 无法获取最新版本信息")
        return
    end

    if not version_greater(latest_version, local_version) then
        show_message("✅ 已是最新版本 ("..local_version..")")
        msg.info("✅ 已是最新版本")
        return
    end

    show_message("⬇️ 发现新版本: " .. latest_version .. "，正在下载...")
    msg.info("⬇️ 发现新版本: " .. latest_version .. "，地址: " .. download_url)

    local cmd = { "curl", "-L", "-o", zip_file, download_url }
    local res = mp.command_native({
        name = "subprocess",
        args = cmd,
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
    })
    if not res or res.status ~= 0 then
        show_message("❌ 下载失败！")
        msg.warn("❌ 下载失败！")
        return
    end

    show_message("📦 下载完成，开始解压覆盖...")
    msg.info("📦 下载完成，开始解压覆盖...")

    if unzip_overwrite(zip_file) then
        os.remove(zip_file)
        show_message("✅ 更新成功！请重启 mpv 以应用更新，当前版本为：" .. latest_version)
        msg.info("✅ 更新成功，当前版本为：" .. latest_version)
    else
        os.remove(zip_file)
        show_message("❌ 解压失败！请查看控制台日志")
        msg.warn("❌ 解压失败！")
    end
end
