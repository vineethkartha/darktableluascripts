import os
import shutil
import glob
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
    return generated_files[0]

def rename_output_file(input_directory, generated_file, desired_final_name):
     extension = ".tif"
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
 

def run_shine_stacker(input_directory, project_name="sample", desired_final_name="caterpillar"):
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
    generated_file = find_output_file(target_cache_folder)

    # 6. Rename the output file
    final_desired_name = rename_output_file(input_directory, generated_file, desired_final_name)
    
        
    shutil.move(generated_file, final_desired_name)
    print(f"Successfully renamed and saved final output to: {final_desired_name}")

     # 7. FORCE CLEANUP: Now that the file is safely moved out, wipe the intermediate folder
    clean_up_workspace(target_cache_folder)

     
if __name__ == "__main__":
    INPUT_FOLDER = "/mnt/ActiveWork/Photos_Library/Focus_Stacking/export"
    
    if os.path.exists(INPUT_FOLDER):
        # Pass the desired folder structure token name here
        run_shine_stacker(INPUT_FOLDER, project_name="sample")
    else:
        print(f"Error: Input folder '{INPUT_FOLDER}' does not exist.")
