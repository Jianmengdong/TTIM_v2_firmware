
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.lite_bus_pack.all;
use work.TTIM_v2_pack.all;

entity TTIM_v2_top is
    Port ( 
    SYS_CLK_P : in STD_LOGIC;
    SYS_CLK_N : in STD_LOGIC;
    --===========================================--
    --     sync link to GCU
    BEC2GCU_1_P : out std_logic_vector(48 downto 1);
    BEC2GCU_1_N : out std_logic_vector(48 downto 1);
    BEC2GCU_2_P : out std_logic_vector(48 downto 1);
    BEC2GCU_2_N : out std_logic_vector(48 downto 1);
    GCU2BEC_1_P : in std_logic_vector(48 downto 1);
    GCU2BEC_1_N : in std_logic_vector(48 downto 1);
    GCU2BEC_2_P : in std_logic_vector(48 downto 1);
    GCU2BEC_2_N : in std_logic_vector(48 downto 1);
    --===========================================--
    ----    trigger link (MGT)
    SFP_RX_P : in std_logic;
    SFP_RX_N : in std_logic;
    SFP_TX_P : out std_logic;
    SFP_TX_N : out std_logic;
    REF_CLK_P : in std_logic;
    REF_CLK_N : in std_logic;
    --===========================================--
    --     interface with Mini-WR
    PDATA_RX : in std_logic_vector(9 downto 0);
    PDATA_TX : inout std_logic_vector(9 downto 0);
    PPS_IN_P : in std_logic;
    PPS_IN_N : in std_logic;
    --===========================================--
    --     test points
    TP_O : out std_logic_vector(3 downto 0);
    SMA_O : inout std_logic_vector(1 downto 0);
    TP_Header : in std_logic_vector(6 downto 0)
    );
end TTIM_v2_top;

architecture Behavioral of TTIM_v2_top is

    signal clk_i,clk_x2_i,clk_200,locked,pps_i : std_logic;
    signal timestamp_i,test_mode_i : std_logic_vector(47 downto 0);
    signal reset_err,l1a_i,inj_err,pair_swap,ttctx_ready : std_logic;
    signal hit_i : t_array2(47 downto 0);
    signal ch_mask_i,ch_ready_i,tx2_en,tx1_sel,inv_o_1 : std_logic_vector(47 downto 0);
    signal ch_sel_i : std_logic_vector(5 downto 0);
    signal tap_cnt_i :std_logic_vector(6 downto 0);
    signal ld_i,ext_trig_i :std_logic_vector(1 downto 0);
    signal error_time1_o,error_time2_o : std_logic_vector(47 downto 0);
    signal error_counter1_o,error_counter2_o,s_1588ptp_period,period_i : std_logic_vector(31 downto 0);
    signal en_trig_i : std_logic_vector(4 downto 0);
    signal trig_i : std_logic_vector(15 downto 0);
    signal nhit_i,threshold_i : std_logic_vector(7 downto 0);
    signal lite_bus_w : t_lite_wbus_arry(NSLV - 1 downto 0);
    signal lite_bus_r : t_lite_rbus_arry(NSLV - 1 downto 0);
    signal register_array,register_array_r : t_array48(NSLV - 1 downto 0);
    signal rx_aligned : std_logic;
begin
--===========================================--
--     sync link to GCU
Inst_clk_time:entity work.clk_time
    port map(
    SYS_CLK_P => SYS_CLK_P,
    SYS_CLK_N => SYS_CLK_N,
    clk_o => clk_i,
    clk_x2_o => clk_x2_i,
    clk_200 => clk_200,
    locked_o => locked,
    pps_i => pps_i,
    timestamp_o => timestamp_i
    );
--===========================================--
--     sync link to GCU
Inst_sync_link:entity work.sync_links
    port map(
    BEC2GCU_1_P =>BEC2GCU_1_P,
    BEC2GCU_1_N => BEC2GCU_1_N,
    BEC2GCU_2_P => BEC2GCU_2_P,
    BEC2GCU_2_N => BEC2GCU_2_N,
    GCU2BEC_1_P => GCU2BEC_1_P,
    GCU2BEC_1_N => GCU2BEC_1_N,
    GCU2BEC_2_P => GCU2BEC_2_P,
    GCU2BEC_2_N => GCU2BEC_2_N,
    
    clk_i       => clk_i,
    clk_x2_i    => clk_x2_i,
    clk_200     => clk_200,
    sys_clk_lock => locked,
    test_mode_i => test_mode_i,
    reset_i     => reset_err,
    l1a_i       => l1a_i,
    nhit_gcu_o  => hit_i,
    timestamp_i => timestamp_i,
    ch_mask_i   => ch_mask_i,
    ch_ready_o  => ch_ready_i,
    tx2_en      => tx2_en,
    tx1_sel     => tx1_sel,
    inv_o_1     => inv_o_1,
    ch_sel_i    => ch_sel_i,
    tap_cnt_i   => tap_cnt_i,
    ld_i        => ld_i,
    inj_err     => inj_err,
    pair_swap   => pair_swap,
    ttctx_ready => ttctx_ready,
    error_time1_o    => error_time1_o,
    error_time2_o    => error_time2_o,
    error_counter1_o => error_counter1_o,
    error_counter2_o => error_counter2_o,
    s_1588ptp_period => s_1588ptp_period
    );
