function buzzBitWrite(FG,bytedata,BitInfoSpeed)

try fclose(FG);
    fopen(FG);
catch
    error('did not properly establish connection to function generator.');
end

buzzDur = 5; % [ms]
bitDur = 1000/BitInfoSpeed; % [ms]

fprintf(FG,'SOUR1:AM:STAT 0');

fprintf(FG,'SOUR1:FUNC SQU');
fprintf(FG,'SOUR1:FUNC:SQU:DCYC 50');
fprintf(FG,'SOUR1:VOLT 5');
fprintf(FG,'SOUR1:VOLT:OFFS 2.5');
fprintf(FG,'SOUR1:FREQ 7000');

fprintf(FG,'OUTP1 ON');
pause(buzzDur/1000);

for Bit = bytedata
    if Bit
        fprintf(FG,'SOUR1:FUNC DC');
        pause(bitDur/1000);
        fprintf(FG,'SOUR1:FUNC SQU');
    else
        fprintf(FG,'OUTP1 OFF');
        pause(bitDur/1000)
        fprintf(FG,'OUTP1 ON');
    end
    pause(buzzDur/1000);
    
end
fprintf(FG,'OUTP1 OFF');
