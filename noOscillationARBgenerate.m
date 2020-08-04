function noOscillationARBgenerate(FG,bytedata,BitInfoSpeed,isFirst)

try fclose(FG)
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

sequenceName    = 'ArbData';

fprintf(FG,'OUTP1 OFF');
fprintf(FG,'OUTP1 OFF');

%fprintf(FG,'DATA:VOL:CLE');
pause(0.001);
fprintf(FG,'SOUR1:FUNC ARB');
fprintf(FG,'SOUR1:FUNC:ARB:FILTER OFF');
pause(0.001);
DC0 =  zeros(10,1);
DC5 =   ones(10,1);

DC0Name         = 'DC0bit';
DC5Name         = 'DC5bit';

samplingrate = length(DC0) / (1/BitInfoSpeed);

if isFirst
fprintf(FG,['DATA:ARB:DAC ',DC0Name,sprintf( ',%d',round( DC0* (2^15-1) ) )] );
fprintf(FG,['SOUR1:FUNC:ARB:SRATE ',num2str(samplingrate)]);
fprintf(FG,['FUNC:ARB ',DC0Name]); % change to sequence

fprintf(FG,['DATA:ARB:DAC ',DC5Name,sprintf( ',%d',round( DC5* (2^15-1) ) )] );
fprintf(FG,['SOUR1:FUNC:ARB:SRATE ',num2str(samplingrate)]);
fprintf(FG,['FUNC:ARB ',DC5Name]); % change to arb

end
SEQ_command = ['"ByteData",',...
    '"',DC0Name,'",1,repeatTilTrig,maintain,4,'...
    '"',DC5Name,'",1,once,maintain,4,'];

for bit = bytedata
    switch bit
        case 0 % add a DC0
            SEQ_command = [SEQ_command,'"',DC0Name,'", 1,once,maintain,4,'];
        case 1 % add a DC5
            SEQ_command = [SEQ_command,'"',DC5Name,'", 1,once,maintain,4,'];
        otherwise
    end
end

SEQ_command = [SEQ_command,'"',DC5Name,'",1,once,maintain,4,'];
npoints = length(SEQ_command)-1;
ndigits = floor(log10(length(SEQ_command)))+1;

fprintf(FG,['DATA:SEQ #',...
             num2str(ndigits),... % number of digits in block
             num2str(npoints),... % number of points in block
             SEQ_command]);       % actual sequence order

fprintf(FG,['FUNC:ARB ','ByteData']);
fprintf(FG,['SOUR1:FUNC:ARB:SRATE ',num2str(samplingrate)]);

fprintf(FG,'OUTP1 ON');
fprintf(FG,'SOUR1:VOLT 5');
pause(0.5);
fprintf(FG,'*TRG');
pause((length(bytedata)+16)/BitInfoSpeed);
fprintf(FG,'OUTP1 OFF');
end
