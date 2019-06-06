function inputs = inputsargcheck(inputs)
% inputsargcheck checks the structure inputs so that it includes the necessary inputs.  If it doesn't
% find the parameter, default values are added.
%
%   Name        Default Value
%   TF              N/A (must be specified before inputsargcheck is called)
%   ModFreqs        N/A (must be specified before inputsargcheck is called)
%   DutyCycles      N/A (must be specified before inputsargcheck is called)
%   PulseDurations  N/A (must be specified before inputsargcheck is called)
%   Amplitudes      N/A (must be specified before inputsargcheck is called)
%   bytesize        16
%   DCType          'ARB'
%
%   ~~~ Buffers Substructure ~~~
%   Bit             10
%   Buf             1
%   InterTrial      5000
%   BeforeTrial     500
%   
try inputs.TF;
    inputs.ModFreqs;
    inputs.DutyCycles;
    inputs.PulseDurations;
    inputs.Amplitudes;
catch
    error('inputs must include at least one value for all 5 parameters.');
end

if length(inputs.TF) > 1
    warning('More than one Transducer Frequency specified. Using the first value only.');
    s = input('Frequencies: ',num2str(inputs.TF),'. Continue? (Y/N)','s');
    switch s
        case 'Y'
        case 'N'
            error('');
        otherwise
            error('');
    end
end
try inputs.bytesize;
catch
   inputs.bytesize = 16; % default, 16-bit
end

try inputs.Buffers.Bit;
catch
   inputs.Buffers.Bit = 5; % default, 5 ms
end

try inputs.Buffers.Buf;
catch
   inputs.Buffers.Buf = 1; % default, 1 ms
end

try inputs.Buffers.InterTrial;
catch
   inputs.Buffers.InterTrial = 5000; % default, 5000 ms
end

try inputs.Buffers.BeforeTrial;
catch
    inputs.Buffers.BeforeTrial = 500;   % default, 500 ms
end

try inputs.DCType;
catch
    inputs.DCType = 'ARB'; % default, ARB
end

% input error for DCType
if ~strcmp(inputs.DCType,'ARB') || ~strcmp(inputs.DCType,'BUR')
    inputs.DCType = 'ARB'; % default, ARB
end
    