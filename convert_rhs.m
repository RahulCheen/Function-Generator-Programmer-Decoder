clear;

[file, path, filterindex] = ...
    uigetfile('*.rhs', 'Select an RHS2000 Data File', 'MultiSelect', 'on');

if ~iscell(file)
    file = {file};
end
cd(path);
for ii=1:length(file)
    clearvars -except filename file path ii
    filename = [path,file{ii}];
    disp(filename);
read_Intan_RHS2000_file(filename);

a = whos;
b = {a.name};

try save([filename(1:end-4),'_Amplifier'],  'amp*','charge*','compliance*','spike*','stim*','freq*','notes');
catch; end
try save([filename(1:end-4),'_Digital'],    '*dig*','freq*','notes');
catch; end
try save([filename(1:end-4),'_Analog'],     '*adc*','freq*','notes');
catch; end
%save(filename(1:end-4),b{:});
end