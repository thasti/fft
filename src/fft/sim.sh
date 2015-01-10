#!/bin/bash

TIME=100us
UNIT=fft_tb
ghdl --clean
ghdl -a ../counter/counter.vhd
ghdl -a ../butterfly/butterfly.vhd
ghdl -a ../delayline/delayline.vhd
ghdl -a ../rotator/rotator.vhd
ghdl -a ../twiddle_rom/twiddle_rom.vhd
ghdl -a fft.vhd
ghdl -a $UNIT.vhd
ghdl -e $UNIT
ghdl -m $UNIT 

echo "[ TIME SIMULATION ]";
ghdl -r $UNIT --wave=output.ghw  --stop-time=$TIME
gtkwave output.ghw gtkwave.sav
ghdl --clean
