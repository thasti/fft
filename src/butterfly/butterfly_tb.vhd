library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity butterfly_tb is
end butterfly_tb;

architecture tb of butterfly_tb is
	constant iowidth : integer := 8;

	signal clk	: std_logic := '0';
	signal ctl	: std_logic := '0';
	signal iu_re	: std_logic_vector(iowidth-1 downto 0);
	signal iu_im	: std_logic_vector(iowidth-1 downto 0);
	signal il_re	: std_logic_vector(iowidth-1 downto 0);
	signal il_im	: std_logic_vector(iowidth-1 downto 0);
	signal ou_re	: std_logic_vector(iowidth-1 downto 0);
	signal ou_im	: std_logic_vector(iowidth-1 downto 0);
	signal ol_re	: std_logic_vector(iowidth-1 downto 0);
	signal ol_im	: std_logic_vector(iowidth-1 downto 0);

begin
	dut : entity work.butterfly
	generic map (
		iowidth => 8
	)
	port map (
		clk => clk,
		ctl => ctl,
		iu_re => iu_re,
		iu_im => iu_im,
		il_re => il_re,
		il_im => il_im,
		ou_re => ou_re,
		ou_im => ou_im,
		ol_re => ol_re,
		ol_im => ol_im
	);

	clk <= not clk after 100 ns;

process
	variable ure : integer;
	variable uim : integer;
	variable lre : integer;
	variable lim : integer;
	variable l : line;
	file input_file : text is in "butterfly_stimulus.txt";
begin
	wait until rising_edge(clk);
	while not endfile(input_file) loop
		report "Running test case ...";
		readline(input_file, l);
		read(l, ure);
		read(l, uim);
		read(l, lre);
		read(l, lim);
		report "Upper: Re: " & integer'image(ure) & " Im: " & integer'image(uim) & " - Lower: Re: "
		& integer'image(lre) & " Im: " & integer'image(lim);

		ctl <= '0';
		iu_re <= std_logic_vector(to_signed(ure,iowidth));
		iu_im <= std_logic_vector(to_signed(uim,iowidth));
		il_re <= std_logic_vector(to_signed(lre,iowidth));
		il_im <= std_logic_vector(to_signed(lim,iowidth));
		wait until rising_edge(clk);
		wait until falling_edge(clk);
		-- check result
		assert to_integer(signed(ou_re)) = (ure)
		report "Upper real output incorrect. (ctl=0) "
		& "Expected: " & integer'image(ure) & " Got: " & integer'image(to_integer(signed(ou_re)))
		severity failure;
		assert to_integer(signed(ou_im)) = (uim)
		report "Upper imaginary output incorrect. (ctl=0) "
		& "Expected: " & integer'image(uim) & " Got: " & integer'image(to_integer(signed(ou_im)))
		severity failure;
		assert to_integer(signed(ol_re)) = (lre)
		report "Lower real output incorrect. (ctl=0) "
		& "Expected: " & integer'image(lre) & " Got: " & integer'image(to_integer(signed(ol_re)))
		severity failure;
		assert to_integer(signed(ol_im)) = (lim)
		report "Lower imaginary output incorrect. (ctl=0) "
		& "Expected: " & integer'image(lim) & " Got: " & integer'image(to_integer(signed(ol_im)))
		severity failure;

		ctl <= '1';
		wait until rising_edge(clk);
		wait until falling_edge(clk);
		-- check result
		assert to_integer(signed(ou_re)) = ((ure + lre)/2)
		report "Upper real output incorrect. (ctl=1) "
		& "Expected: " & integer'image((ure + lre)/2) & " Got: " & integer'image(to_integer(signed(ou_re)))
		severity failure;
		assert to_integer(signed(ou_im)) = ((uim + lim)/2)
		report "Upper imaginary output incorrect. (ctl=1) "
		& "Expected: " & integer'image((uim + lim)/2) & " Got: " & integer'image(to_integer(signed(ou_im)))
		severity failure;
		assert to_integer(signed(ol_re)) = ((ure - lre)/2)
		report "Lower real output incorrect. (ctl=1) "
		& "Expected: " & integer'image((ure - lre)/2) & " Got: " & integer'image(to_integer(signed(ol_re)))
		severity failure;
		assert to_integer(signed(ol_im)) = ((uim - lim)/2)
		report "Lower imaginary output incorrect. (ctl=1) "
		& "Expected: " & integer'image((uim - lim)/2) & " Got: " & integer'image(to_integer(signed(ol_im)))
		severity failure;

		report "... done.";

	end loop;
	wait;
end process;

end tb;

