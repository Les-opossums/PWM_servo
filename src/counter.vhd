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
        counter_20ms    : out unsigned (15 downto 0) --integer range 0 to 20000
    );
end counter;

architecture rtl of counter is
    signal counter_20ms_reg : unsigned (15 downto 0) := (others => '0');  -- integer range 0 to 20000 := 0;

    signal counter : integer range 1 to FREQ/1000000 := 1;
begin
    process(clk, rst)
    begin
        if rst = '1' then
            counter_20ms_reg <= (others => '0');
            counter <= 1;
        elsif rising_edge(clk) then
            if counter = (FREQ/1000000) then
                if counter_20ms_reg = 20000 then -- 20 ms
                    counter_20ms_reg <= (others => '0');
                else
                    counter_20ms_reg <= counter_20ms_reg + 1;
                end if;
                counter <= 1;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    counter_20ms <= counter_20ms_reg;
end rtl;