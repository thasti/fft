library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_tb is
end counter_tb;

architecture behav of counter_tb is
    component counter
    generic 
    (
        width   : positive := 16
    );
    
    port 
    (
        clk : in std_logic;
        en  : in std_logic;
        rst : in std_logic;
        init: in std_logic;
        q   : out std_logic_vector(width-1 downto 0) := (others => '0')
    );
    end component;

    signal clk  : std_logic := '0';
    signal en   : std_logic := '1';
    signal rst  : std_logic := '1';
    signal init : std_logic := '0';
    signal q    : std_logic_vector (15 downto 0) := (others=>'0');
begin
    dut : counter 
    port map (
        clk => clk,
        en => en,
        rst => rst,
        init => init,
        q => q
    );
    clk <= not clk after 50 ns;
    rst <= '0' after 200 ns;
    
end behav;
