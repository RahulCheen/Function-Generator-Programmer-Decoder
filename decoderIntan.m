function decoderIntan(nParams)
% DECODERINTAN reads digital data from the function generator (via Intan), and separates out binary
% parameter information and stimulation envelopes.  Output is a file called 'ExtractedData.mat' that
% contains a structure called ExtractedData, which contains information for each trial found in the
% digital channel data.  Information within variable ExtractedData:
%
%           BitData: sub-structure containing information for each bit in the corresponding trial:
%                       bitMean: average value of the bit information
%                      bitValue: whether it's a 1 or 0.  Based on thresholding the bitMean at 0.95
%                      bitStart: start of the bit information within the digital data
%                        bitEnd: end of the bit information within the digital data
%     trialEnvelope: trial information in the digital data
%      stimEnvelope: stimulation envelope, within the trial data
%   trialPhaseStart: start of the trial phase, reference to start of digital data
%     trialPhaseEnd: end of the trial phase, reference to start of digital data
%         stimStart: start of the stimulation, reference to the start of the digital data
%           stimEnd: end of the stimulation, reference to the start of the digital data
%       carrierFreq: decoded carrier frequency for the trial [kHz]
%         amplitude: decoded amplitude for the trial (input to fxn generator) [mV]
%         dutyCycle: decoded duty cycle for the trial [%]
%           modFreq: decoded modulating frequency for the trial [Hz]
%     pulseDuration: decoded pulse duration for the trial [ms]
%
% Errors should not cause the code to quit, but should instead place an empty array in the location
% of the error.
if ~exist('nParams','var')
    nParams = 5;
end

addpath(cd);
addpath(pwd);

[file1,path1] = uigetfile('*.rhs','Select Raw Data','MultiSelect','off');

c = strsplit(file1,'.');
timestamp = c{1};

fileName = [path1,file1(1:end-3),'mat'];
cd(path1);
try load(fileName,'*dig*','*adc*','ana*','freq*','v*'); % load in all variables with these
catch
    error('Must run conversion scripts: convert_rhs.m or convert_dat.m');
end
try d1(1,:) = board_dig_in_data(1,:);
catch
    try d1(1,:) = digital(1,:);
    catch
        try d1(1,:) = v';
        catch
            error('Check input data for variable name.');
        end
    end
end % try to load variables of different names

if ~iscolumn(d1)
    d1 = d1';
end
fs = frequency_parameters.board_dig_in_sample_rate; % get sampling frequency from data

ii = 2; % start at 2nd time point

[startBuzz(1),endBuzz(1),new_ii] = findBuzz(d1,2); % find the first buzz

ii=new_ii;

% initialize export structure
ExtractedData = struct(...
    'bitData',          struct(...
                                'bitMean',      [],...
                                'bitValue',     [],...
                                'bitStart',     [],...
                                'bitEnd',       [],...
                                'bitEnvelope',  []...
                                ),...
    'trialEnvelope',    [],...
    'stimEnvelope',     [],...
    'trialPhaseStart',  [],...
    'trialPhaseEnd',    [],...
    'stimStart',        [],...
    'stimEnd',          [],...
    'carrierFreq',      [],...
    'amplitude',        [],...
    'dutyCycle',        [],...
    'modFreq',          [],...
    'pulseDuration',   	[]...
    );
