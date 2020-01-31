function [DigitalName,TrialsName,AmpName,AnalogName,RawMatName] = MatNames

[rawFileName,path1] = uigetfile('*.rhs','Select Raw File','MultiSelect','Off');

DigitalName         = [rawFileName(1:end-4),'_Digital.mat'  ];
AmpName             = [rawFileName(1:end-4),'_Amplifier.mat'];
AnalogName          = [rawFileName(1:end-4),'_Analog.mat'   ];

TrialsName          = ['trials_', rawFileName(1:end-4),'.mat'];
RawMatName         = [rawFileName(1:end-4),'.mat'];
cd(path1);    

end
