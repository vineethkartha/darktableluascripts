

local dt = require "darktable"
local du = require "lib/dtutils"

local MODULE_NAME = "ShortCutDemo"  -- make sure this is unique, no spaces, no special characters   
local EVENT_NAME = "shortcutdemo"   -- must be unique for this script
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
  name = "ShortCut Demo",
  purpose = "show how shortcuts can trigger functions",
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

local function show_name(images)
    if #images ~= 1 then
        dt.print("Select only one image")
        return
    end
    for _, img in ipairs(images) do
        dt.print("Converting: " .. (img.path) .. "/" .. (img.filename ))
  end
end

-- defensive cleanup: remove any previous registration with the same name/type
pcall(dt.destroy_event, EVENT_NAME, EVENT_TYPE)

dt.register_event(
  EVENT_NAME,           -- event name (unique id)
  EVENT_TYPE,           -- event type
  function(event, shortcut)
    show_name(dt.gui.selection())
  end,
  _("Show name")  -- label shown in Shortcuts prefs
)


return script_data
