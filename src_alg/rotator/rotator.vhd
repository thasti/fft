-- dynamic complex rotator for FFT operation
-- Implements the Complex Number Rotator needed for R2SDF pipelined FFT
-- first implementation uses regular multiplier, but could also be implemented as CORDIC
-- Author: Stefan Biereigel

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rotator is
	port (
		clk		: in std_logic;
		i_re		: in real;
		i_im		: in real;
		tf_re		: in real;
		tf_im		: in real;
		o_re		: out real;
		o_im		: out real
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
	process -- (i_re, i_im, tf_re, tf_im)
	begin
		wait until rising_edge(clk);

		o_re <= i_re*tf_re + i_im*tf_im;
		o_im <= i_re*tf_im + i_im*tf_re;
	end process;
end fourmult;

