#!/bin/bash

TIME=1ms
UNIT=twiddle_rom_tb
ghdl --clean
ghdl -a ../rtl/twiddle_rom.vhd
ghdl -a $UNIT.vhd
ghdl -e $UNIT
ghdl -m $UNIT 

echo "[ TIME SIMULATION ]";
ghdl -r $UNIT --wave=output.ghw  --stop-time=$TIME
gtkwave output.ghw gtkwave.sav
ghdl --clean
