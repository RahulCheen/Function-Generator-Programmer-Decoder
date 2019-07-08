clear;

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
    end
end


for ii=1:length(trials)
    stimStart = trials(ii).stimStart;
    stimEnd   = trials(ii).stimEnd;
    
    
    
    
    % ~~~~~~ ADD AMPLIFIER VALUES TO TRIALS STRUCTURE  ~~~~~~~~~ %
    if exist('allAmpNames','var')
        trials(ii).AmpBeforeStim = [];
        trials(ii).AmpDuringStim = [];
        trials(ii).AmpAfterStim  = [];
        for jj=1:16
            load(allAmpNames{jj},'amp*'); eval(['AMP = amp',num2str(jj),';']); clear amp*
            trials(ii).AmpDuringStim = [trials(ii).AmpDuringStim, AMP(   stimStart          :  stimEnd          )];
            trials(ii).AmpBeforeStim = [trials(ii).AmpBeforeStim, AMP(  (stimStart - 30000) :  stimStart        )];
            trials(ii).AmpAfterStim  = [trials(ii).AmpAfterStim,  AMP(   stimEnd            : (stimEnd + 30000) )];
            
            
            
            clear AMP;
        
        
        end
            
    
            
            
            
            
        
        
        
        
    else
        
        
        
    end
    
    
    
    
    
    
end