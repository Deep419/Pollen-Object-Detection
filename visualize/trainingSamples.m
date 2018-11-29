%% Obsolete for now
function [stats] = trainingSamples(params, data)
dataSize = height(data);
clus = parcluster('local');
pool = parpool('local',clus.NumWorkers);
disp(clus.NumWorkers)

PARAM.por=params.PositiveOverlapRange;
data = table2struct(data);

proposals = zeros(dataSize);
miss = zeros(dataSize);
fprintf('Proposal Progress : ');

parfor imageCtr = 1:dataSize    

    %for imageCtr=1:size(data,1)
    
    % varargin is 1 row of the ground truth table.
    
    % cat all multi-class bounding boxes into one M-by-4 matrix.
    c = struct2cell(data(imageCtr))';
    %s(imageCtr) = vision.internal.cnn.rpn.selectTrainingSamples(params, c{:});
    
    groundTruth = vertcat(c{2:numel(c)});
    %groundTruth = data.ant{imageCtr};
    loc=c{1};
    filename=strsplit(loc,filesep);
    filename=filename{end};
    I = imread(loc);
    
    imageSize = size(I);
    
    inputSize = imageSize;
    
    % find and remove reshape layer.
    layers = nnet.cnn.layer.Layer.getInternalLayers(params.Layers);
    whichOne = cellfun(@(x)isa(x , 'vision.internal.cnn.layer.RPNReshape'), layers);
    layers(whichOne) = [];
    for i = 2:numel(layers)
        inputSize = layers{i}.forwardPropagateSize(inputSize);
    end
    
    featureMapSize = inputSize;
    
    % generate box candidates
    [regionProposals, anchorLocInFeatureMap] = vision.internal.cnn.generateAnchorBoxesInImage(...
        imageSize, featureMapSize, params.MinBoxSizes, params.BoxPyramidScale, params.NumBoxPyramidLevels);
    
    % create anchor Ids for each anchor box. these are required to
    % assign each target to the correct box regressor.
    numAnchors = cellfun(@(x)size(x,1), regionProposals);
    anchorIDs = repelem(1:numel(regionProposals), numAnchors);
    
    % convert from k cells to M-by-2 format.
    regionProposals = (vertcat(regionProposals{:}));
    anchorIndices = (vertcat(anchorLocInFeatureMap{:}));
    
    % Compute the Intersection-over-Union (IoU) metric between the
    % ground truth boxes and the region proposal boxes.
    if isempty(groundTruth)
        iou = zeros(0,size(regionProposals,1));
    elseif isempty(regionProposals)
        iou = zeros(size(groundTruth,1),0);
    else
        
        iou = bboxOverlapRatio(groundTruth, regionProposals, 'union');
    end
    missed=[];
    iou_max_gt = max(iou,[],2);
    if min(iou_max_gt) < PARAM.por(1)
        missed=find(iou_max_gt < PARAM.por(1));
    end
    % Find bboxes that have largest IoU w/ GT.
    [v,idx] = max(iou,[],1);
    
    % Select regions to use as positive training samples
    lower = params.PositiveOverlapRange(1);
    upper = params.PositiveOverlapRange(2);
    positiveIndex =  {v >= lower & v <= upper};
    
    if ~any(positiveIndex{1})
        % select box with highest overlap, but not a negative
        lower = params.NegativeOverlapRange(2);
        positiveIndex =  {v >= lower & v <= upper};
    end
    
    % Select regions to use as negative training samples
    lower = params.NegativeOverlapRange(1);
    upper = params.NegativeOverlapRange(2);
    negativeIndex =  {v >= lower & v < upper};
    
    % remove boxes that have already have positive anchors
    ind = sub2ind(featureMapSize(1:2), anchorIndices(:,2), anchorIndices(:,1));
    
    posind = ind(positiveIndex{1});
    invalid = false(size(ind));
    for i = 1:numel(posind)
        invalid = invalid | (ind == posind(i));
    end
    % make sure negative indices don't contain any positives. This
    % can happen because anchor boxes are centered a 1 position.
    negativeIndex{1}(invalid) = false;
    
    % Create an array that maps ground truth box to positive
    % proposal box. i.e. params is the closest grouth truth box to
    % each positive region proposal.
    if isempty(groundTruth)
        targets = {[]};
    else
        G = groundTruth(idx(positiveIndex{1}), :);
        P = regionProposals(positiveIndex{1},:);
        
        % positive sample regression targets
        targets = vision.internal.rcnn.BoundingBoxRegressionModel.generateRegressionTargets(G, P);
        
        targets = {targets'}; % arrange as 4 by num_pos_samples
        img=I;
        img=insertShape(img,'rectangle',groundTruth,'Color','white');
        img=insertShape(img,'rectangle',P,'Color','red');
%         if ~isempty(missed)
%             img=insertShape(img,'rectangle',groundTruth(missed,:),'Color','green','LineWidth',10);
%         end
%         fn = sprintf('%s/%d_p_%d_m_%d_%s',params.vis_prop,imageCtr,size(P,1),size(missed,1),filename);
        proposals(imageCtr) = size(P,1);
        miss(imageCtr) = size(missed,1);
%         black_img = zeros(2,2,3);
%         if ~isempty(missed)
%             imwrite( black_img , fn );
%         end
    
%     fprintf(repmat('\b',[1 12]));
    end
end
stats.proposals = proposals;
stats.miss = miss;
delete(pool);

end
