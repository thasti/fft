-- sine / cosine unit
-- 
-- clk  	main clock input
-- arg		argument to sine and cosine
-- sin		sine output
-- cos		cosine output

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity twiddle_rom is
	generic (
		inwidth : integer := 12;
		outwidth: integer := 10
	);

	port (
		clk	: in std_logic;
		arg	: in std_logic_vector(inwidth-1 downto 0);
		q_sin	: out std_logic_vector(outwidth-1 downto 0);
		q_cos 	: out std_logic_vector(outwidth-1 downto 0)
	);
end twiddle_rom;

architecture rtl of twiddle_rom is
	constant rom_length 	: integer := (2**(inwidth-1));
	constant rom_max 	: integer := 2**outwidth;

	-- sine rom saves 1 quadrant of sine
	-- upper two bits of arg are used to determine quadrant
	type rom_t is array(0 to rom_length-1) of signed(outwidth-1 downto 0);
	signal sin_rom 		: rom_t;
	signal cos_rom 		: rom_t;
	signal address		: std_logic_vector(inwidth-2 downto 0);

	signal output_sin	: std_logic_vector(outwidth-1 downto 0);
	signal output_cos	: std_logic_vector(outwidth-1 downto 0);
	signal sign		: std_logic;
begin

	table : for i in 0 to rom_length-1 generate
		sin_rom(i) <= to_signed(integer(
			sin(MATH_2_PI * real(i) / real(rom_length*2)) * (real(rom_max)/2.0-1.0)
			), outwidth);
		cos_rom(i) <= to_signed(integer(
			cos(MATH_2_PI * real(i) / real(rom_length*2)) * (real(rom_max)/2.0-1.0)
			), outwidth);
	end generate;


	output_sin <= std_logic_vector(sin_rom(to_integer(unsigned(address))));
	output_cos <= std_logic_vector(cos_rom(to_integer(unsigned(address))));

	q_sin <=	output_sin when sign = '0' else
			std_logic_vector(to_signed(0, output_sin'length) - signed(output_sin));
	q_cos <=	output_cos when sign = '0' else
			std_logic_vector(to_signed(0, output_sin'length) - signed(output_cos));

	output : process
	begin
		wait until rising_edge(clk);
		address <= arg(inwidth-2 downto 0);
		sign <= arg(inwidth-1);
	end process;
end rtl;

