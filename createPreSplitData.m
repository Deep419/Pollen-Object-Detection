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
    %INFO.data_stats
    
    % Save
    save(['misc_mat_data' filesep type_name '_full_dataset.mat'],'trainData','validData','testData','INFO');
    
else
    %% 1 per class dataSet
    logical_data = ~cellfun('isempty',data_new{:,:});
    %vector of total patches per class
    numClasses = size(logical_data,2)-1;
    start_idx(1:3,numClasses+1) = 0;
    for i = 2:size(logical_data,2)
        temp = find(logical_data(:,i));
        if size(temp,1)<9
            start_idx(1,i) = temp(1); %starting index in Data where class i images start
            start_idx(2,i) = temp(2);
            start_idx(3,i) = temp(3);
            continue;
        end
        start_idx(1,i) = temp(1); %starting index in Data where class i images start
        start_idx(2,i) = temp(5);
        start_idx(3,i) = temp(9);
    end
    clear temp;
    trainData = data_new(start_idx(1,2:end),:);
    validData = data_new(start_idx(2,2:end),:);
    testData = data_new(start_idx(3,2:end),:);
    
    %% to test frequencies
    array_test = {};
    array_valid = {};
    array_train = {};
    array_total = [];
    array_class = {};
    
    [nrows,~] = cellfun(@size,trainData{:,:});
    sum_nrows_train = sum(nrows,1);
    [nrows,~] = cellfun(@size,validData{:,:});
    sum_nrows_valid = sum(nrows,1);
    [nrows,~] = cellfun(@size,testData{:,:});
    sum_nrows_test = sum(nrows,1);
    
    for i = 2:numClasses+1
        cur_class = testData.Properties.VariableNames{i};
        array_class{i,1} = cur_class;
        temp_ctr_train = sum_nrows_train(i);
        temp_ctr_valid = sum_nrows_valid(i);
        temp_ctr_test = sum_nrows_test(i);
        
        array_test{i,1} = sprintf('%d ',temp_ctr_test);
        array_valid{i,1} = sprintf('%d ',temp_ctr_valid);
        array_train{i,1} = sprintf('%d ',temp_ctr_train);
    end
    T = table(array_class,array_train,array_valid,array_test);
    T(1,:) = [];
    T.Properties.Description = '# of Pollen Grains in Train/Valid/Test set for each class.';
    T.Properties.VariableNames = {'Class','Train','Valid','Test'};
    INFO.data_stats = T;
    % Save
    save(['misc_mat_data' filesep type_name '_1per_dataset.mat'],'trainData','validData','testData','INFO');
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