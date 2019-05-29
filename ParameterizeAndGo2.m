%version change: Based on MultiRunDigital. Problems to fix
% 1) Handling 100% duty cycle
% 2) Big parameter list
% 3) RUN SPECIFIC parameter list from globals set up front
clearvars -except Parameters FG;

%% ---------------   VARIABLES YOU ARE RESPONSIBLE TO SET   ---------------

% Inter-trial duration saturation occurs at 2000 ms more than the greatest
% trial duration.
inter_trial     = 5000;     % time between stimulations [ms]
bytesize        = 16;       % number of bits to write for each parameter(keep at 16 for parameter values of <= 65000)

% Import a parameter set list, OR populate a parameter set list
TF              =  5                     ;  % TRANSDUCER FREQUENCY (must be a single value) [kHz]
Amplitudes      = [25   100     400    	];  % voltages to achieve 0.1, 2, and 40 W/cm^2     [mV]
DutyCycles      = [5    50      100     ];	% duty cycles                                   [%]
PRFs            = [10   100     1000    ];	% pulse repetition frequencies                  [Hz]
PulseDurations  = [50   200     1000   	];  % pulse durations                               [ms]

trial_order     = 'random'; % = 'in order';
FG_ID           = 'MY52600694'; % serial number of new fxn generator
%FG_ID           = 'MY52600670'; % serial number of old fxn generator

DataDir         = 'C:/Data/';           % data directory
SaveFolderName  = 'Parameter Orders';   % folder subdirectory
saveName        = uigetfile([DataDir,'*.rhs'],...
    'Select Associated Raw File',...
    'MultiSelect','off');


% For handling data cycles
DurBit = 5;     % bit duration approx 2 ms longer   [ms] 
DurBuf = 1;     % square wave buffer duration       [ms]

% For pauses and timing post-processing
DurBeforeStim = 500; % pause between data phase and trial phase [ms]
%% -------------------------   Initializations   -------------------------
Parameters           = allcomb(TF,Amplitudes,DutyCycles,PRFs,PulseDurations); % all possible trial combinations
[Parameters,NCycles] = RemoveParameterErrors(Parameters); % remove bad parameter combinations
bytesize = max([nextpow2(max(max(Parameters))),bytesize]); % take maximum of needed bytesize and user-input bytesize

NumberOfTrials      = size(Parameters,1);
NumberOfParameters  = size(Parameters,2);

disp(['Number of Trials: ',num2str(NumberOfTrials)]);

%2 Create randomized index list, report it.
%A Create random permutation from 1 to number of trials
rng('shuffle'); % Just in case.
if strcmp(trial_order,'random')
    TrialIndices = randperm(NumberOfTrials); % Creates list
else
    TrialIndices = 1:NumberOfTrials; % Creates list only good for testing
end
%B Write list to file with time stamp?

%B Binarize parameters all at once, no special buffers needed:
DataVector = zeros(bytesize, NumberOfTrials, NumberOfParameters);
for iTrial = 1:NumberOfTrials
    for iParam = 1:NumberOfParameters
        DataVector(:,iTrial,iParam) = binarize(Parameters(iTrial,iParam),bytesize);
    end
end


%  Establish connection, List global parameters, etc.
if ~exist('FG','var')
    FG = visa('keysight',['USB0::2391::10759::',FG_ID,'::0::INSTR'])
end
% Runs the new FunGen
% This address depends on the serial number of the machine.
if strcmp(FG.Status,'closed')
    fopen(FG) % There's some output here, so you know it worked.
end


try saveNamePar = saveName(1:end-4); % save as the raw data file selected
catch
    saveNamePar = rhs_tag(DataDir);  % pulls name of last rhs file created
end
% SAVE TO FILE, WITH ASSOCIATED RHS FILE TAG
mkdir([DataDir,SaveFolderName]);
save([DataDir,SaveFolderName,'/','ParameterOrder_',saveNamePar],...
    'Parameters','DataVector','NumberOfTrials','TrialIndices',...
    'DurBit','DurBuf','FG_ID','inter_trial','Data_Dir','saveName',...
    'DurBeforeStim');

disp('Parameters (in randomized order):');
disp(Parameters(TrialIndices,:));


%% A Establish Connection, reset system
fprintf(FG, '*RST'); % Resets to factory default. Very quick. Sets OUTP OFF
fprintf(FG, 'OUTP2:LOAD INF'); % Ch2 needs time to warm up.
fprintf(FG, 'SOUR2:VOLT 5');
fprintf(FG, 'SOUR2:VOLT:OFFS 2.5');
fprintf(FG, 'SOUR2:FREQ 7000');
fprintf(FG, 'SOUR2:FUNC SQU');
fprintf(FG, 'TRIG2:SOUR BUS');
fprintf(FG, 'SOUR2:BURS:STAT 1');
fprintf(FG, 'OUTP2 ON');

