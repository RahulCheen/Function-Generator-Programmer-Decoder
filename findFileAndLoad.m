function fullFileName = findFileAndLoad(fileTag,filePath)
% FINDFILEANDLOAD
switch nargin
    case 0
        error('No file tag.');
    case 1
        filePath = cd;
        currentPath = cd;
    case 2
        currentPath = cd;
end

cd(filePath);
c = dir; a = [c(:).isdir]; c = c(~a);
for ii=1:length(c)
    try check1 = strcmp(c(ii).name(1:length(fileTag)),fileTag);
    catch; check1 = 0;
    end
    if check1
        fullFileName = c(ii).name;
    end
    
end

load(fullFileName);
vars = whos('-file',fullFileName);

for ii=1:length(vars)
    assignin('base',vars(ii).name,eval(vars(ii).name));

end
cd(currentPath);