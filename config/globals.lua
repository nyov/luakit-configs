-- Global variables for luakit
globals = {
 -- homepage            = "http://luakit.org/",
 -- homepage            = "about:blank",
    homepage            = "chrome://favs",
    scroll_step         = 40,
    zoom_step           = 0.1,
    max_cmd_history     = 100,
    max_srch_history    = 100,
 -- http_proxy          = "http://example.com:3128",
    default_window_size = "800x600",
    term                = "x-terminal-emulator",

 -- Disables loading of hostnames from /etc/hosts (for large host files)
 -- load_etc_hosts      = false,
 -- Disables checking if a filepath exists in search_open function
 -- check_filepath      = false,
}

-- Make useragent
local _, arch = luakit.spawn_sync("uname -sm")
-- Only use the luakit version if in date format (reduces identifiability)
local lkv = string.match(luakit.version, "^(%d+.%d+.%d+)")
globals.useragent = string.format("Mozilla/5.0 (%s) AppleWebKit/%s+ (KHTML, like Gecko) WebKitGTK+/%s luakit%s",
    string.sub(arch, 1, -2), luakit.webkit_user_agent_version,
    luakit.webkit_version, (lkv and ("/" .. lkv)) or "")

-- Search common locations for a ca file which is used for ssl connection validation.
local ca_files = {
    -- $XDG_DATA_HOME/luakit/ca-certificates.crt
    luakit.data_dir .. "/ca-certificates.crt",
    "/etc/certs/ca-certificates.crt",
    "/etc/ssl/certs/ca-certificates.crt",
}
-- Use the first ca-file found
for _, ca_file in ipairs(ca_files) do
    if os.exists(ca_file) then
        soup.ssl_ca_file = ca_file
        break
    end
end

-- Change to stop navigation sites with invalid or expired ssl certificates
soup.ssl_strict = false

-- Set cookie acceptance policy
cookie_policy = { always = 0, never = 1, no_third_party = 2 }
soup.accept_policy = cookie_policy.always

-- Set default language
soup.accept_language = "en;q=1.0,de;q=0.5"

-- List of search engines. Each item must contain a single %s which is
-- replaced by URI encoded search terms. All other occurances of the percent
-- character (%) may need to be escaped by placing another % before or after
-- it to avoid collisions with lua's string.format characters.
-- See: http://www.lua.org/manual/5.1/manual.html#pdf-string.format
search_engines = {
    g           = "http://google.com/search?q=%s",
    s           = "https://startpage.com/do/search?q=%s",
    lk          = "http://luakit.org/search/index/luakit?q=%s",
    gh          = "https://github.com/search?q=%s",
    ddg         = "http://duckduckgo.com/?q=%s",
    wikipedia   = "http://en.wikipedia.org/wiki/Special:Search?search=%s",
    debbugs     = "http://bugs.debian.org/%s",
    deb         = "http://packages.debian.org/%s",
    debs        = "http://packages.debian.org/src:%s",
    dqa         = "http://packages.qa.debian.org/%s",
    imdb        = "http://imdb.com/find?s=all&q=%s",
    netflix     = "http://dvd.netflix.com/Search?v1=%s",
    sourceforge = "http://sf.net/search/?words=%s",
    gmaps       = "http://maps.google.com/maps?q=%s",
    yt          = "http://www.youtube.com/results?search_query=%s&search_sort=video_view_count",
}

-- Set fallback / default search engine
search_engines.default = search_engines.s
-- Use this instead to disable auto-searching
--search_engines.default = "%s"

-- Per-domain webview properties
-- See http://webkitgtk.org/reference/webkitgtk-WebKitWebSettings.html
domain_props = {
    -- properties for everything, unless overridden
    ["all"] = {
        -- removed globally for noscript plugin to work
    --  enable_scripts              = false,
    --  enable_plugins              = false,
        enable_private_browsing     = false,
        user_stylesheet_uri         = "",
    },
    -- local properties (luakit:// (chrome://), file:// uri's),
    -- unless overridden in ["luakit"] or ["file"] explicitly
    ["local"] = {
        enable_scripts                        = true,
        enable_plugins                        = true,
        enable_file_access_from_file_uris     = true, -- allow xmlhttprequest for file:// protocol
        user_stylesheet_uri                   = "file://" .. luakit.data_dir .. "/styles/nyov.css",
    },
    -- domain specific properties
    ["github.com"] = {
        enable_scripts              = true,
    },
    ["youtube.com"] = {
        enable_scripts              = true,
        enable_plugins              = true,
    },
    ["bbs.archlinux.org"] = {
        user_stylesheet_uri     = "file://" .. luakit.data_dir .. "/styles/dark.css",
        enable_private_browsing = true,
    },
}

-- vim: et:sw=4:ts=8:sts=4:tw=80
