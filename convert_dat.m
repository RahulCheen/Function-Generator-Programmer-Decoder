clear;

path = uigetdir('');

cd(path); % go to folder

files = dir; % get all files in the folder
files = files(~[files(:).isdir]); % remove subdirectories from the list
analogFiles  = contains({files(:).name},'ANALOG');
digitalFiles = contains({files(:).name},'DIGITAL');
ampFiles     = contains({files(:).name},'amp');
timeFiles    = contains({files(:).name},'time');

rhsFiles     = contains({files(:).name},'rhs');
datFiles     = contains({files(:).name},'dat');
matFiles     = contains({files(:).name},'mat');

amp_data        = [];	amp_order       = [];
analog_data     = [];   analog_order    = [];
digital_data    = [];   digital_order   = [];


read_Intan_RHS2000_file('info.rhs');
for ii=1:length(files) % loop through files
    
    if matFiles(ii) || rhsFiles(ii)
        continue; % dont do anything with mat or rhs files
    end
    
    if datFiles(ii)
        fileName = files(ii).name(1:end-4); % file name
        
        % ~~~~~~~~~~ ANALOG FILES ~~~~~~~~~~ %
        if analogFiles(ii)
            fileinfo    = dir(files(ii).name); % amplifier channel data
            num_samples = fileinfo.bytes/2; % int16 = 2 bytes
            
            fid     = fopen(files(ii).name, 'r');
            v       = fread(fid, num_samples, 'uint16');
            v       = (v - 32768) * 0.0003125; % convert to microvolts
            fclose(fid);
            
            analog_data  = [analog_data,v];
            analog_order = [analog_order,str2num(files(ii).name(end-4))];
        end
        
        % ~~~~~~~~~~ DIGITAL FILES ~~~~~~~~~~ %
        if digitalFiles(ii)
            fileinfo    = dir(files(ii).name); % amplifier channel data
            num_samples = fileinfo.bytes/2; % int16 = 2 bytes
            
            fid     = fopen(files(ii).name, 'r');
            v       = fread(fid, num_samples, 'uint16');
            fclose(fid);
            
            digital_data  = [digital_data,v];
            digital_order = [digital_order,str2num(files(ii).name(end-4))];
        end
        
        % ~~~~~~~~~ AMPLIFIER FILES ~~~~~~~~~ %
        if ampFiles(ii)
            fileinfo    = dir(files(ii).name); % amplifier channel data
            num_samples = fileinfo.bytes/2; % int16 = 2 bytes
            
            fid     = fopen(files(ii).name, 'r');
            v       = fread(fid, num_samples, 'int16');
            v       = v * 0.195;
            fclose(fid);
            
            amp_data  = [amp_data,v];
            amp_order = [amp_order,str2num(files(ii).name(end-6:end-4))];
        end
        
        % ~~~~~~~~~~~ TIME FILE ~~~~~~~~~~~~ %
        if timeFiles(ii)
            fileinfo    = dir('time.dat');
            num_samples = fileinfo.bytes/4; % int32 = 4 bytes
            
            fid     = fopen('time.dat', 'r');
            t       = fread(fid, num_samples, 'int32');
            t       = t / frequency_parameters.amplifier_sample_rate;
            fclose(fid);
        end
        
    end
    disp(fileName);
   
    clearvars -except amp* board* frequency* spike* stim* files ii path *Files *_data *_order t
end


% create dummy file for data processing
c = strsplit(path,{'\','/'});
DataName = [c{end},'.rhs']; % extract folder name from path name
fid = fopen(DataName,'w');
fprintf(fid,'Dummy File.'); % save string 'Dummy File.' to dummy file (duh)
fclose(fid);
clear fid;
