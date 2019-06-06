% variableSpeedArb
clearvars -except FG
n = 1000;
y = (1+flip(cos(pi*linspace(0,1,n)')))/2;   % rise cosine
y_l = flip(y);                              % fall cosine

arbWaveRise = y.*(2^15-1);
arbWaveFall = y_l.*(2^15-1);
arbWaveOn   = ones(10,1).*(2^15-1);

riseDur = 12; %[ms]
fprintf(FG, '*RST'); % Resets to factory default. Very quick. Sets OUTP OFF
fprintf(FG,'SOUR1:FUNC ARB');


fprintf(FG,['DATA:ARB:DAC ','arbWaveRise',sprintf(',%d',arbWaveRise)]);
samplingrate = length(arbWaveRise)*1000/riseDur;
fprintf(FG,['SOUR1:FUNC:ARB:SRATE ',num2str(samplingrate)]);
fprintf(FG,'SOUR1:FUNC:ARB arbWaveRise');
fprintf(FG,'MMEM:STORE:DATA "INT:\arbWaveRise"');

fprintf(FG,['DATA:ARB:DAC ','arbWaveFall',sprintf(',%d',arbWaveFall)]);
samplingrate = length(arbWaveFall)*1000/riseDur;
fprintf(FG,['SOUR1:FUNC:ARB:SRATE ',num2str(samplingrate)]);
fprintf(FG,'SOUR1:FUNC:ARB arbWaveFall');
fprintf(FG,'MMEM:STORE:DATA "INT:\arbWaveFall"');

fprintf(FG,['DATA:ARB:DAC ','arbWaveOn',  sprintf(',%d',arbWaveOn  )]);
samplingrate = length(arbWaveOn)*1000/(1000-2*riseDur);
fprintf(FG,['SOUR1:FUNC:ARB:SRATE ',num2str(samplingrate)]);
fprintf(FG,'SOUR1:FUNC:ARB arbWaveOn');
fprintf(FG,'MMEM:STORE:DATA "INT:\arbWaveOn"');


fprintf(FG,'DATA:ARB DC0,0,0,0,0,0,0,0,0,0,0,0'); % zero volts to start

SEQ_command = ['"VariableSEQ",',...
    '"DC0",              1,repeatTilTrig,maintain,4,',... % 0 volts, repeat until trigger
    '"INT:\arbWaveRise",      1,once,maintain,4,',...
    '"INT:\arbWaveOn",        1,once,maintain,4,',...
    '"INT:\arbWaveFall",      1,once,maintain,4,',...
    ];   % arb waveform, repeat once
npoints = length(SEQ_command)-1;
ndigits = floor(log10(length(SEQ_command)))+1;

% send to function generator
fprintf(FG,['DATA:SEQ #',...
    num2str(ndigits),... % number of digits in block
    num2str(npoints),... % number of points in block
    SEQ_command]);       % actual sequence order

fprintf(FG,'SOUR1:FUNC:ARB VariableSEQ');