%3 Any one-time/last-minute initializing.
fprintf(FG, ['FREQ ' num2str(Parameters(1,1)*1000)]); % Transducer Frequency (kHz)
fprintf(FG,'AM:STAT 1');
fprintf(FG,'AM:SOUR CH2');
% Give Ch1 long enough (at least 1.7 sec) to finish warming up.
pause(2); % This value is arbitrary, but should be sufficiently high (>2 seconds)


%% --------------   Real code: Loop through indices/trials   --------------
for iTrial = 1:NumberOfTrials
    %% ----------------------------   Data Phase   ----------------------------
    % Ch1 silenced, Ch2 to data mode, first buffer
    tic;
    fprintf(FG, 'SOUR2:FUNC SQU'); % Change back to square wave if changed
    fprintf(FG, 'SOUR2:FUNC:SQU:DCYC 50');
    fprintf(FG, 'SOUR2:FREQ 7000'); % Creates 5 ms of 1s @ 7kHz
    fprintf(FG, 'OUTP2 ON');
    %pause(0.5); % Pause to separate trials, let OUTP2 recover
    
    
    fprintf(FG, 'SOUR2:BURS:STAT 0'); % First buffer
    pause(DurBuf/1000);
    
    for iParam = 1:NumberOfParameters % Outputs each parameter sequentially
        for iBit = 1:bytesize % Starts from Most Significant Bit
            if DataVector(iBit,TrialIndices(iTrial),iParam) % Outputs bits of trial to be run
                % MAKE SURE ABOVE IS REFERENCING CORRECTLY
                fprintf(FG, 'SOUR2:FUNC DC');
                pause(DurBit/1000);
                fprintf(FG, 'SOUR2:FUNC SQU');
            else
                fprintf(FG, 'SOUR2:BURS:STAT 1');
                pause(DurBit/1000);
                fprintf(FG, 'SOUR2:BURS:STAT 0');
            end
        end
        pause(DurBuf/1000); % Ch2 offset is now set to zero for trial phase
        
    end
    
    %% ----------------------------   Trial Phase   ---------------------------
    %Run TrialIndices(trial)
    %A Trial Phase Settings
    fprintf(FG, 'OUTP2 OFF'); % Turn this off to prevent false 1s.
    fprintf(FG, 'SOUR2:BURSt:STAT ON');
    %B Trial Specific Settings
    fprintf(FG, ['VOLT ' num2str(Parameters(TrialIndices(iTrial),2)/1000)]);
    if Parameters(TrialIndices(iTrial),3) == 100 % Send a pulse of appropriate length
        PulsePeriod = Parameters(TrialIndices(iTrial),5)/1000*2; % Pulse_period = trial_duration, in seconds.
        fprintf(FG, ['SOUR2:FUNC:PULS:PER ' num2str(PulsePeriod)]); % ON time plus safety margins
        fprintf(FG, ['SOUR2:FUNC:PULS:WIDT ' num2str(Parameters(TrialIndices(iTrial),5)/1000)]); % ON time
        fprintf(FG, 'SOUR2:FUNC:PULS:TRAN:BOTH MAX'); % Sets rise and fall time to longest possible (1 us).
        fprintf(FG, 'SOUR2:FUNC PULS');
        
    else % Make a square wave envelope of appropriate parameters (Switch to pulse based?)
        fprintf(FG, ['SOUR2:FREQ '          num2str(Parameters(TrialIndices(iTrial),4))]); % Modulating Frequency (Hz)
        fprintf(FG, ['SOUR2:FUNC:SQU:DCYC ' num2str(Parameters(TrialIndices(iTrial),3))]); % Duty Cycle (%)
        NCycles = floor(Parameters(TrialIndices(iTrial),4)*Parameters(TrialIndices(iTrial),5)/1000);
        fprintf(FG, ['SOUR2:BURSt:NCYC '    num2str(NCycles)]); % Number of cycles
    end
    %C Go!
    fprintf(FG, 'OUTP1 ON ');
    fprintf(FG, 'OUTP2 ON ');
    pause(DurBeforeStim); % Do we need a pause for these to boot up?
    
    fprintf(FG, '*TRG'); % Starts Ch2 and Ch1 at same time
    pause(Parameters(TrialIndices(iTrial),5)/1000); % Trial duration (ms)
    
    fprintf(FG, 'OUTP1 OFF');
    fprintf(FG, 'OUTP2 OFF');
    pause(inter_trial/1000 - toc); % inter-trial pause
end

%% ------------------------   A support function   ------------------------
function outputBit = binarize(inputDecimal,nBits)
% BINARIZE converts base-10 to binary
outputBit = zeros(1,nBits);
workingNumber = inputDecimal; % Algorithm for converting int to binary
for bit = nBits:-1:1
    outputBit(bit) = mod(workingNumber,2);
    workingNumber = (workingNumber-outputBit(bit))/2;
end
end

% ------------------------- rhs_tag support function ---------------------
function outputstring = rhs_tag(directory1)
% RHS_TAG gets the name of the last file created in the directory specified
c = dir(directory1); a = [c(:).isdir]; c = c(~a);
[~,ii] = sort([c(:).datenum],'descend');
c = c(ii);
outputstring = c(1).name(1:end-4);

end