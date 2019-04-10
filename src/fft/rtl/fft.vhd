-- Pipelined FFT Block
-- Implements Radix-2 single path delay feedback architecture
-- Author: Stefan Biereigel

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fft is
    generic (
        mode_dit    : integer := 0;
        -- input bit width (given in bits)
        d_width     : positive := 8;
        guard_bits  : integer  := 3;
        tf_width    : positive := 12;
        -- FFT length (given as exponent of 2^N)
        length      : positive := 8
    );

    port (
        clk : in std_logic;
        rst : in std_logic;
        d_re    : in std_logic_vector(d_width-1 downto 0);
        d_im    : in std_logic_vector(d_width-1 downto 0);
        q_re    : out std_logic_vector(d_width+length-1 downto 0);
        q_im    : out std_logic_vector(d_width+length-1 downto 0)
    );
end fft;

architecture r2sdf of fft is
    -- DIF architecture
    -- ex: N = 2 stages
    --       | dl |     | dl |
    -- input - bf - rot - bf - rot -- output
    --           rom |      rom |
    --
    -- DIT architecture
    -- ex: N = 2 stages
    --           | dl |     | dl |
    -- input - rot - bf - rot - bf -- output
    --      rom |      rom |
    -- N butterfly to rotator connections (bf2rot)
    -- N rotator to butterfly connections (rot2bf)
    -- N DL to BF connections (dl2bf)
    -- N BF to DL connections (bf2dl)
    type con_sig is array (natural range <>) of std_logic_vector(d_width+guard_bits+length-1 downto 0);
    type tf_sig is array (natural range <>) of std_logic_vector(tf_width-1 downto 0);
    signal bf2rot_re : con_sig(0 to length-1);
    signal bf2rot_im : con_sig(0 to length-1);
    signal rot2bf_re : con_sig(0 to length-1);
    signal rot2bf_im : con_sig(0 to length-1);
    signal rom2rot_re: tf_sig(0 to length-1);
    signal rom2rot_im: tf_sig(0 to length-1);
    signal bf2dl_re  : con_sig(0 to length-1);
    signal bf2dl_im  : con_sig(0 to length-1);
    signal dl2bf_re  : con_sig(0 to length-1);
    signal dl2bf_im  : con_sig(0 to length-1);

    type ctl_sig is array (natural range <>) of std_logic_vector(length-1 downto 0);
    signal ctl_cnt          : ctl_sig(0 to length-1) := (others => (others => '0'));
    signal ctl_cnt_inv      : ctl_sig(0 to length-1);

