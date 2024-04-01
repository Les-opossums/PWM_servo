library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM is
    generic(
            PERIOD      : integer := 20); -- 20ms
    Port (  clk             : in STD_LOGIC;
            reset           : in STD_LOGIC;
            angle           : in integer range 0 to 180;
            counter_20ms    : in integer range 0 to 20000;
            pwm_out         : out STD_LOGIC);
end PWM;

architecture Behavioral of PWM is
    signal counter : integer range 1000 to 2000 := 1500; -- 1.5ms
    signal pwm_out_reg : std_logic := '0';

begin
    process(clk, reset)
    begin
        if reset = '1' then
            counter <= 1500;
            pwm_out_reg <= '0';
        elsif rising_edge(clk) then
            counter <= (angle * 1000) / 180 + 1000;
            if counter_20ms < counter then
                pwm_out_reg <= '1';
            else
                pwm_out_reg <= '0';
            end if;
        end if;
    end process;

    pwm_out <= pwm_out_reg;

end Behavioral;