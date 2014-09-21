% Radix-2 FFT implementation
% as per http://www.alwayslearn.com/dft%20and%20fft%20tutorial/DFTandFFT_FFT_Butterfly_4_Input.html

function y = fft1(x)
    N = length(x);
    if (log2(N) - round(log2(N)) ~= 0)
        error('Input vector length != 2^n');
    end
    if (~iscolumn(x))
        error('Input is not a column vector');
    end
    stages = log2(N)+1;
    tmp = zeros(N,stages);  
    tmp(:,1) = x(bitrevorder(1:N));    % bit reverse input samples
    for i = 2:stages                        % for all stages
        Ns = 2^(i-1);
        Is = 2^(i-2);
        n = 0;
        for k = 1:N                         % for all elements
           if (~bitand(k-1, (2^(i-2))))     % butterfly start elements
               % calculate butterflys
               tf = exp(-1j*2*pi*n/Ns);
               % upper element, don't apply twiddle factor (even half)
               tmp(k,i) = tmp(k,i-1) + tf*tmp(k+Is,i-1);
               % lower element, apply twiddle factor (odd half)
               tmp(k+Is,i) = tmp(k,i-1) - tf*tmp(k+Is,i-1) ;
               n = n + 1; 
           else
               n = 0;
           end
        end
    end
    y = tmp(:,stages);              % last row is output
    
end