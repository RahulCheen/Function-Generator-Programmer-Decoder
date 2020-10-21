clear;

try, instrreset;
catch
end

%%
frequency               = 258;                  % [kHz]
amplitudes              = [0.125 0.25 0.5 1 2];   % [MPa]
conversionVtoMPa        = 4;                    % 4MPa at 1 V
nRepetitions            = 10;

stimuli(1).dutycycle    = 20;           % [%]
stimuli(1).prf          = [10 150];     % [Hz]
stimuli(1).duration     = 1.5;          % [s]

stimuli(2).dutycycle    = 50;           % [%]
stimuli(2).prf          = [500];        % [Hz]
stimuli(2).duration     = 0.3;          % [s]

stimuli(3).dutycycle    = 100;          % [%]
stimuli(3).prf          = [0];          % [Hz]
stimuli(3).duration     = 0.3;          % [s]

inter_trial             = 10;           % [s]
durationBeforeStim      = 0.5;          % [s]
durationBuffer          = 0.001;        % [s]
frequencyBitSpeed       = 15;           % [Hz]

amplitudesmV            = amplitudes/conversionVtoMPa*1000;    % [mV]
amplitudesmV            = round(amplitudesmV);                 % round to get whole numbers

Parameters = allcomb(amplitudesmV,1:length(stimuli));
Parameters = repmat(Parameters,nRepetitions,1);
Parameters = Parameters(randperm(length(Parameters)),:);

bytesize = 10;
bytesize = min([nextpow2(max(max(Parameters))),bytesize]); % take maximum of needed bytesize and user-input bytesize

%DataVector = zeros(length(Parameters),bytesize*size(Parameters,2));
for ii = 1:length(Parameters)
    DataVector(ii,:) = binarize(Parameters(ii,:),[bytesize,2]);
end

estimatedTime = inter_trial*length(Parameters)/60; % [min]
disp(['  Trial Duration:        ',num2str(inter_trial,'%d'),' seconds']);
disp(['Session Duration: ',num2str(floor(estimatedTime)),' min, ',num2str((estimatedTime-floor(estimatedTime))*60),' seconds']);

%%
FG_Mod_ID = 'MY52600694';
FG_Tx_ID  = 'MY52600670';

FG_Mod = visa('keysight',['USB0::0x0957::0x2A07::',FG_Mod_ID,'::0::INSTR']);
FG_Mod.OutputBufferSize = 2^32;
fopen(FG_Mod);
fprintf(FG_Mod,'*RST');

FG_Tx = visa('keysight',['USB0::0x0957::0x2A07::',FG_Tx_ID,'::0::INSTR']);
fopen(FG_Tx);
fprintf(FG_Tx ,'*RST');

%%
fprintf(FG_Tx,['SOUR1:FREQ ',num2str(frequency*1e3)]); % set frequency
fprintf(FG_Tx,['SOUR1:VOLT ',num2str(amplitudesmV(1)*1e-3)]);

fprintf(FG_Tx,['SOUR1:AM:STAT 1']);
fprintf(FG_Tx, 'SOUR1:AM:DSSC 1');
fprintf(FG_Tx, 'SOUR1:AM:SOUR EXT');   % turn the source of AM modulation to channel 2

fprintf(FG_Tx,'SOUR2:VOLT 5');
fprintf(FG_Tx, 'SOUR2:VOLT:OFFS 2.5');     % 2.5V offset (0-5V)
fprintf(FG_Tx, 'SOUR2:FUNC SQU');          % turn to sq. wave
fprintf(FG_Tx, 'SOUR2:FUNC:SQU:DCYC 50');  % duty cycle of sq. wave is 50%
fprintf(FG_Tx, 'SOUR2:FREQ 7000');         % 7000Hz oscillating frequency

fprintf(FG_Tx, 'TRIG2:SOUR BUS');
fprintf(FG_Tx, 'SOUR2:BURS:STAT 0');       % turn burst off so that fast oscillation turns on


%%
fprintf(FG_Mod,'DATA:VOL:CLE'); % clear volatile memory for arbitrary waveform
srate = 1000;

fprintf(FG_Mod,'SOUR1:FUNC ARB'); % Change channel 1's waveform to ARB
fprintf(FG_Mod,'SOUR1:FUNC:ARB:FILTER STEP');

fprintf(FG_Mod, ['DATA:ARB:DAC DC0',sprintf(',%d',round(zeros(8,1)*(2^15-1)))]); % smallest possible arbitraty waveform, to set triggering
fprintf(FG_Mod, ['DATA:ARB:DAC DCOFF',sprintf(',%d',round(zeros(0.5*srate,1)*(2^15-1)))]); % force off for 0.5s

