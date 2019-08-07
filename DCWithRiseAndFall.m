function [arbWave,sizeArb] = DCWithRiseAndFall(sizeArb,riseTime,pulseDuration,onsetType)
% generate arbitrary waveform for a 100% duty-cycle with a rise and fall time.  Inputs are sizeArb
% (number of points in the arbitrary waveform) and riseTime (time for rise and fall of signal).  Rise and
% fall are half-gaussians, with standard deviation of one-fourth the mean, so that the rise and fall
% start and end, respectively, close to zero.
% 
% Example: (default values shown)
%   [arbWave] = DCWithRiseAndFall(1000,10);
%       generates signal that is 1000 points long, with the first 10% rising to voltage and the last 10%
%       falling from voltage

% Input error for sizeArb
if ~exist('sizeArb','var'); sizeArb = 1000;                                     end % no input
if isempty(sizeArb);        sizeArb = 1000;                                     end % empty value
if sizeArb <= 100;          error('sizeArb must be greater than 100 points');   end
if rem(sizeArb,2);          sizeArb = sizeArb - 1;                              end % make sizeArb even

% Input error for riseTime
if ~exist('riseTime','var');    riseTime = 10;                                  end % no input
if isempty(riseTime);           riseTime = 10;                                  end % empty value

% Input error for pulseDuration
if ~exist('pulseDuration','var');   pulseDuration = 1000;                       end % no input, default to 1000
if isempty(pulseDuration);          pulseDuration = 1000;                       end % empty input
if pulseDuration <= 2*riseTime;     error('pulseDuration must be more than twice riseTime'); end

% Input error for onsetType
if ~exist('onsetType','var');       onsetType = 'cosine';                       end % no input, defautl is cosine
if isempty(onsetType);              onsetType = 'cosine';                       end % empty input

sizeArb = round(sizeArb);                   % round value
n = round(riseTime*sizeArb/pulseDuration);  % number of points in rise
switch onsetType
    case 'gaussian'
        y = gaussian(linspace(0,1,n)',1,1,1/16);    % rise gaussian
        y_l = flip(y);                              % fall gaussian
    case 'cosine'
        y = (1+flip(cos(pi*linspace(0,1,n)')))/2;   % rise cosine
        y_l = flip(y);                              % fall cosine
    otherwise
        y = (1+flip(cos(pi*linspace(0,1,n)')))/2;   % rise cosine
        y_l = flip(y);                              % fall cosine
end


if iscolumn(y)
    arbWave = [y;    ones(sizeArb-2*n,  1);             y_l];
else
    arbWave = [y,    ones(1,            sizeArb-2*n),   y_l];
end
