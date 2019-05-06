function [DataName,ExtractedDataName,ParameterOrderName] = MatNames

[rawFileName,path1] = uigetfile('*.rhs','Select Raw File','MultiSelect','Off');

DataName           = [rawFileName(1:end-4),'.mat'];
ExtractedDataName  = ['trials_', rawFileName(1:end-4),'.mat'];
ParameterOrderName = ['ParameterOrder_',rawFileName(1:end-4),'.mat'];

cd(path1);


end
