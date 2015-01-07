library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity delayline_tb is
end delayline_tb;

architecture behav of delayline_tb is

	signal clk	: std_logic := '0';
	signal d	: std_logic_vector (7 downto 0) := (others=>'0');
	signal q	: std_logic_vector (7 downto 0) := (others=>'0');
begin
	dut : entity work.delayline
	generic map (
		delay => 4,	-- 16 samples delay
		iowidth => 8
	)
	port map (
		clk => clk,
		d => d,
		q => q
	);
	clk <= not clk after 50 ns;

	process
	begin
		wait until rising_edge(clk);
		d <= std_logic_vector(unsigned(d) + 1);
	end process;
end behav;
