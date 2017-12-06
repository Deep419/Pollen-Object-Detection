%% Dependencies : +patch_script\id_includer.m
function gt_aug = pollen_patch_picker_mc (path, varargin)
%%  This function will take input of which classes to consider, and will output
%   a GT file with all of those classes combined in FRCNN format

gt_aug = table();
sz_ctr = 0;
if strcmp(varargin{1},'all') == 1    
        files = dir(fullfile(path,'patches','*','*_aug.mat'));    
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
else
    list = patch_script.id_includer(varargin);
    for i = 1:numel(list)
        id_name = list(i);
        folder = id_name(3:end);
        if length(folder) == 1
            folder = ['00' folder];
        elseif length(folder) == 2
            folder = ['0' folder];
        end        
        files = dir(fullfile(path,'patches',[folder '*'],'*_aug.mat'));        
        for ii = 1:size(files,1)
            load([files(ii).folder filesep files(ii).name])
            sz = height(data_aug);
            gt_aug.imageFilename(sz_ctr+1:sz_ctr+sz,1) = data_aug.imageFilename;
            gt_aug.(id_name)(sz_ctr+1:sz_ctr+sz,1) = data_aug.bbox;
            sz_ctr = sz_ctr+ sz;
        end
    end
end
if isempty(strfind(gt_aug.imageFilename{1},'/'))
    gt_aug.imageFilename = strrep(gt_aug.imageFilename,'\',filesep);
else
    gt_aug.imageFilename = strrep(gt_aug.imageFilename,'/',filesep);
end
end