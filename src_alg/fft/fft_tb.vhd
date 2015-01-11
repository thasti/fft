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
		length => 3
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
	variable li : line;
	file input_file : text is in "fft_stimulus.txt";
begin
	wait until rising_edge(clk);
	wait until falling_edge(rst);
	wait until rising_edge(clk);
	while not endfile(input_file) loop
		report "Feeding input sample ...";
		readline(input_file, li);
		read(li, dre);
		read(li, dim);
		report "Re: " & real'image(dre) & " Im: " & real'image(dim);

		d_re <= dre;
		d_im <= dim;
		wait until rising_edge(clk);
		report "... done.";

	end loop;
	wait;
end process;

process
	variable i : integer := 0;
	variable lo : line;
	variable space : character := ' ';
	file output_file : text is out "fft_output.txt";
begin
	wait until rising_edge(clk);
	if q_re < 1000000.0 and q_re > -1000000.0 then
		write(lo, real'image(q_re));
		write(lo, space);
		write(lo, real'image(q_im));
		writeline(output_file, lo);
	end if;
end process;

end tb;

