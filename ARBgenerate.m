function ARBgenerate(FG,PulseDurations,RiseDur)
try fclose(FG); % variable exists, in open state
    FG.OutputBufferSize = 2^32;
    fopen(FG);
catch
    if ~exist('FG','var') % variable doesnt exist
        FG = visa('keysight','USB0::0x0957::0x2A07::MY52600694::0::INSTR')
        FG.OutputBufferSize = 2^32;
        % This address depends on the serial number of the machine.
        fopen(FG) % There's some output here, so you know it worked.
    
    else % already closed
        FG.OutputBufferSize = 2^32;
        fopen(FG);
    end
end

for ii=1:length(PulseDurations)
    arbs{ii} = DCWithRiseAndFall(PulseDurations(ii)*25,RiseDur,PulseDurations(ii),'cosine');
    arbDACs{ii} = round(arbs{ii}*(2^15 - 1));                 % change to DAC values, signed, 16-bit
    arbNames{ii} = ['arbDC',num2str(PulseDurations(ii))];
    seqNames{ii} = ['seqDC',num2str(PulseDurations(ii))];
end

fprintf(FG, '*RST'); % Resets to factory default. Very quick. Sets OUTP OFF

fprintf(FG,'OUTP1 OFF');
fprintf(FG,'OUTP2 OFF');

fprintf(FG,'DATA:VOL:CLE');
fprintf(FG,'SOUR1:FUNC ARB'); % Change channel 1's waveform to ARB
fprintf(FG,'SOUR1:FUNC:ARB:FILTER STEP');

DC0Name         = 'DC0';
DC0             =  zeros(8,1);

fprintf(FG,['DATA:ARB:DAC ',DC0Name,sprintf( ',%d',round( DC0* (2^15-1) ) )] );


samplingrate = length(DC0) / (1/30);


for ii=1:length(PulseDurations)
    
    fprintf(FG,['DATA:ARB:DAC ',arbNames{ii},sprintf(',%d',arbDACs{ii})]);
    samplingrate = length(arbs{ii})*1000/PulseDurations(ii);
    fprintf(FG,['SOUR1:FUNC:ARB:SRATE ',num2str(samplingrate)]);
    
    SEQ_command = ['"',seqNames{ii},'",',...
        '"DC0",              1,repeatTilTrig,maintain,4,',... % 0 volts, repeat until trigger
        '"',arbNames{ii},'", 1,once,         maintain,4,'];   % arb waveform, repeat once
    npoints = length(SEQ_command)-1;
    ndigits = floor(log10(length(SEQ_command)))+1;
    
    % send to function generator
    fprintf(FG,['DATA:SEQ #',...
        num2str(ndigits),... % number of digits in block
        num2str(npoints),... % number of points in block
        SEQ_command]);       % actual sequence order
    fprintf(FG,['FUNC:ARB ',seqNames{ii}]);
    fprintf(FG,['MMEM:STORE:DATA "INT:\',seqNames{ii},'.seq"']);
end
