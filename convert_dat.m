% CONVERT_DAT converts Intan files, from the 'One File per Channel' option.  Amplifier, analog, and
% digital data is saved as *.dat files, with a time-stamp saved as 'time.dat' and metadata saved as
% 'info.rhs'. A dummy file is created, with the same name as the enclosing folder, as an .rhs file for
% processing.
% 
% Two options for saving amplifier data: 'Individual' or 'Altogether'. 'Individual' saves each amplifier
% channel as it's own MAT-file.  'Altogether' saves all amplifier channels in the same file.  Analog and
% Digital Files are saved as individual MAT files.

clear;

AmplifierOption = 'Altogether'; % 'Individual' or 'Altogether'

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
txtFiles     = contains({files(:).name},'txt');

amp_data        = [];	amp_order       = [];
analog_data     = [];   analog_order    = [];
digital_data    = [];   digital_order   = [];


read_Intan_RHS2000_file('info.rhs');
tic;
for ii=1:length(files) % loop through files
    
    if matFiles(ii) || rhsFiles(ii) || txtFiles(ii)
        continue; % dont do anything with mat, rhs, or txt files
    end
    
    if datFiles(ii)
        fileName = files(ii).name(1:end-4); % file name
        
        % ~~~~~~~~~~ ANALOG FILES ~~~~~~~~~~ %
        if analogFiles(ii)
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
        if digitalFiles(ii)
            fileinfo    = dir(files(ii).name); % amplifier channel data
            num_samples = fileinfo.bytes/2; % uint16 = 2 bytes
            
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
            v       = v * 0.195; % convert to [uV]
            fclose(fid);
            
            switch AmplifierOption
                case 'Individual'
                    eval(['amp',num2str(1+str2num(files(ii).name(end-6:end-4))),' = v;']);
                case 'Altogether'
                    amp_data  = [amp_data,v];
                    amp_order = [amp_order,str2num(files(ii).name(end-6:end-4))];
                otherwise
            end
            
        end
        
        % ~~~~~~~~~~~ TIME FILE ~~~~~~~~~~~~ %
        if timeFiles(ii)
            fileinfo    = dir('time.dat');
            num_samples = fileinfo.bytes/4; % int32 = 4 bytes
            
            fid     = fopen('time.dat', 'r');
            t       = fread(fid, num_samples, 'int32');
            t       = t / frequency_parameters.amplifier_sample_rate; % convert to [s]
            fclose(fid);
        end
        
        disp(fileName);
    end
    
    
    clearvars -except AmplifierOption amp* board* frequency* spike* stim* files ii path *Files *_data *_order t
end

% create dummy file for data processing
c = strsplit(path,{'\','/'});
DataName = [c{end},'.rhs']; % extract folder name from path name
fid = fopen(DataName,'w');
fprintf(fid,'Dummy File.'); % save string 'Dummy File.' to dummy file (duh)
fclose(fid);
clear fid;

% ensure the order of data is correct
amp_data        = amp_data      (:,amp_order      + 1  );  % add 1 for MATLAB indexing
analog_data     = analog_data   (:,analog_order     );
digital_data    = digital_data  (:,digital_order    );

disp(['Converting all Files took: ',num2str(toc),' seconds.']);


% save amplifier data to one file
tic;
% switch AmplifierOption
%     case 'Altogether'
%         save([DataName(1:end-4),'_Amplifier']...
%             ,'amp_data' ...
%             ,'freq*'    ...
%             ,'spike*'   ...
%             ,'stim*'    ...
%             ,'t'        ...
%             );
%         
%     case 'Individual'
%         save([DataName(1:end-4),'_amp']...
%             ,'freq*'    ...
%             ,'spike*'   ...
%             ,'stim*'    ...
%             ,'t');
%         for ii=1:16
%             save([DataName(1:end-4),'_amp',num2str(ii)]...
%                 ,['amp',num2str(ii)]...
%                 );
%             disp([DataName(1:end-4),'_amp',num2str(ii)]);
%         end
%     otherwise
% end
% disp(['Saving Amplifier Data took: ',num2str(toc),' seconds.']);

tic;
save([DataName(1:end-4),'_Digital']...
    ,'digital_data' ...
    ,'freq*'        ...
    ,'board_dig*'   ...
    ,'t'            ...
    );
disp(['Saving Digital Data took: ',num2str(toc),' seconds.']);

tic;
save([DataName(1:end-4),'_Analog']...
    ,'analog_data'  ...
    ,'freq*'        ...
    ,'board_adc*'   ...
    ,'t'...
    );
disp(['Saving Analog Data took: ',num2str(toc),' seconds.']);

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
