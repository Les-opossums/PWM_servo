library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM is
    Port (  clk             : in STD_LOGIC;
            reset           : in STD_LOGIC;
            angle           : in unsigned (7 downto 0);
            counter_20ms    : in unsigned (15 downto 0);
            pwm_out         : out STD_LOGIC);
end PWM;

architecture Behavioral of PWM is
    signal counter : unsigned (15 downto 0) := to_unsigned(15000, 16);
    signal pwm_out_reg : std_logic := '0';

begin
    process(clk, reset)
    begin
        if reset = '0' then
            counter <= to_unsigned(1500, 16);
            pwm_out_reg <= '0';
        elsif rising_edge(clk) then
            counter <= to_unsigned((to_integer(angle) * 1000) / 180 + 1000 , 16);
            if to_integer(counter_20ms) < to_integer(counter) then
                pwm_out_reg <= '0';
            else
                pwm_out_reg <= '1';
            end if;
        end if;
    end process;

    pwm_out <= pwm_out_reg;

end Behavioral;