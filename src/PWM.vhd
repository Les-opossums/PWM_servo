library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_axi_slave is
    generic (
        FREQ    : integer := 100000000;                 --! clock frequency : 100 MHz default
        NB_PWM  : integer := 8                          --! number of PWM channels : 8 default
    );
    port (
        clk             : in  std_logic;                --! clock input
        rst             : in  std_logic;                --! reset input active low

        -- AXI4-Lite interface
        s_axi_awaddr    : in  std_logic_vector(31 downto 0);    --! write address
        s_axi_awvalid   : in  std_logic;                        --! write address valid
        s_axi_awready   : out std_logic;                        --! write address ready

        s_axi_wdata     : in  std_logic_vector(31 downto 0);    --! write data
        s_axi_wvalid    : in  std_logic;                        --! write data valid
        s_axi_wready    : out std_logic;                        --! write data ready

        s_axi_bresp     : out std_logic_vector(1 downto 0);     --! write response
        s_axi_bvalid    : out std_logic;                        --! write response valid
        s_axi_bready    : in  std_logic;                        --! write response ready

        s_axi_araddr    : in  std_logic_vector(31 downto 0);    --! read address
        s_axi_arvalid   : in  std_logic;                        --! read address valid
        s_axi_arready   : out std_logic;                        --! read address ready

        s_axi_rdata     : out std_logic_vector(31 downto 0);    --! read data
        s_axi_rresp     : out std_logic_vector(1 downto 0);     --! read response
        s_axi_rvalid    : out std_logic;                        --! read response valid
        s_axi_rready    : in  std_logic;                        --! read response ready

        pwm_out         : out std_logic_vector(NB_PWM-1 downto 0)   --! PWM output
    );
end entity;

