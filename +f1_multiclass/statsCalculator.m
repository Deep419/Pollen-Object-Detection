function [averagePrecision, recall, precision, stats] = statsCalculator(...
    detectionResults, trainingData, varargin)
%statsCalculator Evaluate the precision metric for object detection.
%   averagePrecision = evaluateDetectionPrecision(detectionResults,
%   trainingData) returns average precision to measure the detection
%   performance. For a multi-class detector, averagePrecision is a vector
%   of average precision scores for each object class. The class order
%   follows the same column order as the trainingData table.
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
%                       defined by the variable names of trainingData
%                       table.
%
%   trainingData      - a table that has one column for single-class, or
%                       multiple columns for multi-class. Each column
%                       contains M-by-4 matrices of [x, y, width, height]
%                       bounding boxes specifying object locations. The
%                       column name specifies the class label.

narginchk(2, 3);

% Validate user inputs
vision.internal.detector.evaluationInputValidation(detectionResults, ...
    trainingData, mfilename, varargin{:});

% Hit/miss threshold for IOU (intersection over union) metric
threshold = 0.5;
if ~isempty(varargin)
    threshold = varargin{1};
end

% Match the detection results with ground truth
stats = vision.internal.detector.evaluateDetection(detectionResults, trainingData, threshold);

for i = 1:height(trainingData)
    for j = 1:width(trainingData)
    missed = ismember((1:stats(i,j).NumExpected)',stats(i,j).GroundTruthAssignments)==0;
    stats(i,j).FalseNegative=trainingData.(trainingData.Properties.VariableNames{j}){i}(missed,:);
    stats(i,j).TruePositive = stats(i,j).Detections(stats(i,j).labels==1,:);
    stats(i,j).FalsePositive = stats(i,j).Detections(stats(i,j).labels==0,:);
    tp_gt = [];
    for k = 1:size(stats(i,j).GroundTruthAssignments,1)
        if ~isnan(stats(i,j).GroundTruthAssignments(k))
            tp_gt = [tp_gt; trainingData.(trainingData.Properties.VariableNames{j}){i}(stats(i,j).GroundTruthAssignments(k),:)];
        end
    end
    stats(i,j).dist = f1_multiclass.bbox_dist(tp_gt, stats(i,j).TruePositive);
    end
end


numClasses = width(trainingData);
averagePrecision = zeros(numClasses, 1);
precision        = cell(numClasses, 1);
recall           = cell(numClasses, 1);

% Compute the precision and recall for each class
for c = 1 : numClasses
    
    labels = vertcat(stats(:,c).labels);
    scores = vertcat(stats(:,c).scores);
    numExpected = sum([stats(:,c).NumExpected]);
    
    [ap, p, r] = vision.internal.detector.detectorPrecisionRecall(labels, scores, numExpected);
    
    averagePrecision(c) = ap;
    precision{c} = p;
    recall{c}    = r;
end

if numClasses == 1
    precision = precision{1};
    recall    = recall{1};
end