clear;
try, instrreset;
catch
end

dCycle = 20;                % [%]

PRFSweep.low = 10;          % [Hz]
PRFSweep.high = 150;        % [Hz]
PRFSweep.duration = 1.5;    % [s]

amplitudes = [30 60 100 120 200 250]; % 4 amplitudes [mV]
frequencies = [135 279 885]; % 3 frequencies, [kHz]
PulsedContinuous = [0,1];

inter_trial = 5.0; % time between starts of successive trials [s]

nRepetitions = 5; % number of reptitions for each stimulus

FG_Mod_ID = 'MY52600694'; % modulation function generator
FG_Tx_ID  = 'MY52600670'; % transducer function generator

DurBuf = 1; % buffer duration (used rarely) [ms]

DurBeforeStim = 500; % time between information writing phase and stimulus [ms]
BitInfoSpeed = 30; % how fast the information writing phase writes each binary number [Hz]

DurBit = 1000/BitInfoSpeed;

Parameters = allcomb(frequencies,amplitudes,PulsedContinuous); % matrix of paramerter combinations
Parameters = repmat(Parameters,nRepetitions,1); % repeat parameter combinations

bytesize = nextpow2(max(max(Parameters))); % number of bytes to write, found automatically based on the largest number needed to be written


Parameters = Parameters(randperm(length(Parameters)),:); % randomize trials

% establish connection with function generators
if ~exist('FG_Mod','var') % modulation function generator
    FG_Mod = visa('keysight',['USB0::0x0957::0x2A07::',FG_Mod_ID,'::0::INSTR']);
    FG_Mod.OutputBufferSize = 2^32;
    fopen(FG_Mod);
elseif strcmp(FG_Mod.Status,'closed')
    FG_Mod.OutputBufferSize = 2^32;
    fopen(FG_Mod);
else % already opened
    fclose(FG_Mod);
    FG_Mod.OutputBufferSize = 2^32;
    fopen(FG_Mod);
end

if ~exist('FG_Tx','var') % transducer function generator
    FG_Tx = visa('keysight',['USB0::0x0957::0x2A07::',FG_Tx_ID,'::0::INSTR']);
    %FG_Tx.OutputBufferSize = 2^32;
    fopen(FG_Tx);
elseif strcmp(FG_Tx.Status,'closed')
    %FG_Tx.OutputBufferSize = 2^32;
    fopen(FG_Tx);
else % already opened
    fclose(FG_Tx);
    %FG_Tx.OutputBufferSize = 2^32;
    fopen(FG_Tx);
end

%% Initialize Function generators
fprintf(FG_Tx,'*RST'); % reset
fprintf(FG_Tx, 'OUTP1 OFF');           % turn channel 2 off for data phase
fprintf(FG_Tx,['SOUR1:FREQ ' num2str(frequencies(1)*1000)]); % Transducer Frequency, written to FG in kHz
fprintf(FG_Tx,['SOUR1:VOLT ',num2str(amplitudes(1)/1000)]); % set voltage, written to FG in V
fprintf(FG_Tx, 'SOUR1:AM:STAT 1');     % turn AM modulation on
fprintf(FG_Tx, 'SOUR1:AM:DSSC 1');
fprintf(FG_Tx, 'SOUR1:AM:SOUR EXT');   % turn the source of AM modulation to channel 2
fprintf(FG_Tx, 'OUTP1 OFF');           % turn channel 2 off for data phase
fprintf(FG_Tx, 'OUTP1 ON');


fprintf(FG_Tx, 'SOUR2:VOLT 5');            % 5V peak-to-peak
fprintf(FG_Tx, 'SOUR2:VOLT:OFFS 2.5');     % 2.5V offset (0-5V)
fprintf(FG_Tx, 'SOUR2:FUNC SQU');          % turn to sq. wave
fprintf(FG_Tx, 'SOUR2:FUNC:SQU:DCYC 50');  % duty cycle of sq. wave is 50%
fprintf(FG_Tx, 'SOUR2:FREQ 7000');         % 7000Hz oscillating frequency

fprintf(FG_Tx, 'TRIG2:SOUR BUS');
fprintf(FG_Tx, 'SOUR2:BURS:STAT 0');       % turn burst off so that fast oscillation turns on

