local dt = require "darktable"

-- 1. Create the UI Widgets
local name_entry = dt.new_widget("entry") {
    tooltip = "Enter the desired final name",
    text = "stacked_result"
}

-- ====================================================================
-- Export Function (Returns a list of saved file paths)
-- ====================================================================
--- Exports an array of darktable images to a folder in TIFF format.
-- @param image_list table Array of dt_lua_image_t objects to export.
-- @param target_dir string The directory path where images will save.
-- @return table List of absolute file paths to the newly created TIFF files.
local function export_images_to_tiff(image_list)
    local exported_paths = {}
    
    if not image_list or #image_list == 0 then
        dt.print_log("Export canceled: Missing required arguments.")
        return exported_paths
    end    
    
    local tiff_format = dt.new_format("tiff")
    tiff_format.bpp = 16
    
    for i, img in ipairs(image_list) do
       tiff_format.max_width = img.width
       tiff_format.max_height = img.height
       local temp_file = os.tmpname() .. ".tif"

       dt.print("exporting file#: " .. i ..  "/" .. #image_list .. " " .. temp_file)

       -- Providing a valid job frame satisfies the core runtime parameters,
       -- letting write_image process the underlying loop smoothly.
       tiff_format:write_image(img, temp_file)       
       table.insert(exported_paths, temp_file)       
    end
    return exported_paths
end

local stack_button = dt.new_widget("button") {
    label = "Focus Stack",
    tooltip = "Stack the selected images using Shine Stacker",
    clicked_callback = function(widget)
        -- Get currently selected images in the lighttable
        local images = dt.gui.action_images
        
        if #images < 2 then
            dt.print_error("Shine Stacker: Please select at least 2 images to stack.")
            return
        end

        local desired_name = name_entry.text
        if desired_name == "" then
            desired_name = "stacked_result"
        end

        -- Determine the output directory (defaulting to the folder of the first image)
        local out_dir = images[1].path

	local converted_files = export_images_to_tiff(images)

	
	if #images ~= #converted_files then
	   dt.print("Error: Export mismatch! Selected: " .. #images .. ", Converted: " .. #converted_files)
	   dt.print_log("Exiting the script safely.")	   
	   return 
	end
	
	dt.print("converted all files  to tiff")

	-- PATH CONFIGURATION: Update this if your python script is saved somewhere else
        local PYTHON_BIN = "/home/vineeth/shinestacker/.venv/bin/python3.12"
        local PYTHON_SCRIPT_PATH = "/home/vineeth/.config/darktable/lua/darktableluascripts/lib/shinestackscript.py" 

        -- Build the list of file paths to pass to python
        local file_args = ""
        for _, img in ipairs(converted_files) do
            -- Enclose paths in quotes to handle folder names with spaces
            file_args = file_args .. string.format(' "%s"', img)
        end

        -- Construct the terminal command
        local cmd = string.format('%s %s --name "%s" --outdir "%s" %s', 
                                  PYTHON_BIN, PYTHON_SCRIPT_PATH, desired_name, out_dir, file_args)
        
        dt.print("Shine Stacker started... Darktable may pause while processing.")
        
        -- Execute the Python script
        local result = os.execute(cmd)
        
        if result == 0 or result == true then
	   dt.print("Shine Stacker: Successfully stacked into " .. desired_name .. ".tif!")
        else
            dt.print_error("Shine Stacker: Failed. Please check the terminal/console for Python errors.")
        end
	
	local tif_path = out_dir .. "/" .. desired_name .. ".tif"

	-- Import the file into the darktable database
	local image_obj = dt.database.import(tif_path)

	if image_obj then
	   dt.print("Successfully imported: " .. tif_path)
	else
	   dt.print_error("Failed to import: " .. tif_path)
	end
    end
}

-- 2. Register the module in the Lighttable UI
dt.register_lib(
    "shinestacker_gui",          -- unique module name
    "Shine Stacker",             -- title shown in the Darktable UI
    true,                        -- expandable
    false,                       -- resettable
    {[dt.gui.views.lighttable] = {"DT_UI_CONTAINER_PANEL_RIGHT_CENTER", 100}}, -- place in right panel
    dt.new_widget("box") {
        orientation = "vertical",
        name_entry,
        stack_button
    },
    nil, -- view_enter callback
    nil  -- view_leave callback
)
