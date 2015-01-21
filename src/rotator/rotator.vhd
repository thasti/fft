-- dynamic complex rotator for FFT operation
-- Implements the Complex Number Rotator needed for R2SDF pipelined FFT
-- first implementation uses regular multiplier, but could also be implemented as CORDIC
-- Author: Stefan Biereigel

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rotator is
	generic (
		-- input bit width
		d_width		: positive := 8;
		tf_width	: positive := 8
	);

	port (
		clk		: in std_logic;
		i_re		: in std_logic_vector(d_width-1 downto 0);
		i_im		: in std_logic_vector(d_width-1 downto 0);
		tf_re		: in std_logic_vector(tf_width-1 downto 0);
		tf_im		: in std_logic_vector(tf_width-1 downto 0);
		o_re		: out std_logic_vector(d_width-1 downto 0);
		o_im		: out std_logic_vector(d_width-1 downto 0)
	);
end rotator;

-- complex multiplication is formulated as
--  A+jB * C + jD
-- can be realised as
--  (A*C) - (B*D) + j[(A*D) + (B*C)] (four multiplies, two additions)
-- or possibly as
--  (A*C) - (B*D) + j[(A+B)*(C+D) - (A*C) - (B*D)] (three multiplies, four additions)
architecture fourmult of rotator is
begin
	process
	constant rounding : integer := 2**(d_width+tf_width-2);
	variable temp1 : signed((d_width+tf_width)-1 downto 0);	-- A * C
	variable temp2 : signed((d_width+tf_width)-1 downto 0);	-- B * D
	variable temp3 : signed((d_width+tf_width)-1 downto 0);	-- A * D
	variable temp4 : signed((d_width+tf_width)-1 downto 0);	-- B * C
	variable temp5 : signed((d_width+tf_width)-1 downto 0);	-- A * C - B * D
	variable temp6 : signed((d_width+tf_width)-1 downto 0);	-- A * D + B * C
	begin
		wait until rising_edge(clk);

		-- out = in * tf
		temp1 := signed(i_re) * signed(tf_re) + rounding;
		temp2 := signed(i_im) * signed(tf_im) + rounding;
		temp3 := signed(i_re) * signed(tf_im) + rounding;
		temp4 := signed(i_im) * signed(tf_re) + rounding;

		temp5 := temp1 - temp2;
		temp6 := temp3 + temp4;

		o_re <= std_logic_vector(
			temp5(d_width+tf_width-2 downto tf_width-1)
		);
		o_im <= std_logic_vector(
			temp6(d_width+tf_width-2 downto tf_width-1)
		);
	end process;
end fourmult;

