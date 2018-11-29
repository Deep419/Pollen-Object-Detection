% This function changes label from categorical to cell array of char,
% provide a color choice for inserting objects
% Input:
%       label -- (categorical) labels from RCNN detection
%       color_flag -- a flag for color choice: 1 - jet color, 0 - default
%                       color or provided in the varargin
%       varargin -- possible color for insert object annotation, e.g. 'red'
%                   scores to insert into labels
%
% Output:
%       labels -- (char) converted label from categoriacal to char, if
%                   scores are passed they will be added to the labels
%       color -- RGB or string color

function [labels,color] = labelColor(label,color_flag,varargin)
% Checking the number of inputs and 
vN = nargin();
if vN > 4
    error('Wrong number of arguments');
elseif vN == 4
    if isnumeric(varargin{1,1})
        scores = varargin{1,1};
        tempColor = varargin{1,2};
    else
        scores = varargin{1,2};
        tempColor = varargin{1,1};
    end
elseif vN == 3
    if isnumeric(varargin{1,1})
        scores = varargin{1,1};
        tempColor = 'yellow';
    else
        tempColor = varargin{1,1};
    end
elseif vN == 2
    tempColor = 'yellow';
end

% Check that number of scores is equal number of labels
if size(scores,1) ~= size(label,1)
    error('Number of labels ans scores are different');
end
    

color = jet(250)*255;
rng(10)
color = color([1:5:250 2:5:250 3:5:250 4:5:250 5:5:250 6:6:250 7:7:250 8:8:250 9:9:250 10:10:250],:);
labelColor = [];

for k=1:size(label,1)
    if exist('scores','var') == 1
        labels{k,:} = [char(label(k,1)) ' - ' num2str(round(scores(k,1),3,'decimals'))];
    else
        labels{k,:} = char(label(k,1));
    end
    tempString = strsplit(char(label(k,1)),'_');
    tempString = tempString{1,2};
    tempString = str2num(tempString);
    labelColor(k,:) = color(tempString(1,1),:);
end
    if color_flag
        color = labelColor;
    else
        color = tempColor;
    end
end