architecture rtl of pwm_axi_slave is
    -- constants
    constant CYCLES_PER_US : integer := FREQ / 1000000; --! cycles per microsecond

    -- PWM internals
    type t_angle_array is array (0 to NB_PWM-1) of unsigned(7 downto 0); --! 0-180 degrees
    signal angle_regs : t_angle_array := (others => (others => '0'));

    type t_pwm_thresholds is array (0 to NB_PWM-1) of unsigned(15 downto 0); --! PWM thresholds
    signal pwm_thresholds : t_pwm_thresholds := (others => to_unsigned(1500, 16)); --! default threshold 1500us
    signal pwm_out_reg    : std_logic_vector(NB_PWM-1 downto 0) := (others => '0'); --! PWM output register

    signal counter_20ms   : unsigned(15 downto 0) := (others => '0'); --! 20ms counter
    signal counter_us     : integer range 1 to CYCLES_PER_US := 1; --! microsecond counter

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

    -- LUT for PWM 0° -> 1000µs, 180° -> 2000µs
    type t_pwm_lut is array (0 to 180) of unsigned(15 downto 0); --! lut to store PWM pulse widths
    --! @cond HIDE_LUT
    constant pwm_lut : t_pwm_lut := (
        0   => to_unsigned(1000,16),
        1   => to_unsigned(1006,16),
        2   => to_unsigned(1011,16),
        3   => to_unsigned(1017,16),
        4   => to_unsigned(1022,16),
        5   => to_unsigned(1028,16),
        6   => to_unsigned(1033,16),
        7   => to_unsigned(1039,16),
        8   => to_unsigned(1044,16),
        9   => to_unsigned(1050,16),
        10  => to_unsigned(1056,16),
        11  => to_unsigned(1061,16),
        12  => to_unsigned(1067,16),
        13  => to_unsigned(1072,16),
        14  => to_unsigned(1078,16),
        15  => to_unsigned(1083,16),
        16  => to_unsigned(1089,16),
        17  => to_unsigned(1094,16),
        18  => to_unsigned(1100,16),
        19  => to_unsigned(1106,16),
        20  => to_unsigned(1111,16),
        21  => to_unsigned(1117,16),
        22  => to_unsigned(1122,16),
        23  => to_unsigned(1128,16),
        24  => to_unsigned(1133,16),
        25  => to_unsigned(1139,16),
        26  => to_unsigned(1144,16),
        27  => to_unsigned(1150,16),
        28  => to_unsigned(1156,16),
        29  => to_unsigned(1161,16),
        30  => to_unsigned(1167,16),
        31  => to_unsigned(1172,16),
        32  => to_unsigned(1178,16),
        33  => to_unsigned(1183,16),
        34  => to_unsigned(1189,16),
        35  => to_unsigned(1194,16),
        36  => to_unsigned(1200,16),
        37  => to_unsigned(1206,16),
        38  => to_unsigned(1211,16),
        39  => to_unsigned(1217,16),
        40  => to_unsigned(1222,16),
        41  => to_unsigned(1228,16),
        42  => to_unsigned(1233,16),
        43  => to_unsigned(1239,16),
        44  => to_unsigned(1244,16),
        45  => to_unsigned(1250,16),
        46  => to_unsigned(1256,16),
        47  => to_unsigned(1261,16),
        48  => to_unsigned(1267,16),
        49  => to_unsigned(1272,16),
        50  => to_unsigned(1278,16),
        51  => to_unsigned(1283,16),
        52  => to_unsigned(1289,16),
        53  => to_unsigned(1294,16),
        54  => to_unsigned(1300,16),
        55  => to_unsigned(1306,16),
        56  => to_unsigned(1311,16),
        57  => to_unsigned(1317,16),
        58  => to_unsigned(1322,16),
        59  => to_unsigned(1328,16),
        60  => to_unsigned(1333,16),
        61  => to_unsigned(1339,16),
        62  => to_unsigned(1344,16),
        63  => to_unsigned(1350,16),
        64  => to_unsigned(1356,16),
        65  => to_unsigned(1361,16),
        66  => to_unsigned(1367,16),
        67  => to_unsigned(1372,16),
        68  => to_unsigned(1378,16),
        69  => to_unsigned(1383,16),
        70  => to_unsigned(1389,16),
        71  => to_unsigned(1394,16),
        72  => to_unsigned(1400,16),
        73  => to_unsigned(1406,16),
        74  => to_unsigned(1411,16),
        75  => to_unsigned(1417,16),
        76  => to_unsigned(1422,16),
        77  => to_unsigned(1428,16),
        78  => to_unsigned(1433,16),
        79  => to_unsigned(1439,16),
        80  => to_unsigned(1444,16),
        81  => to_unsigned(1450,16),
        82  => to_unsigned(1456,16),
        83  => to_unsigned(1461,16),
        84  => to_unsigned(1467,16),
        85  => to_unsigned(1472,16),
        86  => to_unsigned(1478,16),
        87  => to_unsigned(1483,16),
        88  => to_unsigned(1489,16),
        89  => to_unsigned(1494,16),
        90  => to_unsigned(1500,16),
        91  => to_unsigned(1506,16),
        92  => to_unsigned(1511,16),
        93  => to_unsigned(1517,16),
        94  => to_unsigned(1522,16),
        95  => to_unsigned(1528,16),
        96  => to_unsigned(1533,16),
        97  => to_unsigned(1539,16),
        98  => to_unsigned(1544,16),
        99  => to_unsigned(1550,16),
        100 => to_unsigned(1556,16),
        101 => to_unsigned(1561,16),
        102 => to_unsigned(1567,16),
        103 => to_unsigned(1572,16),
        104 => to_unsigned(1578,16),
        105 => to_unsigned(1583,16),
        106 => to_unsigned(1589,16),
        107 => to_unsigned(1594,16),
        108 => to_unsigned(1600,16),
        109 => to_unsigned(1606,16),
        110 => to_unsigned(1611,16),
        111 => to_unsigned(1617,16),
        112 => to_unsigned(1622,16),
        113 => to_unsigned(1628,16),
        114 => to_unsigned(1633,16),
        115 => to_unsigned(1639,16),
        116 => to_unsigned(1644,16),
        117 => to_unsigned(1650,16),
        118 => to_unsigned(1656,16),
        119 => to_unsigned(1661,16),
        120 => to_unsigned(1667,16),
        121 => to_unsigned(1672,16),
        122 => to_unsigned(1678,16),
        123 => to_unsigned(1683,16),
        124 => to_unsigned(1689,16),
        125 => to_unsigned(1694,16),
        126 => to_unsigned(1700,16),
        127 => to_unsigned(1706,16),
        128 => to_unsigned(1711,16),
        129 => to_unsigned(1717,16),
        130 => to_unsigned(1722,16),
        131 => to_unsigned(1728,16),
        132 => to_unsigned(1733,16),
        133 => to_unsigned(1739,16),
        134 => to_unsigned(1744,16),
        135 => to_unsigned(1750,16),
        136 => to_unsigned(1756,16),
        137 => to_unsigned(1761,16),
        138 => to_unsigned(1767,16),
        139 => to_unsigned(1772,16),
        140 => to_unsigned(1778,16),
        141 => to_unsigned(1783,16),
        142 => to_unsigned(1789,16),
        143 => to_unsigned(1794,16),
        144 => to_unsigned(1800,16),
        145 => to_unsigned(1806,16),
        146 => to_unsigned(1811,16),
        147 => to_unsigned(1817,16),
        148 => to_unsigned(1822,16),
        149 => to_unsigned(1828,16),
        150 => to_unsigned(1833,16),
        151 => to_unsigned(1839,16),
        152 => to_unsigned(1844,16),
        153 => to_unsigned(1850,16),
        154 => to_unsigned(1856,16),
        155 => to_unsigned(1861,16),
        156 => to_unsigned(1867,16),
        157 => to_unsigned(1872,16),
        158 => to_unsigned(1878,16),
        159 => to_unsigned(1883,16),
        160 => to_unsigned(1889,16),
        161 => to_unsigned(1894,16),
        162 => to_unsigned(1900,16),
        163 => to_unsigned(1906,16),
        164 => to_unsigned(1911,16),
        165 => to_unsigned(1917,16),
        166 => to_unsigned(1922,16),
        167 => to_unsigned(1928,16),
        168 => to_unsigned(1933,16),
        169 => to_unsigned(1939,16),
        170 => to_unsigned(1944,16),
        171 => to_unsigned(1950,16),
        172 => to_unsigned(1956,16),
        173 => to_unsigned(1961,16),
        174 => to_unsigned(1967,16),
        175 => to_unsigned(1972,16),
        176 => to_unsigned(1978,16),
        177 => to_unsigned(1983,16),
        178 => to_unsigned(1989,16),
        179 => to_unsigned(1994,16),
        180 => to_unsigned(2000,16)
    );
    --! @endcond

begin

    ------------------------------------------
    -- PWM Clocking
    ------------------------------------------
    PWM_clk : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                counter_20ms <= (others => '0');
                counter_us <= 1;
            else
                if counter_us = CYCLES_PER_US then
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
    PWM_logic :process(clk)
    begin
        if rst = '0' then
            pwm_out_reg <= (others => '0');
        elsif rising_edge(clk) then
            for i in 0 to NB_PWM-1 loop
                if to_integer(angle_regs(i)) <= 180 then
                    pwm_thresholds(i) <= pwm_lut(to_integer(angle_regs(i)));
                else
                    pwm_thresholds(i) <= to_unsigned(1500, 16); -- security clamp
                end if;

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
    AXI_write : process(clk)
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
    AXI_read : process(clk)
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
