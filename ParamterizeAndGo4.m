% ParameterizeAndGo4
%   Includes Arbitrary Waveforms for 100% DC signals
%   Arduino Connected


clearvars -except Parameters FG s;

%% PARAMETERS
% Inter-trial duration saturation occurs at 3 times the greatest trial duration.
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

ARD_ID          = 'COM7';       % arduino port connection

% For handling data cycles
DurBit = 5;     % bit duration approx 2 ms longer   [ms] 
DurBuf = 1;     % square wave buffer duration       [ms]

DurBeforeStim = 500; % pause between data phase and trial phase [ms]

%% GENERATING PARAMETER LIST & BINARY DATA
Parameters           = allcomb(TF,Amplitudes,DutyCycles,PRFs,PulseDurations); % all possible trial combinations
[Parameters,NCycles] = RemoveParameterErrors(Parameters); % remove bad parameter combinations
bytesize = max([nextpow2(max(max(Parameters))),bytesize]); % take maximum of needed bytesize and user-input bytesize

nTrials      = size(Parameters,1); % number of trials
nParams      = size(Parameters,2); % number of parameters


if strcmp(trial_order,'random')
    rng('shuffle');
    Parameters = Parameters(randperm(nTrials),:);    % reorder parameter list
    disp(num2str(Parameters));
else
    disp(num2str(Parameters));
    warning('Trial order is not randomized.  Consider changing value of trial_order to ''random''.');
end

% Convert base-10 to binary
DataVector = zeros(nTrials, bytesize*nParams);
for ii = 1:nTrials
    DataVector(ii,:) = binarize(Parameters(ii,:),bytesize);
end

%% ESTABLISH CONNECTIONS TO FUNCTION GENERATOR & ARDUINO // FUNCTION GENERATOR INITIALIZATIONS
%  Establish connection to function generator (if does not exist already)
if ~exist('FG','var')
    FG = visa('keysight',['USB0::2391::10759::',FG_ID,'::0::INSTR'])
end

if strcmp(FG.Status,'closed') % if the function generator connection is closed
    fopen(FG)
end

% Establish connection to arduino
try delete(s); catch; end

try s = serial(ARD_ID);
    fopen(s);   % open connection to arduino (triggers solenoid)
    ArduinoFlag = 1;    % arduino detected
catch
    warning(['No Arduino Detected at the specified port (',ARD_ID,')']);
    ArduinoFlag = 0;    % no arduino
end

fprintf(FG, '*RST'); % Resets to factory default, outputs are off by default

% CREATE ARBITRARY WAVEFORMS IN FUNCTION GENERATOR
ARBgenerate(FG,PulseDurations,12);

% INITIALIZATIONS ON CHANNEL 1      (DIGITAL CHANNEL)
fprintf(FG, 'OUTP1:LOAD INF'); % MAY NEED TO CHANGE THIS

fprintf(FG, 'SOUR1:VOLT 5');        % 5V peak-to-peak
fprintf(FG, 'SOUR1:VOLT:OFFS 2.5'); % 2.5V offset (0-5V range)
fprintf(FG, 'SOUR1:FREQ 7000');     % 7000Hz oscillation frequency
fprintf(FG, 'SOUR1:FUNC SQU');      % Sq. wave
fprintf(FG, 'TRIG1:SOUR BUS');      % trigger source is set to USB input
fprintf(FG, 'SOUR1:BURS:STAT 1');   % turn Burst mode on
fprintf(FG, 'OUTP1 ON');            % turn digital channel on

% INITIALIZATIONS ON CHANNEL 2      (TRANSDUCER CHANNEL)
fprintf(FG,['SOUR2:FREQ ' num2str(TF*1000)]); % Transducer Frequency (kHz)
fprintf(FG, 'SOUR2:AM:STAT 1');     % turn AM modulation on
fprintf(FG, 'SOUR2:AM:SOUR CH2');   % turn the source of AM modulation to channel 2
fprintf(FG, 'OUTP2 OFF');           % turn channel 2 off for data phase


pause(2); % one-time pause to allow any buffered SCPI code to be executed by the funciton generator

%% TRIAL ITERATION

