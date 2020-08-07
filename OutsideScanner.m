clear; 
try, instrreset;
catch
end

dCycle = 20;                % [%]

PRFSweep.low = 10;          % [Hz]
PRFSweep.high = 150;        % [Hz]
PRFSweep.duration = 1.5;    % [s]

amplitudes = [30 60 100 120 200 250]; % [mV]
frequencies = [135 279 885]; % [kHz]
PulsedContinuous = [0,1];

inter_trial = 5.0; % time between starts of successive trials [s]

nRepetitions = 5;

FG_Mod_ID = 'MY52600694';
FG_Tx_ID  = 'MY52600670';

DurBuf = 1; % [ms]

DurBeforeStim = 500; % [ms]
BitInfoSpeed = 30; % [Hz]
DurBit = 1000/BitInfoSpeed;

Parameters = allcomb(frequencies,amplitudes,PulsedContinuous);
Parameters = repmat(Parameters,nRepetitions,1);

bytesize = nextpow2(max(max(Parameters)));

Parameters = Parameters(randperm(length(Parameters)),:);

if ~exist('FG_Mod','var')
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

if ~exist('FG_Tx','var')
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

fprintf(FG_Tx,'*RST');
fprintf(FG_Tx, 'OUTP1 OFF');           % turn channel 2 off for data phase
fprintf(FG_Tx,['SOUR1:FREQ ' num2str(frequencies(1)*1000)]); % Transducer Frequency (kHz)
fprintf(FG_Tx,['SOUR1:VOLT ',num2str(amplitudes(1)/1000)]);
fprintf(FG_Tx, 'SOUR1:AM:STAT 1');     % turn AM modulation on
fprintf(FG_Tx, 'SOUR1:AM:DSSC 1');
fprintf(FG_Tx, 'SOUR1:AM:SOUR EXT');   % turn the source of AM modulation to channel 2
fprintf(FG_Tx, 'OUTP1 OFF');           % turn channel 2 off for data phase
fprintf(FG_Tx, 'OUTP1 ON');


fprintf(FG_Mod, '*RST');
fprintf(FG_Mod, 'SOUR2:FUNC SQU');
fprintf(FG_Mod, ['SOUR2:FREQ ',num2str(PRFSweep.low)]);
fprintf(FG_Mod, ['SOUR2:FUNC:SQU:DCYC ', num2str(dCycle)]);  % Duty Cycle (%)
fprintf(FG_Mod, ['SOUR2:VOLT 5']);
fprintf(FG_Mod, ['SOUR2:SWE:SPAC LIN']);
fprintf(FG_Mod, ['SOUR2:SWE:TIME ',    num2str(PRFSweep.duration)]);
fprintf(FG_Mod, ['SOUR2:FREQ:STAR ',   num2str(PRFSweep.low)]);
fprintf(FG_Mod, ['SOUR2:FREQ:STOP ',   num2str(PRFSweep.high)]);
fprintf(FG_Mod,  'SOUR2:SWE:HTIM 0.5');

fprintf(FG_Mod,'DATA:VOL:CLE');
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
    '"DCOFF",   1,once,         maintain,4,']; % third waveform

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
fprintf(FG_Mod, 'OUTP1 ON');
fprintf(FG_Mod, 'OUTP2 ON');
fprintf(FG_Mod, 'TRIG1:SOUR BUS');
fprintf(FG_Mod, 'TRIG2:SOUR BUS');
%%
% isFirst = 1;
estimatedTime = inter_trial*length(Parameters)/60; % [min]
disp(['Estimated Duration of Session: ',num2str(floor(estimatedTime)),' min, ',num2str((estimatedTime-floor(estimatedTime))*60),' seconds']);

pause(2.0);
t = zeros(length(Parameters),1);

