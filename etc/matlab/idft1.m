% IDFT implementation

function y = idft1(x)
    N = length(x);
    y = dft1(x);
    % apply correction factor 1/N
    y = (1/N) * y;
    % change sign of imaginary component
    y = real(y) - 1j*imag(y); 
end