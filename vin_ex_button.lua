

local dt = require "darktable"
local du = require "lib/dtutils"

local MODULE_NAME = "ButtonDemo"  -- make sure this is unique, no spaces, no special characters   

du.check_min_api_version("7.0.0", MODULE_NAME) 

-- https://www.darktable.org/lua-api/index.html#darktable_gettext
local gettext = dt.gettext.gettext

local function _(msgid)
    return gettext(msgid)
end

-- return data structure for script_manager

local script_data = {}

script_data.metadata = {
  name = "Button Demo",
  purpose = "show how the button works",
  author = "Vineeth Kartha",
  help = "abcd" -- this seems important
}

script_data.destroy = nil -- function to destory the script
script_data.destroy_method = nil -- set to hide for libs since we can't destroy them commpletely yet, otherwise leave as nil
script_data.restart = nil -- how to restart the (lib) script after it's been hidden - i.e. make it visible again
script_data.show = nil -- only required for libs since the destroy_method only hides them

-- translation

-- declare a local namespace and a couple of variables we'll need to install the module
local mE = {}
mE.widgets = {}
mE.event_registered = false  -- keep track of whether we've added an event callback or not
mE.module_installed = false  -- keep track of whether the module is module_installed



local function show_name(images)
    if #images ~= 1 then
        dt.print("Select only one image")
        return
    end
    for _, img in ipairs(images) do
        dt.print("Converting: " .. (img.path) .. "/" .. (img.filename ))
  end
end
--[[ We have to create the module in one of two ways depending on which view darktable starts
     in.  In orker to not repeat code, we wrap the darktable.register_lib in a local function.
  ]]

local function install_module()
  if not mE.module_installed then
    local button = dt.new_widget("button"){
      label = _("ShowName"),
      clicked_callback = function()
        show_name(dt.gui.selection())
      end
    }
    -- https://www.darktable.org/lua-api/index.html#darktable_register_lib
    dt.register_lib(
      MODULE_NAME,     -- Module name
      "Button Demo",     -- name that is displayed in scripts manager
      true,                -- expandable
      false,               -- resetable
      {[dt.gui.views.lighttable] = {"DT_UI_CONTAINER_PANEL_RIGHT_CENTER", 100}},   -- containers
      -- https://www.darktable.org/lua-api/types_lua_box.html
      button,
      nil,-- view_enter
      nil -- view_leave
    )
    mE.module_installed = true
  end
end

-- script_manager integration to allow a script to be removed
-- without restarting darktable
local function destroy()
    dt.gui.libs[MODULE_NAME].visible = false -- we haven't figured out how to destroy it yet, so we hide it for now
end

local function restart()
    dt.gui.libs[MODULE_NAME].visible = true -- the user wants to use it again, so we just make it visible and it shows up in the UI
end


-- ... and tell dt about it all
if dt.gui.current_view().id == "lighttable" then -- make sure we are in lighttable view
  install_module()  -- register the lib
else
  if not mE.event_registered then -- if we are not in lighttable view then register an event to signal when we might be
    -- https://www.darktable.org/lua-api/index.html#darktable_register_event
    dt.register_event(
      MODULE_NAME, "view-changed",  -- we want to be informed when the view changes
      function(event, old_view, new_view)
        if new_view.name == "lighttable" and old_view.name == "darkroom" then  -- if the view changes from darkroom to lighttable
          install_module()  -- register the lib
         end
      end
    )
    mE.event_registered = true  --  keep track of whether we have an event handler installed
  end
end

-- set the destroy routine so that script_manager can call it when
-- it's time to destroy the script and then return the data to 
-- script_manager
script_data.destroy = destroy
script_data.restart = restart  -- only required for lib modules until we figure out how to destroy them
script_data.destroy_method = "hide" -- tell script_manager that we are hiding the lib so it knows to use the restart function
script_data.show = restart  -- if the script was "off" when darktable exited, the module is hidden, so force it to show on start

return script_data
-- vim: shiftwidth=2 expandtab tabstop=2 cindent syntax=lua
-- kate: hl Lua;
