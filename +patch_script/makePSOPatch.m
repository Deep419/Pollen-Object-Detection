function makePSOPatch(GT_data,idx,bbox_intersection,patchBox)
%MAKEPSOPATCH Divide images from big_images to smaller patches based on class
%   in patches folder using PSO
warning off;

id_num = GT_data.id{idx};
%if patch folder already exists, skip creating patches for that one
folder_name = fullfile('pso_patches',id_num);
mkdir(folder_name);

mat_exists = dir(fullfile(folder_name,'*.mat'));
if ~isempty(mat_exists)
    fprintf('Patches already exists : %s\n',id_num);
    return;
end
fprintf('Dividing %s : ',id_num);
current_image = GT_data.imageFilename{idx};
I=imread(current_image);

[Row, Column, ~]=size(I);
box = GT_data.bbox{idx};

%% clip patchBox larger than I
high_c = find(patchBox(:,1)+patchBox(:,3) >= Column);
patchBox(high_c,3) = Column - patchBox(high_c,1);

high_r = find(patchBox(:,2)+patchBox(:,4) >= Row);
patchBox(high_r,4) = Row - patchBox(high_r,2);

high_c = find(box(:,1)+box(:,3) >= Column);
box(high_c,3) = Column - box(high_c,1);

high_r = find(box(:,2)+box(:,4) >= Row);
box(high_r,4) = Row - box(high_r,2);

%% BBOx Overlap
iou = bboxOverlapRatio(patchBox,box,'Min');

numPatches = size(patchBox,1);

patchBox_imgs = cell(numPatches,1);
patchBox_gt = cell(numPatches,1);
patchBox_extra = cell(numPatches,1);


for i = 1:numPatches
    x = patchBox(i,1);
    y = patchBox(i,2);
    w = patchBox(i,3);
    h = patchBox(i,4);
    patchBox_imgs{i} = I(y:(y + h)-1,x:(x + w)-1,:);
    
    %% 100% Inside
    gt_list = box(iou(i,:)==1,:);
    if ~isempty(gt_list)
        gt_list(:,1) = gt_list(:,1) - x;
        gt_list(:,2) = gt_list(:,2) - y;
    end
    patchBox_gt{i} = [patchBox_gt{i};gt_list];
    %% Between 100% and bbox_intersection
    gt_list = box(iou(i,:)>=bbox_intersection & iou(i,:)<1,:);
%     Debug intersect_clip
%     gt_list
%     I = uint8(255*zeros(1000,1000,3));
%     patchBox = [300 300 400 400];
%     gt_list = [250 250 100 100; ...
%         500 250 100 100 ; ...
%         650 250 100 100 ; ...
%         250 500 100 100 ; ...
%         650 500 100 100 ; ...
%         250 650 100 100 ; ...
%         500 650 100 100 ; ...
%         650 650 100 100];

    %Clip these to edges
    if ~isempty(gt_list)
        [modified_gt_list,extraList] = intersect_clip(patchBox(i,:),gt_list);
        patchBox_gt{i} = [patchBox_gt{i};modified_gt_list];
        patchBox_extra{i} = [patchBox_extra{i};extraList];
    end
    
