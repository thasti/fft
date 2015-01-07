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
		d_re	: in std_logic_vector(iowidth-1 downto 0);
		d_im	: in std_logic_vector(iowidth-1 downto 0);
		q_re	: out std_logic_vector(iowidth-1 downto 0);
		q_im	: out std_logic_vector(iowidth-1 downto 0)
	);
end fft;

architecture dif_r2sdf of fft is
	-- ex: N = 2 stages
	--       | sr |     | sr |
	-- input - bf - rot - bf - rot -- output
	--           rom |      rom |
	-- N butterfly to rotator connections
	-- N-1 rotator to butterfly connections
	-- N SR to BF connections
	-- N BF to SR connections
	type con_sig is array (natural range <>) of std_logic_vector(iowidth-1 downto 0);
	signal bf2rot_re : con_sig(0 to length-1);
	signal bf2rot_im : con_sig(0 to length-1);
	signal rot2bf_re : con_sig(0 to length-2);
	signal rot2bf_im : con_sig(0 to length-2);
	signal rom2rot_re: con_sig(0 to length-1);
	signal rom2rot_im: con_sig(0 to length-1);
	signal bf2dl_re  : con_sig(0 to length-1);
	signal bf2dl_im  : con_sig(0 to length-1);
	signal dl2bf_re  : con_sig(0 to length-1);
	signal dl2bf_im  : con_sig(0 to length-1);

	signal ctl_cnt : std_logic_vector(length-1 downto 0);

begin
	controller : entity work.counter
	generic map(
		width => length
	)
	port map(
		clk => clk,
		en => '1',
		rst => '0',
		dir => '1',
		q => ctl_cnt
	);

	all_instances : for n in 0 to length-1 generate
		-- delay lines (DL)
		first_dl : if n < length-1 generate
			dl_re : work.delayline
			generic map (
				delay => length-n-1,
				iowidth => iowidth
			)
			port map (
				clk => clk,
				d => bf2dl_re(n),
				q => dl2bf_re(n)
			);

			dl_im : work.delayline
			generic map (
				delay => length-n-1,
				iowidth => iowidth
			)
			port map (
				clk => clk,
				d => bf2dl_im(n),
				q => dl2bf_im(n)
			);
		end generate;

		-- butterflies (BF)
		input_bf : if n = 0 generate
			-- the first butterfly (connected to the input)
			bf_i : work.butterfly
			generic map (
				iowidth => iowidth
			)
			port map (
				clk => clk,
				ctl => ctl_cnt(length-n-1),
				iu_re => dl2bf_re(n),
				iu_im => dl2bf_im(n),
				il_re => d_re,
				il_im => d_im,
				ou_re => bf2rot_re(n),
				ou_im => bf2rot_im(n),
				ol_re => bf2dl_re(n),
				ol_im => bf2dl_im(n)
			);
		end generate;
		middle_bf : if n > 0 generate
			-- the middle butterflies (connected to other stages only)
			bf_m : work.butterfly
			generic map (
				iowidth => iowidth
			)
			port map (
				clk => clk,
				ctl => ctl_cnt(length-n-1),
				iu_re => dl2bf_re(n),
				iu_im => dl2bf_im(n),
				il_re => rot2bf(n-1),
				il_im => rot2bf(n-1),
				ou_re => bf2rot_re(n),
				ou_im => bf2rot_im(n),
				ol_re => bf2dl_re(n),
				ol_im => bf2dl_im(n)
			);
		end generate;

		-- rotators (ROT)
		middle_rot : if n < length-1 generate
			-- the middle rotators (connected to other stages only)
			rot_m : work.rotator
			generic map (
				iowidth => iowidth
			)
			port map (
				clk => clk,
				i_re => bf2rot_re(n),
				i_im => bf2rot_im(n),
				tf_re => rom2rot_re(n),
				tf_im => rom2rot_im(n),
				o_re => rot2bf_re(n),
				o_im => rot2bf_im(n)
			);
		end generate;
		output_rot : if n = length-1 generate
			-- the last rotator (connected to the output)
			rot_o : work.rotator
			generic map (
				iowidth => iowidth
			)
			port map (
				clk => clk,
				i_re => bf2rot_re(n),
				i_im => bf2rot_im(n),
				tf_re => rom2rot_re(n),
				tf_im => rom2rot_im(n),
				o_re => o_re,
				o_im => o_im
			);
		end generate;

		-- TF ROMs (TF)
		rot_o : work.twiddle_rom
		generic map (
			iowidth => iowidth,
			n => n
		)
		port map (
			clk => clk,
			addr => ctl_cnt(length-n-1 downto 0),	-- in case multiplication occurs every cycle, TBC
			q_re => rom2rot_re(n),
			q_im => rom2rot_im(n)
		);
	end generate;

	one_sample_delay : process
	begin
		-- the 1 sample delay can not be inferred from delayline
		-- use a simple register as described below
		wait until rising_edge(clk);
		dl2bf_re(length-1) <= bf2dl_re(length-1);
		dl2bf_im(length-1) <= bf2dl_im(length-1);
	end process;
end dif_r2sdf;

