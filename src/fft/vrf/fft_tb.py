import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure, TestSuccess
from cocotb.regression import TestFactory

import numpy.fft as npfft
import numpy.random as nprnd
import numpy as np
import matplotlib.pyplot as plt

@cocotb.coroutine
def init_dut(dut):
    # reset DUT
    dut.clk = 0
    dut.rst = 1

    # create DUT clock
    cocotb.fork(Clock(dut.clk, 10, 'ns').start())

    yield RisingEdge(dut.clk)
    yield RisingEdge(dut.clk)
    dut.rst <= 0

def bitreversed(a):
    n = a.shape[0]
    assert(not n&(n-1) ) # assert that n is a power of 2

    if n == 1:
        yield a[0]
    else:
        even_index = np.arange(n / 2, dtype=int) * 2
        odd_index = np.arange(n / 2, dtype=int) * 2 + 1
        for even in bitreversed(a[even_index]):
            yield even
        for odd in bitreversed(a[odd_index]):
            yield odd

STIM_PULSE = 0
STIM_RANDOM = 1

MODE_FFT = 0
MODE_IFFT = 1

@cocotb.test()
def fft_test(dut, stimulus=STIM_RANDOM, mode=MODE_IFFT, plot=True):
    fft_length = 2 ** dut.length.value.integer
    
    yield init_dut(dut)

    # prepare FFT test vector
    in_range = 0.7 * 2 ** (dut.d_width.value.integer - 1) - 1
    if stimulus == STIM_PULSE:
        in_i = np.zeros(fft_length)
        in_q = np.zeros(fft_length)
        in_i[1] = in_range
        in_q[1] = in_range
    elif stimulus == STIM_RANDOM:
        in_i = nprnd.randint(-in_range, in_range + 1, fft_length)
        in_q = nprnd.randint(-in_range, in_range + 1, fft_length)

    in_iq = in_i + 1j * in_q
    
    # one idle cycle before start of data
    yield RisingEdge(dut.clk)
    
    # apply FFT input
    for inval in in_iq:
        if mode == MODE_FFT:
            dut.d_re <= int(inval.real)
            dut.d_im <= int(inval.imag)
        elif mode == MODE_IFFT:
            dut.d_re <= int(inval.real)
            dut.d_im <= int(-inval.imag)
        yield RisingEdge(dut.clk)
    
    dut.d_re <= 0
    dut.d_im <= 0

    # one idle wait cycle per FFT stage
    for i in range(dut.length.value.integer-1):
        yield RisingEdge(dut.clk)

    # read FFT output
    out_i = np.zeros_like(in_i)
    out_q = np.zeros_like(in_q)
    for i in range(fft_length):
        if mode == MODE_FFT:
            out_i[i] = dut.q_re.value.signed_integer
            out_q[i] = dut.q_im.value.signed_integer
        elif mode == MODE_IFFT:
            out_i[i] = dut.q_re.value.signed_integer
            out_q[i] = -dut.q_im.value.signed_integer
        yield RisingEdge(dut.clk)

    out_iq = np.array(list(bitreversed(out_i + 1j * out_q)))
    if mode == MODE_FFT:
        model_fft = npfft.fft(in_iq)
    elif mode == MODE_IFFT:
        model_fft = npfft.ifft(in_iq) * fft_length

    mean_i = np.mean(model_fft.real - out_iq.real)
    mean_q = np.mean(model_fft.imag - out_iq.imag)

    dut._log.info("In-Phase   Offset error: %.02f LSB", mean_i)
    dut._log.info("Quadrature Offset error: %.02f LSB", mean_q)

    rms_i = np.std(model_fft.real - out_iq.real)
    rms_q = np.std(model_fft.imag - out_iq.imag)

    dut._log.info("In-Phase   RMS error: %.02f LSB", rms_i)
    dut._log.info("Quadrature RMS error: %.02f LSB", rms_q)
    
    gain_err = np.mean(np.abs(model_fft) - np.abs(out_iq))

    dut._log.info("Gain error: %.02f LSB", gain_err)
    
    if plot:
        plt.figure()
        plt.subplot(2, 1, 1)
        plt.plot(model_fft.real)
        plt.plot(out_iq.real)
        plt.ylabel("In-Phase")
        plt.xlabel("Frequency [samples]")

        plt.subplot(2, 1, 2)
        plt.plot(model_fft.imag)
        plt.plot(out_iq.imag)
        plt.ylabel("Quadrature")
        plt.xlabel("Frequency [samples]")
        
        plt.figure()
        plt.subplot(2, 1, 1)
        plt.plot(np.abs(model_fft))
        plt.plot(np.abs(out_iq))
        plt.ylabel("Magnitude")
        plt.xlabel("Frequency [samples]")
        
        plt.subplot(2, 1, 2)
        plt.plot(np.arctan2(model_fft.imag, model_fft.real))
        plt.plot(np.arctan2(out_iq.imag, out_iq.real))
        plt.ylabel("Phase")
        plt.xlabel("Frequency [samples]")

        plt.show()
