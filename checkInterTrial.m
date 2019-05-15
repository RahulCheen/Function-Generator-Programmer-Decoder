clear;
[dataFile,trialFile,ParameterFile] = MatNames;

load(trialFile);

for ii=2:length(trials)
    tStimOn2 = trials(ii).stimStart;
    tStimOn1 = trials(ii-1).stimStart;
    
    disp((tStimOn2-tStimOn1)/fs);
    
    
    
end