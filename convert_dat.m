% CONVERT_DAT converts Intan files, from the 'One File per Channel' option.  Amplifier, analog, and
% digital data is saved as *.dat files, with a time-stamp saved as 'time.dat' and metadata saved as
% 'info.rhs'. A dummy file is created, with the same name as the enclosing folder, as an .rhs file for
% processing.
%
% Two options for saving amplifier data: 'Individual' or 'Altogether'. 'Individual' saves each amplifier
% channel as it's own MAT-file.  'Altogether' saves all amplifier channels in the same file.  Analog and
% Digital Files are saved as individual MAT files.

clear;

path = uigetdir('');

cd(path); % go to folder

options = [ 1   2   3]; % whether to convert amplifier data (1), digital data (2), or analog data (3)


files = dir; % get all files in the folder
files = files(~[files(:).isdir]); % remove subdirectories from the list

analogFiles  = contains({files(:).name},'ANALOG');
digitalFiles = contains({files(:).name},'DIGITAL');
ampFiles     = contains({files(:).name},'amp');
timeFiles    = contains({files(:).name},'time');

rhsFiles     = contains({files(:).name},'rhs');
datFiles     = contains({files(:).name},'dat');
matFiles     = contains({files(:).name},'mat');
txtFiles     = contains({files(:).name},'txt');

amp_data        = [];	amp_order       = [];
analog_data     = [];   analog_order    = [];
digital_data    = [];   digital_order   = [];


read_Intan_RHS2000_file('info.rhs');
t1 = tic;
for ii=1:length(files) % loop through files
    
    if matFiles(ii) || rhsFiles(ii) || txtFiles(ii)
        continue; % dont do anything with mat, rhs, or txt files
    end
    
    if datFiles(ii)
        fileName = files(ii).name(1:end-4); % file name
        
        % ~~~~~~~~~~ ANALOG FILES ~~~~~~~~~~ %
        if analogFiles(ii) && any(options==3)
            disp(fileName);
            fileinfo    = dir(files(ii).name); % amplifier channel data
            num_samples = fileinfo.bytes/2; % int16 = 2 bytes
            
            fid     = fopen(files(ii).name, 'r');
            v       = fread(fid, num_samples, 'uint16');
            v       = (v - 32768) * 0.0003125; % convert to [V]
            fclose(fid);
            
            analog_data  = [analog_data,v];
            analog_order = [analog_order,str2num(files(ii).name(end-4))];
        end
        
        % ~~~~~~~~~~ DIGITAL FILES ~~~~~~~~~~ %
        if digitalFiles(ii) && any(options==2)
            disp(fileName);
            fileinfo    = dir(files(ii).name); % amplifier channel data
            num_samples = fileinfo.bytes/2; % uint16 = 2 bytes
            
            fid     = fopen(files(ii).name, 'r');
            v       = fread(fid, num_samples, 'uint16');
            fclose(fid);
            
            digital_data  = [digital_data,v];
            digital_order = [digital_order,str2num(files(ii).name(end-4))];
        end
        
        % ~~~~~~~~~ AMPLIFIER FILES ~~~~~~~~~ %
        if ampFiles(ii) && any(options==1)
            disp(fileName);
            fileinfo    = dir(files(ii).name); % amplifier channel data
            num_samples = fileinfo.bytes/2; % int16 = 2 bytes
            
            fid     = fopen(files(ii).name, 'r');
            v       = fread(fid, num_samples, 'int16');
            v       = v * 0.195; % convert to [uV]
            fclose(fid);
            
            eval(['amp',num2str(1+str2num(files(ii).name(end-6:end-4))),' = v;']);
            
        end
        
        % ~~~~~~~~~~~ TIME FILE ~~~~~~~~~~~~ %
        if timeFiles(ii)
            disp(fileName);
            fileinfo    = dir('time.dat');
            num_samples = fileinfo.bytes/4; % int32 = 4 bytes
            
            fid     = fopen('time.dat', 'r');
            t       = fread(fid, num_samples, 'int32');
            t       = t / frequency_parameters.amplifier_sample_rate; % convert to [s]
            fclose(fid);
        end
        
        
    end
    
    
    clearvars -except options amp* board* frequency* spike* stim* t1 files ii path *Files *_data *_order t
end

% create dummy file for data processing
c = strsplit(path,{'\','/'});
DataName = [c{end},'.rhs']; % extract folder name from path name
fid = fopen(DataName,'w');
fprintf(fid,'Dummy File.'); % save string 'Dummy File.' to dummy file (duh)
fclose(fid);
clear fid;


for ii=1:length(options)
    switch options(ii)
        case 1; tic;   % ~~~~~~~~~ AMPLIFIER DATA ~~~~~~~~~~~ %
            save([DataName(1:end-4),'_ampMeta']...    save amplifier meta-data
                ,'freq*'    ...                             % frequency information
                ,'spike*'   ...                             % spiking data
                ,'stim*'    ...                             % stimulation data
                ,'t');                                      % time stamp
            
            for jj=1:16                             % save individual channel to individual file
                save([DataName(1:end-4),'_amp',num2str(jj)]...
                    ,['amp',num2str(jj)]...                 % save only the amplifier data
                    );
                disp([DataName(1:end-4),'_amp',num2str(jj)]);
            end
            disp(['Saving Amplifier Data took: ',num2str(toc),' seconds.']);
            
        case 2; tic; % ~~~~~~~~~ DIGITAL DATA ~~~~~~~~~~~ %
            digital_data = digital_data(:,digital_order);   % re-order data
            save([DataName(1:end-4),'_Digital']...          % save digital data to single file
                ,'digital_data' ...                         %   digital data
                ,'freq*'        ...                         %   frequency data
                ,'board_dig*'   ...                         %   digital meta-data
                ,'t'            ...                         %   time-stamp
                );
            disp(['Saving Digital Data took: ',num2str(toc),' seconds.']);
            
            
        case 3; tic; % ~~~~~~~~~ ANALOG DATA ~~~~~~~~~~~ %
            analog_data = analog_data(:,analog_order);      % re-order data
            save([DataName(1:end-4),'_Analog']...           % save analog data to single file
                ,'analog_data'  ...                         %   analog data    
                ,'freq*'        ...                         %   frequency data
                ,'board_adc*'   ...                         %   analog meta-data
                ,'t'...                                     %   time-stamp
                );
            disp(['Saving Analog Data took: ',num2str(toc),' seconds.']);
            
    end
end
disp(['Converting all Files took: ',num2str(toc(t1)),' seconds.']);








% save(DataName(1:end-4)...
%     ,'amp_data'     ...
%     ,'analog_data'  ...
%     ,'digital_data' ...
%     ,'freq*'        ...
%     ,'board*'       ...
%     ,'spike*'       ...
%     ,'stim*'        ...
%     ,'t'            ...
%     );
%
