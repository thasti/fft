-- Pipelined FFT Block
-- Implements Radix-2 single path delay feedback architecture
-- Author: Stefan Biereigel

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fft is
	generic (
		-- input bit width (given in bits)
		iowidth	: positive := 8;
		-- FFT length (given as exponent of 2^N)
		length	: positive := 8
	);

	port (
		clk	: in std_logic;
		rst	: in std_logic;
		d_re	: in real;
		d_im	: in real;
		q_re	: out real;
		q_im	: out real
	);
end fft;

architecture dif_r2sdf of fft is
	-- ex: N = 2 stages
	--       | sr |     | sr |
	-- input - bf - rot - bf - rot -- output
	--           rom |      rom |
	-- N butterfly to rotator connections (bf2rot)
	-- N rotator to butterfly connections (rot2bf)
	-- N DL to BF connections (dl2bf)
	-- N BF to DL connections (bf2dl)
	type con_sig is array (natural range <>) of real;
	signal bf2rot_re : con_sig(0 to length-1);
	signal bf2rot_im : con_sig(0 to length-1);
	signal rot2bf_re : con_sig(0 to length-1);
	signal rot2bf_im : con_sig(0 to length-1);
	signal rom2rot_re: con_sig(0 to length-1);
	signal rom2rot_im: con_sig(0 to length-1);
	signal bf2dl_re  : con_sig(0 to length-1);
	signal bf2dl_im  : con_sig(0 to length-1);
	signal dl2bf_re  : con_sig(0 to length-1);
	signal dl2bf_im  : con_sig(0 to length-1);

	type ctl_sig is array (natural range <>) of std_logic_vector(length-1 downto 0);
	signal ctl_cnt 		: ctl_sig(0 to length-1);

begin

	controller : entity work.counter
	generic map(
		width => length
	)
	port map(
		clk => clk,
		en => '1',
		rst => rst,
		dir => '1',
		q => ctl_cnt(0)
	);

	all_instances : for n in 0 to length-1 generate
		-- delay lines (DL)
		-- the last 1 sample delay can't be inferred from delay_line, the process below is used for it.
		first_stages_only : if n < length-1 generate
			dl_re : entity work.delayline
			generic map (
				delay => length-n-1
			)
			port map (
				clk => clk,
				d => bf2dl_re(n),
				q => dl2bf_re(n)
			);

			dl_im : entity work.delayline
			generic map (
				delay => length-n-1
			)
			port map (
				clk => clk,
				d => bf2dl_im(n),
				q => dl2bf_im(n)
			);

			-- rotators (ROT)
			rotator : entity work.rotator
			port map (
				clk => clk,
				i_re => bf2rot_re(n),
				i_im => bf2rot_im(n),
				tf_re => rom2rot_re(n),
				tf_im => rom2rot_im(n),
				o_re => rot2bf_re(n+1),
				o_im => rot2bf_im(n+1)
			);

			-- TF ROMs (TF)
			tf_rom : entity work.twiddle_rom
			generic map (
				exponent => length,
				inwidth => length-n-1
			)
			port map (
				clk => clk,
				ctl => ctl_cnt(n)(length-n-1),
				arg => ctl_cnt(n)(length-n-2 downto 0),
				q_sin => rom2rot_im(n),
				q_cos => rom2rot_re(n)
			);
		end generate;

		-- butterflies (BF)
		butterfly : entity work.butterfly
		port map (
			clk => clk,
			ctl => ctl_cnt(n)(length-n-1),
			iu_re => dl2bf_re(n),
			iu_im => dl2bf_im(n),
			il_re => rot2bf_re(n),
			il_im => rot2bf_im(n),
			ou_re => bf2rot_re(n),
			ou_im => bf2rot_im(n),
			ol_re => bf2dl_re(n),
			ol_im => bf2dl_im(n)
		);

	end generate;

	cnt_workaround : for i in 1 to length-1 generate
		ctl_cnt(i) <= ctl_cnt(i-1) when rising_edge(clk);
	end generate;

	one_sample_delay : process
	begin
		-- the 1 sample delay can not be inferred from delayline
		-- use a simple register as described below
		wait until rising_edge(clk);
		dl2bf_re(length-1) <= bf2dl_re(length-1);
		dl2bf_im(length-1) <= bf2dl_im(length-1);
	end process;

	-- connect the input to the first butterfly (no rotator connected there)
	rot2bf_re(0) <= d_re;
	rot2bf_im(0) <= d_im;

	-- connect the output to the last butterfly (no rotator connected there)
	q_re <= bf2rot_re(length-1);
	q_im <= bf2rot_im(length-1);

end dif_r2sdf;

