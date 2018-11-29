function data = remove_aug(data)
list_to_remove = [];
for i = 1:size(data,1)
    img_fn = data.imageFilename{i};
    if strcmp(img_fn(end-4),'0')
        continue;
    end
    list_to_remove = [list_to_remove i];
end
data(list_to_remove,:) = [];
end