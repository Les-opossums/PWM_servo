
# Entity: pwm_axi_slave 
- **File**: PWM.vhd
- The aim of this VHDL file is to create an interface between PS and SERVO motors connected to the ZYNQ.

## Diagram
![Diagram](media/pwm_axi_slave.svg "Diagram")
## Generics

| Generic name | Type    | Value     | Description                        |
| ------------ | ------- | --------- | ---------------------------------- |
| FREQ         | integer | 100000000 | clock frequency : 100 MHz default  |
| NB_PWM       | integer | 8         | number of PWM channels : 8 default |

## Ports

| Port name     | Direction | Type                                | Description            |
| ------------- | --------- | ----------------------------------- | ---------------------- |
| clk           | in        | std_logic                           | clock input            |
| rst           | in        | std_logic                           | reset input active low |
| s_axi_awaddr  | in        | std_logic_vector(31 downto 0)       | write address          |
| s_axi_awvalid | in        | std_logic                           | write address valid    |
| s_axi_awready | out       | std_logic                           | write address ready    |
| s_axi_wdata   | in        | std_logic_vector(31 downto 0)       | write data             |
| s_axi_wvalid  | in        | std_logic                           | write data valid       |
| s_axi_wready  | out       | std_logic                           | write data ready       |
| s_axi_bresp   | out       | std_logic_vector(1 downto 0)        | write response         |
| s_axi_bvalid  | out       | std_logic                           | write response valid   |
| s_axi_bready  | in        | std_logic                           | write response ready   |
| s_axi_araddr  | in        | std_logic_vector(31 downto 0)       | read address           |
| s_axi_arvalid | in        | std_logic                           | read address valid     |
| s_axi_arready | out       | std_logic                           | read address ready     |
| s_axi_rdata   | out       | std_logic_vector(31 downto 0)       | read data              |
| s_axi_rresp   | out       | std_logic_vector(1 downto 0)        | read response          |
| s_axi_rvalid  | out       | std_logic                           | read response valid    |
| s_axi_rready  | in        | std_logic                           | read response ready    |
| pwm_out       | out       | std_logic_vector(NB_PWM-1 downto 0) | PWM output             |

## Signals

| Name           | Type                                | Description              |
| -------------- | ----------------------------------- | ------------------------ |
| angle_regs     | t_angle_array                       |                          |
| pwm_thresholds | t_pwm_thresholds                    | default threshold 1500us |
| pwm_out_reg    | std_logic_vector(NB_PWM-1 downto 0) | PWM output register      |
| counter_20ms   | unsigned(15 downto 0)               | 20ms counter             |
| counter_us     | integer range 1 to CYCLES_PER_US    | microsecond counter      |
| awready_reg    | std_logic                           |                          |
| wready_reg     | std_logic                           |                          |
| bvalid_reg     | std_logic                           |                          |
| arready_reg    | std_logic                           |                          |
| rvalid_reg     | std_logic                           |                          |
| write_addr     | unsigned(31 downto 0)               |                          |
| write_data     | unsigned(31 downto 0)               |                          |
| read_addr      | unsigned(31 downto 0)               |                          |
| rdata_reg      | std_logic_vector(31 downto 0)       |                          |

## Constants

| Name          | Type      | Value          | Description            |
| ------------- | --------- | -------------- | ---------------------- |
| CYCLES_PER_US | integer   | FREQ / 1000000 | cycles per microsecond |
| pwm_lut       | t_pwm_lut | gen_pwm_lut    |                        |

## Types

| Name             | Type | Description                   |
| ---------------- | ---- | ----------------------------- |
| t_angle_array    |      | 0-180 degrees                 |
| t_pwm_thresholds |      | PWM thresholds                |
| t_pwm_lut        |      | lut to store PWM pulse widths |

## Functions
- gen_pwm_lut <font id="function_arguments">()</font> <font id="function_return">return t_pwm_lut</font>

## Processes
- PWM_clk: ( clk )
- PWM_logic: ( clk )
- AXI_write: ( clk )
- AXI_read: ( clk )
