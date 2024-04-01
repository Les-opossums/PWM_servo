library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM_TB is
end PWM_TB;

architecture Behavioral of PWM_TB is
    component PWM is
        Port (
            clk             : in std_logic;
            reset           : in std_logic;
            angle           : in unsigned (7 downto 0); -- integer range 0 to 180;
            counter_20ms    : in unsigned (15 downto 0);-- integer range 0 to 20000;
            pwm_out         : out std_logic);
    end component;

    signal clk_tb           : std_logic := '0';
    signal reset_tb         : std_logic := '0';
    signal angle_tb         : unsigned(7 downto 0) := (others => '0');
    signal counter_20ms_tb  : unsigned(15 downto 0) := (others => '0');
    signal pwm_out_tb       : std_logic;

    constant clk_period : time := 20 ns; -- 20 MHz clock

begin

    dut : PWM
        port map (
            clk => clk_tb,
            reset => reset_tb,
            angle => angle_tb,
            counter_20ms => counter_20ms_tb,
            pwm_out => pwm_out_tb
        );

    counter: process 
    begin
        if counter_20ms_tb = to_unsigned(20000, 16) then
            counter_20ms_tb <= (others => '0');
        else
            counter_20ms_tb <= counter_20ms_tb + 1;
        end if;
        wait for 1 us;
    end process;

    clk_process: process
    begin
        clk_tb <= '0';
        wait for clk_period / 2;
        clk_tb <= '1';
        wait for clk_period / 2;
    end process;

    stim_proc: process
    begin
        reset_tb <= '1';
        wait for 40 ns;
        reset_tb <= '0';

        wait for 100 ms;
        angle_tb <= to_unsigned(0, 8);

        -- Change angle to 45 degrees
        wait for  ms;
        angle_tb <= to_unsigned(45, 8);

        -- Change angle to 90 degrees
        wait for 100 ms;
        angle_tb <= to_unsigned(90, 8);

        -- Change angle to 135 degrees
        wait for 100 ms;
        angle_tb <= to_unsigned(135, 8);

        -- Change angle to 180 degrees
        wait for 100 ms;
        angle_tb <= to_unsigned(180, 8);

        wait;
    end process;

end Behavioral;