fprintf(FG_Mod, '*RST'); % reset
fprintf(FG_Mod, 'SOUR2:FUNC SQU'); % square wave
fprintf(FG_Mod, ['SOUR2:FREQ ',num2str(PRFSweep.low)]); % low frequency of sweep
fprintf(FG_Mod, ['SOUR2:FUNC:SQU:DCYC ', num2str(dCycle)]);  % Duty Cycle (%)
fprintf(FG_Mod, ['SOUR2:VOLT 5']); % 5 V
fprintf(FG_Mod, ['SOUR2:SWE:SPAC LIN']); % sweep parameter - spacing
fprintf(FG_Mod, ['SOUR2:SWE:TIME ',    num2str(PRFSweep.duration)]); % sweep parameter - duration
fprintf(FG_Mod, ['SOUR2:FREQ:STAR ',   num2str(PRFSweep.low)]); % sweep parameter - low frequency
fprintf(FG_Mod, ['SOUR2:FREQ:STOP ',   num2str(PRFSweep.high)]); % sweep parameter - high frequency
fprintf(FG_Mod,  'SOUR2:SWE:HTIM 0.5'); % sweep parameter - hold time (corrects for differing times for sweep and arb)

% arbitrary waveform generation
fprintf(FG_Mod,'DATA:VOL:CLE'); % clear volatile memory for arbitrary waveform
fprintf(FG_Mod,'SOUR1:FUNC ARB'); % Change channel 1's waveform to ARB
fprintf(FG_Mod,'SOUR1:FUNC:ARB:FILTER STEP');

fprintf(FG_Mod, ['DATA:ARB:DAC DC0',sprintf(',%d',round(zeros(8,1)*(2^15-1)))]); % smallest possible arbitraty waveform, to set triggering
pd = PRFSweep.duration;
srate = 1000;
fprintf(FG_Mod, ['DATA:ARB:DAC DCON',sprintf(',%d',round(ones(pd*srate,1)*(2^15-1)))]); % on for sweep time
fprintf(FG_Mod, ['DATA:ARB:DAC DCOFF',sprintf(',%d',round(zeros(0.5*srate,1)*(2^15-1)))]); % force off for 0.5s

SEQ_command = ['"','PRFSweep','",',...
    '"DC0",     1,repeatTilTrig,maintain,4,',... % first waveform
    '"DCON",    1,once,         maintain,4,',... % second waveform
    '"DCOFF",   1,once,         maintain,4,'];   % third waveform

npoints = length(SEQ_command)-1; % number of points in the character vector
ndigits = floor(log10(length(SEQ_command)))+1; % number of digits in the character vector

fprintf(FG_Mod, ['DATA:SEQ #',... % print it to the function generator
    num2str(ndigits),...
    num2str(npoints),...
    SEQ_command]);
fprintf(FG_Mod, ['SOUR1:FUNC:ARB PRFSweep']);
fprintf(FG_Mod,['MMEM:STORE:DATA "INT:\PRFSweep.seq"']);

