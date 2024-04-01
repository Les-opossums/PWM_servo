library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter is
    generic(
        FREQ            : integer := 50000000 -- 50 MHz
    );
    port(
        clk             : in std_logic;
        rst             : in std_logic;
        counter_20ms    : out integer range 0 to 20000
    );
end counter;

architecture rtl of counter is
    signal counter_20ms_reg : integer range 0 to 20000 := 0;

    signal counter : integer range 0 to FREQ/1000 := 0;
begin
    process(clk, rst)
    begin
        if rst = '1' then
            counter_20ms_reg <= 0;
            counter <= 0;
        elsif rising_edge(clk) then
            if counter = FREQ/1000 then
                counter_20ms_reg <= counter_20ms_reg + 1;
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    counter_20ms <= counter_20ms_reg;
end rtl;