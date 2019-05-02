%version change: Based on MultiRunDigital. Problems to fix
% 1) Handling 100% duty cycle
% 2) Big parameter list
% 3) RUN SPECIFIC parameter list from globals set up front
clearvars -except FG;

%% ---------------   VARIABLES YOU ARE RESPONSIBLE TO SET   ---------------

inter_trial     = 5000;     % intertrial duration for 1000 ms between trials (actual is slightly shorter)
bytesize        = 16;       % number of bits to write for each parameter(keep at 16 for parameter values of <= 1000)

% Import a parameter set list, OR populate a parameter set list
TF              = [12                       ];  % TRANSDUCER FREQUENCY          [kHz]
Amplitudes      = [25   100     400         ];  % voltages [mV] to achieve 0.1, 2, and 40 W/cm^2
DutyCycles      = [5    50      100         ];	% duty cycles                   [%]
PRFs            = [0    10      100     1000];	% pulse repetition frequencies  [Hz]
PulseDurations  = [50   200     1000        ];  % pulse durations               [ms]

trial_order     = 'random'; % = 'in order';
FG_serialNumber = 'MY52600694';% serial number of old = MY52600670, new = MY52600694

DataDir = 'C:/Data/';
SaveFolderName  = 'Parameter Orders';
%% -------------------------   Initializations   -------------------------
Parameters           = allcomb(TF,Amplitudes,DutyCycles,PRFs,PulseDurations);
[Parameters,NCycles] = RemoveParameterErrors(Parameters);

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

% SAVE TO FILE, WITH TIME STAMP
timestamp = clockformat(clock); % get current time, format for output data
mkdir([DataDir,SaveFolderName]);
save([DataDir,SaveFolderName,'/','ParameterOrder_',timestamp],'Parameters','DataVector','NumberOfTrials','TrialIndices');

disp('Parameters (in randomized order):');
disp(Parameters(TrialIndices,:));

%  Establish connection, List global parameters, etc.
if ~exist('FG','var')
    FG = visa('keysight',['USB0::0x0957::0x2A07::',FG_serialNumber,'::0::INSTR'])
end
% Runs the new FunGen
% This address depends on the serial number of the machine.
if strcmp(FG.Status,'closed')
    fopen(FG) % There's some output here, so you know it worked.
end

%A Establish Connection, reset system
fprintf(FG, '*RST'); % Resets to factory default. Very quick. Sets OUTP OFF
fprintf(FG, 'OUTP2:LOAD INF'); % Ch2 needs time to warm up.
fprintf(FG, 'SOUR2:VOLT 5');
fprintf(FG, 'SOUR2:VOLT:OFFS 2.5');
fprintf(FG, 'SOUR2:FREQ 7000');
fprintf(FG, 'SOUR2:FUNC SQU');
fprintf(FG, 'TRIG2:SOUR BUS');
fprintf(FG, 'SOUR2:BURS:STAT 1');
fprintf(FG, 'OUTP2 ON');

%A Globals:
% For handling data cycles
DurBit = 10; % ms, bit duration approx 2 ms longer
DurBuf = 1; % ms, square wave buffer duration, should be unnecessary

%3 Any one-time/last-minute initializing.
fprintf(FG, ['FREQ ' num2str(Parameters(1,1)*1000)]); % Transducer Frequency (kHz)
fprintf(FG,'AM:STAT 1');
fprintf(FG,'AM:SOUR CH2');
% Give Ch1 long enough (at least 1.7 sec) to finish warming up.
pause(1.25); % This value is arbitrary, but should be sufficiently high


