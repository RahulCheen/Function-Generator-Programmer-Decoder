clear; 

try, instrreset;
catch
end

%%
frequency               = 260;          % [kHz]
amplitudes              = [30 100 170]; % [mV]

stimuli(1).dutycycle    = 20;           % [%]
stimuli(1).prf          = [10 150];     % [Hz]
stimuli(1).duration     = 1.5;          % [s]

stimuli(2).dutycycle    = 50;           % [%]
stimuli(2).prf          = [500];        % [Hz]
stimuli(2).duration     = 0.3;          % [s]

stimuli(3).dutycycle    = 100;          % [%]
stimuli(3).prf          = [0];          % [Hz]
stimuli(3).duration     = 0.3;          % [s]