--========================================--
--  trigger generator
Inst_trig_gen:entity work.trigger_gen
    port map(
    clk_i => clk_i,
    reset_i => not ttctx_ready,
    reset_event_cnt_i => '0',
    en_trig_i => en_trig_i,
    ext_trig_i => ext_trig_i,
    l1a_o => l1a_i,
    trig_i => trig_i,
    global_time_i => timestamp_i,
    period_i => period_i,
    threshold_i => threshold_i,
    hit_i => hit_i,
    nhit_o => nhit_i
    --trig_info_o => open
    );
    ext_trig_i(0) <= SMA_O(1);
    ext_trig_i(1) <= '0';
--========================================--
--  trigger link with RMU
Inst_trig_link:entity work.trigger_link
    port map(
    SFP_RX_P => SFP_RX_P,
    SFP_RX_N => SFP_RX_N,
    SFP_TX_P => SFP_TX_P,
    SFP_TX_N => SFP_TX_N,
    REF_CLK_P=> REF_CLK_P,
    REF_CLK_N=> REF_CLK_N,
    trig_o => trig_i,
    nhit_i => nhit_i,
    clk_i => clk_i,
    reset_i => not locked,
    rx_aligned => rx_aligned
    );
--========================================--
--  interface with mini-WR
Inst_wr_interface:entity work.wr_interface
    port map(
    sys_clk_i => clk_x2_i,
    reset_i => not locked,
    PPS_IN_P => PPS_IN_P,
    PPS_IN_N => PPS_IN_N,
    PDATA_RX => PDATA_RX,
    PDATA_TX => PDATA_TX,
    lite_bus_w => lite_bus_w,
    lite_bus_r => lite_bus_r,
    pps_o => pps_i
    );
--=======================================--
--  local control_registers
Inst_regs:entity work.control_registers
    port map(
    sys_clk_i => clk_x2_i,
    reset_i => not locked,
    lite_bus_w => lite_bus_w,
    lite_bus_r => lite_bus_r,
    register_o => register_array,
    register_i => register_array_r
    );
  -- register map----
    -- w/r registers
    test_mode_i <= register_array(0);
    register_array_r(0) <= test_mode_i;
    ch_mask_i <= register_array(1);
    register_array_r(1) <= ch_mask_i;
    tx2_en <= register_array(2);
    register_array_r(2) <= tx2_en;
    tx1_sel <= register_array(3);
    register_array_r(3) <= tx1_sel;
    inv_o_1 <= register_array(4);
    register_array_r(4) <= inv_o_1;
    tap_cnt_i <= register_array(5)(6 downto 0);
    register_array_r(5) <= x"0000000000"&"0"&tap_cnt_i;
    ch_sel_i <= register_array(6)(5 downto 0);
    register_array_r(6) <= x"0000000000"&"00"&ch_sel_i;
    ld_i <= register_array(7)(1 downto 0);
    register_array_r(7) <= x"00000000000"&"00"&ld_i;
    reset_err <= register_array(8)(0);
    inj_err <= register_array(8)(1);
    register_array_r(8) <= x"00000000000"&"00"&inj_err&reset_err;
    pair_swap <= register_array(9)(0);
    register_array_r(9) <= x"00000000000"&"000"&pair_swap;
    en_trig_i <= register_array(10)(4 downto 0);
    register_array_r(10) <= x"0000000000"&"000"&ch_sel_i;
    -- read-only registers
    register_array_r(11) <= x"00000000001"&"0"&rx_aligned&ttctx_ready&locked;
    register_array_r(12) <= ch_ready_i;
    register_array_r(13) <= error_time1_o;
    register_array_r(14) <= error_time2_o;
    register_array_r(15) <= x"0000"&error_counter1_o;
    register_array_r(16) <= x"0000"&error_counter2_o;
    register_array_r(19 downto 17) <= (others => (others => '0'));
--=================================--
--  test signals
SMA_O(0) <= pps_i when TP_Header(0) = '1' else clk_i;
SMA_O(1) <= 'Z';

--TP_Header <= (others => '0');
TP_O <= (others => '0');
end Behavioral;
