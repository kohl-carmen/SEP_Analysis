# this was taken from a VirtualImage - Ubuntu - for MNE-C and Freesurfer
#!/bin/bash

export FREESURFER_HOME=/usr/local/FREESURFER_HOME
source $FREESURFER_HOME/SetupFreeSurfer.sh
export SUBJECTS_DIR=$FREESURFER_HOME/SUBJECTS_DIR

my_subject=Beta06

#if DICOM: mri_convert. pick rnd dicom file
shared_dir=/media/sf_Virtual_Shared/Pilot/$my_subject/MRI/
dicom_dir=$(find $shared_dir -name '*ANAT-MEMPRAGE_RMS*')#find mprage dir
file=$(find $dicom_dir -mindepth 1 -print -quit) #mri_conert just needs any file in these, so just select the first one
mri_convert $file new.nii.gz #creates new file in working dir 
mv new.nii.gz ${my_subject}_nifti.nii.gz #rename
mv ${my_subject}_nifti.nii.gz $shared_dir #move 
my_NIfTI=$shared_dir/${my_subject}_nifti.nii.gz

#note:
#no spaces. also, freesurfer does NOT want you to make your own subject folder. just tell it where the general subjects folder is and where your file is and it makes its own folder in subjects dir
# http://surfer.nmr.mgh.harvard.edu/fswiki/RecommendedReconstruction
#my_subject=me
#shared_dir=/media/sf_Virtual_Shared/
#my_NIfTI=$shared_dir/SourcePlay/o05_struc.nii/o05_struc.nii


#================
#FREESURFER
#================
#------------
# Reconstruction
#------------
recon-all -i $my_NIfTI -s $my_subject -all #this takes a day
# this creates a folder for the subject in '\subject'. This folder cannot be in the shared folder because symbolic links are a pain in the butt

#check skull strip
tkmedit $my_subject brainmask.mgz -aux T1.mgz
#check white and plial surfaces
tkmedit $my_subject brainmask.mgz -aux wm.mgz -surfaces
#check segmentation
tkmedit $my_subject brainmask.mgz -surfs -aseg


#================
#MNE-C
#================
#------------
# Dipole Grid
#------------
#create dipole gird on white matter surface (grid of possible dipole locations)
mne_setup_source_space --subject $my_subject #this creates 'bem' folder in subject dir

#------------
# BEM Mesh
#------------
#create BEM model mesh (calculate forward soluation using boundary-elemen model)
#first, segment different surfaces (brain/innter skull)
#I use watershed but for no good reason (https://martinos.org/mne/stable/manual/appendix/bem_model.html#create-bem-model)
mne_watershed_bem --subject $my_subject #creates bem/watershed dir

mne make_scalp_surfaces --subject $my_subject #this is so that I have niver surfaces for the coregistration

#cd${SUBJECTS_DIR}/${my_subject}/bem
#ln -s watershed/${my_subject}_inner_skull_surface${my_subject}-inner_skull.surf
#ln -s watershed/${my_subject}_outer_skin_surface${my_subject}-outer_skin.surf
#ln -s watershed/${my_subject}_outer_skull_surface${my_subject}-outer_skull.surf
#since I can't copy symbolic links, I have to do this nonsense
cd $SUBJECTS_DIR/$my_subject/
cp ./bem//watershed/${my_subject}_inner_skull_surface ./bem/
cp ./bem//watershed/${my_subject}_outer_skull_surface ./bem/
cp ./bem//watershed/${my_subject}_outer_skin_surface ./bem/

cd $SUBJECTS_DIR/$my_subject/bem/
mv ${my_subject}_inner_skull_surface inner_skull.surf
mv ${my_subject}_outer_skull_surface outer_skull.surf
mv ${my_subject}_outer_skin_surface outer_skin.surf

#================
#MNE-Python
#================
#now copy subject folder into virtual shared (ignore symbolic links)
#return to MNE_Python ('Source_Pipe.py')

cp -r -p $SUBJECTS_DIR/$my_subject/$shared_dir
