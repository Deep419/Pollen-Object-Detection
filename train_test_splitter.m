function [trainSet, validSet, testSet, T] = train_test_splitter(data)


%% delete empty rows
del_ones = ~max(~cellfun('isempty',data{:,2:end}),[],2);
data(del_ones,:) = [];

%% splits in 60-20-20

logical_data = ~cellfun('isempty',data{:,:});
%vector of total patches per class
freq = sum(logical_data,1);
uniq_freq = freq./4; %vector of total UNIQUE patches per class
numClasses = size(freq,2)-1;
start_idx(1) = 0;
end_idx(1) = 0;
for i = 2:size(freq,2)
    temp = find(logical_data(:,i));
    start_idx(i) = temp(1); %starting index in Data where class i images start
    end_idx(i) = temp(end); %starting index in Data where class i images end
end
clear temp;

test_freq = round(.2.*uniq_freq);
train_freq = round(.6.*uniq_freq);
valid_freq = round(.2.*uniq_freq);
%if sum is greater than total unique freq, subtract 1 from valid
extra = train_freq+valid_freq+test_freq > uniq_freq;
valid_freq(extra) = valid_freq(extra) - 1;
%if sum is lesser than total unique freq, add 1 to test
extra = train_freq+valid_freq+test_freq < uniq_freq;
test_freq(extra) = test_freq(extra) + 1;

for i = 2:size(freq,2)
    rng(42);
    %relative randperm between 1 and uniqFreq#
    temp = randperm(uniq_freq(i));
    %Splits temp into 3 based on freq for train,valid,test
    idx_splitted=mat2cell(temp,1,[train_freq(i) valid_freq(i) test_freq(i)]);
    
    %:4 to pick only original images (_0)
    actual_range = start_idx(i) : 4 : end_idx(i);
    
    actual_train_idx = actual_range(idx_splitted{1});
    %Augment Train set by including next 3 images, _dia, _lr, _ud
    actual_train_idx(2,:) = actual_train_idx + 1;
    actual_train_idx(3,:) = actual_train_idx(1,:) + 2;
    actual_train_idx(4,:) = actual_train_idx(1,:) + 3;
    actual_train_idx = actual_train_idx(:);
    
    actual_valid_idx = actual_range(idx_splitted{2});
    %Augment Valid set by including next 3 images, _dia, _lr, _ud
    actual_valid_idx(2,:) = actual_valid_idx + 1;
    actual_valid_idx(3,:) = actual_valid_idx(1,:) + 2;
    actual_valid_idx(4,:) = actual_valid_idx(1,:) + 3;
    actual_valid_idx = actual_valid_idx(:);
    
    actual_test_idx = actual_range(idx_splitted{3});
    
    if i == 2
        trainSet = data(actual_train_idx,:);        
        validSet = data(actual_valid_idx,:);        
        testSet = data(actual_test_idx,:);
    else
        trainSet = vertcat(trainSet,data(actual_train_idx,:));
        validSet = vertcat(validSet,data(actual_valid_idx,:));
        testSet = vertcat(testSet,data(actual_test_idx,:));
    end   
end

%% to test frequencies
array_test = {};
array_valid = {};
array_train = {};
array_total = [];
array_class = {};

[nrows,~] = cellfun(@size,trainSet{:,:});
sum_nrows_train = sum(nrows,1);
[nrows,~] = cellfun(@size,validSet{:,:});
sum_nrows_valid = sum(nrows,1);
[nrows,~] = cellfun(@size,testSet{:,:});
sum_nrows_test = sum(nrows,1);

for i = 2:numClasses+1
    cur_class = testSet.Properties.VariableNames{i};
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