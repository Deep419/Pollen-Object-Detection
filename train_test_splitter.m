function [trainSet, validSet, testSet, T] = train_test_splitter(data)

del_mat = [];
%delete empty rows
for i = 1:size(data,1)
    if ~numel(find(~cellfun('isempty',data{i,2:end})))
        del_mat = [del_mat i];
    end
end
data(del_mat,:) = [];

%splits in 60-20-20
numClasses = size(data,2)-1;
sz_ctr = 0;
for i = 2:numClasses+1
    sz = numel(find(~cellfun('isempty',data{:, i})));
    if i == 2
        trainSet = vertcat(data(sz_ctr+1:10:sz_ctr+sz,:), ...
            data(sz_ctr+2:10:sz_ctr+sz,:), ...
            data(sz_ctr+3:10:sz_ctr+sz,:), ...
            data(sz_ctr+4:10:sz_ctr+sz,:), ...
            data(sz_ctr+5:10:sz_ctr+sz,:), ...
            data(sz_ctr+6:10:sz_ctr+sz,:));
        
        validSet = vertcat(data(sz_ctr+7:10:sz_ctr+sz,:), ...
            data(sz_ctr+8:10:sz_ctr+sz,:));
        
        testSet = vertcat(data(sz_ctr+9:10:sz_ctr+sz,:), ...
            data(sz_ctr+10:10:sz_ctr+sz,:));
    else
        trainSet = vertcat(trainSet,data(sz_ctr+1:10:sz_ctr+sz,:), ...
            data(sz_ctr+2:10:sz_ctr+sz,:), ...
            data(sz_ctr+3:10:sz_ctr+sz,:), ...
            data(sz_ctr+4:10:sz_ctr+sz,:), ...
            data(sz_ctr+5:10:sz_ctr+sz,:), ...
            data(sz_ctr+6:10:sz_ctr+sz,:));
        
        validSet = vertcat(validSet,data(sz_ctr+7:10:sz_ctr+sz,:), ...
            data(sz_ctr+8:10:sz_ctr+sz,:));
        
        testSet = vertcat(testSet,data(sz_ctr+9:10:sz_ctr+sz,:), ...
            data(sz_ctr+10:10:sz_ctr+sz,:));
    end
    sz_ctr = sz_ctr + sz;
end

%to test frequencies
array_test = {};
array_valid = {};
array_train = {};
array_total = [];
array_class = {};
for i = 2:numClasses+1
    cur_class = testSet.Properties.VariableNames{i};
    array_class{i,1} = cur_class;
    temp_ctr = 0;
    temp_ctr_train = 0;
    temp_ctr_valid = 0;
    temp_ctr_test = 0;
    for j = 1:size(data,1)
        temp_ctr = temp_ctr+ size(data.(cur_class){j},1);
    end
    for j = 1:size(validSet,1)
        temp_ctr_valid = temp_ctr_valid+ size(validSet.(cur_class){j},1);
    end
    for j = 1:size(trainSet,1)
        temp_ctr_train = temp_ctr_train+ size(trainSet.(cur_class){j},1);
    end
    for j = 1:size(testSet,1)
        temp_ctr_test = temp_ctr_test+ size(testSet.(cur_class){j},1);
    end
    array_test{i,1} = sprintf('%d (%.2f%%)',temp_ctr_test,(temp_ctr_test/temp_ctr)*100);
    array_valid{i,1} = sprintf('%d (%.2f%%)',temp_ctr_valid,(temp_ctr_valid/temp_ctr)*100);
    array_train{i,1} = sprintf('%d (%.2f%%)',temp_ctr_train,(temp_ctr_train/temp_ctr)*100);
    array_total(i,1) = temp_ctr;
end
array_percent = [];
for i = 1:size(array_total,1)
   array_percent(i,1) =  (array_total(i)/sum(array_total)) * 100;
end
T = table(array_class,array_train,array_valid,array_test,array_total,array_percent);
T(1,:) = [];
T.Properties.Description = '# of Pollen Grains in Train/Valid/Test set for each class.';
T.Properties.VariableNames = {'Class','Train','Valid','Test','Total','Percent_of_Total'};