fprintf(FG_Mod,['SOUR1:FUNC:ARB:SRATE ',num2str(srate)]);
fprintf(FG_Mod, 'SOUR1:AM:DSSC OFF'                 );  % turn DSSC off
fprintf(FG_Mod, 'SOUR1:AM:STAT 1');     % turn AM modulation on
fprintf(FG_Mod, 'SOUR1:AM:SOUR CH2');   % turn the source of AM modulation to channel 2
fprintf(FG_Mod, 'SOUR2:SWE:STAT 1');
fprintf(FG_Mod, 'TRIG1:SOUR BUS');      % trigger source is set to USB input
fprintf(FG_Mod, 'SOUR1:VOLT 1');
fprintf(FG_Mod, 'OUTP1 ON');            % turn on (no output as it's waiting for trigger)
fprintf(FG_Mod, 'OUTP2 ON');            % turn on (there is output, but indirectly waiting for trigger)
fprintf(FG_Mod, 'TRIG1:SOUR BUS');      % trigger source is MATLAB
fprintf(FG_Mod, 'TRIG2:SOUR BUS');      % trigger source is MATLAB
%%
% isFirst = 1;
estimatedTime = inter_trial*length(Parameters)/60; % [min]
disp(['Estimated Duration of Session: ',num2str(floor(estimatedTime)),' min, ',num2str((estimatedTime-floor(estimatedTime))*60),' seconds']);

pause(2.0); % allows for function generator to catch up
t = zeros(length(Parameters),1); %

for iTrial = 1:length(Parameters)
    tic;
    disp(['Trial ',num2str(iTrial),': CF = ',num2str(Parameters(iTrial,1)),' kHz, Amp = ',num2str(Parameters(iTrial,2)),' mV', 'Continuous?: ',num2str(Parameters(iTrial,3))]);
    
    
    fprintf(FG_Tx,'OUTP1 OFF'); % turn transducer off
    fprintf(FG_Tx,'OUTP2 OFF'); % turn bit information writing off
    
    
    DataByte = binarize(Parameters(iTrial,:),bytesize); % current trial's parameter information
    DataByte = [DataByte(1:bytesize*2),DataByte(end)]; % only get the last digit of the 3rd parameter (already binary)
    
    % re-initialize channel 1 to buffer bursting
    fprintf(FG_Tx, 'SOUR2:VOLT 5');            % 5V peak-to-peak
    fprintf(FG_Tx, 'SOUR2:VOLT:OFFS 2.5');     % 2.5V offset (0-5V)
    fprintf(FG_Tx, 'SOUR2:FUNC SQU');          % turn to sq. wave
    fprintf(FG_Tx, 'SOUR2:FUNC:SQU:DCYC 50');  % duty cycle of sq. wave is 50%
    fprintf(FG_Tx, 'SOUR2:FREQ 7000');         % 7000Hz oscillating frequency
    
    fprintf(FG_Tx, 'TRIG2:SOUR BUS');
    fprintf(FG_Tx, 'SOUR2:BURS:STAT 0');       % turn burst off so that fast oscillation turns on
    
    
    fprintf(FG_Tx,'OUTP2 ON');                 % turn on
    pause(DurBit/1000);                     % pause for buffer duration
    
    % write binary data
    %DataByte = DataVector(iTrial,:); % current trial's parameter information
    for Bit=DataByte
        if Bit
            fprintf(FG_Tx,'SOUR2:FUNC DC'); % DC of 2.5 (in digital input, 1)
            pause(DurBit/1000);
            fprintf(FG_Tx,'SOUR2:FUNC SQU'); % back to buzz
        else
            fprintf(FG_Tx, 'SOUR2:BURS:STAT 1'); % turn burst on (waiting for trigger, 0V output)
            pause(DurBit/1000);
            fprintf(FG_Tx, 'SOUR2:BURS:STAT 0'); % turn back on (back to buzz)
        end
    end
    
    pause(DurBuf/1000); % Ch2 offset is now set to zero for trial phase
    
    fprintf(FG_Tx, 'OUTP2 OFF'); % Turn this off to prevent false 1s.
    
    
    fprintf(FG_Mod,'SOUR1:FUNC ARB');
    fprintf(FG_Mod, ['SOUR1:FUNC:ARB PRFSweep']);
    fprintf(FG_Mod,['SOUR1:FUNC:ARB:SRATE ',num2str(srate)]); % change sample rate for arbitrary waveform
    fprintf(FG_Mod, 'SOUR1:AM:STAT 1');     % turn AM modulation on
    fprintf(FG_Mod, 'SOUR1:AM:DSSC OFF');   % turn DSSC off
    fprintf(FG_Mod, 'SOUR1:AM:SOUR CH2');   % turn the source of AM modulation to channel 2
    
    
    fprintf(FG_Mod,'SOUR1:AM:STAT 1');
    
    % change transducer frequency and amplitude for current trial
    fprintf(FG_Tx, ['SOUR1:VOLT ',num2str(Parameters(iTrial,2)/1000)]);
    fprintf(FG_Tx, ['SOUR1:FREQ ',num2str(Parameters(iTrial,1)*1e3)]);
    fprintf(FG_Mod, 'TRIG1:SOUR BUS'); % ensure triggering comes from MATLAB and not immediate
    fprintf(FG_Mod, 'TRIG2:SOUR BUS'); % ensure triggering comes from MATLAB and not immediate
    
    
    switch Parameters(iTrial,3)
        case 0 % if it's pulsed, turn on amplitue modulation from CH2 of moduating function generator
            fprintf(FG_Mod, 'SOUR1:AM:STAT 1');     % turn AM modulation on
            fprintf(FG_Mod, 'SOUR1:AM:DSSC OFF');   % turn DSSC off
            
            fprintf(FG_Mod, 'SOUR1:AM:SOUR CH2');   % turn the source of AM modulation to channel 2
            
        case 1 % if it's continuous, turn amplitude moduation off
            fprintf(FG_Mod,'SOUR1:AM:STAT 0');
    end
    
    fprintf(FG_Tx,  'OUTP1 ON'); % turn transducer on
    fprintf(FG_Mod, 'OUTP1 ON'); % turn modulation on
    
    pause(DurBeforeStim/1000);
    fprintf(FG_Mod, '*TRG'); % Starts Ch2 and Ch1 at same time
    
    pause(PRFsweep.duration + 0.5); % pause for longer than the duration of the stimulation
    fprintf(FG_Mod, 'OUTP1 OFF'); % turn transducer off
    fprintf(FG_Tx,  'OUTP1 OFF'); % turn modulation off
    
    t(iTrial) = toc;
    
    pause(inter_trial-t(iTrial)); % pause so that time between the starts of the trials are 5 seconds apart
end
%% SUPPORT FUNCTION: BINARIZE
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