%This function recalculates new bounding boxes coordinates
% INPUT
% box - coordinates of a box[xmin,ymin,width,hight]
% C - column cropping lines
% R - row cropping lines

% OUTPUT
% bbox_new - recalculated coordinates of the box

function [bbox_new, extra] = bboxCalculation(box,C,R,bbox_intersection,bbox_new)
% make sure that image boundaries do not crop bounding boxes
C(1) = 0;
R(1) = 0;
C(end) = C(end)+2;
R(end) = R(end)+2;

extra = [];
c_ar1 = box(1,1) < C;
c_ar2 = (box(1,1)+box(1,3)) < C;
r_ar1 = box(1,2) < R;
r_ar2 = (box(1,2)+box(1,4)) < R;
flag = all(c_ar1 == c_ar2 ) && all(r_ar1 == r_ar2 );

temp_box(1,:) = box(1,:);
boxArea = box(1,3)*box(1,4);

% bbox_new = cell(size(C,2)-1,size(R,2)-1);
% bbox_orig = cell(size(C,2)-1,size(R,2)-1);
%true - boxes do not cross the cropping lines
if flag
    %calculating to what tile does the box belong
    r_index = find(r_ar1);
    r_index = r_index(1,1)-1;
    c_index = find(c_ar1);
    c_index = c_index(1,1)-1;
    
    %recalculating box coordinates
    if(R(r_index) ==1 && C(c_index) == 1)
        temp_box(1,:) = box(1,:);
    elseif (C(c_index) == 1)
        temp_box(1,2) = temp_box(1,2)- R(r_index)+1;
    elseif (R(r_index) == 1)
        temp_box(1,1) = temp_box(1,1)- C(c_index)+1;
    else
        temp_box(1,1) = temp_box(1,1)-C(c_index)+1;
        temp_box(1,2) = temp_box(1,2)-R(r_index)+1;
    end
    
    %added the box to the file structure
    bbox_new{r_index, c_index} = [bbox_new{r_index, c_index}; temp_box(1,:)];
    %%%% Return r_index, c_index, and temp_box    <--------
    %false - boxes cross the cropping lines