%% --------------   Real code: Loop through indices/trials   --------------
for trial = 1:NumberOfTrials
    
    %% ----------------------------   Data Phase   ----------------------------
    % Ch1 silenced, Ch2 to data mode, first buffer
    fprintf(FG, 'SOUR2:FUNC SQU'); % Change back to square wave if changed
    fprintf(FG, 'SOUR2:FUNC:SQU:DCYC 50');
    fprintf(FG, 'SOUR2:FREQ 7000'); % Creates 5 ms of 1s
    fprintf(FG, 'OUTP2 ON');
    pause(1); % Pause to separate trials, let OUTP2 recover
    
    inter_trial = inter_trial - 1;
    
    fprintf(FG, 'SOUR2:BURS:STAT 0'); % First buffer
    pause(DurBuf/1000);
    inter_trial = inter_trial - DurBuf/1000;
    
    for param = 1:NumberOfParameters % Outputs each parameter sequentially
        for bit = 1:bytesize % Starts from Most Significant Bit
            if DataVector(bit,TrialIndices(trial),param) % Outputs bits of trial to be run
                % MAKE SURE ABOVE IS REFERENCING CORRECTLY
                fprintf(FG, 'SOUR2:FUNC DC');
                pause(DurBit/1000); inter_trial = inter_trial - DurBit/1000;
                fprintf(FG, 'SOUR2:FUNC SQU');
            else
                fprintf(FG, 'SOUR2:BURS:STAT 1');
                pause(DurBit/1000); inter_trial = inter_trial - DurBit/1000;
                fprintf(FG, 'SOUR2:BURS:STAT 0');
            end
        end
        pause(DurBuf/1000); % Ch2 offset is now set to zero for trial phase
        inter_trial = inter_trial - DurBuf/1000;
    
    end
    
    %% ----------------------------   Trial Phase   ---------------------------
    %Run TrialIndices(trial)
    %A Trial Phase Settings
    fprintf(FG, 'OUTP2 OFF'); % Turn this off to prevent false 1s.
    fprintf(FG, 'SOUR2:BURSt:STAT ON');
    
    %B Trial Specific Settings
    fprintf(FG, ['VOLT ' num2str(Parameters(TrialIndices(trial),2)/1000)]);
    if Parameters(TrialIndices(trial),3) == 100 % Send a pulse of appropriate length
        PulsePeriod = Parameters(TrialIndices(trial),5)/1000*2; % Pulse_period = trial_duration, in seconds.
        fprintf(FG, ['SOUR2:FUNC:PULS:PER ' num2str(PulsePeriod)]); % ON time plus safety margins
        fprintf(FG, ['SOUR2:FUNC:PULS:WIDT ' num2str(Parameters(TrialIndices(trial),5)/1000)]); % ON time
        fprintf(FG, 'SOUR2:FUNC:PULS:TRAN:BOTH MAX'); % Sets rise and fall time to longest possible (1 us).
        fprintf(FG, 'SOUR2:FUNC PULS');
        
    else % Make a square wave envelope of appropriate parameters (Switch to pulse based?)
        fprintf(FG, ['SOUR2:FREQ '          num2str(Parameters(TrialIndices(trial),4))]); % Modulating Frequency (Hz), (creates 5 ms 1s)
        fprintf(FG, ['SOUR2:FUNC:SQU:DCYC ' num2str(Parameters(TrialIndices(trial),3))]); % Duty Cycle (%)
        NCycles = floor(Parameters(TrialIndices(trial),4)*Parameters(TrialIndices(trial),5)/1000);
        fprintf(FG, ['SOUR2:BURSt:NCYC '    num2str(NCycles)]); % Number of cycles, (creates 5 ms 1s)
    end
    %C Go!
    fprintf(FG, 'OUTP1 ON ');
    fprintf(FG, 'OUTP2 ON ');
    pause(1); % Do we need a pause for these to boot up?
    inter_trial = inter_trial - 1;
    fprintf(FG, '*TRG'); % Starts Ch2 and Ch1 at same time
    pause(Parameters(TrialIndices(trial),5)/1000); % Trial duration (ms)
    fprintf(FG, 'OUTP1 OFF');
    fprintf(FG, 'OUTP2 OFF');
    inter_trial = inter_trial - Parameters(TrialIndices(trial),5)/1000;
    pause(inter_trial); % inter-trial pause
end

%% ------------------------   A support function   ------------------------
function outputBit = binarize(inputDecimal,nBits)
outputBit = zeros(1,nBits);
workingNumber = inputDecimal; % Algorithm for converting int to binary
for bit = nBits:-1:1
    outputBit(bit) = mod(workingNumber,2);
    workingNumber = (workingNumber-outputBit(bit))/2;
end
end

% ---------------------- clockformat support function ---------------------
function outputstring = clockformat(c)
format shortg
for ii=2:6
    if c(ii) < 10;  cbetween{ii} = '0';
    else;           cbetween{ii} = ''; end
end
outputstring = [...
    num2str(rem(c(1),2000)),... % year
    cbetween{2},num2str(c(2)),      ...   	% month
    cbetween{3},num2str(c(3)),'_',  ...    	% day
    cbetween{4},num2str(c(4)),      ...  	% hour
    cbetween{5},num2str(c(5)),      ...   	% minute
    cbetween{6},num2str(round(c(6)))];      % second
format short
end