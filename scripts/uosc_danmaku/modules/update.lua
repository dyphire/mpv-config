local msg = require('mp.msg')
local utils = require("mp.utils")

local repo = "Tony15246/uosc_danmaku"
local zip_file = utils.join_path(os.getenv("TEMP") or "/tmp/", "uosc_danmaku.zip")

local local_version = VERSION or "0.0.0"

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

local function delete_directory_contents(path)
    local cmd = {}
    if PLATFORM == "windows" then
        cmd = {
            "powershell", "-NoProfile", "-Command",
            "Remove-Item -Path '" .. path .. "\\*' -Recurse -Force"
        }
    else
        cmd = { "rm", "-rf", path .. "/*" }
    end
    local res = mp.command_native({
        name = "subprocess",
        args = cmd,
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
    })
    return res and res.status == 0
end

local function unzip_overwrite(zip_file)
    local cmd = {}
    local outpath = mp.get_script_directory()

    msg.verbose("🧹 清理原始目录内容...")
    if not delete_directory_contents(outpath) then
        msg.verbose("❌ 清理失败")
    end

    if PLATFORM == "windows" then
        cmd = {
            "powershell", "-NoProfile", "-Command",
            "Expand-Archive", "-Force", zip_file, "-DestinationPath", outpath
        }
    else
        cmd = { "unzip", "-o", zip_file, "-d", outpath }
    end

    local res = mp.command_native({
        name = "subprocess",
        args = cmd,
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
    })

    return res and res.status == 0
end

function check_for_update()
    local latest_version, download_url = get_latest_release(repo)
    if not latest_version or not download_url then
        show_message("❌ 无法获取最新版本信息，更新失败")
        msg.warn("❌ 无法获取最新版本信息，更新失败")
        return
    end

    if not version_greater(latest_version, local_version) then
        show_message("✅ 已是最新版本，无需更新")
        msg.info("✅ 已是最新版本，无需更新")
        return
    end

    show_message("⬇️ 发现新版本: " .. latest_version .. "，正在下载...")
    msg.info("⬇️ 发现新版本: " .. latest_version .. "，正在下载...")
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
        show_message("✅ 更新成功，当前版本为：" .. latest_version)
        msg.info("✅ 更新成功，当前版本为：" .. latest_version)
    else
        os.remove(zip_file)
        show_message("❌ 解压失败！")
        msg.warn("❌ 解压失败！")
    end
end