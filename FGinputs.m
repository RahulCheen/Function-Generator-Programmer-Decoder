clearvars -except FG

FG_ID           = 'MY52600694'; % serial number of new fxn generator

%  Establish connection, List global parameters, etc.
if ~exist('FG','var')
    FG = visa('keysight',['USB0::2391::10759::',FG_ID,'::0::INSTR'])
end
% Runs the new FunGen
% This address depends on the serial number of the machine.
if strcmp(FG.Status,'closed')
    fopen(FG) % There's some output here, so you know it worked.
end

inputs.TF               =  5;
inputs.Amplitudes       = [10   200     400 ];
inputs.DutyCycles       = [5    50      100 ];
inputs.ModFreqs         = [10   100     1000];
inputs.PulseDurations   = [50   200     1000];

inputs.bytesize         = 10;     % number of bytes

inputs.BitBuffer         = 5;     % [ms]
inputs.Buffer            = 1;     % [ms]
inputs.InterTrialBuffer  = 5000;  % [ms]
inputs.BeforeTrialBuffer = 500;   % [ms]

inputs.DCType = 'Arb'; % type of waveform to use (other option: BUR)



s = serial('COM4','BaudRate',9600);