% implements IFFT
% uses FFT function and applies correction afterwards

function y = ifft1(x)
    N = length(x);
    y = fft1(x);
    % apply correction factor 1/N
    y = (1/N) * y;
    % change sign of imaginary component
    y = real(y) - 1j*imag(y); 
end