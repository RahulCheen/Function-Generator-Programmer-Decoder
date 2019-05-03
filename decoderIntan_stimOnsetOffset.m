clear; clf;
fileTag = 'ExtractedData';
filePath = 'C:\Users\Arjun\Desktop\TestData';

fileName = findFileAndLoad(fileTag,filePath);

c = dir; a = [c(:).isdir]; c = c(~a);
for ii=1:length(c)
    try check1 = strcmp(c(ii).name(1:length(fileTag)),fileTag);
    catch; check1 = 0;
    end
    if check1
        fileName = c(ii).name;
    end
    
end

load(fileName);
load(fileName(length(fileTag)+2:end),'freq*');
for ii=1:length(ExtractedData)
    disp(['Trial #',num2str(ii)]);
    stimEnvelope = ExtractedData(ii).stimEnvelope;
    stimStart    = ExtractedData(ii).stimStart;
    
    t = (0:(length(stimEnvelope)-1))+stimStart;
    
    changes = [0;diff(stimEnvelope)];
    
    stimOns  = zeros(size(stimEnvelope));
    stimOffs = zeros(size(stimEnvelope));
    
    stimOns (changes == 1)  = 1;
    stimOffs(changes == -1) = 1;
    tStimOns    = t(logical(stimOns));
    tStimOffs   = t(logical(stimOffs));
    
    ExtractedData(ii).tStimOns  = tStimOns;
    ExtractedData(ii).tStimOffs = tStimOffs;
    
    
    
end