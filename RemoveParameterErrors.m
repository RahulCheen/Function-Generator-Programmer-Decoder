function [ParametersOut, NCycles] = RemoveParameterErrors(Parameters)
% REMOVEPARAMETERERRORS removes trials that will produce an error in the function generator.  Such
% combination of errors include:
%   100% duty cycle and not 0 Hz modulating frequency.
%   0 Hz modulating freqeuncy and not 100% duty cycle.
%   If the number of cycles in a modulated waveform is less than 2.
%       This occurs if the pulse duration is not more than twice the modulating frequency.


[nTrials,~] = size(Parameters);
disp(['Number of trials: ',num2str(nTrials)]);

TF              = unique(Parameters(:,1));
Amps            = unique(Parameters(:,2));
DCs             = unique(Parameters(:,3));
modfreqs        = unique(Parameters(:,4));
pulseduration   = unique(Parameters(:,5));

if any(DCs == 100)                  % if any of the duty cycles is 100%
    if ~any(modfreqs==0)            % if there aren't any 0 Hz modulating frequencies
        modfreqs = [0,modfreqs];    % add a 0 Hz modulating frequency
    end
elseif any(modfreqs == 0)   % if there is any 0 Hz modulating frequency
    if ~any(DCs == 100)     % if there aren't any 100% duty cycles
        DCs = [DCs,100];    % add a 100% duty cycle
    end
end

% get all new parameter combinations
Parameters = allcomb(TF,Amps,DCs,modfreqs,pulseduration);

disp(['Number of trials after adding 100% DC and 0 Hz ModFreq ',...
    '(if one is present and the other isn''t): ',...
    num2str(nTrials)]);

[nTrials,~] = size(Parameters);


jj=0;
for ii=1:nTrials
    NCycle = floor(Parameters(ii,4).*Parameters(ii,5)./1000);

    if Parameters(ii,3) == 100 % if duty cycle is 100%
        jj=jj+1;
        ParametersOut(jj,:) = Parameters(ii,:);
        ParametersOut(jj,4) = 0;  % change modulating frequency to 0 Hz
        
    elseif Parameters(ii,4) == 0     % if modulating frequency is 0 Hz
        jj=jj+1;
        ParametersOut(jj,:) = Parameters(ii,:);
        ParametersOut(jj,3) = 100; % change duty cycle to 100%
        
    elseif NCycle > 1
        jj=jj+1;
        ParametersOut(jj,:) = Parameters(ii,:);
        
    end
end

% only keep unique trials
[ParametersOut] = unique(ParametersOut,'rows');
NCycles = floor(ParametersOut(:,4).*ParametersOut(:,5)./1000);

[nTrialsOut,~] = size(ParametersOut);

disp(['Number of Trials after removing bad parameter combinations: ',num2str(nTrialsOut)]);
