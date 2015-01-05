-- dynamic butterfly for FFT operation
-- Implements the Dynamic Butterfly needed for R2SDF pipelined FFT
-- Author: Stefan Biereigel

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity butterfly is
	generic (
		-- input bit width
		iowidth		: positive := 8
	);

	port (
		clk		: in std_logic;
		ctl		: in std_logic;
		iu_re		: in std_logic_vector(iowidth-1 downto 0);
		iu_im		: in std_logic_vector(iowidth-1 downto 0);
		il_re		: in std_logic_vector(iowidth-1 downto 0);
		il_im		: in std_logic_vector(iowidth-1 downto 0);
		ou_re		: out std_logic_vector(iowidth-1 downto 0);
		ou_im		: out std_logic_vector(iowidth-1 downto 0);
		ol_re		: out std_logic_vector(iowidth-1 downto 0);
		ol_im		: out std_logic_vector(iowidth-1 downto 0)
	);
end butterfly;

architecture rtl of butterfly is
begin
	process
	variable tmp_ure : std_logic_vector(iowidth downto 0);
	variable tmp_uim : std_logic_vector(iowidth downto 0);
	variable tmp_lre : std_logic_vector(iowidth downto 0);
	variable tmp_lim : std_logic_vector(iowidth downto 0);
	begin
		-- connect FIFO on upper in and lower out
		-- connect rotator on lower in and upper out
		wait until rising_edge(clk);
		-- additions are followed by division by two to ensure bounded output
		-- every stage would have a bit growth of one bit otherwise
		-- Operator "/" is used to ensure a correct rounding scheme is used (needs additional logic)

		if ctl = '0' then
			-- upper = upper
			tmp_ure := std_logic_vector(resize(signed(iu_re),iowidth+1) / 2);
			tmp_uim := std_logic_vector(resize(signed(iu_im),iowidth+1) / 2);

			-- lower = lower
			tmp_lre := std_logic_vector(resize(signed(il_re),iowidth+1) / 2);
			tmp_lim := std_logic_vector(resize(signed(il_im),iowidth+1) / 2);
		else
			-- upper = (upper + lower)
			tmp_ure := std_logic_vector(
				(resize(signed(iu_re),iowidth+1) +
				resize(signed(il_re),iowidth+1)) / 2
			);
			tmp_uim := std_logic_vector(
				(resize(signed(iu_im),iowidth+1) +
				resize(signed(il_im),iowidth+1)) / 2
			);
			-- lower = (upper - lower)
			tmp_lre := std_logic_vector(
				(resize(signed(iu_re),iowidth+1) -
				resize(signed(il_re),iowidth+1)) / 2
			);
			tmp_lim := std_logic_vector(
				(resize(signed(iu_im),iowidth+1) -
				resize(signed(il_im),iowidth+1)) / 2
			);
		end if;

		-- apply division by two
		ou_re <= tmp_ure(iowidth-1 downto 0);
		ou_im <= tmp_uim(iowidth-1 downto 0);
		ol_re <= tmp_lre(iowidth-1 downto 0);
		ol_im <= tmp_lim(iowidth-1 downto 0);

	end process;
end rtl;

