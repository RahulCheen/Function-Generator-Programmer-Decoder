function [DigitalName,TrialsName,AmpName,AnalogName,RawDataName] = MatNames(path)

[rawFileName,path1] = uigetfile([path,'*.rhs'],'Select Raw File','MultiSelect','Off');

DigitalName         = [rawFileName(1:end-4),'_Digital.mat'  ];
AmpName             = [rawFileName(1:end-4),'_Amplifier.mat'];
AnalogName          = [rawFileName(1:end-4),'_Analog.mat'   ];

TrialsName          = ['trials_', rawFileName(1:end-4),'.mat'];
RawDataName         = rawFileName;
cd(path1);    

end
