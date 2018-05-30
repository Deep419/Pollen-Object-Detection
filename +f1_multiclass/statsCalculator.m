function [averagePrecision, recall, precision, stats, conf_info] = statsCalculator(...
    detectionResults, trainingData, varargin)
%statsCalculator Evaluate the precision metric for object detection.
%   averagePrecision = statsCalculator(detectionResults,
%   groundTruthData) returns average precision to measure the detection
%   performance. For a multi-class detector, averagePrecision is a vector
%   of average precision scores for each object class. The class order
%   follows the same column order as the groundTruthData table.
% 
%   Inputs:
%   -------
%   detectionResults  - a table that has two columns for single-class
%                       detector, or three columns for multi-class
%                       detector. The first column contains M-by-4 matrices
%                       of [x, y, width, height] bounding boxes specifying
%                       object locations. The second column contains scores
%                       for each detection. For multi-class detector, the
%                       third column contains the predicted label for each
%                       detection. The label must be categorical type
%                       defined by the variable names of groundTruthData
%                       table.
%
%   groundTruthData   - a table that has one column for single-class, or
%                       multiple columns for multi-class. Each column
%                       contains M-by-4 matrices of [x, y, width, height]
%                       bounding boxes specifying object locations. The
%                       column name specifies the class label.
%  
%   [..., recall, precision] = evaluateDetectionPrecision(...) returns data
%   points for plotting the precision/recall curve. You can visualize the
%   performance curve using plot(recall, precision). For multi-class
%   detector, recall and precision are cell arrays, where each cell
%   contains the data points for each object class.
%
%   [...] = evaluateDetectionPrecision(..., threshold) specifies the
%   overlap threshold for assigning a detection to a ground truth box. The
%   overlap ratio is computed as the intersection over union. The default
%   value is 0.5.

narginchk(2, 3);

% Validate user inputs
vision.internal.detector.evaluationInputValidation(detectionResults, ...
    trainingData, mfilename, true, varargin{:});

% Hit/miss threshold for IOU (intersection over union) metric
threshold = 0.5;
if ~isempty(varargin)
    threshold = varargin{1};
end

% Match the detection results with ground truth
stats = vision.internal.detector.evaluateDetection(detectionResults, trainingData, threshold);
classList = trainingData.Properties.VariableNames;

% This returns col number for each row thats not empty. i.e class serial
% number.
[~,col] = ind2sub([height(trainingData) width(trainingData)],find(~cellfun(@isempty,table2cell(trainingData))));

conf_mat = zeros(width(trainingData)+1,width(trainingData)+1);
%numExpected = zeros(height(trainingData),1);
low_iou_or_floating_pred = zeros(1,width(trainingData));
missed_gt = zeros(width(trainingData),1);

