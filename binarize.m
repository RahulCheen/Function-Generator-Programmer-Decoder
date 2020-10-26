function outputRow = binarize(inputRow,nBits)

% SUPPORT FUNCTION: BINARIZE
% BINARIZE converts base-10 to binary

outputRow = [];
for ii=1:length(inputRow)
    outputBit = zeros(1,nBits(ii));
    workingNumber = inputRow(ii); % Algorithm for converting int to binary
    for bit = nBits(ii):-1:1
        outputBit(bit) = mod(workingNumber,2);
        workingNumber = (workingNumber-outputBit(bit))/2;
    end
    outputRow = [outputRow,outputBit];
end
end