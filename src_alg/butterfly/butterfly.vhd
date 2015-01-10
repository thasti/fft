-- dynamic butterfly for FFT operation
-- Implements the Dynamic Butterfly needed for R2SDF pipelined FFT
-- Author: Stefan Biereigel

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity butterfly is
	port (
		clk		: in std_logic;
		ctl		: in std_logic;
		iu_re		: in real;
		iu_im		: in real;
		il_re		: in real;
		il_im		: in real;
		ou_re		: out real;
		ou_im		: out real;
		ol_re		: out real;
		ol_im		: out real
	);
end butterfly;

architecture rtl of butterfly is
begin
	process (ctl, iu_re, iu_im, il_re, il_im)
	begin
		-- connect FIFO on upper in and lower out
		-- connect rotator on lower in and upper out
		-- wait until rising_edge(clk);
		-- additions are followed by division by two to ensure bounded output
		-- every stage would have a bit growth of one bit otherwise
		-- Operator "/" is used to ensure a correct rounding scheme is used (needs additional logic)

		if ctl = '0' then
			-- upper = upper
			ou_re <= iu_re;
			ou_im <= iu_im;

			-- lower = lower)
			ol_re <= il_re;
			ol_im <= il_im;
		else
			-- upper = (upper + lower)
			ou_re <= iu_re + il_re;
			ou_im <= iu_im + il_im;
			ol_re <= iu_re - il_re;
			ol_im <= iu_im - il_im;
		end if;

	end process;
end rtl;

