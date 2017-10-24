library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity fft_tb is
end fft_tb;

architecture tb of fft_tb is
	constant d_width : integer := 8;
	constant length : integer := 8;

	signal clk	: std_logic := '0';
	signal rst	: std_logic := '1';
	signal d_re	: std_logic_vector(d_width-1 downto 0);
	signal d_im	: std_logic_vector(d_width-1 downto 0);
	signal q_re	: std_logic_vector(d_width+length-1 downto 0);
	signal q_im	: std_logic_vector(d_width+length-1 downto 0);

begin
	dut : entity work.fft
	generic map (
		d_width => d_width,
		tf_width => 14,
		length => length
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

read_input : process
	variable dre : integer;
	variable dim : integer;
	variable qre : integer;
	variable qim : integer;
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
		report "Re: " & integer'image(dre) & " Im: " & integer'image(dim);

		d_re <= std_logic_vector(to_signed(dre,d_width));
		d_im <= std_logic_vector(to_signed(dim,d_width));
		wait until rising_edge(clk);
		report "... done.";

	end loop;
	wait;
end process;

write_output : process
	variable i : integer := 0;
	variable lo : line;
	variable space : character := ' ';
	file output_file : text is out "fft_output.txt";
begin
	wait until rising_edge(clk);
	i := i + 1;
	-- write out only one block of samples
	-- (account for the stage-induced register delay here)
	if (i > ((2**length)+length) and i < 2**(length+1)+length+1) then
		write(lo, to_integer(signed(q_re)));
		write(lo, space);
		write(lo, to_integer(signed(q_im)));
		writeline(output_file, lo);
	end if;
end process;

end tb;