for ii=1:length(stimuli)
    
    fprintf(FG_Mod,'SOUR1:FUNC ARB'); % Change channel 1's waveform to ARB
    fprintf(FG_Mod,'SOUR1:FUNC:ARB:FILTER STEP');
    
    arb = DCWithRiseAndFall(stimuli(ii).duration*srate,12,stimuli(ii).duration*1e3,'cosine');
    arbDAC = round(arb*(2^15 - 1));  % change to DAC values, signed, 16-bit
    arbname = ['arb',num2str(stimuli(ii).duration*1e3)];
    fprintf(FG_Mod,['DATA:ARB:DAC ',arbname,sprintf(',%d',arbDAC)]);
    
    SEQ_command = ['"','STIM',num2str(ii)','",',...
        '"DC0",',                                       '1,','repeatTilTrig,',  'maintain,','4,',... % first waveform
        '"arb',num2str(stimuli(ii).duration*1e3),'",',  '1,','once,',           'maintain,','4,',... % second waveform
        '"DCOFF",',                                     '1,','once,',           'maintain,','4,'];   % third waveform
    
    npoints = length(SEQ_command)-1; % number of points in the character vector
    ndigits = floor(log10(length(SEQ_command)))+1; % number of digits in the character vector
    
    fprintf(FG_Mod, ['DATA:SEQ #',... % print it to the function generator
        num2str(ndigits),...
        num2str(npoints),...
        SEQ_command]);
    fprintf(FG_Mod, ['SOUR1:FUNC:ARB STIM',num2str(ii)]);
    %fprintf(FG_Mod,['MMEM:STORE:DATA "INT:\PRFSweep.seq"']);
    fprintf(FG_Mod,['SOUR1:FUNC:ARB:SRATE ',num2str(srate)]);
    fprintf(FG_Mod,'SOUR1:VOLT 1');
    pause(1);
end
%%
fprintf(FG_Mod, 'SOUR1:AM:STAT 1');
fprintf(FG_Mod, 'SOUR1:AM:SOUR CH2');
fprintf(FG_Mod, 'SOUR1:AM:DSSC OFF');  % turn DSSC off

fprintf(FG_Mod, 'SOUR2:VOLT 5');                        % voltage at 5 V (does not work at 3 V)
fprintf(FG_Mod, 'SOUR2:VOLT:OFFS 2.5');                 % offset to 2.5 V
fprintf(FG_Mod, 'SOUR2:FUNC SQU'                    );  % change to square wave


fprintf(FG_Mod,'TRIG1:SOUR BUS');
fprintf(FG_Mod,'TRIG2:SOUR BUS');

fprintf(FG_Mod, 'SOUR1:VOLT 2');

pause(1);
%%

