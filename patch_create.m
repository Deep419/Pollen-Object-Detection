function patch_create(type)
%PATCH_CREATE This function divides Images into smaller images that can fit
%   on GPU for training. Each big_image gets a folder with its patches
%   along with its augmented version and gt_aug_data.mat file
%
%   Dependencies : +patch_script\* , +other_scripts\textprogressbar.m
%   Last Version Verified : R2018a
%
%   Inputs:
%   -------
%   type  - PSO or GRID


%% 1 Parameters to change
%if more than 50% of a bounding box cropped by a cropping line it will be discarded
bbox_intersection = 0.5;

%% 2. Load GT and fix names and location
load(['big_image' filesep 'GT_data.mat']);
GT_data.Properties.VariableNames{1} = 'imageFilename';
GT_data.imageFilename = strrep(GT_data.imageFilename,' ','_');
test_name = GT_data.imageFilename{1};
if test_name(1:9)~='big_image'
    GT_data.imageFilename = fullfile('big_image',GT_data.imageFilename);
end
%make sure id_num has 3 digits with leading 0's
for i = 1:size(GT_data,1)
    curr_id = GT_data.id{i};
    curr_id = strsplit(curr_id,'_');
    part1 = curr_id{1};
    if length(part1) == 1
        GT_data.id{i} = ['00' part1 '_' curr_id{2:end}];
    elseif length(part1) == 2
        GT_data.id{i} = ['0' part1 '_' curr_id{2:end}];
    end
end
GT_data = sortrows(GT_data,'id','ascend');

%% 3. Load Big Images
images = dir(fullfile('big_image','*.tif'));
if size(images,1)==0
    error('Please add images to big_image folder');
end

%% 4. Rename Big Image files
for i = 1:size(images,1)
    fn = images(i).name;
    nn = strrep(fn,' ','_');
    if ~strcmp(fn , nn)
        movefile(fullfile('big_image',fn),fullfile('big_image',nn));
    end
end
clear fn nn;

save(['big_image' filesep 'GT_data.mat'],'GT_data');

%load(['big_image' filesep 'GT_data.mat']);
images = dir(fullfile('big_image','*.tif'));

clus = parcluster('local');
pool = parpool('local',clus.NumWorkers);
disp(clus.NumWorkers)
%% 5. Start patch creating process
%if size(GT_data,1) < size(images,1)
%    error('gt_data.mat has less images than big_image folder.');
%else
if type=='PSO'
    load(fullfile('misc_mat_data','final_pso_table.mat'));
    for i = 1:size(images,1)
        idx = find(strcmp(['big_image' filesep  images(i).name],GT_data.imageFilename));
        if ~isempty(idx)
            %% IDX = 21, J = best optBox
            gc = cell2mat(final_table.final{idx,1}.grain_cut);
            [maxValue,j] = max(gc);
            j= find(gc == maxValue,1,'first');
            clear gc maxValue;
            patchBoxes = final_table.final{idx,1}.optimalBboxes{j,1};
            patch_script.makePSOPatch(GT_data,idx,bbox_intersection,patchBoxes)
            
        else
            warning('Image Not found.');
        end
    end
elseif type=='GRID'
    parfor i = 1:size(images,1)
        idx = find(strcmp(['big_image' filesep  images(i).name],GT_data.imageFilename));
        if ~isempty(idx)
            patch_script.makeGRIDPatch(GT_data,idx,bbox_intersection)
        else
            warning('Image Not found.');
        end
    end
else
    error('Invalid type entered for patch_create');
end

%end

delete(pool);
disp('Function Completed');
disp('Starting Testing');
warning off;
data = pollen_patch_picker_mc(pwd,'all');
disp('Testing Complete');
