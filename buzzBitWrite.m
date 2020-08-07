function buzzBitWrite(FG,CH_NUM,bytedata,BitInfoSpeed)

if ischar(CH_NUM)
else
    CH_NUM = num2str(CH_NUM);
end
try fclose(FG);
    fopen(FG);
catch
    error('did not properly establish connection to function generator.');
end

buzzDur = 1; % [ms]
bitDur = 1000/BitInfoSpeed; % [ms]

fprintf(FG,['TRIG',CH_NUM,':SOUR BUS']);
fprintf(FG,['SOUR',CH_NUM,':BURS:STAT 0']);

fprintf(FG,['OUTP',CH_NUM,' OFF']);
fprintf(FG,['SOUR',CH_NUM,':AM:STAT 0']);

fprintf(FG,['SOUR',CH_NUM,':FUNC SQU']);
fprintf(FG,['SOUR',CH_NUM,':FUNC:SQU:DCYC 50']);
fprintf(FG,['SOUR',CH_NUM,':VOLT 5']);
fprintf(FG,['SOUR',CH_NUM,':VOLT:OFFS 2.5']);
fprintf(FG,['SOUR',CH_NUM,':FREQ 7500']);

fprintf(FG,['OUTP',CH_NUM,' ON']);
tbuzz = tic;
while toc(tbuzz) < buzzDur/1000
end
for Bit = bytedata
    if Bit
        fprintf(FG,['SOUR',CH_NUM,':FUNC DC']);
        tbit = tic;
        while toc(tbit) < bitDur/1000
        end
        %pause(bitDur/1000);
        fprintf(FG,['SOUR',CH_NUM,':FUNC SQU']);
    else
        fprintf(FG,['SOUR',CH_NUM,':BURS:STAT 1']);
        fprintf(FG,['TRIG',CH_NUM,':SOUR BUS']);
        tbit = tic;
        while toc(tbit) < bitDur/1000
        end
        fprintf(FG,['SOUR',CH_NUM,':BURS:STAT 0']);
    end
    tbuzz = tic;
    while toc(tbuzz) < buzzDur/1000
    end
    
end
fprintf(FG,['OUTP',CH_NUM,' OFF']);