for i = 1:height(trainingData) % I = image counter
%     for j = 1:width(trainingData)
%         numExpected(j) = numExpected(j) + stats(i,j).NumExpected;
%     end
    for j = 1:width(trainingData) % J = class counter
        current_stats = stats(i,j);
        gtBoxPerClass = trainingData.(trainingData.Properties.VariableNames{j}){i};
        %detPerClass = current_stats.Detections;
        if ~isempty(gtBoxPerClass)
            iou = bboxOverlapRatio(gtBoxPerClass, detectionResults.Boxes{i}, 'union');
            for k = 1:size(iou,1)
                [v, ~] = max( iou(k,:) );
                if v < 0.5
                    missed_gt(j,1) = missed_gt(j,1) + 1;
                end
            end
        end
        low_iou_or_floating_pred(j) = low_iou_or_floating_pred(j) + sum(isnan(current_stats.GroundTruthAssignments));
        conf_mat(j,j) = conf_mat(j,j) + sum(~isnan(current_stats.GroundTruthAssignments));
        if isempty(current_stats.GroundTruthAssignments)
            conf_mat(col(i),j) = conf_mat(col(i),j) + size(current_stats.Detections,1);
        end
        %         missed = ismember((1:stats(i,j).NumExpected)',stats(i,j).GroundTruthAssignments)==0;
        %         stats(i,j).FalseNegative=trainingData.(trainingData.Properties.VariableNames{j}){i}(missed,:);
        %         stats(i,j).TruePositive = stats(i,j).Detections(stats(i,j).labels==1,:);
        %         stats(i,j).FalsePositive = stats(i,j).Detections(stats(i,j).labels==0,:);
        %         tp_gt = [];
        %         for k = 1:size(stats(i,j).GroundTruthAssignments,1)
        %             if ~isnan(stats(i,j).GroundTruthAssignments(k))
        %                 tp_gt = [tp_gt; trainingData.(trainingData.Properties.VariableNames{j}){i}(stats(i,j).GroundTruthAssignments(k),:)];
        %             end
        %         end
        temp = [];
        for g = 1:numel(current_stats.GroundTruthAssignments)
            if ~isnan(current_stats.GroundTruthAssignments(g))
                temp = [temp current_stats.GroundTruthAssignments(g)];
            end
        end
        truePositiveDetections = current_stats.Detections(~isnan(current_stats.GroundTruthAssignments),:);
        truePositiveGT = gtBoxPerClass(temp,:);
        stats(i,j).dist = f1_multiclass.bbox_dist(truePositiveGT, truePositiveDetections);
    end
end

%% Adds missed groundtruth boxes and floating or low IoU detections to confusion matrix
for i = 1:size(low_iou_or_floating_pred,2)
    conf_mat(end,i) = low_iou_or_floating_pred(i);
end
for i = 1:size(missed_gt,1)
    conf_mat(i,end) = missed_gt(i);
end


%% New Section - Computes TPR, FPR, FNR from the confusion matrix
conf_info.confusion_matrix = conf_mat;
conf_info.tpr = zeros(width(trainingData),1);
conf_info.fpr_overall = zeros(width(trainingData),1);
conf_info.fpr_wrongClass = zeros(width(trainingData),1);
conf_info.fpr_lowIoU = zeros(width(trainingData),1);
conf_info.fnr_overall = zeros(width(trainingData),1);
conf_info.fnr_wrongClass = zeros(width(trainingData),1);
conf_info.fnr_lowIoU = zeros(width(trainingData),1);
for i = 1:size(conf_mat,1)-1
%     for j = 1:size(conf_mat,2)-1
%         if (i==j)
            conf_info.tpr(i) = conf_mat(i,i)/sum(conf_mat(i,:));
            
            conf_info.fpr_overall(i) = ( sum(conf_mat(:,i)) - conf_mat(i,i) ) / sum(conf_mat(:,i));
            conf_info.fpr_wrongClass(i) = ( sum(conf_mat(:,i)) - conf_mat(i,i) - conf_mat(end,i) ) / sum(conf_mat(:,i));
            conf_info.fpr_lowIoU(i) = ( conf_mat(end,i) ) / sum(conf_mat(:,i));
            
            conf_info.fnr_overall(i) = ( sum(conf_mat(i,:)) - conf_mat(i,i) ) / sum(conf_mat(i,:));
            conf_info.fnr_wrongClass(i) = ( sum(conf_mat(i,:)) - conf_mat(i,i) - conf_mat(i,end) ) / sum(conf_mat(i,:));
            conf_info.fnr_lowIoU(i) = ( conf_mat(i,end) ) / sum(conf_mat(i,:));
%         end
%     end
end



%% Old Section - Computes P, R, F1
numClasses = width(trainingData);
averagePrecision = zeros(numClasses, 1);
precision        = cell(numClasses, 1);
recall           = cell(numClasses, 1);

% Compute the precision and recall for each class
for c = 1 : numClasses
    
    labels = vertcat(stats(:,c).labels);
    scores = vertcat(stats(:,c).scores);
    numExpected = sum([stats(:,c).NumExpected]);
    
    [ap, p, r] = vision.internal.detector.detectorPrecisionRecall(labels, numExpected, scores);
    
    averagePrecision(c) = ap;
    precision{c} = p;
    recall{c}    = r;
end

if numClasses == 1
    precision = precision{1};
    recall    = recall{1};
end
