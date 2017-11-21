function gt_aug = pollen_patch_picker_mc (varargin)
%%  This function will take input of which classes to consider, and will output
%   a GT file with all of those classes combined in FRCNN format
% FUTURE - Add subsetter - train/valid/test
gt_aug = table();
sz_ctr = 0;
if strcmp(varargin{1},'all') == 1
    if isunix
        files = dir(fullfile('/users','dghaghar','research','data','pollen','patches','*','*_aug.mat'));
    else
        files = dir(fullfile('Z:','research','data','pollen','patches','*','*_aug.mat'));
    end
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
    %list = id_includer(varargin);
    for i = 1:numel(list)
        id_name = list{i};
        folder = id_name(3:end);
        if length(folder) == 1
            folder = ['00' folder];
        elseif length(folder) == 2
            folder = ['0' folder];
        end
        if isunix
            files = dir(fullfile('/users','dghaghar','research','data','pollen','patches',[folder '*'],'*_aug.mat'));
        else
            files = dir(fullfile('Z:','research','data','pollen','patches',[folder '*'],'*_aug.mat'));
        end
        for ii = 1:size(files,1)
            load([files(ii).folder filesep files(ii).name])
            sz = height(data_aug);
            gt_aug.imageFilename(sz_ctr+1:sz_ctr+sz,1) = data_aug.imageFilename;
            gt_aug.(id_name)(sz_ctr+1:sz_ctr+sz,1) = data_aug.bbox;
            sz_ctr = sz_ctr+ sz;
        end
        %         fn = fullfile('patches',id_name '_aug.mat'];
        %         load(fn);
        %         sz = height(data_aug);
        %         gt_aug.imageFilename(sz_ctr+1:sz_ctr+sz,1) = data_aug.imageFilename;
        %         gt_aug.(id_name)(sz_ctr+1:sz_ctr+sz,1) = data_aug.bbox;
        %         sz_ctr = sz_ctr+ sz;
    end
end
if isempty(strfind(gt_aug.imageFilename{1},'/'))
    gt_aug.imageFilename = strrep(gt_aug.imageFilename,'\',filesep);
else
    gt_aug.imageFilename = strrep(gt_aug.imageFilename,'/',filesep);
end
end

% function list = id_includer(input)
%     list = {};
%     input = strsplit(input,',');
%     for i = 1:size(input,2)
%         current = input{i};
%         strfind(
%     end
% end