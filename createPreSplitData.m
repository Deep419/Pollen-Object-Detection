data = pollen_patch_picker_mc(pwd,'all');

data_new = data;
fns = data_new.Properties.VariableNames;
for cf = 2:size(fns,2)
    for i = 1:size(data_new,1)
        current = data_new.(fns{cf}){i};
        if isempty(current)
            continue;
        end
        %disp('i');
        [x,~]= ind2sub([size(current,1) 2],find(current(:,[3 4])<28));
        current(x,:) = [];
        data_new.(fns{cf}){i}= current;
    end
end
data = data_new; clear data_new;

[trainData,validData,testData,INFO.data_stats] = train_test_splitter(data);
INFO.data_stats

%% 1 per class section
% curData = testData;
% t = table;
% % trainData = data;
% imageFilename = cell(size(curData,2)-1,1);
% for i = 2:size(curData,2)
%     num = find(~cellfun(@isempty,curData.(curData.Properties.VariableNames{i})),1);
%     bbox = curData.(curData.Properties.VariableNames{i}){num,1};
%     imageFilename{i-1,1} = curData.imageFilename{num,1};
%     temp = cell(size(curData,2)-1,1);
%     temp{i-1,1} = bbox;
%     t.(curData.Properties.VariableNames{i}) = temp;
% end
% t = [table(imageFilename) t];
% 
% testData = t;

%% Save
save(['misc_mat_data' filesep '1perClass_dataset.mat'],'trainData','validData','testData','INFO');