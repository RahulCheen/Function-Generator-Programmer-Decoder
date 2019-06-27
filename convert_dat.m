clear;

path = uigetdir('C:\Data');

cd(path); % go to folder

files = dir; % get all files in the folder
files = files(~[files(:).isdir]); % remove subdirectories from the list
analogFiles  = contains({files(:).name},'ANALOG');
digitalFiles = contains({files(:).name},'DIGITAL');
ampFiles     = contains({files(:).name},'amp');
infoFiles    = contains({files(:).name},'info');
timeFiles    = contains({files(:).name},'time');

rhsFiles     = contains({files(:).name},'rhs');
datFiles     = contains({files(:).name},'dat');
matFiles     = contains({files(:).name},'mat');

for ii=1:length(files) % loop through files
    fileType = files(ii).name(end-3:end); % get file ending
    if matFiles(ii)
        continue;
    end
    
    if rhsFiles(ii)
        fileName = files(ii).name(1:end-4);
        switch fileName
            case 'info'
                read_Intan_RHS2000_file(files(ii).name);
                
                c = whos; d = {c.name};
                
                save(files(ii).name(1:end-4),d{:});
            otherwise
                k = 1;
        end
    end
    
    if datFiles(ii)
        fileName = files(ii).name(1:end-4); % get the file name
        switch fileName
            case 'time' % for the file 'time.dat'
                fileinfo = dir('time.dat');
                num_samples = fileinfo.bytes/4; % int32 = 4 bytes
                fid = fopen('time.dat', 'r');
                t = fread(fid, num_samples, 'int32');
                fclose(fid);
                save(files(ii).name(1:end-4),'t');
                
            otherwise % all other .dat files
                
                fileinfo = dir(files(ii).name); % amplifier channel data
                num_samples = fileinfo.bytes/2; % int16 = 2 bytes
                fid = fopen(files(ii).name, 'r');
                v = fread(fid, num_samples, 'int16');
                fclose(fid);
                save(files(ii).name(1:end-4),'v')
        end
    end
    
   
    clearvars -except files ii path
end


% create dummy file for data processing
c = strsplit(path,{'\','/'});
DataName = [c{end},'.rhs']; % extract folder name from path name
fid = fopen(DataName,'w');
fprintf(fid,'Dummy File.'); % save string 'Dummy File.' to dummy file (duh)
fclose(fid);
clear fid;
