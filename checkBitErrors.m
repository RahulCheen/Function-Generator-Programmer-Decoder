% checkBitErrors
%   checks the the decoded "bit map" against the original order, if available.  The "bit map" contains
%   the byte information for each trial, with dots where a bit was 1.  Uses the function SPY to generate
%   the bit map.
clear

[rawFile,decodedFileName,parameterOrderName] = MatNames;

try load(decodedFileName); % try to load the file
    nTrials = length(ExtractedData);
    % extract bit values and arrange to be of size [nTrials,nParams*bytesize]
    for ii=1:nTrials
        trialBitValues(ii,:) = [ExtractedData(ii).bitData(:).bitValue];
    end
catch
    error('Cannot find ExtractedData file.  Make sure to run decoderIntan first on the raw data file.');
end


try load(parameterOrderName); % try to load the file
    
catch
    error('Cannot find ParameterOrder file.  Make sure it is in the same directory as the raw data file.');
end

[~,~,p] = size(DataVector);
% rearrange DataVector to be of size [nTrials,nParams*bytesize]
trialBits = [];
for ii=1:p
    trialBits = [trialBits,DataVector(:,:,ii)'];
end
trialBits = trialBits(TrialIndices,:); % get trialBits to be in the correct trial order

DecodeDiff = trialBits - trialBitValues; % difference between orginal and decoded


% PLOT BIT MAPS
figure(1); set(gcf,'Units','normalized','Position',[0.125 0.375 0.75 0.3]);
subplot(1,3,1); % decoded
spy(trialBitValues,'k',10); xlabel('bit position'); ylabel('Trial number');
title('Decoded');
set(gca,'FontName','Serif');
set(gca,'FontSize',16);

subplot(1,3,2); % original
spy(trialBits,'k',10);      xlabel('bit position');
title('Original');
set(gca,'FontName','Serif');
set(gca,'FontSize',16);

subplot(1,3,3); % difference
spy(DecodeDiff,'r',10);     xlabel('bit position');
title('Difference');
set(gca,'FontName','Serif');
set(gca,'FontSize',16);
