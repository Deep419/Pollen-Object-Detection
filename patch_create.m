% Dependency - +patch_script
warning('off');

%% 1 Parameters to change
%if more than 50% of a bounding box cropped by a cropping line it will be discarded
bbox_intersection = 0.5;

%% 2. Load GT and fix names and location
load(['big_image' filesep 'GT_data.mat']);
GT_data.Properties.VariableNames{1} = 'imageFilename';
GT_data.imageFilename = strrep(GT_data.imageFilename,' ','_');
GT_data.imageFilename = fullfile('big_image',GT_data.imageFilename);
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

%% 3. Load Images and match sizes
images = dir(fullfile('big_image','*.tif'));
if size(images,1)==0
     error('Please add images to big_image folder');
     quit;
end
%% 4. Rename Image files
for i = 1:size(images,1)
    fn = images(i).name;
    nn = strrep(fn,' ','_');
    if ~strcmp(fn , nn)
        movefile(fullfile('big_image',fn),fullfile('big_image',nn));
    end
end
clear fn nn;

%if size(GT_data,1) > size(images,1)
    for i = 1:size(images,1)
       idx = find(strcmp(['big_imag\' images(i).name],GT_data.imageFilename));
       if ~isempty(idx)           
            patch_script.makepatch(GT_data,idx,bbox_intersection)
       else
           warning('Image Not found.');
       end
    end    
% %elseif size(GT_data,1) == size(images,1)    
%     for i=1:size(GT_data,1)
%         patch_script.makepatch(GT_data,i,bbox_intersection)
%     end
% %else
%     error('Number of Images in Big_Image folder do not match Size of GT.');
% %end
disp('Function Completed');