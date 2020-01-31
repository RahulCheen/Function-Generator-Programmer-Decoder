FG_ID           = 'MY52600694'; % serial number of new fxn generator
if ~exist('FG','var')
    FG = visa('keysight',['USB0::2391::10759::',FG_ID,'::0::INSTR'])
end

if strcmp(FG.Status,'closed') % if the function generator connection is closed
    fopen(FG)
end

fprintf(FG, '*RST'); % Resets to factory default, outputs are off by default

testByte = [0 0 0 0 1 0 0 0 0 1 ...
            1 0 0 0 0 0 1 0 0 1 ...
            0 0 0 0 1 1 1 0 0 1 ...
            0 0 0 0 0 0 0 0 1 0 ...
            1 0 0 0 1 0 1 0 1 0 ];

        
fprintf(FG, 'SOUR1:FUNC SQU');
fprintf(FG, 'SOUR1:FUNC:SQ:DCYC 99.99');
fprintf(FG, 'SOUR1:FREQ 0.000001');
fprintf(FG, 'SOUR1:VOLT 4.001');
fprintf(FG, 'OUTP1 ON');
t = zeros(50,2);
ii=1;
pause
for bit = testByte
    tic;
    %disp(['Bit Value: ',num2str(bit)]);
    fprintf(FG, ['SOUR1:VOLT:OFFS ',num2str(4*bit + 0.001)]);
    
    while toc <= 1/30
    end
    t(ii,:) = [bit,toc]; ii = ii+1;
end
    