import rawpy
from PIL import Image
import glob
import os
import sys

def convertRAWToJpg(nef_path, jpg_path):
    with rawpy.imread(nef_path) as raw:
        rgb = raw.postprocess()
    Image.fromarray(rgb).save(jpg_path, "JPEG")


def batchConvertRAWToJpg(nef_paths, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    for nef_path in nef_paths:
        base_name = os.path.splitext(os.path.basename(nef_path))[0]
        jpg_path = os.path.join(output_dir, base_name + ".jpg")
        print(f"Converting {nef_path} to {jpg_path}")
        convertRAWToJpg(nef_path, jpg_path)


    # Example usage from command line with wildcards:
    # On Windows Command Prompt:
    #   python raw2jpgConverter.py output_dir C:\path\to\raws\*.NEF
    #
    # On Unix-like shells (bash, zsh):
    #   python raw2jpgConverter.py output_dir /path/to/raws/*.NEF
    #
    # The shell will expand the wildcard (*.NEF) to a list of files before passing them to the script.
    # Make sure to quote paths with spaces, e.g. "C:\My Photos\*.NEF"
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python raw2jpgConverter.py <output_dir> <raw_file1> [<raw_file2> ...]")
        sys.exit(1)
    output_dir = sys.argv[1]

    raw_args = sys.argv[2:]

    # expand wildcards (for Windows where the shell doesn't expand them)
    nef_paths = []
    for arg in raw_args:
        matches = glob.glob(arg)
        if matches:
            nef_paths.extend(matches)
        else:
            nef_paths.append(arg)
    print(nef_paths)
    batchConvertRAWToJpg(nef_paths, output_dir)

