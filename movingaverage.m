function y = movingaverage(a,n,optn1)
% movingaverage takes a moving average of vector a, with averaging occuring over n points.  optn1 has
% three choices: 'left', 'center', 'right', which decides in which direction the averaged point takes
% it's average from.
if ~exist('n','var')
    n = 100;
end

if ~exist('optn1','var')
    optn1 = 'left';
end

y = zeros(length(a)-n+1,1);
switch optn1
    case 'left'
        startindex  = 1;
        endindex    = length(a)-n+1;
        
        for ii=startindex:endindex
            searchfrom  = ii:ii+n-1;
            y(ii)       = mean(a(searchfrom));
        end
    case 'right'
        startindex  = n;
        endindex    = length(a);
        
        for ii=startindex:endindex
            searchfrom = ii-n+1:ii;
            y(ii) = mean(a(searchfrom));
        end
    case 'center'
        switch rem(n,2)
            case 1 % odd
                startindex  = ceil(n/2);
                endindex    = length(a)-floor(n/2);
                
                for ii=startindex:endindex
                    searchfrom = ii-floor(n/2):ii+floor(n/2);
                    y(ii) = mean(a(searchfrom));
                end
                
            case 0 % even
                startindex  = n/2;
                endindex    = length(a)-n/2+1;
                
                for ii=startindex:endindex
                    searchfrom = ii-n/2+1:ii+n/2-1;
                    y(ii) = mean(a(searchfrom));
                end
        end
    otherwise
        startindex  = 1;
        endindex    = length(a)-n+1;
        
        for ii=startindex:endindex
            searchfrom  = ii:ii+n-1;
            y(ii)       = mean(a(searchfrom));
        end
end