for iTrial = 1:length(Parameters)
    tic;
    disp(['Trial ',num2str(iTrial),': CF = ',num2str(Parameters(iTrial,1)),' kHz, Amp = ',num2str(Parameters(iTrial,2)),' mV', 'Continuous?: ',num2str(Parameters(iTrial,3))]);
    
    
    fprintf(FG_Tx,'OUTP1 OFF');
    fprintf(FG_Tx,'OUTP2 OFF');
    
    
    DataByte = binarize(Parameters(iTrial,:),bytesize); % current trial's parameter information
    DataByte = [DataByte(1:bytesize*2),DataByte(end)]; % only get the last digit of the 3rd parameter (already binary)
    %buzzBitWrite(FG_Tx,2,DataByte,BitInfoSpeed);
    
    % re-initialize channel 1 to buffer bursting
    fprintf(FG_Tx, 'SOUR2:VOLT 5');            % 5V peak-to-peak
    fprintf(FG_Tx, 'SOUR2:VOLT:OFFS 2.5');     % 2.5V offset (0-5V)
    fprintf(FG_Tx, 'SOUR2:FUNC SQU');          % turn to sq. wave
    fprintf(FG_Tx, 'SOUR2:FUNC:SQU:DCYC 50');  % duty cycle of sq. wave is 50%
    fprintf(FG_Tx, 'SOUR2:FREQ 7000');         % 7000Hz oscillating frequency
    %fprintf(FG_Tx, 'OUTP2 ON');                % turn on
    
    fprintf(FG_Tx, 'TRIG2:SOUR BUS');
    fprintf(FG_Tx, 'SOUR2:BURS:STAT 0');       % turn burst on
    
    
    fprintf(FG_Tx,'OUTP2 ON');                 % turn on
    pause(DurBit/1000);                     % pause for buffer duration
    
    % write binary data
    %DataByte = DataVector(iTrial,:); % current trial's parameter information
    for Bit=DataByte
        if Bit
            fprintf(FG_Tx,'SOUR2:FUNC DC'); % DC of 1
            pause(DurBit/1000);
            fprintf(FG_Tx,'SOUR2:FUNC SQU'); % back to buzz
        else
            fprintf(FG_Tx, 'SOUR2:BURS:STAT 1'); % turn off
            pause(DurBit/1000);
            fprintf(FG_Tx, 'SOUR2:BURS:STAT 0'); % turn back on
        end
    end
    
    pause(DurBuf/1000); % Ch2 offset is now set to zero for trial phase
     
    fprintf(FG_Tx, 'OUTP2 OFF'); % Turn this off to prevent false 1s.
    
    %noOscillationARBgenerate(FG_Mod,DataByte,BitInfoSpeed,isFirst);
    % isFirst = 0;
    
    fprintf(FG_Mod,'SOUR1:FUNC ARB');
    
    fprintf(FG_Mod, ['SOUR1:FUNC:ARB PRFSweep']);
    fprintf(FG_Mod,['SOUR1:FUNC:ARB:SRATE ',num2str(srate)]);
    fprintf(FG_Mod, 'SOUR1:AM:STAT 1');     % turn AM modulation on
    fprintf(FG_Mod, 'SOUR1:AM:DSSC OFF'                 );  % turn DSSC off
    fprintf(FG_Mod, 'SOUR1:AM:SOUR CH2');   % turn the source of AM modulation to channel 2
    
    
    fprintf(FG_Mod,'SOUR1:AM:STAT 1');
    %
    %     pause(DurBuf/1000);
    %     t1 = toc;
    
    fprintf(FG_Tx, ['SOUR1:VOLT ',num2str(Parameters(iTrial,2)/1000)]);
    fprintf(FG_Tx, ['SOUR1:FREQ ',num2str(Parameters(iTrial,1)*1e3)]);
    fprintf(FG_Mod, 'TRIG1:SOUR BUS');
    fprintf(FG_Mod, 'TRIG2:SOUR BUS');
    
    
    switch Parameters(iTrial,3)
        case 0
            fprintf(FG_Mod, 'SOUR1:AM:STAT 1');  % turn AM modulation on
            fprintf(FG_Mod, 'SOUR1:AM:DSSC OFF'                 );  % turn DSSC off
            
            fprintf(FG_Mod, 'SOUR1:AM:SOUR CH2');   % turn the source of AM modulation to channel 2
            
        case 1
            fprintf(FG_Mod,'SOUR1:AM:STAT 0');
    end
    
    fprintf(FG_Tx,'OUTP1 ON');
    fprintf(FG_Mod, 'OUTP1 ON');
    
    pause(DurBeforeStim/1000);
    
    fprintf(FG_Mod, '*TRG'); % Starts Ch2 and Ch1 at same time
    
    pause(2.0);
    fprintf(FG_Mod, 'OUTP1 OFF');
    fprintf(FG_Tx,'OUTP1 OFF');
    
    t(iTrial) = toc;
    
    pause(inter_trial-t(iTrial));
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