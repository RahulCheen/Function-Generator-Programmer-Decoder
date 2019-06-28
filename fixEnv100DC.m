function fixEnv100DC(correction)
% fixEnv100DC corrects the stim onset/offset for arbitrary waveforms.  Since the arbitrary waveform goes
% into the digital channel on Intan, the onset/offset is not accurate to the start and end of
% stimulation.  This function corrects that by shifting the onset and offset by a specified duration of
% time.  The default correction is 4.666667 ms (at 30,000 Sa/s, this corresponds to 140 points).  The
% units for the correction input is in [ms].  Additionally, two fields are created in the 'trials'
% structure: 'isArb' and 'digCorrected', which shows which 

if ~exist('correction','var')
    correction = 4.66666666667; 
elseif isempty(correction)
    correction = 4.66666666667;
end
[~,trialsName,~,~] = MatNames;

load(trialsName,'trials','fs');

nTrials = length(trials);

correction_pts = round(fs*(correction/1000)); % convert to points
for ii=1:nTrials
    if trials(ii).dutyCycle == 100
        trialsCorrected(ii)              = trials(ii);
        trialsCorrected(ii).stimStart    = trialsCorrected(ii).stimStart - correction_pts;
        trialsCorrected(ii).stimEnd      = trialsCorrected(ii).stimEnd   + correction_pts;
        trialsCorrected(ii).stimDur      = 1000*(trialsCorrected(ii).stimEnd - trialsCorrected(ii).stimStart)./fs;
        trialsCorrected(ii).isArb        = true;
        trialsCorrected(ii).digCorrected = true;
    else
        trialsCorrected(ii)              = trials(ii);
        trialsCorrected(ii).isArb        = false;
        trialsCorrected(ii).digCorrected = false;
    end    
    
end
save(trialsName,'-append','trialsCorrected');
assignin('base','trialsCorrected',  eval('trialsCorrected'));
assignin('base','trials',           eval('trials'));
assignin('base','fs',               eval('fs'));

end