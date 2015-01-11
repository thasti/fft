-- Twiddle Factor generator
-- for a given N-element-FFT the Twiddle Factors for every stage can be computed
--
-- generics:
--  exponent	exponent of the length of the FFT (N=8 -> exponent = 3 (2^3 = 8)
--  inwidth	number of address pins (-> ROM length)
--  outwidth	width of the twiddle factors
--
-- ports:
--  clk  	main clock input
--  ctl		enable/disable twiddle rom - use 1 + 0j when ctl=0 (rom disabled)
--  arg		argument to sine and cosine
--  sin		sine output (imaginary part of TF)
--  cos		cosine output (real part of TF)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity twiddle_rom is
	generic (
		exponent: integer := 3;
		inwidth : integer := 2;
		outwidth: integer := 10
	);

	port (
		clk	: in std_logic;
		ctl	: in std_logic;
		arg	: in std_logic_vector(inwidth-1 downto 0);
		q_sin	: out std_logic_vector(outwidth-1 downto 0);
		q_cos 	: out std_logic_vector(outwidth-1 downto 0)
	);
end twiddle_rom;

architecture rtl of twiddle_rom is
	constant rom_length 	: integer := (2**inwidth);
	constant rom_max 	: integer := 2**outwidth;

	-- sine rom saves 1 quadrant of sine
	-- upper two bits of arg are used to determine quadrant
	type rom_t is array(0 to rom_length-1) of signed(outwidth-1 downto 0);
	signal sin_rom 		: rom_t;
	signal cos_rom 		: rom_t;
	signal address		: std_logic_vector(inwidth-1 downto 0);

	signal output_sin	: std_logic_vector(outwidth-1 downto 0);
	signal output_cos	: std_logic_vector(outwidth-1 downto 0);
begin

	-- twiddle factors: W^k_N = exp(j*2*pi*k/N)
	-- where k:
	--  (0,1,..,N/2-1) for first stage (N/2 factors, exponent = inwidth-1)
	--  (0,2,..,N/2-1) for second stage (N/4 factors, exponent = inwidth-2)
	--  (0,4,..,N/2-1) for third stage (N/8 factors, exponent = inwidth-3)
	table : for i in 0 to rom_length-1 generate
		sin_rom(i) <= to_signed(integer(
			-sin(MATH_2_PI * real((2**(exponent-inwidth-1))*i) / real(2**exponent)) * (real(rom_max)/2.0-1.0)
			), outwidth);
		cos_rom(i) <= to_signed(integer(
			cos(MATH_2_PI * real((2**(exponent-inwidth-1))*i) / real(2**exponent)) * (real(rom_max)/2.0-1.0)
			), outwidth);
	end generate;


	output_sin <= std_logic_vector(sin_rom(to_integer(unsigned(address))));
	output_cos <= std_logic_vector(cos_rom(to_integer(unsigned(address))));

	q_sin <=	output_sin when ctl = '0' else
			(others => '0'); -- imaginary part = 0


	q_cos <=	output_cos when ctl = '0' else
			'0' & std_logic_vector(to_signed(-1, q_cos'length-1)); -- real part = +1

	output : process
	begin
		wait until rising_edge(clk);
		address <= std_logic_vector(unsigned(arg(inwidth-1 downto 0)) + to_unsigned(1, inwidth));
	end process;
end rtl;

