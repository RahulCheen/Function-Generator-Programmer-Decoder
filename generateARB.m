clearvars -except FG
if ~exist('FG','var')
    FG = visa('keysight','USB0::0x0957::0x2A07::MY52600694::0::INSTR')
    % This address depends on the serial number of the machine.
    fopen(FG) % There's some output here, so you know it worked.
end

DC = 50;
Modfreq = 10;

scpi = readSCPIfile('SCPIcode1.txt');

[n,m] = size(scpi);

for ii=1:n
    linecode = scpi{ii,1};
    if contains(linecode,'#aaaa')
        disp(' ');
        c = split(linecode,',');
        string1 = join(c(2:end),',');
        npoints = strlength(string1)-1;
        ndigits = floor(log10(npoints))+1;
        c = strsplit(linecode,'#aaaa');
        linecode = [c{1},'#',num2str(ndigits),num2str(npoints),c{2}];
    end
    fprintf(FG,linecode);
    disp(linecode);
end