% Implementation of Radix-2-FFT and IFFT in VHDL
%
% Stefan Biereigel

# Motivation
The FFT is a transformation used in a variety of signal-processing contexts, including but not limited to filtering, spectral shaping, modulations such as OFDM, signal analysis etc. As it seemed like an interesting topic, the goal was set to implement an efficient DFT algorithm, namely the Radix-2-FFT in VHDL for use in FPGA designs with Altera FPGAs.

# Task Defintion
* Comprehend Fourier Transform, inverse Fourier Transform and their implications
* Gain confidence in usage of Matlabs internal fft() and ifft()-functions
* algorithmically implement DFT in Matlab
* implement FFT Radix-2 algorithm in Matlab
* Research on FFT implementations in FPGAs (focus on Pipelining Concepts, Radix Sizes, etc.)
* create test environment for VHDL implementation (Matlab integration, Test vectors, Test definitions)
* implement necessary components for at least one possible FFT implementation
* optional: implement components for more possible implementations
* test & verify implemented models (simulation)
* test on real hardware (stimulus generator -> IFFT -> DAC)
* analyse implementations regarding FFT size - resource usage - max. speed

