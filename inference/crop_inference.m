%% Dependencies : inference\*
%% Last Version Verified : R2018a

function [avg_f1,info, conf] = ...
    main ( detectData, detector, nsr, imWriteFlag, varargin )

% Avg f1 = Average of multiclass F1 scores
% info = Individual Class AP,Precision,Recall,F1
% conf = Confusion Matrix Analysis
% imWriteFlag = If want to print visualizations/detection results
% varagin = if printing results, directory to print in

numClasses = width(detectData)-1;

resultsStruct = struct([]);

for i = 1:height(detectData)
    fn = detectData.imageFilename{i};
    % Read the image.
    I = imread( fn );
    fn = strsplit(fn,'.');
    fn = fn{1};
    fn = strsplit(fn,filesep);
    fn = fn{end};
    % Run the detector.
    [bboxes, scores, labels] = detect(detector, I,'NumStrongestRegions',nsr);
    % Collect the results.
    resultsStruct(i).Boxes = bboxes;
    resultsStruct(i).Scores = scores;
    resultsStruct(i).Labels = labels;
end
% Convert the results into a table.
results = struct2table(resultsStruct);
expectedResults = detectData(:, 2:end);

if imWriteFlag
    %save('bbox.mat','results','expectedResults');
    outputDir = varargin{1};
    for i = 1:height(detectData)
        fn = detectData.imageFilename{i};
        img = imread( fn );
        %         fn = strsplit(fn,'.');
        %         fn = fn{1};
        %         fn = strsplit(fn,filesep);
        %         fn = ['output_' fn{2} '_' fn{3}];
        for j = 1:numel(results.Scores{i})
            img = insertObjectAnnotation(img,'rectangle',results.Boxes{i}(j,:),char(results.Labels{i}(j,1)));
        end
        img = insertShape(img,'rectangle',gt.bbox{i},'LineWidth',2,'color','green');
        imwrite(img,sprintf('%s%s%s.png',outputDir,filesep,fn));
        %figure; imshow(img);
    end
end
% -original-
%[ap, rC, pC] = evaluateDetectionPrecision(results, expectedResults);

% -previous custom function-
%[ap, rC, pC] = cal_DetectionPrecision(results, expectedResults);

% -current custom with extra stats output-
[averagePrecision, recall, precision, stats, conf] = statsCalculator( results, ...
    expectedResults);

%info.data = detectData;
temp_f1=[];

for i = 1:numClasses
    
    current_class = expectedResults.Properties.VariableNames{i};
    info.(current_class).averagePrecision = averagePrecision(i);
    info.(current_class).stats = stats(:,i);
    
    if numClasses == 1
        info.(current_class).v_recall = recall;
        info.(current_class).v_precision = precision;
        info.(current_class).recall = recall(end);
        info.(current_class).precision = precision(end);
        p = precision(end);
        r = recall(end);
        f1 = (2*p*r)/(p+r);
        if isnan(f1)
            f1 = 0;
        end
        info.(current_class).f1 = f1;
        temp_f1=[temp_f1 ; f1];
        break;
    end

    info.(current_class).v_recall = recall{i};
    info.(current_class).v_precision = precision{i};
    info.(current_class).recall = recall{i}(end);
    info.(current_class).precision = precision{i}(end);
    
    
    p = precision{i}(end);
    r = recall{i}(end);
    f1 = (2*p*r)/(p+r);
    if isnan(f1)
        f1 = 0;
    end
    info.(current_class).f1 = f1;  
    temp_f1=[temp_f1 ; f1];    
end

avg_f1 = mean(temp_f1);