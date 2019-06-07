function FGencoder(FG,inputs)
clearvars -except FG inputs

Parameters = allcomb(...
    inputs.TF,...
    inputs.Amplitudes,...
    inputs.DutyCycles,...
    inputs.ModFreqs,...
    inputs.PulseDurations); % all possible trial combinations
[Parameters,NCycles] = RemoveParameterErrors(Parameters); % remove bad parameter combinations
inputs.bytesize = max([nextpow2(max(max(Parameters))),inputs.bytesize]); % take maximum of needed bytesize and user-input bytesize

nTrials      = size(Parameters,1);
nParams      = size(Parameters,2);

TrialIndices = randperm(nTrials); % Creates list

Parameters = Parameters(TrialIndices,:);

for ii=1:nTrials
    DataVector(ii,:) = binarize(Parameters(ii,:),inputs.bytesize);
end


disp('Parameters (in randomized order):');
disp(num2str(Parameters));

fprintf(FG, '*RST'); % Resets to factory default. Very quick. Sets OUTP OFF
ARBgenerate(FG,inputs.PulseDurations,12);

fprintf(FG, 'OUTP1:LOAD INF'); % Ch2 needs time to warm up.
%fprintf(FG, 'SOUR1:APPL:SQU 7000,5 VPP,0');
fprintf(FG, 'SOUR1:VOLT 5');
fprintf(FG, 'SOUR1:VOLT:OFFS 2.5');
fprintf(FG, 'SOUR1:FREQ 7000');
fprintf(FG, 'SOUR1:FUNC SQU');
fprintf(FG, 'TRIG1:SOUR BUS');
fprintf(FG, 'SOUR1:BURS:STAT 1');
fprintf(FG, 'OUTP1 ON');

%3 Any one-time/last-minute initializing.
fprintf(FG,['SOUR2:FREQ ' num2str(inputs.TF*1000)]); % Transducer Frequency (kHz)
fprintf(FG, 'SOUR2:AM:STAT 1');
fprintf(FG, 'SOUR2:AM:SOUR CH2');
fprintf(FG, 'OUTP2 OFF'); % turn channel 2 off for data phase

pause(2); % This value is arbitrary, but should be sufficiently high (>2 seconds)
for iTrial = 1:nTrials
    tic
    fprintf(FG, 'SOUR1:VOLT 5');
    fprintf(FG, 'SOUR1:VOLT:OFFS 2.5');
    fprintf(FG,'SOUR1:FUNC SQU');
    fprintf(FG,'SOUR1:FUNC:SQU:DCYC 50');
    fprintf(FG,'SOUR1:FREQ 7000');
    fprintf(FG,'OUTP1 ON');
    
    fprintf(FG,'SOUR1:BURS:STAT 0');
    
    pause(inputs.Buffers.Buf/1000);
    fprintf(FG,'OUTP1 ON');
    
    DataByte = DataVector(iTrial,:);
    
    %chck1 = arbDataPhase(FG,DataByte,chck1);
    for Bit=DataByte
        if Bit
            fprintf(FG,'SOUR1:FUNC DC'); % DC of 1
            pause(inputs.Buffers.Bit/1000);
            fprintf(FG,'SOUR1:FUNC SQU'); % back to buzz
        else
            fprintf(FG, 'SOUR1:BURS:STAT 1'); % turn off
            pause(inputs.Buffers.Bit/1000);
            fprintf(FG, 'SOUR1:BURS:STAT 0'); % turn back on
        end
    end
    % pause(inputs.Buffers.BeforeTrial/1000); % Do we need a pause for these to boot up?
    %
    pause(inputs.Buffers.Buf/1000); % Ch2 offset is now set to zero for trial phase
    
    fprintf(FG, 'OUTP1 OFF'); % Turn this off to prevent false 1s.
    fprintf(FG, ['SOUR2:VOLT ' num2str(Parameters(TrialIndices(iTrial),2)/1000)]);
    
    DC = Parameters(iTrial,3);
    pD = Parameters(iTrial,5);
    MF = Parameters(iTrial,4);
    
    switch DC
        case 100
            fprintf(FG, 'SOUR1:BURSt:STAT OFF'               ); % turn burst mode off
            fprintf(FG, 'SOUR2:AM:DSSC ON'                ); % turn DSSC on
            fprintf(FG, 'SOUR1:FUNC  ARB'                    ); % change to arbitrary waveform
            fprintf(FG,['SOUR1:FUNC:ARB SEQDC',num2str(pD)]); % change to pulse duration sequence
            fprintf(FG, 'SOUR1:VOLT 5');
            fprintf(FG, 'SOUR1:VOLT:OFFS 0');
        otherwise
            fprintf(FG, 'SOUR1:VOLT 5');
            fprintf(FG, 'SOUR1:VOLT:OFFS 2.5');
            fprintf(FG, 'SOUR1:FUNC SQU'                    );  % change to square wave
            fprintf(FG, 'SOUR2:AM:DSSC OFF'                 );  % turn DSSC off
            fprintf(FG,['SOUR1:FREQ ',          num2str(MF)]);  % Modulating Frequency (Hz)
            fprintf(FG,['SOUR1:FUNC:SQU:DCYC ', num2str(DC)]);  % Duty Cycle (%)
            
            NCycles = floor(MF*pD/1000);                        % Number of cycles
            fprintf(FG,['SOUR1:BURS:NCYC '      num2str(NCycles)]);
            fprintf(FG, 'SOUR1:BURS:STAT ON');                  % turn burst mode on
            
    end
    
    fprintf(FG, 'OUTP1 ON ');
    fprintf(FG, 'OUTP2 ON ');
    pause(inputs.Buffers.BeforeTrial/1000); % Do we need a pause for these to boot up?
    
    fprintf(FG, '*TRG'); % Starts Ch2 and Ch1 at same time
    pause(pD*2/1000);
    fprintf(FG,'OUTP1 OFF');
    fprintf(FG,'OUTP2 OFF');
    
    pause(inputs.Buffers.InterTrial/1000 - toc);
end




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