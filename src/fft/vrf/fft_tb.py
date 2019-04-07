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

@cocotb.test()
def fft_test(dut):
    fft_length = 2 ** dut.length.value.integer
    
    yield init_dut(dut)

    # prepare FFT test vector
    in_range = 0.5 * 2 ** (dut.d_width.value.integer - 1) - 1
    in_i = nprnd.randint(-in_range, in_range, fft_length)
    in_q = nprnd.randint(-in_range, in_range, fft_length)
    in_iq = in_i + 1j * in_q
    
    # apply FFT input
    for inval in in_iq:
        dut.d_re <= int(inval.real)
        dut.d_im <= int(inval.imag)
        yield RisingEdge(dut.clk)
    
    dut.d_re <= 0
    dut.d_im <= 0

    # one wait cycle per FFT stage
    for i in range(dut.length.value.integer):
        yield RisingEdge(dut.clk)

    # read FFT output
    out_i = np.zeros_like(in_i)
    out_q = np.zeros_like(in_q)
    for i in range(fft_length):
        out_i[i] = dut.q_re.value.signed_integer
        out_q[i] = dut.q_im.value.signed_integer
        yield RisingEdge(dut.clk)

    model_fft = npfft.fft(in_iq)
    for sample in zip(model_fft.real, bitreversed(out_i)):
        print(sample)

    plt.subplot(3, 1, 1)
    plt.plot(model_fft.real)
    plt.plot(list(bitreversed(out_i)))

    plt.subplot(3, 1, 2)
    plt.plot(model_fft.imag)
    plt.plot(list(bitreversed(out_q)))
    
    plt.subplot(3, 1, 3)
    plt.plot(np.abs(model_fft))
    plt.plot(list(bitreversed(np.sqrt(out_i**2 + out_q**2))))
    

    plt.show()


