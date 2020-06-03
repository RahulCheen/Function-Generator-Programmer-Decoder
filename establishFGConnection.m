function FG = establishFGConnection(ID,OutputBufferSize)

if exist('OutputBufferSize','var')
    OutputBufferSize = 2^16;
end

FG = visa('keysight',['USB0::0x0957::0x2A07::',ID,'::0::INSTR']);
FG.OutputBufferSize = OutputBufferSize;
% This address depends on the serial number of the machine.
fopen(FG) % There's some output here, so you know it worked.