iBit = 0; iTrial = 1;
while ii<length(d1) % loop through digitalData
    disp(['Trial #',num2str(iTrial),', Bit ',num2str(iBit)]);
    % find the next buzz

    [startBuzz(2),endBuzz(2),new_ii] = findBuzz(d1,ii);
    
    % inter-buzz duration
    lbetweenBuzz = startBuzz(2)-endBuzz(1);
    
    bit = lbetweenBuzz < fs/2; % bit information is always less than 0.5 seconds
    
    switch bit
        case 1 % treat data as a bit
            iBit = iBit + 1; % go to next bit
            bitstream = d1(endBuzz(1):startBuzz(2)); % stream of bit
            bitMean = mean(bitstream); % average value of the bit data
            bitValue = bitMean > 0.95; % separates 0s from 1s with threshold of 0.95
            ExtractedData(iTrial).bitData(iBit).bitMean     = bitMean;
            ExtractedData(iTrial).bitData(iBit).bitValue    = bitValue;
            ExtractedData(iTrial).bitData(iBit).bitStart    = endBuzz  (1);
            ExtractedData(iTrial).bitData(iBit).bitEnd      = startBuzz(2);
            ExtractedData(iTrial).bitData(iBit).bitEnvelope = d1(endBuzz(1):startBuzz(2));
            
        case 0 % treat data as a trial
            
            trial_remove = 100;
            trialstream = d1(endBuzz(1)+trial_remove:startBuzz(2)-trial_remove); % trial stream, remove 100 points from either end
            
            
            stimStart   = find(trialstream,1,'first') - 1;
            stimEnd     = find(trialstream,1,'last' ) + 1;
            
            % get parameter information from the bit data for each trial
            try trialByte        = [ExtractedData(iTrial).bitData(:).bitValue]; % try to get the information
                trial_parameters = debinarize(trialByte,nParams);
                ExtractedData(iTrial).carrierFreq       = trial_parameters(1);
                ExtractedData(iTrial).amplitude         = trial_parameters(2);
                ExtractedData(iTrial).dutyCycle         = trial_parameters(3);
                ExtractedData(iTrial).modFreq           = trial_parameters(4);
                ExtractedData(iTrial).pulseDuration     = trial_parameters(5);
                
            catch % unable to extract parameters, set to empty, find corresponding trial in ParameterOrder.mat
                ExtractedData(iTrial).carrierFreq       = [];
                ExtractedData(iTrial).amplitude         = [];
                ExtractedData(iTrial).dutyCycle         = [];
                ExtractedData(iTrial).modFreq           = [];
                ExtractedData(iTrial).pulseDuration     = [];
            
            end
            
            ExtractedData(iTrial).trialPhaseStart   = endBuzz  (1)+trial_remove;  % start of trial phase
            ExtractedData(iTrial).trialPhaseEnd     = startBuzz(2)-trial_remove;  % end of trial phase
            ExtractedData(iTrial).trialEnvelope     = trialstream;   % entire trial phase
            try ExtractedData(iTrial).stimStart         = stimStart + startBuzz(2); % start of stimulation
                ExtractedData(iTrial).stimEnd           = stimEnd   + startBuzz(2); % end of stimulation
                ExtractedData(iTrial).stimEnvelope      = trialstream(stimStart:stimEnd); %
            catch % replace with empty values if there is no stimulation
                ExtractedData(iTrial).stimStart         = []; % start of stimulation
                ExtractedData(iTrial).stimEnd           = []; % end of stimulation
                ExtractedData(iTrial).stimEnvelope      = []; %
            end
            iBit = 0; % reset bit counter
            iTrial = iTrial + 1; % increment trial counter
    end
    
    % shift 2nd buzz to first position
    startBuzz(1) = startBuzz(2);
    endBuzz(1)   = endBuzz(2);
    
    ii=new_ii; % start looking where you left off
    
end

% save to file, in same folder as data
save(['ExtractedData_',timestamp],'ExtractedData','d1','fileName');

