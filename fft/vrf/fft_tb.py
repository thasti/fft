import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure, TestSuccess
from cocotb.regression import TestFactory
from enum import Enum, auto
from collections import deque

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

class FFTStimulus(Enum):
    STIM_PULSE = auto()
    STIM_RANDOM = auto()
    STIM_DC = auto()
    STIM_SIN = auto()
    STIM_COS = auto()
    STIM_EXP = auto()

class FFTMode(Enum):
    MODE_FFT = auto()
    MODE_IFFT = auto()

class FFTTestBench:
    def __init__(self, dut, stimulus, mode, plot, error_spec_lsb, num_ffts):
        self.dut = dut
        self.fft_inputs = deque()
        self.stimulus = stimulus
        self.mode = mode
        self.num_ffts = num_ffts
        self.error_spec_lsb = error_spec_lsb
        self.fft_length = 2 ** dut.length.value.integer
        self.plot = plot

    @cocotb.coroutine
    def drive_fft(self):
        for fft_count in range(self.num_ffts):
            # prepare FFT test vector
            in_range = 0.707 * 2 ** (self.dut.d_width.value.integer - 1) - 1
            if self.stimulus == FFTStimulus.STIM_PULSE:
                in_i = np.zeros(self.fft_length)
                in_q = np.zeros(self.fft_length)
                pulse_idx = nprnd.randint(0, self.fft_length)
                in_i[pulse_idx] = in_range
                in_q[pulse_idx] = in_range
            elif self.stimulus == FFTStimulus.STIM_RANDOM:
                in_i = nprnd.randint(-in_range, in_range + 1, self.fft_length)
                in_q = nprnd.randint(-in_range, in_range + 1, self.fft_length)
            elif self.stimulus == FFTStimulus.STIM_DC:
                in_i = int(fft_count / (self.num_ffts - 1) * in_range) * np.ones(self.fft_length)
                in_q = np.zeros(self.fft_length)
            elif self.stimulus == FFTStimulus.STIM_SIN:
                num_periods = nprnd.randint(1, 20)
                in_i = in_range * np.sin(np.linspace(0, num_periods * 2 * np.pi, self.fft_length, endpoint=False))
                in_q = np.zeros(self.fft_length)
            elif self.stimulus == FFTStimulus.STIM_COS:
                num_periods = nprnd.randint(1, 20)
                in_i = in_range * np.cos(np.linspace(0, num_periods * 2 * np.pi, self.fft_length, endpoint=False))
                in_q = np.zeros(self.fft_length)
            elif self.stimulus == FFTStimulus.STIM_EXP:
                num_periods = nprnd.randint(1, 20)
                in_i = in_range * np.sin(np.linspace(0, num_periods * 2 * np.pi, self.fft_length, endpoint=False))
                in_q = in_range * np.cos(np.linspace(0, num_periods * 2 * np.pi, self.fft_length, endpoint=False))

            in_iq = np.around(in_i + 1j * in_q)
            self.fft_inputs.append(in_iq)

            # apply FFT input
            if self.dut.mode_dit.value.integer:
                # DIT: bit-reversed input order
                in_iq_dut = np.array(list(bitreversed(in_iq)))
            else:
                # DIF: natural input order
                in_iq_dut = in_iq

            for inval in in_iq_dut:
                if self.mode == FFTMode.MODE_FFT:
                    self.dut.d_re <= int(inval.real)
                    self.dut.d_im <= int(inval.imag)
                elif self.mode == FFTMode.MODE_IFFT:
                    self.dut.d_re <= int(inval.real)
                    self.dut.d_im <= int(-inval.imag)
                yield RisingEdge(self.dut.clk)
            
            self.dut.d_re <= 0
            self.dut.d_im <= 0

    @cocotb.coroutine
    def read_fft(self):
        errors = False
        # first fill FFT pipeline
        for i in range(self.fft_length):
            yield RisingEdge(self.dut.clk)

        # one additional pipeline cycle per FFT stage
        for i in range(self.dut.length.value.integer-1):
            yield RisingEdge(self.dut.clk)

        for fft_count in range(self.num_ffts):
            # read FFT output
            out_i = np.zeros(self.fft_length)
            out_q = np.zeros(self.fft_length)
            for i in range(self.fft_length):
                if self.mode == FFTMode.MODE_FFT:
                    out_i[i] = self.dut.q_re.value.signed_integer
                    out_q[i] = self.dut.q_im.value.signed_integer
                elif self.mode == FFTMode.MODE_IFFT:
                    out_i[i] = self.dut.q_re.value.signed_integer
                    out_q[i] = -self.dut.q_im.value.signed_integer
                yield RisingEdge(self.dut.clk)

            if self.dut.mode_dit.value.integer:
                # DIT: natural output order
                out_iq = out_i + 1j * out_q
            else:
                # DIF: bit-reversed output order
                out_iq = np.array(list(bitreversed(out_i + 1j * out_q)))

            in_iq = self.fft_inputs.popleft()
            if self.mode == FFTMode.MODE_FFT:
                model_fft = npfft.fft(in_iq)
            elif self.mode == FFTMode.MODE_IFFT:
                model_fft = npfft.ifft(in_iq) * self.fft_length

            mean_i = np.mean(model_fft.real - out_iq.real)
            mean_q = np.mean(model_fft.imag - out_iq.imag)

            self.dut._log.info("In-Phase   Offset error: %.02f LSB", mean_i)
            self.dut._log.info("Quadrature Offset error: %.02f LSB", mean_q)

            rms_i = np.std(model_fft.real - out_iq.real)
            rms_q = np.std(model_fft.imag - out_iq.imag)

            self.dut._log.info("In-Phase   RMS error: %.02f LSB", rms_i)
            self.dut._log.info("Quadrature RMS error: %.02f LSB", rms_q)
            
            gain_err = np.mean(np.abs(model_fft) - np.abs(out_iq))

            self.dut._log.info("Gain error: %.02f LSB", gain_err)

            if abs(mean_i) > self.error_spec_lsb["offset"] or abs(mean_q) > self.error_spec_lsb["offset"]:
                errors = True

            if rms_i > self.error_spec_lsb["rms"] or rms_q > self.error_spec_lsb["rms"]:
                errors = True

            if abs(gain_err) > self.error_spec_lsb["gain"]:
                errors = True
            
            if self.plot:
                plt.figure()
                plt.subplot(2, 2, 1)
                plt.plot(model_fft.real)
                plt.plot(out_iq.real)
                plt.grid()
                plt.ylabel("In-Phase")
                plt.xlabel("Frequency [samples]")

                plt.subplot(2, 2, 2)
                plt.plot(model_fft.imag)
                plt.plot(out_iq.imag)
                plt.grid()
                plt.ylabel("Quadrature")
                plt.xlabel("Frequency [samples]")

                plt.subplot(2, 2, 3)
                plt.plot(np.abs(model_fft))
                plt.plot(np.abs(out_iq))
                plt.grid()
                plt.ylabel("Magnitude")
                plt.xlabel("Frequency [samples]")
                
                plt.subplot(2, 2, 4)
                plt.plot(np.arctan2(model_fft.imag, model_fft.real))
                plt.plot(np.arctan2(out_iq.imag, out_iq.real))
                plt.grid()
                plt.ylabel("Phase")
                plt.xlabel("Frequency [samples]")
                plt.tight_layout()

                plt.show()

        if errors:
            raise TestFailure("Error bounds exceeded.")
        else:
            raise TestSuccess("Test finished OK.")

    def start(self):
        self.drive_coro = cocotb.fork(self.drive_fft())
        self.read_coro = cocotb.fork(self.read_fft())

    @cocotb.coroutine
    def join(self):
        yield self.drive_coro.join()
        yield self.read_coro.join()

@cocotb.coroutine
def fft_test(dut, stimulus=FFTStimulus.STIM_SIN, mode=FFTMode.MODE_FFT, plot=False):
    error_spec = {}
    error_spec["offset"] = 3
    error_spec["rms"] = 6
    error_spec["gain"] = 3
    tb = FFTTestBench(dut, stimulus, mode, plot, error_spec_lsb=error_spec, num_ffts=10)    

    yield init_dut(dut)
    tb.start()
    yield tb.join()

tf = TestFactory(fft_test)
tf.add_option("stimulus", FFTStimulus)
tf.add_option("mode", FFTMode)
tf.generate_tests()
