--------------------------
-- speeddial extension  --
--------------------------

local chrome = require "chrome"
local cutycapt_bin = "/usr/bin/cutycapt"
local cutycapt_opt = "--min-width=1024 --min-height=768"
local mogrify_bin  = "/usr/bin/mogrify"
local mogrify_opt  = "-extent 1024x768 -size 240x180 -resize 240x180"

local html_template = [==[
<html>
<head>
    <title>Speed Dial</title>
    <style type="text/css">
        body {
            background: #afafaf;
            text-align: center;
        }
        a.fav {
            background: #e0e0e0;
            display:inline-block;
            width: 280;
            border: 1px solid black;
            border-radius: 5px;
            padding-top: 10px;
            margin:8px;
            text-align: center;

            text-decoration: none;
            font-weight: bold;
            color: black;
        }
        a.fav:hover {
            background: #ffffff;
            border-width:1px;
        }
        a.fav img {
            border: 1px solid #909090;
        }
    </style>
</head>
<body>
{favs}
</body>
</html>
]==]

local fav_template = [==[
    <a class="fav" href={url}><img src="{thumb}" width="240" height="180" border="0" />{title}</a>
]==]

local function favs()
    local favs = {}
    local updated = {}

    local f = io.open(luakit.data_dir .. "/favs")
    for line in f:lines() do
        local url, thumb, refresh, title = line:match("(%S+)%s+(%S+)%s+(%S+)%s+(.+)")
        if thumb == "none" or refresh == "yes" then
            thumb = string.format("%s/thumb-%s.png", luakit.data_dir, url:gsub("%W",""))
            local cmd = string.format('%s %s --url="%s" --out="%s" && %s %s %s', cutycapt_bin, cutycapt_opt, url, thumb, mogrify_bin, mogrify_opt, thumb)
            luakit.spawn(string.format("/bin/sh -c '%s'", cmd))
        end
        updated[#updated+1] = string.format("%s %s %s %s", url, thumb, refresh, title)

        local subs = {
            url   = url,
            thumb = "file://"..thumb,
            title = title,
        }
        favs[#favs+1] = fav_template:gsub("{(%w+)}", subs)
    end
    f:close()

    local f = io.open(luakit.data_dir .. "/favs", "w")
    f:write(table.concat(updated, "\n"))
    f:close()

    return table.concat(favs, "\n")
end

chrome.add("favs/", function (view, uri)
    -- the file:// is neccessary so that the thumbnails will be shown.
    -- disables reload though.
    local html = string.gsub(html_template, "{favs}", favs())
    view:load_string(html, "file://favs/")
end)

-- http://www.luakit.org/projects/luakit/wiki/Opera_Speed_Dial_like_chrome
