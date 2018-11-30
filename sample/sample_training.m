TIME.ScriptStart = clock;
warning('off')
% gpuDevice
% tic
% profile on

%% 1.  PARAMETERS & SETTINGS

% Code
INFO.codeVersion = 'sample_training';
INFO.title = 'This is a sample training script.';

% Dataset
DATASET.preloaded = 'YES'; %YES if you wanna load presplit data with all classes, NO if using any class 
DATASET.type = 'GRID'; % GRID or PSO
DATASET.size = 'one_each'; % FULL or one_each

% Network
PARAM.savedNet = false;
PARAM.model_loc = ['pretrained_networks' filesep 'alex_net.mat'];
PARAM.epochsPerCycle = 1;
PARAM.noImproveCycleCount = 75;
PARAM.aug = 1;
%PARAM.useK = false;
%PARAM.K=0;

% Visualize
VIS.trainingProposals = false;
VIS.trainResults = false;
VIS.validResults = false;
VIS.testResults = false;

% RCNN Settings
PARAM.frcnnDefaultOpts = 0;
PARAM.nor=0.35;
PARAM.por=0.75;
PARAM.NegativeOverlap = [0 PARAM.nor];
PARAM.PositiveOverlap = [PARAM.por 1];
PARAM.BoxPyramidScale = 1.5;
PARAM.NumBoxPyramidLevels = 10;
PARAM.NumStrongestRegions=200;
PARAM.minAnchorSz=28;
PARAM.minAnchorRatio = 1.5;



%% 2.  DIRECTORY SETUP

% Directories
DIR.output = sprintf ( 'output_%s', INFO.codeVersion );
DIR.checkpoint = sprintf ( '%s/checkpoint', DIR.output );
DIR.visualize_proposals = sprintf ( '%s/vis_proposals',DIR.output );
DIR.trainResults = sprintf ( '%s/trainResults',DIR.output );
DIR.validResults = sprintf ( '%s/validResults',DIR.output );
DIR.testResults = sprintf ( '%s/testResults',DIR.output );

mkdir ( DIR.output );
mkdir ( DIR.checkpoint );
mkdir ( DIR.visualize_proposals );
if VIS.trainResults
    mkdir ( DIR.trainResults );
end
if VIS.validResults
    mkdir ( DIR.validResults );
end
if VIS.testResults
    mkdir ( DIR.testResults );
end

%Path to POLLEN-MASTER
if ispc
    DIR.pollenpath = 'D:\Deep\repos\pollen-master';
elseif isunix
    DIR.pollenpath = '/users/dghaghar/research/data/pollen/pollen-master';
end
addpath(genpath(DIR.pollenpath));



%% 3.  LOAD DATASET
if strcmp(DATASET.preloaded,'YES')
    if strcmp(DATASET.size,'FULL')
        if strcmp(DATASET.type,'GRID')
            load(fullfile(DIR.pollenpath,'misc_mat_data','grid_full_dataset.mat'));
        else
            load(fullfile(DIR.pollenpath,'misc_mat_data','pso_full_dataset.mat'));
        end
    else %one_each dataset
        if strcmp(DATASET.type,'GRID')
            load(fullfile(DIR.pollenpath,'misc_mat_data','grid_1per_dataset.mat'));
        else
            load(fullfile(DIR.pollenpath,'misc_mat_data','pso_1per_dataset.mat'));
        end
    end
else
    data = pollen_patch_picker_mc(pwd,'GRI','discrete',1);
    [trainData,validData,testData,INFO.data_stats] = train_test_splitter(data);
end

