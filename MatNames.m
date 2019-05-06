function [rawFileName,ExtractedDataName,ParameterOrderName] = MatNames

[rawFileName,path1] = uigetfile('*.rhs','Select Raw File','MultiSelect','Off');

ExtractedDataName  = ['ExtractedData_', rawFileName(1:end-4),'.mat'];
ParameterOrderName = ['ParameterOrder_',rawFileName(1:end-4),'.mat'];

cd(path1);


end
