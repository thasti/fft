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

Design goals
============
This core was implemented as an educational experiment. It focusses on parametric synthesis instead of maximum
performance. It uses open source tools for implementation, simulation and test. The original implementation was
done as an assignment on Digital Signal Processors at EAH Jena in 2014/2015.

I/O and pipeline characteristics
========================
The following data input/output relationships are important:

- FFT blocks start on the first clock cycle after deassertion of the reset signal
- On the input, consecutive data windows of FFT length in correct ordering are expected
- Valid output data starts appearing N clock cycles after the first input data block was inserted, where N is
  the number of stages of the FFT (log2 of FFT length)
- After the first intrinsic pipeline delay, output data blocks appear consecutively at the output

Limitations
===========
The design has some limitations which could still be improved:

- Switching between DIF and DIT is done via a generic instead of using different architectures. This is mostly a
  cocotb-related limitation, as the arhictecture can't be selected at build time. Should not impact synthesis.
- The long combinational path in each stage from twiddle factor ROM, through the rotator, butterfly and delay
  line limits the maximum operation frequency somewhat (60 MHz on Cyclone IV). Could be improved by adding more 
  pipelining stages.
