function sortTrials(category)

if ~exist('category','var')
    category = 'amp'; % default category is modulating frequency
end
if ~iscell(category)
    category = {category}; % change to cell array if not cell array
end

[~,trialsName,~,~] = MatNames;
vars = whos('-file',trialsName); % variable names

if ismember('trialsCorrected',[vars(:).name]) % if DC100 has been corrected
    load(trialsName,'trialsCorrected');
    trialsWorking = trialsCorrected;
else
    load(trialsName,'trials');
    trialsWorking = trials;
end

nCategories = length(category); % number of categories to sort

for ii=1:nCategories % loop through categories
    switch category{ii} % category-specific sorting
        case {'amp','amplitude','Amp','Amplitude'}
            ampVals = unique([trialsWorking(:).amplitude]);
            nAmps = length(ampVals);
            for jj=1:nAmps
                trialsCat = trialsWorking([trialsWorking(:).amplitude] == ampVals(jj));
                assignin('base',...
                    ['trialsAmp',num2str(ampVals(jj))],...
                    eval(trialsCat));
            end
            
        case {'DC','dutyCycle','DutyCycle','Duty Cycle','duty cycle'}
            DCVals = unique([trialsWorking(:).dutyCycle]);
            nDCs = length(DCVals);
            for jj=1:nDCs
                eval(['trialsCat',num2str(ii),'Val',num2str(DCVals(jj)),...
                    ' = trialsWorking([trialsWorking(:).dutyCycle] == ',num2str(DCVals(jj)),');']);
                assignin('base',...
                    ['trialsCat',num2str(ii),'Val',num2str(DCVals(jj))],...
                    eval(['trialsCat',num2str(ii),'Val',num2str(DCVals(jj))]));
            end
            
        case {'modFreq','ModFreq','ModFrequency','ModulatingFrequency','Modulating Freqeuncy','PRF','PulseRepetitionFrequency','Pulse Repetition Frequency','PulseRepFreq','pulserepfreq'}
            MFVals = unique([trialsWorking(:).modFreq]);
            nMFs = length(MFVals);
            for jj=1:nMFs
                eval(['trialsCat',num2str(ii),'Val',num2str(MFVals(jj)),...
                    ' = trialsWorking([trialsWorking(:).modFreq] == ',num2str(MFVals(jj)),');']);
                assignin('base',...
                    ['trialsCat',num2str(ii),'Val',num2str(MFVals(jj))],...
                    eval(['trialsCat',num2str(ii),'Val',num2str(MFVals(jj))]));
            end
            
        case {'pulseDuration','PulseDuration','PD','Pulse Duration','Duration','Dur','dur','duration','PulseDur','pulseDur'}
            PDVals = unique([trialsWorking(:).pulseDuration]);
            nPDs = length(PDVals);
            for jj=1:nPDs
                eval(['trialsCat',num2str(ii),'Val',num2str(PDVals(jj)),...
                    ' = trialsWorking([trialsWorking(:).pulseDuration] == ',num2str(PDVals(jj)),');']);
                assignin('base',...
                    ['trialsCat',num2str(ii),'Val',num2str(PDVals(jj))],...
                    eval(['trialsCat',num2str(ii),'Val',num2str(PDVals(jj))]));
            end
            
        otherwise
            error('unrecognized category');
    end
end

end
