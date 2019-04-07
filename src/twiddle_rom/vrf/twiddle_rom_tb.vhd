library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity twiddle_rom_tb is
end twiddle_rom_tb;

architecture behav of twiddle_rom_tb is
	signal clk	: std_logic := '0';
	signal ctl	: std_logic := '0';
	signal arg	: std_logic_vector(0 downto 0) := (others => '0');
	signal q_sin	: std_logic_vector(7 downto 0);
	signal q_cos	: std_logic_vector(7 downto 0);

begin
	dut : entity work.twiddle_rom
	generic map (
		exponent => 3,
		inwidth => 1,
		outwidth => 8
	)
	port map (
		clk => clk,
		ctl => ctl,
		arg => arg,
		q_sin => q_sin,
		q_cos => q_cos
	);
	clk <= not clk after 50 ns;

	process
	begin
		wait until rising_edge(clk);
		arg <= std_logic_vector(unsigned(arg) + to_unsigned(1, 1));
	end process;
end behav;
