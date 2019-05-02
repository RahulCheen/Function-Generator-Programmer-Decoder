clear;

path = uigetdir('C:\Data');

cd(path);
pause(0.0001);
a = dir;

a = a(~[a(:).isdir]);

for ii=1:length(a)
    a(ii).name(end-3:end)
    if strcmp(a(ii).name(end-3:end),'.dat')
        
        if strcmp(a(ii).name(1:4),'time')
            fileinfo = dir('time.dat');
            num_samples = fileinfo.bytes/4; % int32 = 4 bytes
            fid = fopen('time.dat', 'r');
            t = fread(fid, num_samples, 'int32');
            fclose(fid);
            save(a(ii).name(1:end-4),'t');
        else
            fileinfo = dir(a(ii).name); % amplifier channel data
            num_samples = fileinfo.bytes/2; % int16 = 2 bytes
            fid = fopen(a(ii).name, 'r');
            v = fread(fid, num_samples, 'int16');
            fclose(fid);
            save(a(ii).name(1:end-4),'v')
            
        end
        
    end
    if strcmp(a(ii).name(end-3:end),'.rhs')
        read_Intan_RHS2000_file(filename);
        
        c = whos;
        d = {c.name};
        
        save(filename(1:end-4),d{:});
        
        
        
        
    end
    clearvars -except a ii path
end