function [arbWave,sizeArb] = DCWithRiseAndFall(sizeArb,riseTime)
% generate arbitrary waveform for a 100% duty-cycle with a rise and fall time.  Inputs are sizeArb
% (number of points in the arbitrary waveform) and riseTime (percentage of the waveform for rising to
% voltage, as well as fall from voltage).  Rise and fall are half-gaussians, with standard deviation of
% one-fourth the mean, so that the rise and fall start and end, respectively, close to zero.
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
if riseTime >=50;               error('riseTime must be less than 50%');        end

sizeArb = round(sizeArb);                   % round value
n = round(sizeArb*riseTime/100);            % number of points in rise
y = gaussian(linspace(0,1,n)',1,1,1/16);    % rise gaussian
y_l = flip(y);                              % fall gaussian

if iscolumn(y)
    arbWave = [y;    ones(sizeArb-2*n,  1);             y_l];
else
    arbWave = [y,    ones(1,             sizeArb-2*n),  y_l];
end
