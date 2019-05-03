% checkBitErrors
%   checks the the decoded "bit map" against the original order, if available.  The "bit map" contains
%   the byte information for each trial, with dots where a bit was 1.  Uses the function SPY to generate
%   the bit map.
clear

[file1,path1] = uigetfile('*.rhs','Select Raw Data File','MultiSelect','off');
cd(path1);
decodedFileName = ['ExtractedData_',file1(1:end-4)];
try load(decodedFileName); % try to load the file
    nTrials = length(ExtractedData);
    % extract bit values and arrange to be of size [nTrials,nParams*bytesize]
    for ii=1:nTrials
        trialBitValues(ii,:) = [ExtractedData(ii).bitData(:).bitValue];
    end
catch
    error('Cannot find ExtractedData file.  Make sure to run decoderIntan first on the raw data file.');
end

decodedFileName = ['ExtractedData_',file1(1:end-4)];
c = dir; a = [c(:).isdir]; c = c(~a); % get all filenames in the directory
for ii=1:length(c)
    if strcmp(c(ii).name(17:end),file1(17:end)) && strcmp(c(ii).name(1:14),'ParameterOrder')
        parameterOrderName = c(ii).name;
    end
end

try load(parameterOrderName); % try to load the file
    [~,~,p] = size(DataVector);
    % rearrange DataVector to be of size [nTrials,nParams*bytesize]
    trialBits = [];
    for ii=1:p
        trialBits = [trialBits,DataVector(:,:,ii)'];
    end
    trialBits = trialBits(TrialIndices,:); % get trialBits to be in the correct trial order

catch
    error('Cannot find ParameterOrder file.  Make sure it is in the same directory as the raw data file.');
end

DecodeDiff = trialBits - trialBitValues; % difference between orginal and decoded


% PLOT BIT MAPS
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
