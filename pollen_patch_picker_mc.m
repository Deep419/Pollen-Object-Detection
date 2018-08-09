function gt_aug = pollen_patch_picker_mc (path,type,pattern,varargin)
%%  This function will take input of which classes to consider, and will output
%   a GT file with all of those classes combined in FRCNN format
%
%   if PATTERN = ALL, no varargin required
%   if PATTERN = CONTINOUS, nargin is multiple of 2, first is start, second
%       is end
%   if PATTERN = DISCRETE, nargin is specific id's

switch type
    case 'GRI'
        type_name = 'grid';
    case 'PSO'
        type_name = 'pso';
    otherwise
        error("Invalid 'Type' selected. Choices are 'GRI' for grid or 'PSO' for pso");
end

id_list = [];
files = dir(fullfile(path,[type_name '_patches'],'*','*_aug.mat'));
for i = 1:size(files,1)
    load([files(i).folder filesep files(i).name])
    id_name = strsplit(files(i).folder,filesep);
    id_name = strsplit(id_name{end},'_');
    id_list(i) = str2num(id_name{1});
    files(i).id = str2num(id_name{1});
end
available_id_list = unique(id_list);

switch pattern
    % All picks all ids/class
    case 'all'
        gt_aug = pick_aug_data_from_patches(files);
        
    % Continous picks range of ids
    case 'continous'
        required_id_list = sort(cell2mat(reshape(varargin,[2 (nargin-3)/2])),2);
        if ismember(required_id_list,available_id_list)
            t = [];
            for col = 1:size(required_id_list,2)
                t = [t (required_id_list(1,col):required_id_list(2,col))];
            end
            required_id_list = t;
            tabFiles = struct2table(files);
            files = files(ismember(tabFiles.id, required_id_list));
            gt_aug = pick_aug_data_from_patches(files);
        else
            error('Out of range ID inserted. Check your entered ids');
        end
        
    case 'discrete'
        required_id_list = sort(cell2mat(varargin));
        if ismember(required_id_list,available_id_list)           
            tabFiles = struct2table(files);
            files = files(ismember(tabFiles.id, required_id_list));
            gt_aug = pick_aug_data_from_patches(files);
        else
            error('Out of range ID inserted. Check your entered ids');
        end
    otherwise
        error("Invalid 'Pattern' selected. Choices are 'all', 'continous', and 'discrete'");
end

gt_aug.imageFilename = fullfile(gt_aug.imageFilename);
end

function gt_aug = pick_aug_data_from_patches(files)
warning off;
gt_aug = table();
sz_ctr = 0;
for i = 1:size(files,1)
    load([files(i).folder filesep files(i).name])
    id_name = strsplit(files(i).folder,filesep);
    id_name = strsplit(id_name{end},'_');
    id_name = ['id_' id_name{1}];
    sz = height(data_aug);
    gt_aug.imageFilename(sz_ctr+1:sz_ctr+sz,1) = data_aug.imageFilename;
    gt_aug.(id_name)(sz_ctr+1:sz_ctr+sz,1) = data_aug.bbox;
    sz_ctr = sz_ctr+ sz;
end
end