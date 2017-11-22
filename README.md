# README #

This repo contains all the MATLAB scripts that you will need to create pollen patches and calculate training metrics.

Steps : 

1. Add 'big_image' folder to wherever you clone this repo
2. Add the large pollen images along with GT_data.mat files which contains class_id, names and bboxes.
3. Run patch_create.m script
4. This will create patches folder with folders for each class, along with individual gt files.