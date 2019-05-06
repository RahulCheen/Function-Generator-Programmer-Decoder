clear; clf;
[rawFileName,trialsName,ParameterOrderName] = MatNames;

load(trialsName);

for ii=1:length(trials)
    %disp(['Trial #',num2str(ii)]);
    stimEnvelope = trials(ii).stimEnvelope;
    stimStart    = trials(ii).stimStart;
    
    t = (0:(length(stimEnvelope)-1))+stimStart;
    
    changes = [0;diff(stimEnvelope)];
    
    stimOns  = zeros(size(stimEnvelope));
    stimOffs = zeros(size(stimEnvelope));
    
    stimOns (changes == 1)  = 1;
    stimOffs(changes == -1) = 1;
    tStimOns    = t(logical(stimOns));
    tStimOffs   = t(logical(stimOffs));
    
    trials(ii).BurstOns  = tStimOns';
    trials(ii).BurstOffs = tStimOffs';
    trials(ii).nBursts   = length(tStimOns);
    
    BurstDuration = (tStimOffs-tStimOns)./fs;
    PRFwaveform = fs./[0,diff(tStimOns)];
    DCcalcs = BurstDuration.*PRFwaveform*100;
    BurstDurationCalc = trials(ii).dutyCycle./trials(ii).modFreq;
    disp(num2str([ii,...
        mean(PRFwaveform(2:end)),trials(ii).modFreq,...
        mean(BurstDuration(2:end))*100000,BurstDurationCalc*1000],...
        '%14.4g'));
end