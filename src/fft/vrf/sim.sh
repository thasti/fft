#!/bin/bash

TIME=200us
UNIT=fft_tb
ghdl --clean
ghdl -a ../../counter/rtl/counter.vhd
ghdl -a ../../butterfly/rtl/butterfly.vhd
ghdl -a ../../delayline/rtl/delayline.vhd
ghdl -a ../../rotator/rtl/rotator.vhd
ghdl -a ../../twiddle_rom/rtl/twiddle_rom.vhd
ghdl -a ../rtl/fft.vhd
ghdl -a $UNIT.vhd
ghdl -e $UNIT
ghdl -m $UNIT 

echo "[ TIME SIMULATION ]";
ghdl -r $UNIT --wave=output.ghw  --stop-time=$TIME
gtkwave output.ghw gtkwave.sav
ghdl --clean
