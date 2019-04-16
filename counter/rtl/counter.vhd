-- counter
-- clk: clock input
-- en: enable input
-- rst: reset input
-- dir: direction pin (1 = up, 0 = down)
-- q: output

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
    generic (
        width   : positive := 16
    );

    port (
        clk : in std_logic;
        en  : in std_logic;
        rst : in std_logic;
        init: in std_logic;
        q   : out std_logic_vector(width-1 downto 0) := (others => '1')
    );
end counter;

architecture behav of counter is
signal cnt  : unsigned(width-1 downto 0) := to_unsigned(0, width);
begin
    process
    begin
        wait until rising_edge(clk);
        if (rst = '1') then
            cnt <= (width-1 downto 1 => '0') & init;
        elsif (en = '1') then
            cnt <= cnt + to_unsigned(1, cnt'length);
        end if;
    end process;
    q <= std_logic_vector(cnt);
end behav;

