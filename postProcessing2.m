clear;
tBefore = 1; % [seconds]
tAfter  = 1; % [seconds]

[~,trialsName,AmpName,AnalogName,RawDataName] = MatNames('D:\rat\Test\');

vars = who('-file',trialsName);

if ismember('trialsCorrected',vars)
    load(trialsName,'trialsCorrected','fs'); trials = trialsCorrected; clear trialsCorrected;
    disp('Arb Waveforms: 100% duty cycle stim onset/offset corrected.')
else
    load(trialsName,'trials','fs');
end

files = dir; files = {files(:).name};

allAmpNames = {};
if ismember([RawDataName(1:end-4),'_amp1.mat'],files)
    for ii=1:16
        allAmpNames = [allAmpNames,[RawDataName(1:end-4),'_amp',num2str(ii),'.mat']];
        ampOption = 'Individual';
    end
else
    ampOption = 'Altogether';
end



for ii=1:length(trials)
    disp(['Trial #',num2str(ii)]);
    stimStart   = trials(ii).stimStart;
    stimEnd     = trials(ii).stimEnd;
    
    trials(ii).ampData = struct(...
        'beforeStim',[],        ...
        'duringStim',[],        ...
        'afterStim', []         ...
        );
    
    for jj=1:length(allAmpNames)
        disp(['Amplifier Channel #',num2str(jj-1)]);
        ampName = allAmpNames{jj};
        
        m = matfile(ampName);
        eval(['trials(ii).ampData(jj).beforeStim = [trials(ii).ampData(jj).beforeStim,m.amp',num2str(jj),'((stimStart-tBefore*fs):stimStart,1)];']);
        
        eval(['trials(ii).ampData(jj).beforeStim = ',...
            'm.amp',num2str(jj),'((stimStart-',num2str(tBefore*fs),') : stimStart                        , 1);']);
        
        eval(['trials(ii).ampData(jj).duringStim = ',...
            'm.amp',num2str(jj),'( stimStart                          : stimEnd                          , 1);']);
        
        eval(['trials(ii).ampData(jj).afterStim  = ',...
            'm.amp',num2str(jj),'( stimEnd                            :(stimEnd + ',num2str(tAfter*fs),'), 1);']);
        
    end
    
    
    
end