begin

    controller : entity work.counter
    generic map(
        width => length
    )
    port map(
        clk => clk,
        en => '1',
        rst => rst,
        init => to_unsigned(mode_dit, 1)(0),
        q => ctl_cnt(0)
    );
    
    -- pipelined copies of the control counter
    cnt_workaround : for i in 1 to length-1 generate
        ctl_cnt(i) <= ctl_cnt(i-1) when rising_edge(clk);
        ctl_cnt_inv(i) <= ctl_cnt_inv(i-1) when rising_edge(clk);
    end generate;
    ctl_cnt_inv(0) <= not ctl_cnt(0);

    -- decimation in frequency (DIF) implementation
    dif_arch : if mode_dit = 0 generate
        all_instances : for n in 0 to length-1 generate
            -- delay lines (DL)
            -- the last 1 sample delay can't be inferred from delay_line
            first_stages_only : if n < length-1 generate
                dl_re : entity work.delayline
                generic map (
                    delay => length-n-1,
                    iowidth => d_width+guard_bits+n+1
                )
                port map (
                    clk => clk,
                    d => bf2dl_re(n)(d_width+guard_bits+n downto 0),
                    q => dl2bf_re(n)(d_width+guard_bits+n downto 0)
                );

                dl_im : entity work.delayline
                generic map (
                    delay => length-n-1,
                    iowidth => d_width+guard_bits+n+1
                )
                port map (
                    clk => clk,
                    d => bf2dl_im(n)(d_width+guard_bits+n downto 0),
                    q => dl2bf_im(n)(d_width+guard_bits+n downto 0)
                );

                -- rotators (ROT)
                rotator : entity work.rotator
                generic map (
                    d_width => d_width+guard_bits+n+1,
                    tf_width => tf_width
                )
                port map (
                    clk => clk,
                    i_re => bf2rot_re(n)(d_width+guard_bits+n downto 0),
                    i_im => bf2rot_im(n)(d_width+guard_bits+n downto 0),
                    tf_re => rom2rot_re(n),
                    tf_im => rom2rot_im(n),
                    o_re => rot2bf_re(n+1)(d_width+guard_bits+n downto 0),
                    o_im => rot2bf_im(n+1)(d_width+guard_bits+n downto 0)
                );

                -- TF ROMs (TF)
                tf_rom : entity work.twiddle_rom
                generic map (
                    exponent => length,
                    inwidth => length-n-1,
                    outwidth => tf_width
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
            generic map (
                iowidth => d_width+guard_bits+n
            )
            port map (
                clk => clk,
                ctl => ctl_cnt(n)(length-n-1),
                iu_re => dl2bf_re(n)(d_width+guard_bits+n downto 0),
                iu_im => dl2bf_im(n)(d_width+guard_bits+n downto 0),
                il_re => rot2bf_re(n)(d_width+guard_bits+n-1 downto 0),
                il_im => rot2bf_im(n)(d_width+guard_bits+n-1 downto 0),
                ou_re => bf2rot_re(n)(d_width+guard_bits+n downto 0),
                ou_im => bf2rot_im(n)(d_width+guard_bits+n downto 0),
                ol_re => bf2dl_re(n)(d_width+guard_bits+n downto 0),
                ol_im => bf2dl_im(n)(d_width+guard_bits+n downto 0)
            );

        end generate;

        one_sample_delay : process
        begin
            -- the 1 sample delay can not be inferred from delayline
            wait until rising_edge(clk);
            dl2bf_re(length-1) <= bf2dl_re(length-1);
            dl2bf_im(length-1) <= bf2dl_im(length-1);
        end process;
    end generate;


    -- decmation in time (DIT) implementation
    dit_arch : if mode_dit = 1 generate
        all_instances : for n in 0 to length-1 generate
            -- delay lines (DL)
            -- the first 1 sample delay can't be inferred from delay_line
            first_stages_only : if n > 0 generate
                dl_re : entity work.delayline
                generic map (
                    delay => n,
                    iowidth => d_width+guard_bits+n+1
                )
                port map (
                    clk => clk,
                    d => bf2dl_re(n)(d_width+guard_bits+n downto 0),
                    q => dl2bf_re(n)(d_width+guard_bits+n downto 0)
                );

                dl_im : entity work.delayline
                generic map (
                    delay => n,
                    iowidth => d_width+guard_bits+n+1
                )
                port map (
                    clk => clk,
                    d => bf2dl_im(n)(d_width+guard_bits+n downto 0),
                    q => dl2bf_im(n)(d_width+guard_bits+n downto 0)
                );

                -- rotators (ROT)
                rotator : entity work.rotator
                generic map (
                    d_width => d_width+guard_bits+n,
                    tf_width => tf_width
                )
                port map (
                    clk => clk,
                    i_re => bf2rot_re(n-1)(d_width+guard_bits+n-1 downto 0),
                    i_im => bf2rot_im(n-1)(d_width+guard_bits+n-1 downto 0),
                    tf_re => rom2rot_re(n-1),
                    tf_im => rom2rot_im(n-1),
                    o_re => rot2bf_re(n)(d_width+guard_bits+n-1 downto 0),
                    o_im => rot2bf_im(n)(d_width+guard_bits+n-1 downto 0)
                );

                -- TF ROMs (TF)
                tf_rom : entity work.twiddle_rom
                generic map (
                    exponent => length,
                    inwidth => n,
                    outwidth => tf_width
                )
                port map (
                    clk => clk,
                    ctl => ctl_cnt(n-1)(n),
                    arg => ctl_cnt(n-1)(n-1 downto 0),
                    q_sin => rom2rot_im(n-1),
                    q_cos => rom2rot_re(n-1)
                );
            end generate;

            -- butterflies (BF)
            butterfly : entity work.butterfly
            generic map (
                iowidth => d_width+guard_bits+n
            )
            port map (
                clk => clk,
                ctl => ctl_cnt_inv(n)(n),
                iu_re => dl2bf_re(n)(d_width+guard_bits+n downto 0),
                iu_im => dl2bf_im(n)(d_width+guard_bits+n downto 0),
                il_re => rot2bf_re(n)(d_width+guard_bits+n-1 downto 0),
                il_im => rot2bf_im(n)(d_width+guard_bits+n-1 downto 0),
                ou_re => bf2rot_re(n)(d_width+guard_bits+n downto 0),
                ou_im => bf2rot_im(n)(d_width+guard_bits+n downto 0),
                ol_re => bf2dl_re(n)(d_width+guard_bits+n downto 0),
                ol_im => bf2dl_im(n)(d_width+guard_bits+n downto 0)
            );

        end generate;

        one_sample_delay : process
        begin
            -- the 1 sample delay can not be inferred from delayline
            wait until rising_edge(clk);
            dl2bf_re(0) <= bf2dl_re(0);
            dl2bf_im(0) <= bf2dl_im(0);
        end process;
    end generate;
    
    -- connect the input to the first butterfly (no rotator connected there)
    rot2bf_re(0)(d_width+guard_bits-1 downto guard_bits) <= d_re;
    rot2bf_im(0)(d_width+guard_bits-1 downto guard_bits) <= d_im;

    rot2bf_re(0)(guard_bits-1 downto 0) <= (others => '0');
    rot2bf_im(0)(guard_bits-1 downto 0) <= (others => '0');

    -- connect the output to the last butterfly (no rotator connected there)
    q_re <= bf2rot_re(length-1)(d_width+length+guard_bits-1 downto guard_bits);
    q_im <= bf2rot_im(length-1)(d_width+length+guard_bits-1 downto guard_bits);

end r2sdf;

