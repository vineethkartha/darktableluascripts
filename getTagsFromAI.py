import rawpy
from PIL import Image
import subprocess
import sys
import os
import pathlib

def convertRAWToJpg(nef_path, jpg_path):
    with rawpy.imread(nef_path) as raw:
        rgb = raw.postprocess()
    Image.fromarray(rgb).save(jpg_path, "JPEG")

def generate_caption(jpg_path):
    prompt = f"""
    For this photo: {jpg_path}
    1. Output a line starting with TAGS: followed by 10 short descriptive tags, comma-separated.
    2. Output a line starting with CAPTION: with a short 1-line catchy caption.
    3. Output a line starting with WRITEUP: with a 3-sentence writeup.
    """
    result = subprocess.run(
        ["ollama", "run", "llava", prompt],
        capture_output=True, text=True, encoding="utf-8", errors="ignore"
    )
    return result.stdout

if __name__ == "__main__":
    nef_file = sys.argv[1]
    jpg_file = nef_file.rsplit(".", 1)[0] + ".jpg"

    outfile = sys.argv[2]

    # Convert NEF → JPG
    convertRAWToJpg(nef_file, jpg_file)

    # Generate tags/caption/writeup
    output = generate_caption(jpg_file)
    print(output)
   
    user_input = input("Would you like to [a]ccept, [e]edit or [r]egenerate the output: ")
    while True:
        if user_input.lower() == 'a':
            break
        elif user_input.lower() == 'e':
            temp_file = "temp_output.txt"
            pathlib.Path(temp_file).write_text(output, encoding="utf-8")
            os.system(f"notepad {temp_file}")
            output = pathlib.Path(temp_file).read_text(encoding="utf-8")
            os.remove(temp_file)
            print(output)
        elif user_input.lower() == 'r':
            output = generate_caption(jpg_file)
            print(output)
        else:
            print("Invalid input. Please enter 'a', 'e', or 'r'.")
        
        user_input = input("Would you like to [a]ccept, [e]edit or [r]egenerate the output: ")
    # Delete temp JPG
    if os.path.exists(jpg_file):
        os.remove(jpg_file)

    pathlib.Path(outfile).write_text(output, encoding="utf-8")
    a = input("Press Enter to continue...")