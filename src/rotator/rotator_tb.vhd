library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity rotator_tb is
end rotator_tb;

architecture tb of rotator_tb is
	constant iowidth : integer := 8;

	signal clk	: std_logic := '0';
	signal i_re	: std_logic_vector(iowidth-1 downto 0);
	signal i_im	: std_logic_vector(iowidth-1 downto 0);
	signal tf_re	: std_logic_vector(iowidth-1 downto 0);
	signal tf_im	: std_logic_vector(iowidth-1 downto 0);
	signal o_re	: std_logic_vector(iowidth-1 downto 0);
	signal o_im	: std_logic_vector(iowidth-1 downto 0);

begin
	dut : entity work.rotator
	generic map (
		iowidth => 8
	)
	port map (
		clk => clk,
		i_re => i_re,
		i_im => i_im,
		tf_re => tf_re,
		tf_im => tf_im,
		o_re => o_re,
		o_im => o_im
	);

	clk <= not clk after 100 ns;

process
	variable ire : integer;
	variable iim : integer;
	variable tfre : integer;
	variable tfim : integer;
	variable l : line;
	variable res_re : integer;
	variable res_im : integer;
	file input_file : text is in "rotator_stimulus.txt";
begin
	wait until rising_edge(clk);
	while not endfile(input_file) loop
		report "Running test case ...";
		readline(input_file, l);
		read(l, ire);
		read(l, iim);
		read(l, tfre);
		read(l, tfim);
		report "Data: Re: " & integer'image(ire) & " Im: " & integer'image(iim) & " - TF: Re: "
		& integer'image(tfre) & " Im: " & integer'image(tfim);

		i_re <= std_logic_vector(to_signed(ire,iowidth));
		i_im <= std_logic_vector(to_signed(iim,iowidth));
		tf_re <= std_logic_vector(to_signed(tfre,iowidth));
		tf_im <= std_logic_vector(to_signed(tfim,iowidth));

		-- apply Q0.7 multiplication
		res_re := ((ire * tfre) - (iim * tfim))/64;
		res_im := ((ire * tfim) + (iim * tfre))/64;

		-- apply division by two because of bit growth in addition
		res_re := res_re / 2;
		res_im := res_im / 2;
		wait until rising_edge(clk);
		wait until falling_edge(clk);
		-- check result
		assert to_integer(signed(o_re)) = res_re
		report "Real output incorrect. "
		& "Expected: " & integer'image(res_re) & " Got: " & integer'image(to_integer(signed(o_re)))
		severity failure;
		assert to_integer(signed(o_im)) = res_im
		report "Imaginary output incorrect. "
		& "Expected: " & integer'image(res_im) & " Got: " & integer'image(to_integer(signed(o_im)))
		severity failure;

		report "... done.";

	end loop;
	wait;
end process;

end tb;

