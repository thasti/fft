% Implementation of Radix-2-FFT and IFFT in VHDL
%
% Stefan Biereigel

# Motivation
The FFT is a transformation used in a variety of signal-processing contexts, including but not limited to filtering, spectral shaping, modulations such as OFDM, signal analysis etc. As it seemed like an interesting topic, the goal was set to implement an efficient DFT algorithm, namely the Radix-2-FFT in VHDL for use in FPGA designs with Altera FPGAs.

# Roadmap
As FFT up to now was mainly used in pre-built functions such as Matlab's fft() and ifft(), it was first to be examined how a DFT is to be implemented algorithmically. After successful implementation and functional verification by comparing results with the known functions, the FFT algorithm could be looked at. This algorithm was also implemented and tested on the PC first, to verify correct function. After this was done, a concept for implementation in VHDL (with focus on resource-efficient synthesis on Altera FPGAs) could be developed.
Because multiplications can't be avoided and are expensive to realise in hardware, the DSP-units of the FPGA should be used efficiently. Therefore, the different existing efficient FFT schemes were analysed and a suitable compromise was chosen.

# Test and Verification
In the process of implementation, the following steps to ensure functional correctness were taken:

* Research on the topic of DFT and FFT
* Re-Implement the Matlab builtin functions fft() and ifft()
    * first as generic (inefficient) DFT algorithm
    * afterwards as fast (efficient) FFT algorithm
    * test the results against the builtin functions
* Matlab implementation of efficient FFT scheme for translation into VHDL
* VHDL implementation
* test against Matlab implementation

# Radix-2 FFT
Compared to the regular DFT, the Radix-2 FFT saves a lot of computation with usage of the Danielson-Lanczos lemma, which states that a DFT of length N can be divided into two DFTs of length N/2 - the odd and the even indexed elements of the input. When this rule is applied until N DFTs of length 1 are left, the DFT is trivial to implement. When stopping at N/2 DFTs of length 2, the classic Radix-2 FFT is acheived. A single 2-point DFT can be computed by a simple equation - shown as the butterfly graph below.
**TODO Grafik Butterfly 2**
When raising N from 2 to 4 samples, two stages of two butterflies each are needed. The first stages computes the DFT of the two vectors containing 2 samples each, the second stage combines the results in another two length-2-DFTs to produce the DFT result of the 4 element vector.
**TODO Grafik Butterfly 4**
Notice the Input element indices. This ordering comes from successive use of even and odd numbered elements for the smaller FFTs. What it represents after any number of stages is called "reverse bit ordering". While the output sample indices count up (00=0, 01=1, 10=2, 11=3), the input samples use reversed bit ordering, meaning 00=0, 10=2, 01=1, 11=3 - which makes it easy to get samples from e.g. a RAM. The corresponding address counter has to count up, but its output vector has to be bit order reversed and then connected to the address bus of the RAM.

# Resource-Efficient, streamed Implementation
We assume the elements for which the FFT should be computed are input in a serial fashion, one after the other. Every new sample enables some operations to be performed and another sample to be output. This implies that the amount of registers and DSP elements can be reduced to the amount neccesary for storing all information needed in later stages. As the "lower" elements of the length-2-FFTs have to be multiplied by the so called twiddle factor, additional logic keeps track of the current input sample and applies the neccesary factors.
As can be seen, not the full complexity as in the graphic above has to be implemented in a streamed FFT implementation. Only a small fraction is needed, as calculation elements from the first stage are only needed for a short time, namely the multiplication of two consecutive samples, etc.
There exist a variety of more or less efficient pipelined FFT algorithms. As a good initial tradeoff between resource usage and description complexity, the Radix-2 single path delay feedback architecture was chosen.

# Interface specification
As the FFT should be streamed, only one input sample is input at every clock cycle. After running through the processing stages, one output sample is output. The input and output signals are of complex data type, real and imaginary components can be input on different signals. To temporarily halt operation of the FFT processing, a d\_valid signal is used, which has to be asserted to indicate valid data on the input.

This results in the following interface specification:

* Inputs
    * clock -		System clock
    * reset -		resetting the internal logic to a point where sample 0 can be input afterwards
    * d\_real -		real part of input sample
    * d\_imag -		imaginary part of input sample
    * d\_valid -	indicates valid data on d\_real and d\_imag
* Outputs
    * q\_real -		real part of output sample
    * q\_imag -		imaginary part of output sample
    * q\_first -	indicating the sample corresponding to index 0 is valid on the output
    * q\_valid -	indicates validity of the data on the outputs

# VHDL entities
The design is composed of small subunits, which are connected together in the top level entitity _fft.vhd_.

* FIFO
    * Implementing a variable-size, variable-width first-in-first-out buffer. Each processing stage needs one of these.
* Butterfly
    * The main processing unit, having two complex inputs and outputs, and one control signal to change the data flow inside the butterfly
* Twiddle factor ROM
    * Instantiates a ROM for the complex twiddle factor. Can either store the multiplication factors or just the angles for a CORDIC rotation computation implementation.


