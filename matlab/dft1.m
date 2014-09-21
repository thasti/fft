% DFT implementation
% as per http://www.alwayslearn.com/dft%20and%20fft%20tutorial/DFTandFFT_TheDFT.html

function y = dft1(x)
    N = length(x);
    y = zeros(N,1);
    for n = 0:N-1
        for k = 0:N-1
            y(n+1) = y(n+1) + x(k+1)*exp((-1j*2*pi*k*n)/N);
        end
    end
    y = y';
end
