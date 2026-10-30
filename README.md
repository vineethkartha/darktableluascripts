# Darktable Lua Scripts

A collection of custom Lua scripts, utilities, and demos for [Darktable](https://www.darktable.org/) to automate workflows, manage metadata, and integrate with external tools like FastRawViewer and ShineStacker.

## Repository Structure

### Core Scripts
* **`vin_attach_exif_tags.lua`**: Automatically extracts relevant EXIF metadata from your images and attaches them as Darktable tags.
* **`vin_generate_tags.lua`**: Generates and applies custom tags to selected images in the Lighttable view.
* **`vin_ex_fastrawviewer.lua` & `vin_launchFastRawViewer.lua`**: Integration scripts to seamlessly launch and pass selected RAW files from Darktable directly into [FastRawViewer](https://www.fastrawviewer.com/) for rapid culling and analysis.
* **`vin_resyncXMPFiles.lua`**: Resynchronizes XMP sidecar files with the Darktable database, useful when metadata has been modified by external applications.
* **`vin_stackwithShineStacker.lua`**: Exports and processes selected images for focus stacking using ShineStacker (works in conjunction with `lib/shinestackscript.py`).

### Libraries (`lib/`)
* **`utilities.lua`**: Shared helper functions and common utilities required by the main Lua scripts.
* **`shinestackscript.py`**: Python backend helper script invoked by `vin_stackwithShineStacker.lua` to handle the stacking pipeline.

### Demos & Examples (`demos/`)
* **`vin_ex_button.lua`**: Demonstrates how to create and register custom UI buttons within the Darktable interface.
* **`vin_ex_shortcut.lua`**: Shows how to register custom keyboard shortcuts in Darktable via Lua.
* **`vin_exportFile.lua`**: A demonstration of handling custom file export workflows programmatically.
* **`vin_os_commands_demo.lua`**: Examples of executing external operating system commands safely from within Darktable's Lua environment.

---

## 🚀 Installation

1. **Locate your Darktable configuration directory:**
   * **Linux / macOS:** `~/.config/darktable/`
   * **Windows:** `C:\Users\<YourUsername>\AppData\Local\darktable\`

2. **Clone this repository into your `lua` folder:**
   ```bash
   cd ~/.config/darktable/
   git clone https://github.com/vineethkartha/darktableluascripts.git lua
   ```
   *(Note: If you already have a `lua` folder, clone this repository into a subdirectory or copy the files over).*

3. **Enable the scripts via `luarc`:**
   Open (or create) the `luarc` file inside your `~/.config/darktable/` directory and require the scripts you want to load on startup. For example:
   ```lua
   require "vin_attach_exif_tags"
   require "vin_generate_tags"
   require "vin_launchFastRawViewer"
   require "vin_resyncXMPFiles"
   require "vin_stackwithShineStacker"
   ```

---

## Prerequisites & Configuration

* **Darktable:** Built with Lua support enabled.
* **Python 3:** Required if you are using `vin_stackwithShineStacker.lua` (which relies on `lib/shinestackscript.py`).
* **External Applications:** Ensure that executables for external tools (such as **FastRawViewer** or **ShineStacker**) are either added to your system's `PATH` or properly configured within Darktable's Lua preferences/script variables.
