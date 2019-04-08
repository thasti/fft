Synthesizable Radix 2 FFT implementation for HDL designs
========================================================

This repository contains an implementation of the R2SDF (Radix 2 Single-Path Delay Feeback) FFT architecture.
Both decimation-in-time (DIT) and decimation-in-frequency (DIF) configurations are supported. The DIT variant
requires bit-reverse-ordered inputs and produces natural-ordered outputs, while the opposite is true for the
DIF variant.
Both variants can be used to compute the IFFT by applying complex conjugate data and also interpreting the
output as such (sign inversion on imaginary component).

The Python testbench shows how to use the FFT in practice. It also verifies the output against the numpy FFT
implementation and calculates magnitude/phase and RMS errors.

