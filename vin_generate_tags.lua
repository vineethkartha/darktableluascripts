local dt = require "darktable"
local du = require "lib/dtutils"
local df = require "lib/dtutils.file"
local dsys = require "lib/dtutils.system"

local MODULE_NAME = "AITagGenerator" -- make sure this is unique, no spaces, no special characters   
local EVENT_NAME = "AItaggenerator" -- must be unique for this script
local EVENT_TYPE = "shortcut" -- the event we want (keyboard shortcut)

du.check_min_api_version("7.0.0", MODULE_NAME)

-- https://www.darktable.org/lua-api/index.html#darktable_gettext
local gettext = dt.gettext.gettext

local function _(msgid)
    return gettext(msgid)
end

-- return data structure for script_manager
local script_data = {}

script_data.metadata = {
    name = "AITagsGenerator",
    purpose = "Generate appropriate tags for images with an LLM",
    author = "Vineeth Kartha",
    help = "abcd" -- this seems important
}

-- script_manager integration to allow a script to be removed
-- without restarting darktable
local function destroy()
    pcall(dt.destroy_event, EVENT_NAME, EVENT_TYPE)
    dt.print("Cleaned up " .. EVENT_NAME)
end

-- set the destroy routine so that script_manager can call it when
-- it's time to destroy the script and then return the data to 
-- script_manager
script_data.destroy = destroy

local function convert_to_temp_jpg(image)
    local temp_file = os.tmpname() .. ".jpg"
    local jpeg_exporter = dt.new_format("jpeg")
    dt.print_log("Exporting: " .. temp_file)
    jpeg_exporter:write_image(image, temp_file, true)
    dt.print_log("Exported to: " .. temp_file)
    return temp_file
end

local function parse_result(output)
    local tags = {}
    local caption = ""
    local writeup = ""

    -- Extract TAGS
    local tags_section = output:match("TAGS:%s*(.-)%s*CAPTION:")
    if tags_section then
        for tag in tags_section:gmatch("([^,%s]+)") do
            table.insert(tags, tag)
        end
    end

    -- Extract CAPTION
    caption = output:match("CAPTION:%s*(.-)%s*WRITEUP:") or ""

    -- Extract WRITEUP
    writeup = output:match("WRITEUP:%s*(.*)") or ""

    dt.print_log("Parsed Tags: " .. table.concat(tags, ", "))
    dt.print_log("Parsed Caption: " .. caption)
    dt.print_log("Parsed Writeup: " .. writeup)
    return tags, caption, writeup
end

local function attach_tags_to_image(image, tags)
    for _, tag in ipairs(tags) do
        dt.print_log("Attaching tag " .. tag .. " to image " .. image.filename)
        local dt_tag = dt.tags.create(tag) -- create or fetch existing tag    
        dt.tags.attach(dt_tag, image) -- attach tag object to image
    end
    dt.print_log("Attached tags to image: " .. table.concat(tags, ", "))
end

local function add_title_to_image(image, title)
    image.title = title
    dt.print_log("Set title for image " .. image.filename .. " to: " .. title)
end

local function add_description_to_image(image, description)
    image.description = description
    dt.print_log("Set description for image " .. image.filename .. " to: " .. description)
end

local function generate_tags_title_description_with_ai(image)
    local jpegfile = convert_to_temp_jpg(image)
    local prompt =
        "You are an expert in image recognition and tagging. Generate a catchy title and generate single word relevant tags. Format the output as: TAGS: tag1, tag2, tag3 CAPTION: A catchy title WRITEUP: A brief writeup about the image. "
    local LLM = "gemma3:4b"
    local cmd = "ollama run " .. LLM .. " " .. prompt .. " " .. jpegfile
    dt.print_log("Running command: " .. cmd)
    local handle = io.popen(cmd)
    dt.print_log("Command executed")
    local result = handle:read("*a")
    handle:close()
    os.remove(jpegfile) -- clean up the temp file
    dt.print_log("Output: " .. result)
    return parse_result(result)
end

local function generate_and_attach(images)
    if #images ~= 1 then
        dt.print("Select only one image")
        return
    end
    for _, img in ipairs(images) do
        dt.print("Converting: " .. (img.path) .. "/" .. (img.filename))
        local tags, caption, writeup = generate_tags_title_description_with_ai(img)
        attach_tags_to_image(img, tags)
        add_title_to_image(img, caption)
        -- add_description_to_image(img, writeup)
    end
end

-- local function generate_

-- defensive cleanup: remove any previous registration with the same name/type
pcall(dt.destroy_event, EVENT_NAME, EVENT_TYPE)

dt.register_event(EVENT_NAME, -- event name (unique id)
EVENT_TYPE, -- event type
function(event, shortcut)
    generate_and_attach(dt.gui.selection())
end, _("attach AI tags and title to the images") -- label shown in Shortcuts prefs
)

return script_data
