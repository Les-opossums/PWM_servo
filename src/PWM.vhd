library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_axi_slave is
    generic (
        FREQ    : integer := 50000000; -- Fréquence d'horloge en Hz
        NB_PWM  : integer := 8         -- Nombre de canaux PWM
    );
    port (
        -- Clock / Reset
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;

        -- AXI4-Lite slave interface
        s_axi_awaddr  : in  STD_LOGIC_VECTOR(31 downto 0);
        s_axi_awvalid : in  STD_LOGIC;
        s_axi_awready : out STD_LOGIC;

        s_axi_wdata   : in  STD_LOGIC_VECTOR(31 downto 0);
        s_axi_wvalid  : in  STD_LOGIC;
        s_axi_wready  : out STD_LOGIC;

        s_axi_bresp   : out STD_LOGIC_VECTOR(1 downto 0);
        s_axi_bvalid  : out STD_LOGIC;
        s_axi_bready  : in  STD_LOGIC;

        s_axi_araddr  : in  STD_LOGIC_VECTOR(31 downto 0);
        s_axi_arvalid : in  STD_LOGIC;
        s_axi_arready : out STD_LOGIC;

        s_axi_rdata   : out STD_LOGIC_VECTOR(31 downto 0);
        s_axi_rresp   : out STD_LOGIC_VECTOR(1 downto 0);
        s_axi_rvalid  : out STD_LOGIC;
        s_axi_rready  : in  STD_LOGIC;

        -- PWM output
        pwm_out       : out STD_LOGIC_VECTOR(NB_PWM-1 downto 0)
    );
end entity;

architecture rtl of pwm_axi_slave is

    type t_angle_array is array (0 to NB_PWM-1) of unsigned(7 downto 0);
    signal angle_regs : t_angle_array := (others => (others => '0'));

    type t_pwm_thresholds is array (0 to NB_PWM-1) of unsigned(15 downto 0);
    signal pwm_thresholds : t_pwm_thresholds := (others => to_unsigned(1500, 16));
    signal pwm_out_reg    : std_logic_vector(NB_PWM-1 downto 0) := (others => '0');

    signal counter_20ms   : unsigned(15 downto 0) := (others => '0');
    signal counter_us     : integer range 1 to FREQ/1_000_000 := 1;

    -- AXI handshake
    signal write_en       : std_logic := '0';
    signal write_addr     : unsigned(31 downto 0);
    signal write_data     : unsigned(31 downto 0);

    signal read_en        : std_logic := '0';
    signal read_addr      : unsigned(31 downto 0);

begin

    ------------------------------------------
    -- PWM Base Time Counter (20 ms period)
    ------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                counter_20ms <= (others => '0');
                counter_us <= 1;
            else
                if counter_us = FREQ/1_000_000 then
                    counter_us <= 1;
                    if counter_20ms = 20000 then
                        counter_20ms <= (others => '0');
                    else
                        counter_20ms <= counter_20ms + 1;
                    end if;
                else
                    counter_us <= counter_us + 1;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------
    -- PWM Logic
    ------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            for i in 0 to NB_PWM-1 loop
                pwm_thresholds(i) <= to_unsigned((to_integer(angle_regs(i)) * 1000) / 180 + 1000, 16);
                if to_integer(counter_20ms) < to_integer(pwm_thresholds(i)) then
                    pwm_out_reg(i) <= '1';
                else
                    pwm_out_reg(i) <= '0';
                end if;
            end loop;
        end if;
    end process;

    pwm_out <= pwm_out_reg;

    ------------------------------------------
    -- AXI Write Logic
    ------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            write_en <= '0';
            if s_axi_awvalid = '1' and s_axi_wvalid = '1' and s_axi_bready = '1' then
                write_en   <= '1';
                write_addr <= unsigned(s_axi_awaddr);
                write_data <= unsigned(s_axi_wdata);
            end if;
        end if;
    end process;

    process(clk)
        variable index : integer;
    begin
        if rising_edge(clk) then
            if write_en = '1' then
                index := to_integer(write_addr(5 + NB_PWM - 1 downto 2));
                if index >= 0 and index < NB_PWM then
                    angle_regs(index) <= write_data(7 downto 0);
                end if;
            end if;
        end if;
    end process;

    -- Write handshake
    s_axi_awready <= '1';
    s_axi_wready  <= '1';
    s_axi_bvalid  <= '1';
    s_axi_bresp   <= "00"; -- OKAY

    ------------------------------------------
    -- AXI Read Logic
    ------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            read_en <= '0';
            if s_axi_arvalid = '1' and s_axi_rready = '1' then
                read_en   <= '1';
                read_addr <= unsigned(s_axi_araddr);
            end if;
        end if;
    end process;

    process(clk)
        variable index : integer;
    begin
        if rising_edge(clk) then
            if read_en = '1' then
                index := to_integer(read_addr(5 + NB_PWM - 1 downto 2));
                if index >= 0 and index < NB_PWM then
                    s_axi_rdata <= (others => '0');
                    s_axi_rdata(7 downto 0) <= std_logic_vector(angle_regs(index));
                else
                    s_axi_rdata <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    -- Read handshake
    s_axi_arready <= '1';
    s_axi_rvalid  <= '1';
    s_axi_rresp   <= "00"; -- OKAY

end rtl;
