function createPreSplitData(type)

fullDatasetFlag = 0;
switch type
    case 'GRI'
        type_name = 'grid';
    case 'PSO'
        type_name = 'pso';
    otherwise
        error("Invalid 'Type' selected. Choices are 'GRI' for grid or 'PSO' for pso");
end


%% This section removes all GT boxes with W or H less than 28
data = pollen_patch_picker_mc(pwd,type,'all');
data_cell = data{:,:};
trimmed_data = cellfun(@checkWHdim,data_cell,'UniformOutput',false);
data_new = cell2table(trimmed_data);
data_new.Properties.VariableNames = data.Properties.VariableNames;
clear data data_cell trimmed_data

%% Split data_new
if fullDatasetFlag
    [trainData,validData,testData,INFO.data_stats] = train_test_splitter(data_new);
    INFO.data_stats
    
    % Save
    save(['misc_mat_data' filesep type_name '_full_dataset.mat'],'trainData','validData','testData','INFO');
    
else    
%% 1 per class dataSet    
    logical_data = ~cellfun('isempty',data_new{:,:});
    %vector of total patches per class
    numClasses = size(logical_data,2)-1;
    start_idx(1) = 0;
    for i = 2:size(logical_data,2)
        temp = find(logical_data(:,i));
        start_idx(i) = temp(1); %starting index in Data where class i images start
    end
    clear temp;
    trainData = data_new(start_idx(2:end),:);
    
    % Save
    save(['misc_mat_data' filesep type_name '_1per_dataset.mat'],'trainData');
end

end

%% Function handles
function trimmed_gt = checkWHdim (gt)
% This function removes all GT boxes with W or H less than 28 due to DNN
% architecture constraints.
if isempty(gt)
    trimmed_gt = [];
else
    [x,~]= ind2sub([size(gt,1) 2],find(gt(:,[3 4])<28));
    gt(x,:) = [];
    trimmed_gt= gt;
end
end