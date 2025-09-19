local dt = require "darktable"
local du = require "lib/dtutils"
local utils = require "darktableluascripts/utilities"

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

--- Parses the output string to extract tags, caption, and writeup sections.
-- The expected format of the output string is:
-- "TAGS: tag1, tag2, ... CAPTION: some caption WRITEUP: some writeup"
--
-- @param output string: The input string containing the sections to parse.
-- @return table: A table (array) of tags extracted from the TAGS section.
-- @return string: The caption extracted from the CAPTION section.
-- @return string: The writeup extracted from the WRITEUP section.
local function parse_tags_title(output)
    local tags = {}
    -- Extract TAGS
    local tags_section = output:match("TAGS:%s*(.-)%s*CAPTION:")
    if tags_section then
        for tag in tags_section:gmatch("([^,%s]+)") do
            table.insert(tags, tag)
        end
    end

    -- Extract text after CAPTION:
    local caption = output:match("CAPTION:%s*(.*)")

    -- Clean up caption: keep only alphanumeric characters and spaces
    caption = caption:gsub("[^%w%s]", "")
    -- Extract WRITEUP
    -- writeup = output:match("WRITEUP:%s*(.*)") or ""

    dt.print_log("Parsed Tags: " .. table.concat(tags, ", "))
    dt.print_log("Parsed Caption: " .. caption)
    -- dt.print_log("Parsed Writeup: " .. writeup)
    return tags, caption
end
--[[
  Attaches a list of tags to a given image.

  Parameters:
    image (dt.image_t): The image object to which tags will be attached.
    tags (table): A list (array) of tag strings to be sanitized, created (if not existing), and attached to the image.

  Behavior:
    - Each tag in the provided list is sanitized using the sanitize_tag function.
    - For each sanitized tag, attempts to create the tag or fetch it if it already exists.
    - Attaches each tag object to the specified image.
    - Logs the operation, listing all tags attached to the image.
]]
local function attach_tags_to_image(image, tags)
    for _, tag in ipairs(tags) do
        dt.print_log("Processing tag: " .. tag)
        tag = utils.sanitize_text(tag)
        if tag == "" then
            dt.print_log("Skipping empty tag after sanitization")
            goto continue
        else
            local dt_tag = dt.tags.create(tag) -- create or fetch existing tag    
            dt.tags.attach(dt_tag, image) -- attach tag object to image
        end
        ::continue::
    end
    dt.print_log("Attached tags to image: " .. table.concat(tags, ", "))
end

--[[
  Adds a title to the specified image object.

  @param image (table) The image object to which the title will be assigned. 
            It is expected to have at least a 'filename' property for logging.
  @param title (string) The title to set for the image.

  This function sets the 'title' property of the image object to the provided title string,
  and logs the operation using dt.print_log, including the image's filename and the new title.
]]
local function add_title_to_image(image, title)
    image.title = title
    dt.print_log("Set title for image " .. image.filename .. " to: " .. title)
end

--[[
  Adds a description to the specified image object.

  @param image (table) The image object to which the description will be added.
  @param description (string) The description text to set for the image.

  This function sets the 'description' field of the given image object to the provided description string.
  It also logs the action, including the image's filename and the new description, using dt.print_log.
]]
local function add_description_to_image(image, description)
    image.description = description
    dt.print_log("Set description for image " .. image.filename .. " to: " .. description)
end

--[[
  Generates tags, a catchy title, and a brief description for a given JPEG image using an AI language model.

  This function constructs a prompt for an image recognition and tagging task, then calls an external LLM (Large Language Model)
  via the `ollama` command-line tool to analyze the specified image file. The AI is instructed to return single-word tags,
  a catchy caption, and a brief writeup about the image, all formatted in a specific way. The function logs the command execution
  and output, then parses and returns the result.

  @param jpegfile (string): The file path to the JPEG image to be analyzed.
  @return (table): The parsed result containing tags, caption, and writeup generated by the AI.
]]
local function generate_tags_title_description_with_ai(jpegfile)
    local prompt = "You are an expert in image recognition and tagging." ..
                       " Generate a catchy title and generate single word relevant tags and rate the image for overall appeal." ..
                       " Format the output as: TAGS: tag1, tag2, tag3 CAPTION: A catchy title for social media"
    local LLM = "gemma3:4b"
    local result = utils.call_ollama(LLM, prompt, jpegfile)
    dt.print("Tags and title generated")
    dt.print_hinter("Tags and title generated")
    dt.print_log("Output: " .. result)
    return parse_tags_title(result)
end

--[[
  Generates AI-based tags and a title for a single selected image, attaches them to the image,
  and cleans up any temporary files created during the process.

  Parameters:
    images (table): A table containing image objects. Only one image should be selected.

  Workflow:
    1. Checks if exactly one image is selected; if not, notifies the user and exits.
    2. For the selected image:
      - Prints a message indicating processing has started.
      - Converts the image to a temporary JPEG file for AI processing.
      - Uses AI to generate tags, a caption (title), and a writeup (description).
      - Attaches the generated tags to the image.
      - Adds the generated caption as the image's title.
      - (Optional) Adds the writeup as the image's description (currently commented out).
      - Removes the temporary JPEG file to clean up.

  Note:
    - The functions `convert_to_temp_jpg`, `generate_tags_title_description_with_ai`,
      `attach_tags_to_image`, and `add_title_to_image` are assumed to be defined elsewhere.
    - The function currently only supports processing one image at a time.
--]]
local function generate_and_attach(images)
    for _, img in ipairs(images) do
        dt.print_toast("Generating tags and title for: " .. (img.path) .. "/" .. (img.filename))
        local jpegfile = utils.convert_to_temp_jpg(img)
        dt.print_hinter("Generated temp file: " .. jpegfile)
        local tags, caption = generate_tags_title_description_with_ai(jpegfile)
        attach_tags_to_image(img, tags)
        add_title_to_image(img, caption)
        -- add_description_to_image(img, writeup)
        os.remove(jpegfile) -- clean up the temp file

    end
end

-- defensive cleanup: remove any previous registration with the same name/type
pcall(dt.destroy_event, EVENT_NAME, EVENT_TYPE)

dt.register_event(EVENT_NAME, -- event name (unique id)
EVENT_TYPE, -- event type
function(event, shortcut)
    generate_and_attach(dt.gui.selection())
end, _("attach AI tags and title to the images") -- label shown in Shortcuts prefs
)

return script_data
