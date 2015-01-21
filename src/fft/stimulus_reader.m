% stimulus reader

FFT_length = 256;

y = dlmread('fft_output.txt', ' ');
y_complex = y(:,1) + 1j*y(:,2);

y_complex = bitrevorder(y_complex)';

fft_in = fft(round(x));
fft_out = y_complex;

hold on
subplot(2,1,1);
plot(real(fft_in)-real(fft_out));
subplot(2,1,2);
plot(imag(fft_in)-imag(fft_out));