trainData.imageFilename = fullfile(DIR.pollenpath,strrep(trainData.imageFilename,'\',filesep));
validData.imageFilename = fullfile(DIR.pollenpath,strrep(validData.imageFilename,'\',filesep));
testData.imageFilename = fullfile(DIR.pollenpath,strrep(testData.imageFilename,'\',filesep));
TIME.AfterDataLoad = clock;
INFO.data_stats

fprintf (' \n Time for Data Load :  %f \n', etime(TIME.AfterDataLoad , TIME.ScriptStart));



%% 4.  SCRATCH OR FINE-TUNE

if exist(fullfile(DIR.output,'stats_all.mat'))==2
    PARAM.trainType = 'FINETUNE';
    load(fullfile(DIR.output,'stats_all.mat'))
    load(fullfile(DIR.output,'time_all.mat'))
    prevLoop = size(STATS.f1TrainV,2);
    loopCt = prevLoop + 1;
    load(fullfile(DIR.output,sprintf('frcnn_loop_%02d.mat',prevLoop)));
    detectorPrev = detector;
    clear detector;
    [~, bestValidIdx] = max ( STATS.f1ValidV );
    load(fullfile(DIR.output,sprintf('frcnn_loop_%02d.mat',bestValidIdx)));
    detectorBest = detector;
    clear detector;
    moreLoop = true;
    load(fullfile(DIR.output,'stats_all'));
else
    PARAM.trainType = 'SCRATCH';
end



%% 5.  NETWORK ARCHITECTURE IF SCRATCH
if strcmp(PARAM.trainType,'SCRATCH')
    
    %Using a known network?
    if PARAM.savedNet
        load(PARAM.model_loc)
        net = alexnet;
        layersTransfer = net.Layers(1:end-3);
        numClasses = numel(trainData.Properties.VariableNames);
        layers = [
            layersTransfer
            fullyConnectedLayer(numClasses,'WeightLearnRateFactor',20,'BiasLearnRateFactor',20)
            softmaxLayer
            classificationLayer];
        
    % Or building a network from scratch?
    else 
        numImageCategories = numel(trainData.Properties.VariableNames);
        imageSize = [100 100 3];
        numChannels = 3;
        filterSize = [5 5];
        numFilters = 32;
        layers = [
            imageInputLayer(imageSize);
            convolution2dLayer(filterSize, numFilters, 'Padding', 2)
            reluLayer()
            maxPooling2dLayer(3, 'Stride', 3)
            convolution2dLayer(filterSize, numFilters, 'Padding', 2)
            reluLayer()
            maxPooling2dLayer(3, 'Stride',3)
            convolution2dLayer(filterSize, 2 * numFilters, 'Padding', 2)
            reluLayer()
            maxPooling2dLayer(3, 'Stride',3)
            fullyConnectedLayer(64)
            reluLayer
            fullyConnectedLayer(numImageCategories)
            softmaxLayer
            classificationLayer
            ];
        layers(2).Weights = normrnd(0,(1/prod([filterSize numChannels])),[filterSize numChannels numFilters]);
    end
end



%% 6.  FOUR STEP TRAINING OPTIONS

optionsStage1 = trainingOptions('sgdm', ...
    'MaxEpochs', 1, ...
    'InitialLearnRate', 1e-5);

optionsStage2 = trainingOptions('sgdm', ...
    'MaxEpochs', PARAM.epochsPerCycle, ...
    'InitialLearnRate', 1e-5);

optionsStage3 = trainingOptions('sgdm', ...
    'MaxEpochs', 1, ...
    'InitialLearnRate', 1e-6);

optionsStage4 = trainingOptions('sgdm', ...
    'MaxEpochs', PARAM.epochsPerCycle, ...
    'InitialLearnRate', 1e-6, ...
    'CheckpointPath', DIR.checkpoint );

options = [
    optionsStage1
    optionsStage2
    optionsStage3
    optionsStage4
    ];



%% 5.  VISUALIZE PROPOSAL BOXES
PROPS = load('pollen_vis_params.mat');%------ Layers would change if using different Layers
if ~PARAM.frcnnDefaultOpts
    PROPS.params.PositiveOverlapRange = PARAM.PositiveOverlap;
    PROPS.params.NegativeOverlapRange = PARAM.NegativeOverlap;
    PROPS.params.BoxPyramidScale = PARAM.BoxPyramidScale;
    PROPS.params.NumBoxPyramidLevels = PARAM.NumBoxPyramidLevels;
    a = sqrt((PARAM.minAnchorSz^2)/PARAM.minAnchorRatio);
    b = PARAM.minAnchorRatio * a;
    PARAM.MinBoxSizes = [PARAM.minAnchorSz PARAM.minAnchorSz];
    %PARAM.MinBoxSizes = [PARAM.MinBoxSizes; a b; b a];
    PROPS.params.MinBoxSizes = PARAM.MinBoxSizes;
end
% VIS.params.NumAnchors= 9;
PROPS.params.vis_prop = DIR.visualize_proposals;
%cumprod([1 repelem(PROPS.params.BoxPyramidScale, PROPS.params.NumBoxPyramidLevels-1)])
if VIS.trainingProposals
    stats = trainingSamples(PROPS.params, trainData(2:end,:));
    save(sprintf ('%s/proposal_stats.mat', DIR.output),'stats'); clear stats;
end

%% 6.  TRAIN (keep going only if the validation F1 is higher)

if strcmp(PARAM.trainType,'SCRATCH')
    moreLoop = true;
    loopCt = 1;
    
    STATS.f1TrainV = [];
    STATS.f1ValidV = [];
    STATS.f1TestV = [];
end

TIME.NetworkStart = [];
TIME.NetworkEnd = [];
TIME.F1Stop = [];

while ( moreLoop == true )
    TIME.NetworkStart(loopCt,:) = clock;
    if ( loopCt == 1 )
        if PARAM.frcnnDefaultOpts
            detector = trainFasterRCNNObjectDetector ...
                (trainData, layers, options, ...
                'NegativeOverlapRange', PARAM.NegativeOverlap, ...
                'PositiveOverlapRange', PARAM.PositiveOverlap);
        else
            detector = trainFasterRCNNObjectDetector ...
                (trainData, layers, options, ...
                'NegativeOverlapRange', PARAM.NegativeOverlap, ...
                'PositiveOverlapRange', PARAM.PositiveOverlap, ...
                'BoxPyramidScale', PARAM.BoxPyramidScale, ...
                'NumBoxPyramidLevels', PARAM.NumBoxPyramidLevels, ...
                'MinBoxSizes', PARAM.MinBoxSizes);
        end
        
    else
        if PARAM.frcnnDefaultOpts
            detector = trainFasterRCNNObjectDetector ...
                (trainData, detectorPrev, options, ...
                'NegativeOverlapRange', PARAM.NegativeOverlap, ...
                'PositiveOverlapRange', PARAM.PositiveOverlap);
        else
            detector = trainFasterRCNNObjectDetector ...
                (trainData, detectorPrev, options, ...
                'NegativeOverlapRange', PARAM.NegativeOverlap, ...
                'PositiveOverlapRange', PARAM.PositiveOverlap, ...
                'BoxPyramidScale', PARAM.BoxPyramidScale, ...
                'NumBoxPyramidLevels', PARAM.NumBoxPyramidLevels, ...
                'MinBoxSizes', PARAM.MinBoxSizes);
        end
    end
    TIME.NetworkEnd(loopCt,:) = clock;
    
    %     if loopCt == 1
    %         toc
    %         profile viewer
    %         loopCt
    %     end
    
    % save the trained detector
    fn = sprintf ( '%s/frcnn_loop_%02d.mat', DIR.output, loopCt );
    save (fn,'detector');
    % check the performance
    [f1Train , stats_train, conf_train] = crop_inference ( trainData, detector, 2000, ...
        VIS.trainResults, DIR.trainResults );
    TIME.F1AfterTrain(loopCt,:) = clock;
    [f1Valid , stats_valid,conf_valid] = crop_inference ( validData , detector, 2000, ...
        VIS.validResults, DIR.validResults );
    TIME.F1AfterValid(loopCt,:) = clock;
    [f1Test , stats_test,conf_test] = crop_inference ( testData, detector, 2000, ...
        VIS.testResults, DIR.testResults );
    TIME.F1Stop(loopCt,:) = clock;
    fn = sprintf ( '%s/stats_%02d.mat', DIR.output, loopCt );
    save (fn,'f1Train','f1Valid','f1Test','stats_train','stats_valid','stats_test','conf_train','conf_valid','conf_test');
    
    % remember stats
    STATS.f1TrainV(loopCt) = f1Train;
    STATS.f1ValidV(loopCt) = f1Valid;
    STATS.f1TestV(loopCt) = f1Test;
    
    save(sprintf ( '%s/stats_all.mat', DIR.output ), 'STATS');
    save(sprintf ( '%s/time_all.mat', DIR.output ), 'TIME');
    fprintf ( '\n\n\n=========================================================================\n' );
    %for i = 1:loopCt
    classes = fieldnames(stats_train);
    for j = 1:numel(classes)
        fprintf ( '\t %2d - %s |  %.4f -  %.4f - %.4f\n',j,classes{j}, ...
            stats_train.(classes{j}).f1, ...
            stats_valid.(classes{j}).f1, ...
            stats_test.(classes{j}).f1);
    end
    fprintf ( '\n %2d | T [%.4f] - V [%.4f] - Test [%.4f]\n',loopCt, f1Train, f1Valid,f1Test);
    %end
    fprintf ( '=========================================================================\n' );
    fprintf (' \n Time for Network Train : %f and Time for all Test : %f \n', ...
        etime(TIME.NetworkEnd(loopCt,:),TIME.NetworkStart(loopCt,:)),etime(TIME.F1Stop(loopCt,:),TIME.NetworkEnd(loopCt,:)));
    fprintf ( '=========================================================================\n\n\n' );
    
    %decide if need to go on
    %- find the index of the best performing loop
    [bestValid, bestValidIdx] = max ( STATS.f1ValidV );
    
    % - if the latest was the best, then keep that detector model
    if ( bestValidIdx == loopCt )
        detectorBest = detector;
    end
    
    %- if the best is long time ago, then terminate
    if ( ( loopCt - bestValidIdx )  >  PARAM.noImproveCycleCount )
        fprintf ( 'loopCt (%d) - bestValidIdx (%d) > PARAM.noImproveCycleCount (%d)\n', ...
            loopCt, bestValidIdx, PARAM.noImproveCycleCount );
        moreLoop = false;
        continue;
    end
    
    detectorPrev = detector;
    %     if loopCt == 1
    %         toc
    %         profile viewer
    %         loopCt
    %     end
    loopCt = loopCt + 1;
end

% save the best detector
fn = sprintf ( '%s/frcnn.mat', DIR.output );
detector = detectorBest;
save ( fn, 'detectorBest');
TIME.ScriptEnd = clock;
save(sprintf ( '%s/time_all.mat', DIR.output ), 'TIME');