for iTrial = 1:nTrials
    tic; % start counter for each trial
    
    % re-initialize channel 1 to buffer bursting
    fprintf(FG, 'SOUR1:VOLT 5');            % 5V peak-to-peak
    fprintf(FG, 'SOUR1:VOLT:OFFS 2.5');     % 2.5V offset (0-5V)
    fprintf(FG, 'SOUR1:FUNC SQU');          % turn to sq. wave
    fprintf(FG, 'SOUR1:FUNC:SQU:DCYC 50');  % duty cycle of sq. wave is 50%
    fprintf(FG, 'SOUR1:FREQ 7000');         % 7000Hz oscillating frequency
    fprintf(FG, 'OUTP1 ON');                % turn on
    
    fprintf(FG, 'SOUR1:BURS:STAT 0');       % turn burst on
    
    pause(DurBuf/1000);                     % pause for buffer duration
    fprintf(FG,'OUTP1 ON');                 % turn on
    
    % write binary data
    DataByte = DataVector(iTrial,:); % current trial's parameter information
    for Bit=DataByte
        if Bit
            fprintf(FG,'SOUR1:FUNC DC'); % DC of 1
            pause(DurBit/1000);
            fprintf(FG,'SOUR1:FUNC SQU'); % back to buzz
        else
            fprintf(FG, 'SOUR1:BURS:STAT 1'); % turn off
            pause(DurBit/1000);
            fprintf(FG, 'SOUR1:BURS:STAT 0'); % turn back on
        end
    end
    
    pause(DurBuf/1000); % Ch2 offset is now set to zero for trial phase
     
    fprintf(FG, 'OUTP1 OFF'); % Turn this off to prevent false 1s.
    
    % WRITE ACTUAL WAVEFORM
    fprintf(FG, ['SOUR2:VOLT ' num2str(Parameters(iTrial,2)/1000)]);
    
    DC = Parameters(iTrial,3); % current trial's duty cycle
    MF = Parameters(iTrial,4); % current trial's modulating freqeuncy
    pD = Parameters(iTrial,5); % current trial's pulse duration
    
    % INITIALIZE WAVEFORM IN FUNCTION GENERATOR
    switch DC % change behavior based on duty cycle
        case 100 % 100% duty cycle (arbitrary waveform)
            fprintf(FG, 'SOUR1:BURSt:STAT OFF'               ); % turn burst mode off
            fprintf(FG, 'SOUR2:AM:DSSC ON'                   ); % turn DSSC on
            
            fprintf(FG, 'SOUR1:FUNC  ARB'                    ); % change to arbitrary waveform
            fprintf(FG,['SOUR1:FUNC:ARB SEQDC',num2str(pD)]  ); % change to sequence for current pulse duration
            fprintf(FG, 'SOUR1:VOLT 3');                        % voltage at 3 V (does not work with 5 V)
            fprintf(FG, 'SOUR1:VOLT:OFFS 0');                   % offset to 0 V
            
        otherwise % not 100% duty cycle (burst mode)
            fprintf(FG, 'SOUR1:VOLT 5');                        % voltage at 5 V (does not work at 3 V)
            fprintf(FG, 'SOUR1:VOLT:OFFS 2.5');                 % offset to 2.5 V
            fprintf(FG, 'SOUR1:FUNC SQU'                    );  % change to square wave
            fprintf(FG, 'SOUR2:AM:DSSC OFF'                 );  % turn DSSC off
            fprintf(FG,['SOUR1:FREQ ',          num2str(MF)]);  % Modulating Frequency (Hz)
            fprintf(FG,['SOUR1:FUNC:SQU:DCYC ', num2str(DC)]);  % Duty Cycle (%)
            
            NCycles = floor(MF*pD/1000);                        % Number of cycles
            fprintf(FG,['SOUR1:BURS:NCYC '      num2str(NCycles)]);
            fprintf(FG, 'SOUR1:BURS:STAT ON');                  % turn burst mode on
            
    end
    
    % TURN FUNCTION GENERATOR OUTPUTS ON AND TRIGGER
    fprintf(FG, 'OUTP1 ON ');
    fprintf(FG, 'OUTP2 ON ');
    pause(DurBeforeStim/1000);
    
    fprintf(FG, '*TRG'); % Starts Ch2 and Ch1 at same time
    pause(pD*2/1000); % pause sufficiently to allow the full waveform to occur
    fprintf(FG,'OUTP1 OFF');
    fprintf(FG,'OUTP2 OFF');
    
    if ArduinoFlag
        fclose(FG); % close function generator connection
        
        fwrite(s,1); % write anything to arduino to turn solenoid on
        fclose(s);  % close connection to arduino (close it immediately to ensure no accidental triggers)
        fopen(s);   %
        
        fopen(FG);  % open function generator connection
    end
    pause(inter_trial/1000 - toc); % pause for remaining amount of time
end




%% SUPPORT FUNCTION:        BINARIZE
function outputRow = binarize(inputRow,nBits)
% BINARIZE converts base-10 to binary
outputRow = [];
for ii=1:length(inputRow)
    outputBit = zeros(1,nBits);
    workingNumber = inputRow(ii); % Algorithm for converting int to binary
    for bit = nBits:-1:1
        outputBit(bit) = mod(workingNumber,2);
        workingNumber = (workingNumber-outputBit(bit))/2;
    end
    outputRow = [outputRow,outputBit];
end
end