for ii=1:length(Parameters)
    tic;
    s1 = stimuli(Parameters(ii,2));
    fprintf(FG_Tx,['SOUR1:VOLT ',num2str(Parameters(ii,1)*1e-3)]);
    switch Parameters(ii,2)
        case 1
            disp(['Trial ',num2str(ii),...
                ' CF = ',num2str(frequency),' kHz',...
                ' Amp = ',num2str(Parameters(ii,1)*1e-3*4,'%4.3f'),' MPa',...
                ' duration = ',num2str(stimuli(Parameters(ii,2)).duration*1000),' ms',...
                ' // Stimulus: Swept from 10 to 150 Hz, 20% duty cycle']);
            
            fprintf(FG_Mod, 'SOUR1:FUNC ARB');
            fprintf(FG_Mod,['SOUR1:FUNC:ARB STIM',num2str(Parameters(ii,2))]);
            
            fprintf(FG_Mod, 'SOUR1:AM:STAT 1');
            fprintf(FG_Mod, 'SOUR2:BURSt:STAT 0');
            fprintf(FG_Mod, ['SOUR2:FREQ ',num2str(s1.prf(1))]); % low frequency of sweep
            fprintf(FG_Mod, ['SOUR2:FUNC:SQU:DCYC ', num2str(s1.dutycycle)]);  % Duty Cycle (%)
            fprintf(FG_Mod, ['SOUR2:VOLT 5']); % 5 V
            fprintf(FG_Mod, ['SOUR2:SWE:SPAC LIN']); % sweep parameter - spacing
            fprintf(FG_Mod, ['SOUR2:SWE:TIME ',    num2str(s1.duration)]); % sweep parameter - duration
            fprintf(FG_Mod, ['SOUR2:FREQ:STAR ',   num2str(s1.prf(1))]); % sweep parameter - low frequency
            fprintf(FG_Mod, ['SOUR2:FREQ:STOP ',   num2str(s1.prf(2))]); % sweep parameter - high frequency
            fprintf(FG_Mod,  'SOUR2:SWE:HTIM 0.5'); % sweep parameter - hold time (corrects for differing times for sweep and arb)
            fprintf(FG_Mod,  'SOUR2:SWE:STAT 1');
        case 2
            disp(['Trial ',num2str(ii),...
                ' CF = ',num2str(frequency),' kHz',...
                ' Amp = ',num2str(Parameters(ii,1)*1e-3*4,'%4.3f'),' MPa',...
                ' duration = ',num2str(stimuli(Parameters(ii,2)).duration*1000,'%4.0f'),' ms',...
                ' // Stimulus: PRF = 500 Hz, 50% duty cycle']);
            
            fprintf(FG_Mod, 'SOUR1:FUNC ARB');
            fprintf(FG_Mod,['SOUR1:FUNC:ARB STIM',num2str(Parameters(ii,2))]);
            fprintf(FG_Mod, 'SOUR1:AM:STAT 1');

            fprintf(FG_Mod,['SOUR2:FREQ ',          num2str(s1.prf)]);  % Modulating Frequency (Hz)
            fprintf(FG_Mod,['SOUR2:FUNC:SQU:DCYC ', num2str(s1.dutycycle)]);  % Duty Cycle (%)
            
            NCycles = floor(s1.prf*s1.duration*1.25);                        % Number of cycles
            fprintf(FG_Mod,['SOUR2:BURS:NCYC '      num2str(NCycles)]);
            fprintf(FG_Mod, 'SOUR2:BURS:STAT ON');                  % turn burst mode on
            
        case 3
            disp(['Trial ',num2str(ii),...
                ' CF = ',num2str(frequency),' kHz',...
                ' Amp = ',num2str(Parameters(ii,1)*1e-3*4,'%4.3f'),' MPa',...
                ' duration = ',num2str(stimuli(Parameters(ii,2)).duration*1000,'%4.0f'),' ms',...
                ' // Stimulus: continuous']);
            
            fprintf(FG_Mod, 'SOUR1:FUNC ARB');
            fprintf(FG_Mod,['SOUR1:FUNC:ARB STIM',num2str(Parameters(ii,2))]);
            fprintf(FG_Mod, 'SOUR1:AM:STAT 0');

        otherwise
            continue
    end
    
    fprintf(FG_Tx, 'SOUR2:BURS:STAT 0');       % turn burst on
    
    pause(durationBuffer);                % pause for buffer duration
    fprintf(FG_Tx,'OUTP2 ON');                 % turn on
    
    % write binary data
    DataByte = DataVector(ii,:); % current trial's parameter information
    for Bit=DataByte
        if Bit
            fprintf(FG_Tx,'SOUR2:FUNC DC'); % DC of 1
            pause(1/frequencyBitSpeed);
            fprintf(FG_Tx,'SOUR2:FUNC SQU'); % back to buzz
        else
            fprintf(FG_Tx, 'SOUR2:BURS:STAT 1'); % turn off
            pause(1/frequencyBitSpeed);
            fprintf(FG_Tx, 'SOUR2:BURS:STAT 0'); % turn back on
        end
    end
    
    pause(durationBuffer); % Ch2 offset is now set to zero for trial phase
    
    fprintf(FG_Tx,'OUTP2 OFF');
    fprintf(FG_Mod, 'SOUR1:VOLT 2.9');

    fprintf(FG_Tx, 'OUTP1 ON');
    fprintf(FG_Mod,'OUTP1 ON');
    
    pause(durationBeforeStim);
    fprintf(FG_Mod, '*TRG');
    
    pause(s1.duration + 0.5); % pause for longer than the duration of the stimulation
    fprintf(FG_Mod, 'OUTP1 OFF'); % turn transducer off
    fprintf(FG_Tx,  'OUTP1 OFF'); % turn modulation off
    
    t(ii) = toc;
    
    pause(inter_trial-t(ii)); % pause so that time between the starts of the trials are 5 seconds apart

end
%% SUPPORT FUNCTION: BINARIZE
function outputRow = binarize(inputRow,nBits)
% BINARIZE converts base-10 to binary
outputRow = [];
for ii=1:length(inputRow)
    outputBit = zeros(1,nBits(ii));
    workingNumber = inputRow(ii); % Algorithm for converting int to binary
    for bit = nBits(ii):-1:1
        outputBit(bit) = mod(workingNumber,2);
        workingNumber = (workingNumber-outputBit(bit))/2;
    end
    outputRow = [outputRow,outputBit];
end
end