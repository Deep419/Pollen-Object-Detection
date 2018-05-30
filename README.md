# README #

This repo contains all the MATLAB scripts that you will need to create pollen patches and calculate training metrics.

Steps : 

1. Add 'big_image' folder to wherever you clone this repo
2. Add the large pollen images along with GT_data.mat files which contains class_id, names and bboxes.
    Link to big_images : https://www.dropbox.com/work/collab-shin-group/archive/data/pollen/lund/2017/129-class-data
    Last Updated : 3/1/2018
    Count : 129 Classes
3. Run patch_create.m script
4. This will create patches folder with folders for each class, along with individual gt files.