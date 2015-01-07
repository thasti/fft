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
		iowidth		: positive := 8
	);

	port (
		clk		: in std_logic;
		i_re		: in std_logic_vector(iowidth-1 downto 0);
		i_im		: in std_logic_vector(iowidth-1 downto 0);
		tf_re		: in std_logic_vector(iowidth-1 downto 0);
		tf_im		: in std_logic_vector(iowidth-1 downto 0);
		o_re		: out std_logic_vector(iowidth-1 downto 0);
		o_im		: out std_logic_vector(iowidth-1 downto 0)
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
	variable temp1 : signed(2*iowidth-1 downto 0);	-- A * C
	variable temp2 : signed(2*iowidth-1 downto 0);	-- B * D
	variable temp3 : signed(2*iowidth-1 downto 0);	-- A * D
	variable temp4 : signed(2*iowidth-1 downto 0);	-- B * C
	variable temp5 : signed(2*iowidth-1 downto 0);	-- A * C - B * D
	variable temp6 : signed(2*iowidth-1 downto 0);	-- A * D + B * C
	begin
		wait until rising_edge(clk);

		-- out = in * tf
		temp1 := signed(i_re) * signed(tf_re) + integer(2.0**real(iowidth-2));
		temp2 := signed(i_im) * signed(tf_im) + integer(2.0**real(iowidth-2));
		temp3 := signed(i_re) * signed(tf_im) + integer(2.0**real(iowidth-2));
		temp4 := signed(i_im) * signed(tf_re) + integer(2.0**real(iowidth-2));

		temp5 := temp1 - temp2;
		temp6 := temp3 + temp4;

		-- o_re <= std_logic_vector(resize(
		-- 	(resize(temp1(2*iowidth-2 downto iowidth-1),iowidth+1) -
		-- 	resize(temp2(2*iowidth-2 downto iowidth-1), iowidth+1) / 2), iowidth)
		-- );
		-- o_im <= std_logic_vector(resize(
		-- 	(resize(temp3(2*iowidth-2 downto iowidth-1),iowidth+1) +
		-- 	resize(temp4(2*iowidth-2 downto iowidth-1), iowidth+1) / 2), iowidth)
		-- );
		o_re <= std_logic_vector(
			temp5(2*iowidth-1 downto iowidth) / 2
		);
		o_im <= std_logic_vector(
			temp6(2*iowidth-1 downto iowidth) / 2
		);
	end process;
end fourmult;

