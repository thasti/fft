export USER_DIR:=$(shell pwd)

TOPLEVEL_LANG=vhdl
TOPLEVEL=fft
MODULE=fft_tb
SIM=ghdl

VHDL_SOURCES =$(PWD)/../../counter/rtl/counter.vhd
VHDL_SOURCES+=$(PWD)/../../butterfly/rtl/butterfly.vhd
VHDL_SOURCES+=$(PWD)/../../delayline/rtl/delayline.vhd
VHDL_SOURCES+=$(PWD)/../../rotator/rtl/rotator.vhd
VHDL_SOURCES+=$(PWD)/../../twiddle_rom/rtl/twiddle_rom.vhd
VHDL_SOURCES+=$(PWD)/../rtl/fft.vhd

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim

