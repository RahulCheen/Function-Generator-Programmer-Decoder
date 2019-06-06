clearvars -except FG

inter_trial     = 5000;     % time between stimulations [ms]
bytesize        = 10;       % number of bits to write for each parameter(keep at 16 for parameter values of <= 65000)

TF              =  5;
Amplitudes      = [25   100     400];
DutyCycles      = [5    50      100];
ModFreqs        = [10   100     1000];
PulseDurations  = [50   200     1000];

FG_ID           = 'MY52600694'; % serial number of new fxn generator


% For handling data cycles
DurBit = 5;     % bit duration approx 2 ms longer   [ms] 
DurBuf = 1;     % square wave buffer duration       [ms]

% For pauses and timing post-processing
DurBeforeStim = 500; % pause between data phase and trial phase [ms]

Parameters           = allcomb(TF,Amplitudes,DutyCycles,ModFreqs,PulseDurations); % all possible trial combinations
[Parameters,NCycles] = RemoveParameterErrors(Parameters); % remove bad parameter combinations
bytesize = max([nextpow2(max(max(Parameters))),bytesize]); % take maximum of needed bytesize and user-input bytesize

nTrials      = size(Parameters,1);
nParams      = size(Parameters,2);

TrialIndices = randperm(nTrials); % Creates list

Parameters = Parameters(TrialIndices,:);

for ii=1:nTrials
    DataVector(ii,:) = binarize(Parameters(ii,:),bytesize);
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


disp('Parameters (in randomized order):');
disp(num2str(Parameters));

fprintf(FG, '*RST'); % Resets to factory default. Very quick. Sets OUTP OFF
ARBgenerate;

fprintf(FG, 'OUTP1:LOAD INF'); % Ch2 needs time to warm up.
fprintf(FG, 'SOUR1:VOLT 5');
fprintf(FG, 'SOUR1:VOLT:OFFS 2.5');
fprintf(FG, 'SOUR1:FREQ 7000');
fprintf(FG, 'SOUR1:FUNC SQU');
fprintf(FG, 'TRIG1:SOUR BUS');
fprintf(FG, 'SOUR1:BURS:STAT 1');
fprintf(FG, 'OUTP1 ON');
fprintf(FG, 'OUTP2 OFF');

%3 Any one-time/last-minute initializing.
fprintf(FG,['SOUR2:FREQ ' num2str(TF*1000)]); % Transducer Frequency (kHz)
fprintf(FG, 'SOUR2:AM:STAT 1');
fprintf(FG, 'SOUR2:AM:SOUR CH2');

pause(2); % This value is arbitrary, but should be sufficiently high (>2 seconds)

for iTrial = 1:nTrials
    tic
    fprintf(FG,'SOUR1:FUNC SQU');
    fprintf(FG,'SOUR1:FUNC:SQU:DCYC 50');
    fprintf(FG,'SOUR1:FREQ 7000');
    fprintf(FG,'OUTP1 ON');
    
    fprintf(FG,'SOUR1:BURS:STAT 0');
    
    pause(DurBuf/1000);
    
    DataByte = DataVector(iTrial,:);
    for Bit=DataByte
        if Bit
            fprintf(FG,'SOUR1:FUNC DC');
            pause(DurBit/1000);
            fprintf(FG,'SOUR1:FUNC SQU');
        else
            fprintf(FG, 'SOUR1:BURS:STAT 1');
            pause(DurBit/1000);
            fprintf(FG, 'SOUR1:BURS:STAT 0');
        end
    end
    pause(DurBuf/1000); % Ch2 offset is now set to zero for trial phase
        
    fprintf(FG, 'OUTP1 OFF'); % Turn this off to prevent false 1s.
    fprintf(FG, ['SOUR2:VOLT ' num2str(Parameters(TrialIndices(iTrial),2)/1000)]);
    
    DC = Parameters(iTrial,3);
    pD = Parameters(iTrial,5);
    MF = Parameters(iTrial,4);
    
    switch DC
        case 100
            fprintf(FG, 'SOUR1:BURSt:STAT OFF');
            fprintf(FG,'SOUR2:AM:DSSC ON');
            fprintf(FG,'SOUR1:FUNC ARB'); % Change channel 1's waveform to ARB
            fprintf(FG,['SOUR1:FUNC:ARB SEQDC',num2str(pD)]);
            
            
        otherwise
            fprintf(FG, 'SOUR1:FUNC SQU');
            fprintf(FG,'SOUR2:AM:DSSC OFF');
            fprintf(FG,['SOUR1:FREQ '          num2str(MF)]); % Modulating Frequency (Hz)
            fprintf(FG,['SOUR1:FUNC:SQU:DCYC ' num2str(DC)]); % Duty Cycle (%)
            NCycles = floor(MF*pD/1000);
            fprintf(FG,['SOUR1:BURSt:NCYC '    num2str(NCycles)]); % Number of cycles
            
            fprintf(FG, 'SOUR1:BURSt:STAT ON');
            
    end
    
    fprintf(FG, 'OUTP1 ON ');
    fprintf(FG, 'OUTP2 ON ');
    pause(DurBeforeStim/1000); % Do we need a pause for these to boot up?
    
    fprintf(FG, '*TRG'); % Starts Ch2 and Ch1 at same time
    pause(pD*2/1000);
    fprintf(FG,'OUTP1 OFF');
    fprintf(FG,'OUTP2 OFF');
    
    pause(inter_trial/1000 - toc);
end






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