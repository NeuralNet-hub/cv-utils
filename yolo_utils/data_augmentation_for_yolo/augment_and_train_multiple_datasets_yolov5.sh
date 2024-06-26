#!/bin/bash




# ===================== Setting global values (Please modify) ========================== #

# Set workspace and output of the augmentetd dataset Some examples as follow they should be set you once.
workspace=/home/henry/Projects/cv-utils/

# datasset paths
dataset_path=/home/henry/Projects/ultralytics/datasets/your_dataset
final_dataset_path=$dataset_path\final_dataset
train_output=$final_dataset_path/train
val_output=$final_dataset_path/val

# Remove dataset final
rm -r $final_dataset_path

# Check if the path exists and is a directory
if [ ! -d "$dataset_path" ]; then
  echo "ERROR!⚠️⚠️⚠️ Invalid path or path is not a directory: $dataset_path"
  exit 1
fi

# Get the list of immediate subdirectories inside the specified path
folder_list=$(find "$dataset_path" -maxdepth 1 -mindepth 1 -type d)


# ===================== Create path final_dataset ========================== #

if [ -d $final_dataset_path ] 
then
    echo Directory $final_dataset_path exists. It will be removed
    rm -r $final_dataset_path
    mkdir $final_dataset_path
else
    echo Creating path $final_dataset_path ...
    mkdir $final_dataset_path
fi




# ===================== Activate a screen using 'screen -S augmentation_train' ========================== #

# virtualenv activation
virtualenv_path=`which virtualenvwrapper.sh`
source $virtualenv_path

workon general




# ============================================================================================== #
#  ____            _                          _       _ 
# |  _ \    __ _  | |_    __ _   ___    ___  | |_    / |
# | | | |  / _` | | __|  / _` | / __|  / _ \ | __|   | |
# | |_| | | (_| | | |_  | (_| | \__ \ |  __/ | |_    | |
# |____/   \__,_|  \__|  \__,_| |___/  \___|  \__|   |_|
# ============================================================================================== #



# ===================== Setting data for each dataset and augmentations (Please modify) ========================== #




# Set the augment_val flag
augment_val=false

# ===================== Setting data for each dataset and augmentations ========================== #

# Iterate over folder_list
for folder in $folder_list; do
    # Print folders
    echo "Applying data augmentation for folder :"
    echo $folder

    # For each dataset you neet to set these variables.
    train_orig=$folder/train_orig
    var_orig=$folder/val
    augment_val= false # false is recommended
    
    
    # numpy augmentation
    echo Applying numpy augmentations for dataset $train_orig ...
    cd $workspace/yolo_utils/data_augmentation_for_yolo/numpy_augmentation/
    #python full_data_aug.py -i $train_orig -o $train_output --random_scale --random_translate --rotate --random_shear --random_HSV --random_noise --random_bright_contrast --sequence --copy_orig --gray # No flip
    python full_data_aug.py -i $train_orig -o $train_output --full # All augmentations
    echo sleeping 3 minutes in order to assert augmentations finish, Zzzz...
    sleep 5

    # geometric bboxes augmentations
    cd $workspace/yolo_utils/data_augmentation_for_yolo/pytorch_augmentation/
    python geometric_bboxes.py -i $train_orig -o $train_output --rotate --translateX --translateY --shearX --shearY
    # python geometric_bboxes.py -i $train_orig -o $train_output --full
    echo sleeping 1 minute in order to assert augmentations finish, Zzzz...
    sleep 5

    # geometric bboxes augmentations
    cd $workspace/yolo_utils/data_augmentation_for_yolo/pytorch_augmentation/
    python color_bboxes.py -i $train_orig -o $train_output --cutout --equalize
    # python color_bboxes.py -i $train_orig -o $train_output --full
    echo sleeping 1 minute in order to assert augmentations finish, Zzzz...
    sleep 5

    # copy/move the validation dataset
    if [ -d $var_orig ] 
    then
        echo Moving validation dataset: $val_orig
        cp -r $var_orig $val_output
    else
        echo "WARNING! ⚠️ Validation dataset ($var_orig) doesn't exist "
    fi
done

# ============================== End augmentations code for the dataset =================================== #





# ============================================================================================== #
# __   __   ___    _        ___            ____  
# \ \ / /  / _ \  | |      / _ \  __   __ | ___| 
#  \ V /  | | | | | |     | | | | \ \ / / |___ \ 
#   | |   | |_| | | |___  | |_| |  \ V /   ___) |
#   |_|    \___/  |_____|  \___/    \_/   |____/ 
# ============================================================================================== #                          



#screen -S yolov5
workon yolov5

# change to yolov5 path
yolov5_path=/home/henry/Projects/yolo/yolov5/
cd $yolov5_path
git pull
pip install -r requirements.txt

# config parameters yolov5
weights='yolov5s.pt'
data=$dataset_path/data.yaml # dataset_path has been defined above (at the beginning)
wandb_project='yourwandbproject' # wandb will save with this name, same as local
name_project='SmallV2'
bs=160 # batch size for 4 TeslaV100 32GB
epochs=300 # put 100 in case of retrain
patience=50 # put 20 in case of retrain
cache=ram # ram in case augmented dataset is less than 100K images otherwise put disk
workers=16 # still don't know how to put all cores automatically



# Local train or 1 GPU
python train.py --weights $weights --data $data --epochs $epochs --batch-size -1 --workers $workers --project $wandb_project --name $name_project --cache $cache --patience $patience --exist-ok

# python -m torch.distributed.launch --nproc_per_node 4 train.py --weights $weights --data $data --epochs $epochs --batch-size $bs --workers $workers --project $wandb_project --name $name_project --cache $cache --patience $patience --exist-ok



