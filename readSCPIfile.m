function SCPIcode = readSCPIfile(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as a matrix.
%   SCPICODE = IMPORTFILE(FILENAME) Reads data from text file FILENAME for the default selection.
%
%   SCPICODE = IMPORTFILE(FILENAME, STARTROW, ENDROW) Reads data from rows STARTROW through ENDROW of
%   text file FILENAME.
%
% Example:
%   SCPIcode = readSCPIfile('SCPIcode1.txt', 1, 13);
%
%    See also TEXTSCAN.


%% Initialize variables.
if nargin<=2
    startRow = 1;
    endRow = inf;
end

%% Read columns of data as text:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this code. If an error occurs for a
% different file, try regenerating the code from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'HeaderLines', startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'HeaderLines', startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    dataArray{1} = [dataArray{1};dataArrayBlock{1}];
end

%% Remove white space around all cell columns.
dataArray{1} = strtrim(dataArray{1});

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric text to numbers.
% Replace non-numeric text with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));


%% Split data into numeric and string columns.
rawNumericColumns = {};
rawStringColumns = string(raw(:, 1));


%% Create output variable
SCPIcode = raw;
