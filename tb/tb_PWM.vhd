library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PWM_TB is
end PWM_TB;

architecture Behavioral of PWM_TB is
    component PWM is
        generic(
            PERIOD      : integer := 20
        );
        Port (
            clk             : in STD_LOGIC;
            reset           : in STD_LOGIC;
            angle           : in integer range 0 to 180;
            counter_20ms    : in integer range 0 to 20000;
            pwm_out         : out STD_LOGIC
        );
    end component;

    signal clk_tb : STD_LOGIC := '0';
    signal reset_tb : STD_LOGIC := '0';
    signal angle_tb : integer range 0 to 180 := 90; -- Starting angle
    signal counter_20ms_tb : integer range 0 to 20000 := 10000; -- Halfway through the 20ms cycle
    signal pwm_out_tb : STD_LOGIC;

    constant clk_period : time := 50 ns; -- 20 MHz clock

begin

    dut : PWM
        generic map (
            PERIOD => 20
        )
        port map (
            clk => clk_tb,
            reset => reset_tb,
            angle => angle_tb,
            counter_20ms => counter_20ms_tb,
            pwm_out => pwm_out_tb
        );


    counter: process 
    begin
        if counter_20ms_tb = 20000 then
            counter_20ms_tb <= 0;
        else
            counter_20ms_tb <= counter_20ms_tb + 1;
            wait for 1 us;
        end if;
        wait for clk_period;
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

        -- Change angle to 45 degrees
        wait for 100 ms;
        angle_tb <= 45;

        -- Change angle to 90 degrees
        wait for 100 ms;
        angle_tb <= 90;

        -- Change angle to 135 degrees
        wait for 100 ms;
        angle_tb <= 135;

        -- Change angle to 180 degrees
        wait for 100 ms;
        angle_tb <= 180;

        wait;
    end process;

end Behavioral;