ParameterOrderDecoded = [...
    [ExtractedData(:).carrierFreq]',...
    [ExtractedData(:).amplitude]',...
    [ExtractedData(:).dutyCycle]',...
    [ExtractedData(:).modFreq]',...
    [ExtractedData(:).pulseDuration]'];

disp(['       Number of Trials: ',num2str(length(ParameterOrderDecoded))]);
disp(['Number of Unique Trials: ',num2str(length(unique(ParameterOrderDecoded,'rows')))]);

assignin('base','ExtractedData',eval('ExtractedData'));
end

% ~~~~~~~~~~~~~~~~~~~~~~~~~ FindBuzz ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function [buzzStart,buzzEnd,new_ii] = findBuzz(d1,startindex)
% FINDBUZZ finds the next buzz in the digital channel.  Inputs are the full digital channel data, and the
% starting index to find the next buzz.  Outputs are the start of the buzz, the end of the buzz, and the
% new starting index for the next iteration.  If the loop goes to the end of the digital channel without
% finding a buzz, a "phantom" buzz is returned, where the start and end of the buzz are both at the last
% point in the digital data.
% 
% The algorithm to find the buzz uses a 10 data point window, and slides it along the digital data.  As
% it slides along the data until it finds where there are equal number of 1s and 0s, as well as more than
% 1 positive and negative changes, meaning there are fast oscillations occuring.  Once it finds the first
% point that this occurs (the start of the buzz), it continues until the sliding window shows only all 1s
% or 0s.  This algorithm can be sped up by increasing the size of the window, or by changing how fast the
% window slides along the data, but at a possible cost of decreased robustness and accuracy.

buzzStart   = length(d1);   % returns last point in digital data if not found in algorithm
buzzEnd     = length(d1);
new_ii      = length(d1);   % returns the end of the digital data if this is not found in the algorithm
ii          = startindex;   % start while loop at startindex

inbuzzflag = 0;         % initialize inbuzz to 0 (not in a buzz)

while ii < length(d1)-10
    win = ii:ii+9; % scanning window to find a Buzz
    
    nZeros          = sum(d1(win) == 0);         	% number of zeros in window
    nOnes           = sum(d1(win) == 1);         	% number of ones in window
    nPosChanges     = sum(diff(d1(win)) == 1);      % number of positive changes in window
    nNegChanges     = sum(diff(d1(win)) == -1);     % number of negative changes in window
    
    if abs(nZeros-nOnes) <= 1 % if the number of ones and zeros are close to each other, it's oscillating
        if nPosChanges > 1 && nNegChanges > 1 % if it is acutally oscillating, both of these numbers will be greater than 1
            if ~inbuzzflag % not in a buzz already
                buzzStart = win(1); % start of buzz at first detection of oscillation
            end
            inbuzzflag = 1; % we know we're in a buzz, change behavior

        else% no need to do anything here
        end
        
    elseif abs(nZeros-nOnes) == length(win) % stopped oscillation, steadily 0 or 1
        if inbuzzflag==1 % only if currently in a buzz, break out of loop
            buzzEnd = win(1);
            new_ii  = win(end);
            break; % exit while loop
        end
    else% error catching should go in here, works well without anything here so far
    end
    
    ii=ii+1;
    
    if ii >= length(d1)-10 % goes to end of data, didn't find one at all
        buzzStart   = length(d1); % set to end
        buzzEnd     = length(d1); % set to end
        new_ii      = length(d1); % set to end
    end
end
end


% ~~~~~~~~~~~~~~~~~~~~~~~ debinarize ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ParaOut = debinarize(dataBlock,nParams)
% DEBINARIZE converts from binary to base-10.  Requires a 2^n byte size (8, 16, 32, etc).

[numberOfTrials,N] = size(dataBlock); % get size of dataBlock

bytesize = floor(N/nParams);   % byte-size the divisor of number of columns and number of params

ParaOut = zeros(numberOfTrials,nParams); % initialize
for i = 1:numberOfTrials % Trial
    for j = 1:nParams % Parameter
        for b = 1:bytesize % Bit (Goes from MSB to LSB)
            ParaOut(i,j) = 2*ParaOut(i,j); % Bitshift
            ParaOut(i,j) = ParaOut(i,j)+dataBlock(i,bytesize*j-bytesize+b); % Add next bit
        end
    end
end

end