%     if ~isempty(patchBox_extra{i})
%         hold on;
%         insertShape(I,'polygon',patchBox_extra{i},'LineWidth',8,'Color',color(numPatches+1,:));
%         hold off;
%     end
    %bbox(gt_list,
end
% figure;imshow(insertShape(I,'rectangle',patchBox,'LineWidth',10,'Color',color(1:numPatches,:)));
clear i x y w h gt_list


% Create Vis image
img = insertShape(I,'rectangle',patchBox,'LineWidth',6,'Color','white');
color = 255*jet(numPatches);
for i = 1:numPatches
    gt_list = patchBox_gt{i};
    x = patchBox(i,1);
    y = patchBox(i,2);
    gt_list(:,1) = gt_list(:,1) + x;
    gt_list(:,2) = gt_list(:,2) + y;
    img = insertShape(img,'rectangle',gt_list,'LineWidth',8,'Color',color(i,:));
    if ~isempty(patchBox_extra{i})
        for j = 1:size(patchBox_extra{i},1)
            b = patchBox_extra{i}(j,:);
            b(isnan(b)) = [];
            img = insertShape(img,'polygon',b,'LineWidth',8,'Color','black');
        end
    end
end
%figure;imshow(img);

imageFilename = {};
pollen = {};

bbox = patchBox_gt; clear patchBox_gt

fprintf('done | ');

other_scripts.textprogressbar(sprintf('Creating patches for ID %s : ',id_num));
progressBar = numel(1:4:size(patchBox_imgs,1)*4);
counter = 1;
%% add aug script here
for aug_i = 1:4:size(patchBox_imgs,1)*4%15000
    
    patch_image = patchBox_imgs{ceil(aug_i/4)};
    loc = fullfile(folder_name , [id_num '_pat_' num2str(ceil(aug_i/4)) '_aug_']);
    bbox_per = bbox{ceil(aug_i/4)};
    [Row,Column,~] = size(patch_image);
    %[R,C,~]=size(I);
    fn = [loc '0' '.png'];
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
    fn = [loc 'ud' '.png'];
    imageFilename{aug_i+1,1} = fn;
    pollen{aug_i+1,1} = bbox_down;
    imwrite(I_down,fn);
    
    I_side = fliplr(patch_image);
    bbox_side = [];
    if ~isempty(bbox_per)
        bbox_side = [Column-(bbox_per(:,1)+bbox_per(:,3)-2) bbox_per(:,2) bbox_per(:,3) bbox_per(:,4)];
    end
    %figure;imshow(insertShape(I_side,'rectangle',bbox_side));
    fn = [loc 'lr' '.png'];
    imageFilename{aug_i+2,1} = fn;
    pollen{aug_i+2,1} = bbox_side;
    imwrite(I_side,fn);
    
    I_diag = fliplr(I_down);
    bbox_diag = [];
    if ~isempty(bbox_per)
        bbox_diag = [Column-(bbox_down(:,1)+bbox_down(:,3)-2) bbox_down(:,2) bbox_down(:,3) bbox_down(:,4)];
    end
    %figure;imshow(insertShape(I_diag,'rectangle',bbox_diag));
    fn = [loc 'diag' '.png'];
    imageFilename{aug_i+3,1} = fn;
    pollen{aug_i+3,1} = bbox_diag;
    imwrite(I_diag,fn);
    other_scripts.textprogressbar((counter/progressBar)*100);
    counter = counter + 1;
end
other_scripts.textprogressbar('done');

bbox = pollen; clear pollen;
data_aug = table(imageFilename, bbox);

imwrite(img,fullfile(folder_name,['vis_big-' id_num '.png']));
save(fullfile(folder_name,'gt_data_aug.mat'), 'data_aug');
end

function [newList,extraList] = intersect_clip(patchBox, gt_list)
%% This function divides a GT box into parts when intersected by patchBox

newList = [];
extraList = nan(size(gt_list,1),12);
p_x = patchBox(1);
p_y = patchBox(2);
for i = 1:size(gt_list,1)
    bboxB = gt_list(i,:);
    
    a = bbox2points(patchBox);
    b = bbox2points(bboxB);
    a1 = polyshape(a(:,1),a(:,2));
    a2 = polyshape(b(:,1),b(:,2));
    inside = intersect(a1,a2);
    polyPoints = inside.Vertices;
    x = round(min(polyPoints(:, 1)));
    y = round(min(polyPoints(:, 2)));
    w = round(max(polyPoints(:, 1))) - x;
    h = round(max(polyPoints(:, 2))) - y;
    newList = [newList; [max(1,x-p_x) max(1,y-p_y) w h]];
    
    %Extra
    out = xor(a1,a2);
    extra_poly = out.subtract(a1);
    vrtx = extra_poly.Vertices;
    % Pad with 0(nan later) to retain matrix size
    extraList(i,:) = padarray(reshape(vrtx',1,size(vrtx,1)*2),[0 12 - numel(vrtx)],'post');
end
extraList(extraList==0) = nan;
% figure;imshow(insertShape(I,'rectangle',newList,'LineWidth',1,'Color',255*jet(8)));
end
