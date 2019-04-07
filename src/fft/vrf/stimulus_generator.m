% FFT stimulus generator

FFT_length = 256;

t = 0:FFT_length-1;
x = 127 * cos(2*pi*10*t/FFT_length);

x_real = [round(x) 0]'; % round and pad a zero
x_imag = zeros(length(x_real),1);

dlmwrite('fft_stimulus.txt', [x_real x_imag], ' ');
