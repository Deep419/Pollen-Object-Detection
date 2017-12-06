function ctr = id_includer(varargin)
lista = varargin{1};
list = lista{1};
foundComma = strfind(list,',');
if foundComma
    list = strsplit(list,',');
end
foundDash = strfind(list,'-');
ctr = [];
if iscell(foundDash)
    for i = 1:numel(list)
        if foundDash{i}
            a = strsplit(list{i},'-');
            ctr = [ctr str2num(a{1}):str2num(a{2})]
        else
            ctr = [ctr str2num(list{i})]
        end
    end
else
    for i = 1:numel(lista)
        if foundDash
            a = strsplit(list,'-');
            ctr = [ctr str2num(a{1}):str2num(a{2})]
        else
            ctr = [ctr str2num(list)]
        end
    end
end
end

