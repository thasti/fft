-- delay line
-- Implements a sample delay of N/2 samples
-- Can be used with >= 2 samples delay.
-- Adapted from fifo.vhd by Sebastian Weiss, DL3YC
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity delayline is
	generic
	(
		delay	: positive     	:= 8;                  -- FIFO Depth (as exponent to 2^n)
		iowidth	: positive      := 8
	);

	port
	(
		clk     : in std_logic;                                 -- System Clock

		d       : in std_logic_vector(iowidth-1 downto 0);   -- Input Data
		q       : out std_logic_vector(iowidth-1 downto 0)  -- Output Data
	);
end entity;

architecture behavioral of delayline is
type mem_type is array(integer(2.0**real(delay))-1 downto 0) of std_logic_vector(iowidth-1 downto 0);
signal mem:             mem_type := (others => (others => '0'));
signal read_adr:        unsigned(delay-1 downto 0) := (others => '0');
signal write_adr:       unsigned(delay-1 downto 0) := (others => '1');
begin
	process
	begin
		wait until rising_edge(clk);
		mem(to_integer(write_adr)) <= d;
		write_adr <= write_adr + 1;
		read_adr <= read_adr + 1;
		q <= mem(to_integer(read_adr));
	end process;

end behavioral;
