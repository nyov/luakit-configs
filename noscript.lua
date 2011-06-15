local os = require "os"
local tonumber = tonumber
local assert = assert
local webview = webview
local add_binds = add_binds
local table = table
local string = string
local lousy = require "lousy"
local capi = { luakit = luakit, sqlite3 = sqlite3 }
local sql_escape = lousy.util.sql_escape

module "noscript"

-- Default enable values
local enable_scripts = true
local enable_plugins = true

db = capi.sqlite3{ filename = capi.luakit.data_dir .. "/noscript.db" }
db:exec("PRAGMA synchronous = OFF; PRAGMA secure_delete = 1;")

create_table = [[
CREATE TABLE IF NOT EXISTS by_domain (
    id INTEGER PRIMARY KEY,
    domain TEXT,
    enable_scripts INTEGER, 
    enable_plugins INTEGER
);]]

db:exec(create_table)

function webview.methods.toggle_scripts(view, w)
    local uri = assert(lousy.uri.parse(view.uri), "invalid uri")
    local domain = string.lower(uri.host)

    local results = db:exec(string.format("SELECT * FROM by_domain "
        .. "WHERE domain == %s;", sql_escape(domain)))

    local scripts = enable_scripts or view:get_property("enable-scripts")

    if results[1] then
        local row = results[1]
        scripts = (tonumber(row.enable_scripts) == 1)
        db:exec(string.format("UPDATE by_domain SET enable_scripts = %d "
            .. "WHERE id == %d;", (not scripts) and 1 or 0, row.id))
    else
        db:exec(string.format("INSERT INTO by_domain " 
            .. "VALUES(NULL, %s, %d, %d);", sql_escape(domain), 
            (not scripts) and 1 or 0, enable_plugins and 1 or 0))
    end 

    if scripts then
        w:notify("Disabled scripts for domain: " .. domain)
    else
        w:notify("Enabled scripts for domain: " .. domain)
    end
end

function webview.methods.toggle_plugins(view, w)
    local uri = assert(lousy.uri.parse(view.uri), "invalid uri")
    local domain = string.lower(uri.host)

    local results = db:exec(string.format("SELECT * FROM by_domain "
        .. "WHERE domain == %s;", sql_escape(domain)))

    local plugins = enable_plugins or view:get_property("enable-plugins")

    if results[1] then
        local row = results[1]
        plugins = (tonumber(row.enable_plugins) == 1)
        db:exec(string.format("UPDATE by_domain SET enable_plugins = %d "
            .. "WHERE id == %d;", (not plugins) and 1 or 0, row.id))
    else
        db:exec(string.format("INSERT INTO by_domain " 
            .. "VALUES(NULL, %s, %d, %d);", sql_escape(domain), 
            enable_scripts and 1 or 0, (not plugins) and 1 or 0))
    end 

    if plugins then
        w:notify("Disabled plugins for domain: " .. domain)
    else
        w:notify("Enabled plugins for domain: " .. domain)
    end
end

webview.init_funcs.noscript_load = function (view) 
    view:add_signal("load-status", function (v, status)
        if status ~= "committed" or v.uri == "about:blank" then return end
        local domain = string.lower(lousy.uri.parse(v.uri).host)
        local scripts, plugins = enable_scripts, enable_plugins
        local results = db:exec(string.format("SELECT * FROM by_domain "
            .. "WHERE domain == %s;", sql_escape(domain)))
        if results[1] then
            local row = results[1] 
            scripts = (tonumber(row.enable_scripts) == 1)
            plugins = (tonumber(row.enable_plugins) == 1)
        end
        view:set_property("enable-scripts", scripts)
        view:set_property("enable-plugins", plugins)
    end)
end

local buf = lousy.bind.buf
add_binds("normal", {
    buf("^,ts$", function (w) w:toggle_scripts() end),
    buf("^,tp$", function (w) w:toggle_plugins() end),
})