else
    extra = temp_box;
    %croped by column and row cropping lines
    if(all(c_ar1 == c_ar2 )==0 && all(r_ar1 == r_ar2)==0)
        crossingColumn = C(find(~(c_ar1 == c_ar2)));
        crossingRow = R(find(~(r_ar1 == r_ar2)));
        
        %I quadrant box
        r_index = find(r_ar1);
        r_index = r_index(1,1)-1;
        c_index = find(c_ar1);
        c_index = c_index(1,1)-1;
        %recalculating box coordinates
        temp_box(1,1) = box(1,1)-C(c_index)+1;
        temp_box(1,2) = box(1,2)-R(r_index)+1;
        temp_box(1,3) = crossingColumn-box(1,1);
        temp_box(1,4) = crossingRow-box(1,2);
        temp_boxArea = temp_box(1,3)*temp_box(1,4);
        if(temp_boxArea/boxArea>=bbox_intersection)
            bbox_new{r_index, c_index} = [bbox_new{r_index, c_index}; temp_box(1,:)];
        end
        
        %II quadrant box
        r_index = find(r_ar1);
        r_index = r_index(1,1)-1;
        c_index = find(c_ar1);
        c_index = c_index(1,1);
        %recalculating box coordinates
        temp_box(1,1) = crossingColumn-C(c_index)+1;
        temp_box(1,2) = box(1,2)-R(r_index)+1;
        temp_box(1,3) = box(1,1)+box(1,3)-crossingColumn;
        temp_box(1,4) = crossingRow-box(1,2);
        temp_boxArea = temp_box(1,3)*temp_box(1,4);
        if(temp_boxArea/boxArea>=bbox_intersection)
            bbox_new{r_index, c_index} = [bbox_new{r_index, c_index}; temp_box(1,:)];
        end
        
        %III quadrant box
        r_index = find(r_ar1);
        r_index = r_index(1,1);
        c_index = find(c_ar1);
        c_index = c_index(1,1)-1;
        %recalculating box coordinates
        temp_box(1,1) = box(1,1)-C(c_index)+1;
        temp_box(1,2) = crossingRow-R(r_index)+1;
        temp_box(1,3) = crossingColumn-box(1,1);
        temp_box(1,4) = box(1,2)+box(1,4)-crossingRow;
        temp_boxArea = temp_box(1,3)*temp_box(1,4);
        if(temp_boxArea/boxArea>=bbox_intersection)
            bbox_new{r_index, c_index} = [bbox_new{r_index, c_index}; temp_box(1,:)];
        end
        
        %IV quadrant box
        r_index = find(r_ar1);
        r_index = r_index(1,1);
        c_index = find(c_ar1);
        c_index = c_index(1,1);
        %recalculating box coordinates
        temp_box(1,1) = crossingColumn-C(c_index)+1;
        temp_box(1,2) = crossingRow-R(r_index)+1;
        temp_box(1,3) = box(1,1)+box(1,3)-crossingColumn;
        temp_box(1,4) = box(1,2)+box(1,4)-crossingRow;
        temp_boxArea = temp_box(1,3)*temp_box(1,4);
        if(temp_boxArea/boxArea>=bbox_intersection)
            bbox_new{r_index, c_index} = [bbox_new{r_index, c_index}; temp_box(1,:)];
        end
        
        %croped by column cropping line
        %not croped by row line
    elseif(all(c_ar1 == c_ar2 )==0 && all(r_ar1 == r_ar2)==1)
        crossingColumn = C(find(~(c_ar1 == c_ar2)));
        
        %I quadrant box (box on the left from the cropping line)
        r_index = find(r_ar1);
        r_index = r_index(1,1)-1;
        c_index = find(c_ar1);
        c_index = c_index(1,1)-1;
        
        %recalculating box coordinates
        temp_box(1,1) = box(1,1)-C(c_index)+1;
        temp_box(1,2) = box(1,2)-R(r_index)+1;
        temp_box(1,3) = crossingColumn-box(1,1);
        temp_box(1,4) = box(1,4);
        temp_boxArea = temp_box(1,3)*temp_box(1,4);
        if(temp_boxArea/boxArea>=bbox_intersection)
            bbox_new{r_index, c_index} = [bbox_new{r_index, c_index}; temp_box(1,:)];
        end
        
        %II quadrant box (box on the right from the cropping line)
        r_index = find(r_ar1);
        r_index = r_index(1,1)-1;
        c_index = find(c_ar1);
        c_index = c_index(1,1);
        
        %recalculating box coordinates
        temp_box(1,1) = crossingColumn-C(c_index)+1;
        temp_box(1,2) = box(1,2)-R(r_index)+1;
        temp_box(1,3) = box(1,1)+box(1,3)-crossingColumn;
        temp_box(1,4) = box(1,4);
        temp_boxArea = temp_box(1,3)*temp_box(1,4);
        if(temp_boxArea/boxArea>=bbox_intersection)
            bbox_new{r_index, c_index} = [bbox_new{r_index, c_index}; temp_box(1,:)];
        end
        
        %croped by row cropping line
        %not croped by column line
    elseif(all(c_ar1 == c_ar2 )==1 && all(r_ar1 == r_ar2)==0)
        crossingRow = R(find(~(r_ar1 == r_ar2)));
        
        %I quadrant box (a box above the cropping line)
        r_index = find(r_ar1);
        r_index = r_index(1,1)-1;
        c_index = find(c_ar1);
        c_index = c_index(1,1)-1;
        
        %recalculating box coordinates
        temp_box(1,1) = box(1,1)-C(c_index)+1;
        temp_box(1,2) = box(1,2)-R(r_index)+1;
        temp_box(1,3) = box(1,3);
        temp_box(1,4) = crossingRow-box(1,2);
        temp_boxArea = temp_box(1,3)*temp_box(1,4);
        if(temp_boxArea/boxArea>=bbox_intersection)
            bbox_new{r_index, c_index} = [bbox_new{r_index, c_index}; temp_box(1,:)];
        end
        
        %III quadrant box (a box below the cropping line)
        r_index = find(r_ar1);
        r_index = r_index(1,1);
        c_index = find(c_ar1);
        c_index = c_index(1,1)-1;
        
        %recalculating box coordinates
        temp_box(1,1) = box(1,1)-C(c_index)+1;
        temp_box(1,2) = crossingRow-R(r_index)+1;
        temp_box(1,3) = box(1,3);
        temp_box(1,4) = box(1,2)+box(1,4)-crossingRow;
        temp_boxArea = temp_box(1,3)*temp_box(1,4);
        if(temp_boxArea/boxArea>=bbox_intersection)
            bbox_new{r_index, c_index} = [bbox_new{r_index, c_index}; temp_box(1,:)];
        end
        
    end
end
end