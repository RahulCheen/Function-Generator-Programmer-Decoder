clearvars -except FG

pulseDuration = 250; %[ms]
arbWave = DCWithRiseAndFall(1000,30);
arbWaveDAC = round(arbWave*32767);
ARBname = 'DC_with_rise';
SEQname = 'PulseOnTrig';
try fclose(FG);
    FG.OutputBufferSize = 32768;
    fopen(FG);
catch
end

if ~exist('FG','var')
    FG = visa('keysight','USB0::0x0957::0x2A07::MY52600694::0::INSTR')
    FG.OutputBufferSize = 32768;
    % This address depends on the serial number of the machine.
    fopen(FG) % There's some output here, so you know it worked.
end

% header + parameters
fprintf(FG,'DATA:VOL:CLE');
fprintf(FG,'SOUR1:FUNC ARB'); % Change channel 1's waveform to ARB
fprintf(FG,['SOUR1:FUNC:ARB:SRATE ',num2str(length(arbWave)*1000/pulseDuration)]);
fprintf(FG,'SOUR1:FUNC:ARB:FILTER STEP');
fprintf(FG,'SOUR1:FUNC:ARB:PTPEAK 2');

% generate ARB in function generator
datastr = sprintf(',%4.3f',arbWave);
fprintf(FG,['DATA:ARB:DAC ',ARBname,sprintf(',%d',arbWaveDAC)]);
fprintf(FG,['FUNC:ARB ',ARBname]);

% create SEQ in function generator
fprintf(FG,'DATA:ARB DC0,0,0,0,0,0,0,0,0,0,0,0');

command0 = ['"',SEQname,'","DC0",1,repeatTilTrig,maintain,4,"',ARBname,'",1,once,maintain,4,"DC0",1,once,maintain,4'];
npoints = length(command0)-1;
ndigits = floor(log10(length(command0)))+1;
fprintf(FG,['DATA:SEQ #',num2str(ndigits),num2str(npoints),command0]);
fprintf(FG,['FUNC:ARB ',SEQname]);

