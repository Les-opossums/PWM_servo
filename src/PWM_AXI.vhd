library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM_AXI is
    Port (
        -- AXI4-Lite interface
        S_AXI_ACLK      : in  std_logic;
        S_AXI_ARESETN   : in  std_logic;
        S_AXI_AWADDR    : in  std_logic_vector(3 downto 0);
        S_AXI_AWVALID   : in  std_logic;
        S_AXI_AWREADY   : out std_logic;
        S_AXI_WDATA     : in  std_logic_vector(31 downto 0);
        S_AXI_WSTRB     : in  std_logic_vector(3 downto 0);
        S_AXI_WVALID    : in  std_logic;
        S_AXI_WREADY    : out std_logic;
        S_AXI_BRESP     : out std_logic_vector(1 downto 0);
        S_AXI_BVALID    : out std_logic;
        S_AXI_BREADY    : in  std_logic;
        S_AXI_ARADDR    : in  std_logic_vector(3 downto 0);
        S_AXI_ARVALID   : in  std_logic;
        S_AXI_ARREADY   : out std_logic;
        S_AXI_RDATA     : out std_logic_vector(31 downto 0);
        S_AXI_RRESP     : out std_logic_vector(1 downto 0);
        S_AXI_RVALID    : out std_logic;
        S_AXI_RREADY    : in  std_logic;

        -- Externe
        counter_20ms    : in  unsigned(15 downto 0);
        pwm_out         : out std_logic
    );
end PWM_AXI;

architecture Behavioral of PWM_AXI is

    -- Internal AXI signals
    signal slv_reg_angle : unsigned(7 downto 0) := (others => '0');

    signal awready_i, wready_i, bvalid_i, arready_i, rvalid_i : std_logic := '0';
    signal rdata_i : std_logic_vector(31 downto 0) := (others => '0');
    signal axi_bresp, axi_rresp : std_logic_vector(1 downto 0) := "00";

    -- Register write enable
    signal wr_en : std_logic := '0';
    signal rd_en : std_logic := '0';

begin

    ----------------------
    -- PWM instantiation
    ----------------------
    PWM_inst : entity work.PWM
        port map (
            clk           => S_AXI_ACLK,
            reset         => S_AXI_ARESETN,
            angle         => slv_reg_angle,
            counter_20ms  => counter_20ms,
            pwm_out       => pwm_out
        );

    ----------------------
    -- Write process
    ----------------------
    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                slv_reg_angle <= (others => '0');
                awready_i     <= '0';
                wready_i      <= '0';
                bvalid_i      <= '0';
                axi_bresp     <= "00";
            else
                awready_i <= '1';
                wready_i  <= '1';

                if S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' then
                    case S_AXI_AWADDR(3 downto 2) is
                        when "00" =>  -- address 0x00 => angle
                            slv_reg_angle <= unsigned(S_AXI_WDATA(7 downto 0));
                        when others =>
                            null;
                    end case;
                    bvalid_i <= '1';
                    axi_bresp <= "00"; -- OKAY
                elsif bvalid_i = '1' and S_AXI_BREADY = '1' then
                    bvalid_i <= '0';
                end if;
            end if;
        end if;
    end process;

    ----------------------
    -- Read process
    ----------------------
    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                arready_i <= '0';
                rvalid_i  <= '0';
                axi_rresp <= "00";
                rdata_i   <= (others => '0');
            else
                arready_i <= '1';
                if S_AXI_ARVALID = '1' and arready_i = '1' then
                    case S_AXI_ARADDR(3 downto 2) is
                        when "00" =>
                            rdata_i <= (others => '0');
                            rdata_i(7 downto 0) <= std_logic_vector(slv_reg_angle);
                        when others =>
                            rdata_i <= (others => '0');
                    end case;
                    rvalid_i <= '1';
                    axi_rresp <= "00";
                elsif rvalid_i = '1' and S_AXI_RREADY = '1' then
                    rvalid_i <= '0';
                end if;
            end if;
        end if;
    end process;

    ----------------------
    -- AXI output assignment
    ----------------------
    S_AXI_AWREADY <= awready_i;
    S_AXI_WREADY  <= wready_i;
    S_AXI_BVALID  <= bvalid_i;
    S_AXI_BRESP   <= axi_bresp;

    S_AXI_ARREADY <= arready_i;
    S_AXI_RVALID  <= rvalid_i;
    S_AXI_RDATA   <= rdata_i;
    S_AXI_RRESP   <= axi_rresp;

end Behavioral;