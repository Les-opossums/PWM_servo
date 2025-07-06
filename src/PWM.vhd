library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_axi_slave is
    generic (
        FREQ    : integer := 50000000;
        NB_PWM  : integer := 8
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;

        -- AXI4-Lite interface
        s_axi_awaddr  : in  std_logic_vector(31 downto 0);
        s_axi_awvalid : in  std_logic;
        s_axi_awready : out std_logic;

        s_axi_wdata   : in  std_logic_vector(31 downto 0);
        s_axi_wvalid  : in  std_logic;
        s_axi_wready  : out std_logic;

        s_axi_bresp   : out std_logic_vector(1 downto 0);
        s_axi_bvalid  : out std_logic;
        s_axi_bready  : in  std_logic;

        s_axi_araddr  : in  std_logic_vector(31 downto 0);
        s_axi_arvalid : in  std_logic;
        s_axi_arready : out std_logic;

        s_axi_rdata   : out std_logic_vector(31 downto 0);
        s_axi_rresp   : out std_logic_vector(1 downto 0);
        s_axi_rvalid  : out std_logic;
        s_axi_rready  : in  std_logic;

        pwm_out       : out std_logic_vector(NB_PWM-1 downto 0)
    );
end entity;

architecture rtl of pwm_axi_slave is

    -- PWM internals
    type t_angle_array is array (0 to NB_PWM-1) of unsigned(7 downto 0);
    signal angle_regs : t_angle_array := (others => (others => '0'));

    type t_pwm_thresholds is array (0 to NB_PWM-1) of unsigned(15 downto 0);
    signal pwm_thresholds : t_pwm_thresholds := (others => to_unsigned(1500, 16));
    signal pwm_out_reg    : std_logic_vector(NB_PWM-1 downto 0) := (others => '0');

    signal counter_20ms   : unsigned(15 downto 0) := (others => '0');
    signal counter_us     : integer range 1 to FREQ/1000000 := 1;

    -- AXI control signals
    signal awready_reg  : std_logic := '0';
    signal wready_reg   : std_logic := '0';
    signal bvalid_reg   : std_logic := '0';
    signal arready_reg  : std_logic := '0';
    signal rvalid_reg   : std_logic := '0';

    signal write_addr   : unsigned(31 downto 0);
    signal write_data   : unsigned(31 downto 0);
    signal read_addr    : unsigned(31 downto 0);
    signal rdata_reg    : std_logic_vector(31 downto 0) := (others => '0');

begin

    ------------------------------------------
    -- PWM Clocking
    ------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                counter_20ms <= (others => '0');
                counter_us <= 1;
            else
                if counter_us = FREQ/1000000 then
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
        if rst = '0' then
            pwm_out_reg <= (others => '0');
        elsif rising_edge(clk) then
            for i in 0 to NB_PWM-1 loop
                pwm_thresholds(i) <= to_unsigned((to_integer(angle_regs(i)) * 1000) / 180 + 1000, 16);
                if to_integer(counter_20ms) < to_integer(pwm_thresholds(i)) then
                    pwm_out_reg(i) <= '0';
                else
                    pwm_out_reg(i) <= '1';
                end if;
            end loop;
        end if;
    end process;

    pwm_out <= pwm_out_reg;

    ------------------------------------------
    -- AXI Write Channel
    ------------------------------------------
    process(clk)
        variable index : integer;
    begin
        if rising_edge(clk) then
            if rst = '0' then
                awready_reg <= '0';
                wready_reg  <= '0';
                bvalid_reg  <= '0';
            else
                -- Accept write
                if s_axi_awvalid = '1' and s_axi_wvalid = '1' and awready_reg = '0' and wready_reg = '0' then
                    awready_reg <= '1';
                    wready_reg  <= '1';
                    write_addr  <= unsigned(s_axi_awaddr);
                    write_data  <= unsigned(s_axi_wdata);
                else
                    awready_reg <= '0';
                    wready_reg  <= '0';
                end if;

                -- Generate bvalid
                if awready_reg = '1' and wready_reg = '1' then
                    bvalid_reg <= '1';

                    -- Write operation
                    index := to_integer(write_addr(5 + NB_PWM - 1 downto 2));
                    if index >= 0 and index < NB_PWM then
                        angle_regs(index) <= write_data(7 downto 0);
                    end if;
                elsif bvalid_reg = '1' and s_axi_bready = '1' then
                    bvalid_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------
    -- AXI Read Channel
    ------------------------------------------
    process(clk)
        variable index : integer;
    begin
        if rising_edge(clk) then
            if rst = '0' then
                arready_reg <= '0';
                rvalid_reg  <= '0';
                rdata_reg   <= (others => '0');
            else
                -- Accept read
                if s_axi_arvalid = '1' and arready_reg = '0' then
                    arready_reg <= '1';
                    read_addr <= unsigned(s_axi_araddr);
                else
                    arready_reg <= '0';
                end if;

                -- Generate rvalid
                if arready_reg = '1' then
                    index := to_integer(read_addr(5 + NB_PWM - 1 downto 2));
                    if index >= 0 and index < NB_PWM then
                        rdata_reg <= (others => '0');
                        rdata_reg(7 downto 0) <= std_logic_vector(angle_regs(index));
                    else
                        rdata_reg <= (others => '0');
                    end if;
                    rvalid_reg <= '1';
                elsif rvalid_reg = '1' and s_axi_rready = '1' then
                    rvalid_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------
    -- AXI Outputs
    ------------------------------------------
    s_axi_awready <= awready_reg;
    s_axi_wready  <= wready_reg;
    s_axi_bvalid  <= bvalid_reg;
    s_axi_bresp   <= "00";

    s_axi_arready <= arready_reg;
    s_axi_rvalid  <= rvalid_reg;
    s_axi_rresp   <= "00";
    s_axi_rdata   <= rdata_reg;

end architecture;
