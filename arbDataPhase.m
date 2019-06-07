function chck1 = arbDataPhase(FG,DataRow,chck1)


if chck1 == 1
    fprintf(FG,'SOUR1:FUNC:ARB seqData');
elseif chck1 == 0
    chck1 = 1;
end

%DataRow = [0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,1,0,1,0,0,0,0,0,1,1,0,0,1,0,1,1,1,1,1,0,1,0,0,0,1,1,1,1,1,0,1,0,0,0];

%  fprintf(FG,'*RST');
%  fprintf(FG,'SOUR1:FUNC ARB');
%  fprintf(FG,'DATA:ARB:DAC Data0,0,0,0,0,0,0,0,0');
%  fprintf(FG,'SOUR1:FUNC:ARB:SRATE 3000');
%  fprintf(FG,'DATA:ARB:DAC Data1,32767,32767,32767,32767,32767,32767,32767,32767');
%  fprintf(FG,'SOUR1:FUNC:ARB:SRATE 3000');

strData = '"seqData","Data0",1,repeatTilTrig,maintain,4';
for ii=1:length(DataRow)
    strData = [strData,...
        ',"Data',num2str(DataRow(ii)),'",1,once,maintain,4',...
        ];
end
npoints = length(strData);
ndigits = floor(log10(length(strData)))+1;

fprintf(FG,['DATA:SEQ #',...
    num2str(ndigits),... % number of digits in block
    num2str(npoints),... % number of points in block
    strData]);       % actual sequence order

fprintf(FG,'SOUR1:FUNC:ARB:SRATE 300');
fprintf(FG,'SOUR1:FUNC:ARB seqData');