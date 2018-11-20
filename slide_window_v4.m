function [bboxes,scores,labels] = slide_window_v4(img, window_sz, detector)
%SLIDE_WINDOW This function computes detection using sliding-window
%approach on large images.
%   
%       bboxes, scores, labels = slide_window_v4(I,1000,detector)
%

[r,c,~] = size(img);

for_i = 1:500:r;
for_j = 1:500:c;
row_div = length(for_i);
row_div = row_div-1;
col_div = length(for_j);
col_div = col_div-1;

img_blocks = cell(row_div,col_div);
bbox_blocks = cell(row_div,col_div);
scores_blocks = cell(row_div,col_div);
labels_blocks = cell(row_div,col_div);

for_i = [for_i-1 r];
for_j = [for_j-1 c];

for i = 1:row_div
    for j = 1:col_div
        img_blocks{i,j} = img(for_i(i)+1:for_i(i+2),for_j(j)+1:for_j(j+2),:);
        [bbox_blocks{i,j}, scores_blocks{i,j}, labels_blocks{i,j}] = ...
            detect(detector, img_blocks{i,j},'NumStrongestRegions',inf,'SelectStrongest',true,'Threshold',0.50);
    end
end

%merge blocks
bboxes_master = [];

for i = 1:row_div
    for j = 1:col_div
        current_bbox = bbox_blocks{i,j};
        %if row 1, dont change row (y)
        if i == 1 && j ~= 1
            current_bbox(:,1) = for_j(j) + current_bbox(:,1);
            %if col 1, dont change col (x)
        elseif i ~= 1 && j == 1
            current_bbox(:,2) = for_i(i) + current_bbox(:,2);
        elseif i ~= 1 && j ~= 1
            current_bbox(:,1) = for_j(j) + current_bbox(:,1);
            current_bbox(:,2) = for_i(i) + current_bbox(:,2);
        end
        bboxes_master = [bboxes_master;current_bbox];
    end
end

%scores and labels master
scores_master = [];
labels_master = [];
for i = 1:row_div
    scores_master = [scores_master; vertcat(scores_blocks{i,:})];
    labels_master = [labels_master; vertcat(labels_blocks{i,:})];
end

[bboxes, scores, labels] = filterBBoxes(bboxes_master, ...
    scores_master, labels_master);


[bboxes, scores, labels] = selectStrongestBboxMulticlass(bboxes, ...
    scores, labels, 'RatioType', 'Min', 'OverlapThreshold', 0.5);

matrix = bboxOverlapRatio(bboxes,bboxes,'Min');


remove_list = [];
for i = 1:size(bboxes,1)
    current = matrix(i,:);
    [m, idx] = sort(current);
    m(idx==i) = [];
    idx(idx==i) = [];
    list = [i];
    for j = 1:length(m)
        if m(j)> 0.5
            list = [list; idx(j)];
        end
    end
    if length(list) > 1
        [mag, id] = max(scores(list));
        remove_list = [remove_list; list(find(list ~= list(id)))];
        
    end
end

remove_list = unique(remove_list,'sorted');
labels(remove_list) = [];
scores(remove_list) = [];
bboxes(remove_list,:) = [];

end

function [bboxes, scores, labels] = filterBBoxes(bboxes, scores, labels)

tooSmall = any((bboxes(:,[4 3]) < [37 37]), 2);

% regression may transform boxes so that they are smaller than
% minSize.
bboxes(tooSmall,:) = [];
scores(tooSmall,:) = [];
labels(tooSmall,:) = [];

tooBig = any((bboxes(:,[4 3]) > [1000 1000]), 2);

bboxes(tooBig,:) = [];
scores(tooBig,:) = [];
labels(tooBig,:) = [];
end
