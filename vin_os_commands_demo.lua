

local dt = require "darktable"
local du = require "lib/dtutils"
local dsys = require "lib/dtutils.system"

local MODULE_NAME = "RunOSCommand"  -- make sure this is unique, no spaces, no special characters   
local EVENT_NAME = "runoscommand"   -- must be unique for this script
local EVENT_TYPE = "shortcut"          -- the event we want (keyboard shortcut)


du.check_min_api_version("7.0.0", MODULE_NAME) 

-- https://www.darktable.org/lua-api/index.html#darktable_gettext
local gettext = dt.gettext.gettext

local function _(msgid)
    return gettext(msgid)
end

-- return data structure for script_manager
local script_data = {}

script_data.metadata = {
  name = "Run an OS Command",
  purpose = "show how run an OS command and get output",
  author = "Vineeth Kartha",
  help = "abcd" -- this seems important
}

-- script_manager integration to allow a script to be removed
-- without restarting darktable
local function destroy()
    pcall(dt.destroy_event, EVENT_NAME, EVENT_TYPE)
    dt.print("Destroyed" .. EVENT_NAME)
end

-- set the destroy routine so that script_manager can call it when
-- it's time to destroy the script and then return the data to 
-- script_manager
script_data.destroy = destroy

local function run_acommand()
    local cmd = "dir"
    local handle = io.popen(cmd)
    dt.print_log("Command executed")
    local result = handle:read("*a")
    handle:close()
    dt.print_log("Result: " .. result)
end

run_acommand()
-- defensive cleanup: remove any previous registration with the same name/type
pcall(dt.destroy_event, EVENT_NAME, EVENT_TYPE)


return script_data
