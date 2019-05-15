% section amplifier data
clear;

[dataFile,trialsFile,parametersFile,rawDataFile] = MatNames;

load(trialsFile);
m = matfile(dataFile);

tAfterStim = 5; % 5 seconds after

ampData(1:length(trials)) = struct(...
     'beforeStim',[]...
    ,'duringStim',[]...
    ,'afterStim' ,[]...
    );
for ii=1:length(trials)
    disp(['Trial #',num2str(ii)]);
    stimStart = trials(ii).stimStart;
    stimEnd   = trials(ii).stimEnd;
    
    afterStimEnd = trials(ii).stimEnd + tAfterStim*fs; % 5 seconds after stimulation
    
    ampData(ii).duringStim = m.amplifier_data(:,stimStart:stimEnd);
    try ampData(ii).afterStim  = m.amplifier_data(:,stimEnd  :afterStimEnd);
    catch
        ampData(ii).afterStim  = m.amplifier_data(:,stimEnd  :end);
    end
    
    
    
    
    
    
    
end

save(['amp_',dataFile],'ampData');