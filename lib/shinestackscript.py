import os
import shutil
import glob
import argparse
from shinestacker import StackJob, CombinedActions, AlignFrames, BalanceFrames, FocusStack, PyramidStack

def getUniqueName(filename):
    counter = 1
    name,ext = os.path.splitext(filename)
    while os.path.exists(filename):
        filename = f"{name}_{counter}{ext}"
        counter +=1 
    return filename


def find_output_file(target_cache_folder):
    generated_files = glob.glob(os.path.join(target_cache_folder, "*.tif*")) + glob.glob(os.path.join(target_cache_folder, "*.png"))
    # FIX: Prevent an IndexError if the folder is empty
    if not generated_files:
        raise FileNotFoundError(f"No stacked output found in {target_cache_folder}. The stacking job may have failed.")
    return generated_files[0]

def rename_output_file(input_directory, generated_file, desired_final_name):
    # FIX: Dynamically grab the actual extension of the generated file
     _, extension = os.path.splitext(generated_file)

     # Route it safely out of the temporary folder directly into your root directory
     final_name = os.path.join(input_directory, f"{desired_final_name}{extension}")

     #if the desired_final_name already exists uniqify the name
     uniqified_name = getUniqueName(final_name)
     return uniqified_name

def clean_up_workspace(target_cache_folder):
    if os.path.exists(target_cache_folder):
        print(f"Purging internal intermediate folders at: {target_cache_folder}")
        shutil.rmtree(target_cache_folder)
        print("Disk space successfully reclaimed!") 
 

def run_shine_stacker(input_directory, output_directory,project_name, desired_final_name):
    # 1. Target the workspace source directory directly
    # Using project_name ensures Shine Stacker isolates operations inside the 'sample' subfolder
    job = StackJob(name=project_name, working_path=input_directory, input_path=input_directory) 

    # 2. Configure alignment and illumination algorithms together
    alignment_module = AlignFrames(transformation="rigid", reference_idx=0)
    balance_module = BalanceFrames(method="mean_luminance")
    job.add_action(CombinedActions("pre_processing", [alignment_module, balance_module], delete_output_at_end=True))
    
    # 3. Schedule the final Focus Stacking stage
    blending_strategy = PyramidStack(levels=6)
    job.add_action(FocusStack(project_name, blending_strategy))
    
    # 4. Execute the pipeline
    print(f"Starting Shine Stacker job inside folder: '{project_name}'...")
    job.run()
    
    # 5. VERIFIED RENAME WORKAROUND: Find and relocate the file
    # Shine Stacker places the final output inside: input_directory/project_name/
    target_cache_folder = os.path.join(input_directory, project_name)
    try:
        generated_file = find_output_file(target_cache_folder)
    except FileNotFoundError as e:
        print(e)
        return

    # 6. Rename the output file
    final_desired_name = rename_output_file(output_directory, generated_file, desired_final_name)
    
    shutil.move(generated_file, final_desired_name)
    print(f"Successfully renamed and saved final output to: {final_desired_name}")

     # 7. FORCE CLEANUP: Now that the file is safely moved out, wipe the intermediate folder
    clean_up_workspace(target_cache_folder)


def run_shinestacker_on_files(image_paths, output_directory, project_name, desired_final_name):
    # 1. Setup an isolated temporary staging workspace
    temp_workspace = os.path.join(output_directory, f"{project_name}_workspace")
    os.makedirs(temp_workspace, exist_ok=True)
    
    # 2. Stage the specific files into the isolated workspace
    print(f"Staging {len(image_paths)} images in temporary workspace...")
    for img_path in image_paths:
        if os.path.exists(img_path):
            # shutil.copy2 preserves file metadata (timestamps, etc.)
            shutil.copy2(img_path, temp_workspace)
        else:
            print(f"Warning: Could not find '{img_path}'. Skipping.")

    run_shine_stacker(temp_workspace, output_directory, project_name, desired_final_name)
    clean_up_workspace(temp_workspace)


#    INPUT_FOLDER = "/mnt/ActiveWork/Photos_Library/Focus_Stacking/export"
#    # Pass exactly the files you want stacked
#    IMAGES_TO_STACK = [
#        "/mnt/ActiveWork/Photos_Library/Focus_Stacking/export/VIN_7317.tif",
#        "/mnt/ActiveWork/Photos_Library/Focus_Stacking/export/VIN_7318.tif",
#        "/mnt/ActiveWork/Photos_Library/Focus_Stacking/export/VIN_7319.tif"
#    ]
#
#    
#    if os.path.exists(INPUT_FOLDER):
#        # Test for run_shine_stacker
#        #run_shine_stacker(INPUT_FOLDER, INPUT_FOLDER, "sample", "caterpillar")
#        # Test for run_shinestacker_on_files
#        run_shinestacker_on_files(IMAGES_TO_STACK,INPUT_FOLDER,"test","plainTiger")
#        
#    else:
#        print(f"Error: Input folder '{INPUT_FOLDER}' does not exist.")

if __name__ == "__main__":
    # Setup argument parser to catch the inputs from the Darktable Lua script
    parser = argparse.ArgumentParser(description="Run Shine Stacker from Darktable.")
    parser.add_argument("--name", required=True, help="Desired final output name")
    parser.add_argument("--outdir", required=True, help="Directory to save the final file")
    
    # nargs='+' means it will accept a space-separated list of any number of files
    parser.add_argument("images", nargs='+', help="List of image paths to stack")
    
    args = parser.parse_args()
    
    if os.path.exists(args.outdir):
        run_shinestacker_on_files(
            image_paths=args.images, 
            output_directory=args.outdir, 
            project_name="dt_stack_job", 
            desired_final_name=args.name
        )
    else:
        print(f"Error: Output folder '{args.outdir}' does not exist.")
