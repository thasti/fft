library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity fft_tb is
end fft_tb;

architecture tb of fft_tb is
	constant iowidth : integer := 8;

	signal clk	: std_logic := '0';
	signal rst	: std_logic := '1';
	signal d_re	: real;
	signal d_im	: real;
	signal q_re	: real;
	signal q_im	: real;

begin
	dut : entity work.fft
	generic map (
		length => 2
	)
	port map (
		clk => clk,
		rst => rst,
		d_re => d_re,
		d_im => d_im,
		q_re => q_re,
		q_im => q_im
	);

	clk <= not clk after 100 ns;
	rst <= '0' after 200 ns;

process
	variable dre : real;
	variable dim : real;
	variable qre : real;
	variable qim : real;
	variable l : line;
	file input_file : text is in "fft_stimulus.txt";
begin
	wait until rising_edge(clk);
	wait until falling_edge(rst);
	wait until rising_edge(clk);
	while not endfile(input_file) loop
		report "Feeding input sample ...";
		readline(input_file, l);
		read(l, dre);
		read(l, dim);
		report "Re: " & real'image(dre) & " Im: " & real'image(dim);

		d_re <= dre;
		d_im <= dim;
		wait until rising_edge(clk);
		report "... done.";

	end loop;
	wait;
end process;

end tb;

