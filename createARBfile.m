% generate SCPI code
clearvars -except FG;
close all;
arbWave = DCWithRiseAndFall(1000,5);
arbWaveDAC = round(arbWave*32767);
fid = fopen('ExampleARB.arb','w');

fprintf(fid,'File Format:1.10\n');
fprintf(fid,'Checksum:0\n');
fprintf(fid,'Channel Count:1\n');
fprintf(fid,['Sample Rate:',num2str(length(arbWave)),'\n']);
fprintf(fid,'High Level:5.00000\n');
fprintf(fid,'Data Type:"short"\n');
fprintf(fid,'Filter:"step"\n');
fprintf(fid,['Data Points:',num2str(length(arbWave)),'\n']);
fprintf(fid,'Data:\n');

for ii=1:length(arbWave)
    fprintf(fid,num2str(arbWaveDAC(ii)));
    fprintf(fid,'\n');
end

fclose(fid)
