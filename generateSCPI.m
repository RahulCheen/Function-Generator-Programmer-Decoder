clearvars -except FG

% parameters
ARB_npoints = 1000;     % [# of points]
ARB_risetime = 30;      % [% of total waveform]
pulseDuration = 250;    % [ms]

% generate waveform
arbWave = DCWithRiseAndFall(ARB_npoints,ARB_risetime);  % generates waveform
arbWaveDAC = round(arbWave*(2^15 - 1));                 % change to DAC values, signed, 16-bit

ARBname = 'DC_with_rise';
SEQname = 'PulseOnTrig';

% need to increase buffer size to send in larger ARB data points

try fclose(FG); % variable exists, in open state
    FG.OutputBufferSize = 32768;
    fopen(FG);
catch
    if ~exist('FG','var') % variable doesnt exist
        FG = visa('keysight','USB0::0x0957::0x2A07::MY52600694::0::INSTR')
        FG.OutputBufferSize = 32768;
        % This address depends on the serial number of the machine.
        fopen(FG) % There's some output here, so you know it worked.
    
    else % already closed
        FG.OutputBufferSize = 32768;
        fopen(FG);
    end
end

% if ~exist('FG','var')
%     FG = visa('keysight','USB0::0x0957::0x2A07::MY52600694::0::INSTR')
%     FG.OutputBufferSize = 32768;
%     % This address depends on the serial number of the machine.
%     fopen(FG) % There's some output here, so you know it worked.
% end

% header + parameters
fprintf(FG,'OUTP1 OFF');
fprintf(FG,'OUTP2 OFF');

fprintf(FG,'DATA:VOL:CLE');
fprintf(FG,'SOUR1:FUNC ARB'); % Change channel 1's waveform to ARB
fprintf(FG,['SOUR1:FUNC:ARB:SRATE ',num2str(length(arbWave)*1000/pulseDuration)]);
fprintf(FG,'SOUR1:FUNC:ARB:FILTER STEP');
fprintf(FG,'SOUR1:FUNC:ARB:PTPEAK 2');
fprintf(FG,'SOUR2:AM:SOUR CH1');
fprintf(FG,'SOUR2:AM:DEPT 100');
fprintf(FG,'SOUR2:AM:DSSC ON');
fprintf(FG,'SOUR2:AM:STAT ON');

% generate ARB in function generator
datastr = sprintf(',%4.3f',arbWave);
fprintf(FG,['DATA:ARB:DAC ',ARBname,sprintf(',%d',arbWaveDAC)]);
%fprintf(FG,['FUNC:ARB ',ARBname]);

% create SEQ in function generator
fprintf(FG,'DATA:ARB DC0,0,0,0,0,0,0,0,0,0,0,0'); % zero volts to start

    % sequence goes:
    %   1) 0 volts,             repeat until trigger
    %   2) arbitrary waveform,  once
    %   3) 0 volts,             once
SEQ_command = ['"',SEQname,'",',...
    '"DC0",         1,repeatTilTrig,maintain,4,',... % 0 volts, repeat until trigger
    '"',ARBname,'", 1,once,         maintain,4,'];   % arb waveform, repeat once
npoints = length(SEQ_command)-1;
ndigits = floor(log10(length(SEQ_command)))+1;

    % send to function generator
fprintf(FG,['DATA:SEQ #',...
    num2str(ndigits),... % number of digits in block
    num2str(npoints),... % number of points in block
    SEQ_command]);       % actual sequence order

fprintf(FG,['FUNC:ARB ',SEQname]); % change to sequence

fprintf(FG,'OUTP1 ON');
fprintf(FG,'OUTP2 ON');
