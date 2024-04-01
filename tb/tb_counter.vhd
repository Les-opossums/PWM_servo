library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_tb is
end counter_tb;

architecture Behavioral of counter_tb is
    component counter is
        generic(
            FREQ            : integer := 50000000 -- 50 MHz
        );
        port(
            clk             : in std_logic;
            rst             : in std_logic;
            counter_20ms    : out unsigned (15 downto 0)
        );
    end component;

    signal clk_tb : std_logic := '0';
    signal rst_tb : std_logic := '0';
    signal counter_20ms_tb : unsigned (15 downto 0);

    constant clk_period : time := 20 ns; -- 50 MHz clock

begin

    dut : counter
        generic map (
            FREQ => 50000000 -- 50 MHz
        )
        port map (
            clk => clk_tb,
            rst => rst_tb,
            counter_20ms => counter_20ms_tb
        );

    clk_process: process
    begin
        clk_tb <= '0';
        wait for clk_period / 2;
        clk_tb <= '1';
        wait for clk_period / 2;
    end process;

    stim_proc: process
    begin
        rst_tb <= '1';
        wait for 40 ns;
        rst_tb <= '0';

        -- Wait for 20 milliseconds
        wait for 30 ms;

        assert counter_20ms_tb = 20_000
            report "Test failed: counter_20ms_tb should be 20000 after 20 milliseconds"
            severity error;

        wait;
    end process;

end Behavioral;