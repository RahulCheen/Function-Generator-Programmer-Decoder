% check trial lengths

[rawFile,ExtractedFile,ParameterFile] = MatNames;

load(ExtractedFile);

nTrials = length(trials);

for ii=1:nTrials
    
    trialEnvelope = trials(ii).trialEnvelope;
    stimEnvelope  = trials(ii).stimEnvelope;
    pulseDuration = trials(ii).pulseDuration/1000;
    modFreq       = trials(ii).modFreq;
    DC            = trials(ii).dutyCycle;
    
    stimChanges = [0;diff(stimEnvelope)];
    nRises = sum(stimChanges == 1);
    nPeaks = length(findpeaks(stimEnvelope));
    
    t = [1:1:length(trialEnvelope)]./fs;
    t_stim = [1:1:length(stimEnvelope)]./fs;
    
    hold off; clf;
    subplot(2,1,1);
    plot(t,trialEnvelope,'LineWidth',0.1);
    title(['Trial #',num2str(ii),' // Pulse Duration: ',num2str(pulseDuration),' s']); 
    xlim([0 inf]);
    set(gca,'XTick',[0 0.25 (0.25+pulseDuration) inf]);
    
    subplot(2,1,2);
    plot(t_stim,stimEnvelope,'LineWidth',0.1);
    xlim([-0.25 t(end)-0.25]);
    set(gca,'XTick',[-.25 0 (pulseDuration)]);
    xlabel('time [s]');
    
    pause
    hold off;
end