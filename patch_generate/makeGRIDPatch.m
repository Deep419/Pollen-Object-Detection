function makeGRIDPatch(GT_data,i,bbox_intersection)
%makeGRIDPatch Divide images from big_images to smaller patches based on class
%   in patches folder


id_num = GT_data.id{i};
%if patch folder already exists, skip creating patches for that one
folder_name = fullfile('grid_patches',id_num);
mkdir(folder_name);

mat_exists = dir(fullfile(folder_name,'*.mat'));
if ~isempty(mat_exists)
    fprintf('Patches already exists : %s\n',id_num);
    return;
end
fprintf('Dividing %s : ',id_num);
current_image = GT_data.imageFilename{i};
I=imread(current_image);
[Row, Column, ~]=size(I);
minRC = min(Row,Column);

if minRC < 1000
    numToDivide = minRC - rem(minRC,100);
    rowLines = ceil(Row/numToDivide); %number of lines dividing by height
    columnLines = ceil(Column/numToDivide);  %number of lines dividing by width
    
else
    rowLines = ceil(Row/1000); %number of lines dividing by height
    columnLines = ceil(Column/1000);  %number of lines dividing by width
end
%% 6. Create array of Row and Column Lines
R = [];
C = [];
%create an array of Row cropping lines
R(1)=floor(Row/rowLines);
for k=2:rowLines-1
    R(k)=R(k-1)+floor(Row/rowLines);
end
% image do not have cropping lines
if R(end) == Row
    R = [1 Row]; clear k;
    % image has croppin lines
else
    R = [1 R Row]; clear k;
end

%create an array of Column cropping lines
C(1)=floor(Column/columnLines);
for k=2:columnLines-1
    C(k)=C(k-1)+floor(Column/columnLines);
end
% if image do not have cropping lines
if C(end) == Column
    C = [1 Column]; clear k;
    % image has cropping lines
else
    C = [1 C Column]; clear k;
end

x = mat2cell(I, diff([0 R(2:end)]) , diff([0 C(2:end)]) , 3);

%check if boxes crosses the crop lines
%split GT for each cropped image
bbox = cell(size(x));
extra = [];
box = GT_data.bbox{i};%{k,index};
%box = box{1};
%a=1; %a - index for boxes on cropping lines
for m=1:size(box,1)     %m - number of bboxes for each picture
    [bbox,e] = bboxCalculation(box(m,:),C,R,bbox_intersection,bbox);
    extra = [extra; e];
    
end

%% Visualize Entire Image with Patch GT
bbox_o = cell(size(x));
for ii = 1:size(bbox_o,1)
    for jj = 1:size(bbox_o,2)
        if ~isempty(bbox{ii,jj})
            bbox_o{ii,jj}=[bbox{ii,jj}(:,1)+C(jj)-1 bbox{ii,jj}(:,2)+R(ii)-1 bbox{ii,jj}(:,3) bbox{ii,jj}(:,4)];
        end
    end
end
img = I;
for ro = 2:numel(R)-1
    img = insertShape(img,'Line',[1 R(ro) Column R(ro)],'LineWidth',10,'Color','white');
end
for co = 2:numel(C)-1
    img = insertShape(img,'Line',[C(co) 1 C(co) Row],'LineWidth',10,'Color','white');
end
img = insertShape(img,'rectangle',extra,'color','black','LineWidth',10);
% To vislize extra
%figure;imshow(img);

sz = 0;
color = jet(size(bbox,1)*size(bbox,2)*5);
for ii = 1:size(bbox,1)
    for jj = 1:size(bbox,2)
        if ~isempty(bbox{ii,jj})
            img = insertShape(img,'rectangle',bbox_o{ii,jj},'color', ...
                color(sub2ind([size(bbox,1) size(bbox,2)],ii,jj)*5,:)*255,'LineWidth',10);
            sz = sz + size(bbox_o{ii,jj},1);
        end
    end
end
%figure;imshow(img);


% Make patches linear
x_temp = x';
x_temp=x_temp(:);
imageFilename = {};
pollen = {};

bbox = bbox';
bbox = bbox(:);
fprintf('done | ');


textprogressbar(sprintf('Creating patches for ID %s : ',id_num));
progressBar = numel(1:4:size(x_temp,1)*4);
counter = 1;
%% add aug script here
for aug_i = 1:4:size(x_temp,1)*4%15000
    
    patch_image = x_temp{ceil(aug_i/4)};
    loc = fullfile(folder_name , [id_num '_pat_' num2str(ceil(aug_i/4)) '_aug_']);
    bbox_per = bbox{ceil(aug_i/4)};
    [Row,Column,~] = size(patch_image);
    %[R,C,~]=size(I);
    fn = [loc '0' '.jpg'];
    imageFilename{aug_i,1} = fn;
    pollen{aug_i,1} = bbox_per;
    %figure;imshow(insertShape(I,'rectangle',bbox));
    imwrite(patch_image, fn);
    
    I_down = flipud(patch_image);
    bbox_down = [];
    if ~isempty(bbox_per)
        bbox_down = [bbox_per(:,1) Row-(bbox_per(:,2)+bbox_per(:,4)-2) bbox_per(:,3) bbox_per(:,4)];
    end
    %figure;imshow(insertShape(I_down,'rectangle',bbox_down));
    fn = [loc 'ud' '.jpg'];
    imageFilename{aug_i+1,1} = fn;
    pollen{aug_i+1,1} = bbox_down;
    imwrite(I_down,fn);
    
    I_side = fliplr(patch_image);
    bbox_side = [];
    if ~isempty(bbox_per)
        bbox_side = [Column-(bbox_per(:,1)+bbox_per(:,3)-2) bbox_per(:,2) bbox_per(:,3) bbox_per(:,4)];
    end
    %figure;imshow(insertShape(I_side,'rectangle',bbox_side));
    fn = [loc 'lr' '.jpg'];
    imageFilename{aug_i+2,1} = fn;
    pollen{aug_i+2,1} = bbox_side;
    imwrite(I_side,fn);
    
    I_diag = fliplr(I_down);
    bbox_diag = [];
    if ~isempty(bbox_per)
        bbox_diag = [Column-(bbox_down(:,1)+bbox_down(:,3)-2) bbox_down(:,2) bbox_down(:,3) bbox_down(:,4)];
    end
    %figure;imshow(insertShape(I_diag,'rectangle',bbox_diag));
    fn = [loc 'diag' '.jpg'];
    imageFilename{aug_i+3,1} = fn;
    pollen{aug_i+3,1} = bbox_diag;
    imwrite(I_diag,fn);
    textprogressbar((counter/progressBar)*100);
    counter = counter + 1;
end
textprogressbar('done');

bbox = pollen; clear pollen;
data_aug = table(imageFilename, bbox);

imwrite(img,fullfile(folder_name,['vis_big-' id_num '.jpg']));
save(fullfile(folder_name,'gt_data_aug.mat'), 'data_aug');
end
