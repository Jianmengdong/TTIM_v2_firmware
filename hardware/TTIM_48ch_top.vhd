----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2019/06/21 21:18:31
-- Design Name: 
-- Module Name: TTIM_48ch_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
library work;
use work.GCUpack.all;
use work.ipbus.all;

entity TTIM_48ch_top is
    generic(
    g_Hamming           : boolean := true;
    g_cs_wonly_deep     : natural := 54; -- configuration space number of write only registers;
    g_cs_ronly_deep     : natural := 200; -- configuration space number of read only registers;	
    g_NSLV              : positive := 6;
    g_TTC_memory_deep   : positive := 26;
	g_number_of_GCU : integer := 48
	);
    Port ( 
    SYS_CLK_P : in STD_LOGIC;
    SYS_CLK_N : in STD_LOGIC;
    --===========================================--
    --     sync link with GCU
    BEC2GCU_1_P : out std_logic_vector(48 downto 1);
    BEC2GCU_1_N : out std_logic_vector(48 downto 1);
    BEC2GCU_2_P : out std_logic_vector(48 downto 1);
    BEC2GCU_2_N : out std_logic_vector(48 downto 1);
    GCU2BEC_1_P : in std_logic_vector(48 downto 1);
    GCU2BEC_1_N : in std_logic_vector(48 downto 1);
    GCU2BEC_2_P : in std_logic_vector(48 downto 1);
    GCU2BEC_2_N : in std_logic_vector(48 downto 1);
    --===========================================--
    --     interface with Mini-WR
    -- PDATA_RX : in std_logic_vector(9 downto 0);
    -- PDATA_TX : out std_logic_vector(9 downto 0);
    -- PPS_IN_P : in std_logic;
    -- PPS_IN_N : in std_logic;
    --===========================================--
    ----    trigger link (MGT)
    SFP_RX_P : in std_logic;
    SFP_RX_N : in std_logic;
    SFP_TX_P : out std_logic;
    SFP_TX_N : out std_logic;
    REF_CLK_P : in std_logic;
    REF_CLK_N : in std_logic;
    --===========================================--
    --     test points
    TP_O : out std_logic_vector(3 downto 0);
    SMA_I : in std_logic; --J6
    SMA_O : out std_logic; --J5
    TP_Header : out std_logic_vector(6 downto 0)
    );
end TTIM_48ch_top;

architecture Behavioral of TTIM_48ch_top is

    signal bec2gcu_1_r,bec2gcu_1_i,inv_o_1,gcu2bec_1_d : std_logic_vector(47 downto 0);
    signal bec2gcu_1_i0,bec2gcu_1_i1,bec2gcu_1_i2 : std_logic_vector(47 downto 0);
    signal bec2gcu_2_r,bec2gcu_2_i,inv_o_2,gcu2bec_2_d : std_logic_vector(47 downto 0);
    signal gcu2bec_1_r,gcu2bec_1_i,inv_i_1 : std_logic_vector(47 downto 0);
    signal gcu2bec_2_r,gcu2bec_2_i,inv_i_2 : std_logic_vector(47 downto 0);
    signal  sys_clk_i,sys_clk_r,sys_clk_lock,clk_10M,clk_125M,clk_200M,clk_250M,clk_62M5 : std_logic;
    signal  trig_to_gcu : std_logic;
    signal  hit_from_gcu,hit_inv,hit_from_gcu_r,sc_from_gcu,sc_inv,sc_from_gcu_r : std_logic_vector(g_number_of_GCU - 1 downto 0);
    signal  time_count : signed(47 downto 0);
    signal  s_global_time,catch_time : std_logic_vector(47 downto 0);
    signal  nhit_gcu,nhit_err,nhit_gcu_r : t_array2;
    signal  i_nhit_gcu,i_nhit_err : std_logic_vector(1 downto 0);
    signal  gcuid_i : t_array16;
    signal  s_ttcrx_ready,aligned,s_aligned,i_aligned,hit_mask,v_hit_mask : std_logic_vector(g_number_of_GCU - 1 downto 0);
    signal  s_cmd_pulse_vector : t_brd_command;
    signal  s_long_frame_in1,s_long_frame_in2,s_long_frame_in3 : t_ttc_long_frame;
    signal  chb_busy_o,chb_grant1_o,s_chb_grant2,s_chb_grant3,chb_req1_i,s_chb_req3,s_ttctx_ready : std_logic;
    signal  s_delay_req : std_logic_vector(g_number_of_GCU - 1 downto 0);
    signal  single_bit_err_cnt,duble_bit_err_cnt,comm_err_cnt : t_array32;
    signal  i_single_bit_err_cnt,i_duble_bit_err_cnt,i_comm_err_cnt : std_logic_vector(31 downto 0);
    signal  gcu_sel,current_gcu : std_logic_vector(5 downto 0);
    signal  gcu_no : integer range 0 to 47;
    signal  sys_clk_u,clk_200,ext_trig,trig_per_i,l1a_i,trig_vio,reset_event,reset_err,v_reset_err : std_logic;
    signal  threshold_i,v_threshold_i : std_logic_vector(5 downto 0);
    signal  period_i,v_period_i : std_logic_vector(31 downto 0);
    signal  en_trig_i,v_en_trig_i : std_logic_vector(4 downto 0);
    signal  ext_trig_i : std_logic_vector(2 downto 0);
    signal  s_1588ptp_period,v_1588ptp_period : std_logic_vector(31 downto 0) := x"20000000";
    signal  s_cs_data_o     : std_logic_vector(g_cs_wonly_deep*32-1 downto 0) := (others => '0');
    signal  s_cs_data_i     : std_logic_vector(g_cs_ronly_deep*32-1 downto 0);
    signal  ipb_mosi_i : ipb_wbus;
    signal  ipb_miso_o : ipb_rbus;
    signal  s_1588ptp_enable,v_1588ptp_enable,use_vio : std_logic;
    signal mac_addr: std_logic_vector(47 downto 0);
	signal ip_addr: std_logic_vector(31 downto 0);
    signal ipb_master_out: ipb_wbus;
	signal ipb_master_in: ipb_rbus;
    signal rst_ipb,ipb_clk,pkt_rx,pkt_tx,soft_rst,s_go,rst_event : std_logic;
    signal s_status             : std_logic_vector(31 downto 0);
    signal ptp_fsm : std_logic_vector(4 downto 0);
    signal clk_phs1,clk_phs2,clk_phs3 : std_logic_vector(95 downto 0);
    signal gcu2bec_1_i0,gcu2bec_1_i1,gcu2bec_1_i2,gcu2bec_2_i0,gcu2bec_2_i1,gcu2bec_2_i2: std_logic_vector(47 downto 0);
    signal sc_in, hit_in : std_logic_vector(47 downto 0);
    signal clk_62M5_1,clk_62M5_2,clk_125M_1,clk_125M_2 : std_logic;
    signal s_chb_req2,s_tap_calib_enable,s_chb_req4,s_chb_grant4 : std_logic;
    
begin
--================================================--
--  the BEC2GCU link doesn't need invertion if it's clk link
g_sync_link: for i in 47 downto 0 generate
    i_bec2gcu1: OBUFDS
        generic map(
        SLEW => "SLOW"
        )
        port map(
        I => clk_62M5,
        O => BEC2GCU_1_P(i+1),
        OB => BEC2GCU_1_N(i+1)
        );
        --bec2gcu_1_r(i) <= bec2gcu_1_i(i) when inv_o_1(i) = '0' else not bec2gcu_1_i(i);
        --bec2gcu_1_r(i) <= prbs_o when inv_o_1(i) = '0' else not prbs_o;
    i_bec2gcu2: OBUFDS
        generic map(
        SLEW => "SLOW"
        )
        port map(
        I => bec2gcu_1_r(i),
        O => BEC2GCU_2_P(i+1),
        OB => BEC2GCU_2_N(i+1)
        );
        bec2gcu_1_r(i) <= bec2gcu_1_i0(i) when clk_phs3(i * 2 + 1 downto i * 2) = "00" else 
                    bec2gcu_1_i1(i) when clk_phs3(i * 2 + 1 downto i * 2) = "01" else 
                    bec2gcu_1_i2(i);
        bec2gcu_1_i(i) <= trig_to_gcu when inv_o_1(i) = '0' else not trig_to_gcu;
    i_gcu2bec1: IBUFDS
        port map(
        I => GCU2BEC_1_P(i+1),
        IB => GCU2BEC_1_N(i+1),
        O => gcu2bec_2_r(i)
        );
        gcu2bec_1_i(i) <= gcu2bec_1_r(i) when inv_i_1(i) = '0' else not gcu2bec_1_r(i);
    i_gcu2bec2: IBUFDS
        port map(
        I => GCU2BEC_2_P(i+1),
        IB => GCU2BEC_2_N(i+1),
        O => gcu2bec_1_r(i)
        );
        gcu2bec_2_i(i) <= gcu2bec_2_r(i) when inv_i_2(i) = '0' else not gcu2bec_2_r(i);
end generate;
--===========================================--
i_sys_clk: IBUFDS
    port map(
    I => SYS_CLK_P,
    IB => SYS_CLK_N,
    O => sys_clk_u
    );
i_sysclk_bufg: BUFG
    port map(
    I => sys_clk_u,
    O => sys_clk_i
    );
i_clk_gen:entity work.clk_wiz_0
   port map ( 
  -- Clock out ports  
   clk_out1 => open,
   clk_out2 => clk_62M5,
   clk_out3 => clk_125M,
   clk_out4 => clk_125M_1,
   clk_out5 => clk_125M_2,
   clk_out6 => clk_62M5_1,
   clk_out7 => clk_62M5_2,
  -- Status and control signals                
   locked => sys_clk_lock,
   -- Clock in ports
   clk_in1 => sys_clk_i
 );
process(clk_125M)
begin
    if rising_edge(clk_125M) then
        bec2gcu_1_i0 <= bec2gcu_1_i;
    end if;
end process;
process(clk_125M_1)
begin
    if rising_edge(clk_125M_1) then
        bec2gcu_1_i1 <= bec2gcu_1_i;
    end if;
end process;
process(clk_125M_2)
begin
    if rising_edge(clk_125M_2) then
        bec2gcu_1_i2 <= bec2gcu_1_i;
    end if;
end process;
process(clk_125M)
begin
    if rising_edge(clk_125M) then
        gcu2bec_1_i0 <= gcu2bec_1_i;
    end if;
end process;
process(clk_125M_1)
begin
    if rising_edge(clk_125M_1) then
        gcu2bec_1_i1 <= gcu2bec_1_i;
    end if;
end process;
process(clk_125M_2)
begin
    if rising_edge(clk_125M_2) then
        gcu2bec_1_i2 <= gcu2bec_1_i;
    end if;
end process;
process(clk_62M5)
begin
    if rising_edge(clk_62M5) then
        gcu2bec_2_i0 <= gcu2bec_2_i;
    end if;
end process;
process(clk_62M5_1)
begin
    if rising_edge(clk_62M5_1) then
        gcu2bec_2_i1 <= gcu2bec_2_i;
    end if;
end process;
process(clk_62M5_2)
begin
    if rising_edge(clk_62M5_2) then
        gcu2bec_2_i2 <= gcu2bec_2_i;
    end if;
end process;
 ---------------------------------global time counter---------------------------------
p_time_counter : process(clk_125M)
begin
   if rising_edge(clk_125M) then
      if sys_clk_lock = '0' then
         time_count <= (others => '0');
      else
         time_count <= time_count + 1;
      end if;
   end if;
end process p_time_counter;
s_global_time <= std_logic_vector(time_count);
----TTC tx, Trig and slow control to GCU
Inst_ttc_encoder : entity work.ttc_encoder
    generic map(
      g_pll_locked_delay => 200
      )
    port map(
    locked_i         => sys_clk_lock,
    ttc_sys_clock_i  => clk_62M5,
    clk_x2_i         => clk_125M,
    --clk_x4_i         => clk_250M,
    brd_cmd_vector_i => s_cmd_pulse_vector,
    l1a_i            => l1a_i,
    long_frame1_i    => s_long_frame_in1,
    long_frame2_i    => s_long_frame_in2,
    long_frame3_i    => s_long_frame_in3,
    ttc_stream_o     => trig_to_gcu, --TTC up link
    chb_busy_o       => chb_busy_o,
    chb_grant1_o     => chb_grant1_o, --brd cmd channel
    chb_grant2_o     => s_chb_grant2,
    chb_grant3_o     => s_chb_grant3,
    chb_grant4_o     => s_chb_grant4,
    chb_req1_i       => chb_req1_i,
    chb_req2_i       => s_chb_req2,
    chb_req3_i       => s_chb_req3,
    chb_req4_i       => s_chb_req4,
    ready_o          => s_ttctx_ready,
    sbit_err_inj_i   => '0',
    dbit_err_inj_i   => '0',
    err_pos1_i       => "000000",
    err_pos2_i       => "000000"
    );
Inst_brd_cmd:entity work.brd_cmd_generator
    port map(
    clk_i => clk_62M5,
    rst_i => not s_ttctx_ready,
    period => s_global_time(10),
    rst_event => rst_event,
    chb_busy_i => chb_busy_o,
    chb_req_o => chb_req1_i,
    chb_grant_i => chb_grant1_o,
    brd_cmd_vector => s_cmd_pulse_vector
    );
i_trig_gen:entity work.trigger_gen
    port map(
    clk_i => clk_62M5,
    ipb_clk_i => ipb_clk,
    reset_i => not s_ttctx_ready,
    reset_event_cnt_i => reset_event,
    en_trig_i => en_trig_i,
    ext_trig_i => ext_trig_i,
    trig_o => l1a_i,
    global_time_i => s_global_time,
    chb_grant_i     => s_chb_grant2,
    chb_req_o       => s_chb_req2,
    ttc_long_o      => s_long_frame_in1,
    period_i => period_i,
    threshold_i => threshold_i,
    hit_i => nhit_gcu_r,
    rst_event => rst_event,
    hit_mask_i => hit_mask,
    ipb_mosi_i => ipb_mosi_i,
    ipb_miso_o => ipb_miso_o,
    trig_info_o => open,
    debug_fsm => open
    );
i_r_sma:entity work.r_edge_detect
    generic map(
      g_clk_rise => "TRUE"
      )
    port map(
      clk_i => clk_62M5,
      sig_i => SMA_I,
      sig_o => ext_trig_i(0)
    );
i_r_vio:entity work.r_edge_detect
    generic map(
      g_clk_rise => "TRUE"
      )
    port map(
      clk_i => clk_62M5,
      sig_i => trig_vio,
      sig_o => ext_trig_i(1)
    );
genGCUupLink:for i in g_number_of_GCU - 1 downto 0 generate
    gcuid_i(i) <= std_logic_vector(to_unsigned(i + 1, 16));
    hit_in(i) <= gcu2bec_1_i0(i) when clk_phs1(i * 2 + 1 downto i * 2) = "00" else 
                 gcu2bec_1_i1(i) when clk_phs1(i * 2 + 1 downto i * 2) = "01" else 
                 gcu2bec_1_i2(i);
    ----Hit receiver, recognize hit from GCU
    Inst_hit_recognizer:entity work.hit_recognizer
        port map(
        hit_from_gcu => hit_in(i),
        clk_i => clk_62M5,
        clk_x2_i => clk_125M,
        rst_i => not sys_clk_lock,
        --aligned_o => open,
        hit_o => nhit_gcu(i)
        );
        nhit_gcu_r(i) <= nhit_gcu(i) when hit_mask(i) = '1' else (others => '0');
        FakeHitChk:entity work.PRBS_ANY
        generic map(
        CHK_MODE => true,
        INV_PATTERN => false,
        POLY_LENGHT => 7,
        POLY_TAP => 3,
        NBITS => 2
        )
        port map(
        RST => '0',
        CLK => clk_62M5,
        DATA_IN => nhit_gcu(i),
        EN => '1',
        DATA_OUT => nhit_err(i)
        );
    ----slow control receiver
    sc_in(i) <= gcu2bec_2_i0(i) when clk_phs2(i * 2 + 1 downto i * 2) = "00" else 
                gcu2bec_2_i1(i) when clk_phs2(i * 2 + 1 downto i * 2) = "01" else 
                gcu2bec_2_i2(i);
    Inst_sc_decoder:entity work.sc_decoder
        generic map(
        g_Hamming => g_Hamming,
        g_TTC_memory_deep => g_TTC_memory_deep
        )
        port map(
        sc_from_gcu          => sc_in(i),
        clk_i                => clk_62M5,
        rst_i                => not sys_clk_lock,
        ttcrx_coarse_delay_i => "00000",
        gcuid_i              => gcuid_i(i),
        brd_command_vector_o => open,
        l1a_time_o           => open,
        synch_o              => open,
        delay_req_o          => s_delay_req(i),
        synch_req_o          => open,
        byte5_o              => open,
        delay_o              => open,
        ttc_ctrl_o           => open,
        single_bit_err_o     => single_bit_err_cnt(i),
        duble_bit_err_o      => duble_bit_err_cnt(i),
        comm_err_o           => comm_err_cnt(i),
        ready_o              => s_ttcrx_ready(i),
        reset_err            => reset_err,
        no_errors_o          => open,
        aligned_o            => aligned(i),
        not_in_table_o       => open
        );
        s_aligned(i) <= aligned(i) when hit_mask(i) = '1' else '0';
end generate;
---------------------------------1588 ptp protocol BEC side-------------------------
Inst_bec_1588_ptp:entity work.BEC_1588_ptp_v2
    port map(
    clk_i   => clk_125M,
    clk_div2 => clk_62M5,
    rst_i   => not s_ttctx_ready,
    ttcrx_ready => s_aligned,
    enable_i    => s_1588ptp_enable,
    period_i    => s_1588ptp_period,--x"20000000", --32b time interval for ptp check
    delay_req_i => s_delay_req,
    chb_grant_i => s_chb_grant3,
    local_time_i=> s_global_time, --48b local time
    chb_req_o   => s_chb_req3,
    fsm_debug_o => ptp_fsm,
    current_gcu => current_gcu,
    catch_time => catch_time,
    s_go_o => s_go,
    gcu_id_i    => gcuid_i, --GCU IDs in parallel
    ttc_long_o  => s_long_frame_in2 --ttc long format to encoder
    );
------------------------------------------------------------------------------------
------------------------------------TTC calibration---------------------------------			  
Inst_tap_calibration: entity work.tap_calibration 
   generic map(
	       g_number_of_GCU => g_number_of_GCU,
			 g_error_threshold => 10
	       )
   port map(	
        clk_i           => clk_62M5,
        rst_i           => not s_ttctx_ready,  
        start_i         => s_tap_calib_enable,  
        gcu_sel_i       => gcu_sel,   
		aligned_i       => s_aligned, -- 48 bit
		comm_err_i      => comm_err_cnt,  
        chb_grant_i     => s_chb_grant4, 
        chb_req_o       => s_chb_req4, 
		gcu_id_i        => gcuid_i, 
		ttc_long_o      => s_long_frame_in3,
		eye_o           => open, 
		debug_fsm_o     => open,
		debug_bomb_o    => open,
		debug_error     => open,
		debug_bit       => open
           );

-- gen_eye_vector : for i in 1 to g_number_of_GCU generate
   -- s_eye_v(i - 1) <= x"000000" & '0' & s_tap_eye(i*7 - 1 downto (i - 1)*7);
-- end generate gen_eye_vector;
------------------------------------------------------------------------------------
--------------------------------------eye scanner-----------------------------------	
-- Inst_eye_scan: entity work.eye_scan 
   -- generic map(
	       -- g_number_of_GCU => g_number_of_GCU
	       -- )
   -- port map(	
           -- clk_i           => s_sysclk_x4,
           -- rst_i           => s_reset or (not s_ttctx_ready),  
           -- tap_rst_i       => s_tap_rst,
           -- tap_incr_i      => s_tap_incr,
			  -- gcu_sel_i       => s_gcu_sel,             
			  -- chb_grant_i     => s_chb_grant4,
           -- chb_req_o       => s_chb_req4,
			  -- gcu_id_i        => s_gcuid_vec,
			  -- ttc_long_o      => s_long_frame_in3,
			  -- comm_err_i      => s_comm_err,
			  -- error_count_o   => s_tap_error_count,
			  -- debug_fsm_o     => s_eye_fsm_debug
           -- );
			  
-- gen_comm_err_vector : for i in 1 to g_number_of_GCU generate
   -- s_comm_err(i*32 - 1 downto (i-1)*32)<= comm_err_cnt(i-1);
-- end generate gen_comm_err_vector;
----- IPbus core and slaves inst
ipbus_core: entity work.kc705_basex_infra
	port map(
		eth_clk_p => REF_CLK_P,
		eth_clk_n => REF_CLK_N,
        sys_clk => clk_62M5,
		gtrefclk_out => open,
		eth_tx_p => SFP_TX_P,
		eth_tx_n => SFP_TX_N,
		eth_rx_p => SFP_RX_P,
		eth_rx_n => SFP_RX_N,
		sfp_los => '0',
		clk_ipb_o => ipb_clk,
		rst_ipb_o => rst_ipb,
		nuke => '0',
		soft_rst => soft_rst,
		leds => open,
		mac_addr => mac_addr,
		ip_addr => ip_addr,
		ipb_in => ipb_master_in,
		ipb_out => ipb_master_out,
        pkt_rx => pkt_rx,
        pkt_tx => pkt_tx,
        clk125_out => open,
        phy_done_out => open
	);
    mac_addr <= X"021ddba11509"; -- Careful here, arbitrary addresses do not always work
	ip_addr <= X"C0A80110";  -- 192.168.1.16
    
    ipbus_slaves: entity work.slaves
    generic map(
	    g_cs_wonly_deep => g_cs_wonly_deep, -- configuration space number of write only registers;
        g_cs_ronly_deep => g_cs_ronly_deep,  -- configuration space number of read only registers;
	    g_NSLV          => g_NSLV
        )
    port map(
	    ipb_clk          => ipb_clk,  -- 31.25 MHz
	    ipb_rst          => rst_ipb,
	    ipb_in           => ipb_master_out,
	    ipb_out          => ipb_master_in,
	    rst_out          => soft_rst,
	    cs_data_o        => s_cs_data_o,
	    cs_data_i        => s_cs_data_i,
        ipb_mosi_i => ipb_mosi_i,
        ipb_miso_o => ipb_miso_o,
	    pkt_rx           => pkt_rx,
	    pkt_tx           => pkt_tx
	    );
s_cs_data_i(63 downto 0) <= x"0000" & s_global_time(47 downto 32) & s_global_time(31 downto 0);

GEN_GCU_STATUS_ARRAY_1:
for I in 1 to 48 generate
	s_cs_data_i((2 + I)*32 - 1 downto (1 + I)*32) <= single_bit_err_cnt(I - 1)(31 downto 0);
	s_cs_data_i((50 + I)*32 - 1 downto (49 + I)*32) <= duble_bit_err_cnt(I - 1)(31 downto 0);
	s_cs_data_i((98 + I)*32 - 1 downto (97 + I)*32) <= comm_err_cnt(I - 1)(31 downto 0);
	s_cs_data_i((151 + I)*32 - 1 downto (150 + I)*32) <= (others => '0');--s_eye_v(I - 1);
end generate GEN_GCU_STATUS_ARRAY_1;

s_cs_data_i(147*32 - 1 downto 146*32) <= s_ttcrx_ready(31 downto 0);
s_cs_data_i(148*32 - 1 downto 147*32) <= x"0000" & s_ttcrx_ready(47 downto 32);
s_cs_data_i(149*32 - 1 downto 148*32) <= s_aligned(31 downto 0);
s_cs_data_i(150*32 - 1 downto 149*32) <= x"0000" & s_aligned(47 downto 32);
s_cs_data_i(151*32 - 1 downto 150*32) <= s_status;
s_cs_data_i(200*32 - 1 downto 199*32) <= (others => '0'); --s_tap_error_count;

s_status <= x"0000000" & '0' & chb_grant1_o & s_ttctx_ready & sys_clk_lock;
--s_coarse_delay                <= s_cs_data_o(4) & s_cs_data_o(3) & s_cs_data_o(2) & s_cs_data_o(1) & s_cs_data_o(0);
en_trig_i                <= s_cs_data_o(4 downto 0) when use_vio = '0' else v_en_trig_i;
reset_err                  <= s_cs_data_o(5) when use_vio = '0' else v_reset_err; --reset
s_1588ptp_enable              <= s_cs_data_o(6) when use_vio = '0' else v_1588ptp_enable;
--s_polarity                    <= s_cs_data_o(7) when use_vio = '0' else v_polarity;
--s_chb_req1                    <= s_cs_data_o(8) when use_vio = '0' else v_chb_req1;
--s_tap_calib_enable            <= s_cs_data_o(9) when use_vio = '0' else v_tap_calib_enable;
--s_tap_rst                     <= s_cs_data_o(26) when use_vio = '0' else v_tap_rst;
--s_tap_incr                    <= s_cs_data_o(27) when use_vio = '0' else v_tap_incr;
s_1588ptp_period              <= s_cs_data_o(63 downto 32) when use_vio = '0' else v_1588ptp_period;
--s_pulse_time(31 downto 0)     <= s_cs_data_o(95 downto 64) when use_vio = '0' else v_pulse_time(31 downto 0); 
period_i     <= s_cs_data_o(95 downto 64) when use_vio = '0' else v_period_i; 
--s_pulse_time(47 downto 32)    <= s_cs_data_o(111 downto 96) when use_vio = '0' else v_pulse_time(47 downto 32); 
hit_mask    <= s_cs_data_o(143 downto 96) when use_vio = '0' else v_hit_mask; 
--s_pulse_width                 <= s_cs_data_o(159 downto 128) when use_vio = '0' else v_pulse_width;
--s_pulse_delay                 <= s_cs_data_o(191 downto 160) when use_vio = '0' else v_pulse_delay;
--s_gcu_sel                     <= s_cs_data_o(15 downto 10) when use_vio = '0' else v_gcu_sel;
threshold_i                     <= s_cs_data_o(15 downto 10) when use_vio = '0' else v_threshold_i;

---- debug cores
InstILA :entity work.ila_0
    port map(
    clk => clk_125M,
    probe0 => i_nhit_gcu,
    probe1 => i_single_bit_err_cnt,
    probe2 => i_duble_bit_err_cnt,
    probe3 => i_comm_err_cnt,
    probe4 => i_aligned,
    probe5 => s_ttcrx_ready,
    probe6 => s_global_time,
    probe7 => i_nhit_err,
    probe8 => ptp_fsm,
    probe9(0) => l1a_i,
    probe10 => current_gcu,
    probe11 => catch_time,
    probe12(0) => s_cmd_pulse_vector.rst_event
    );
    process(clk_125M)
    begin
        if rising_edge(clk_125M) then
            i_nhit_gcu <= nhit_gcu(gcu_no);
            i_single_bit_err_cnt <= single_bit_err_cnt(gcu_no);
            i_duble_bit_err_cnt <= duble_bit_err_cnt(gcu_no);
            i_comm_err_cnt <= comm_err_cnt(gcu_no);
            i_nhit_err <= nhit_err(gcu_no);
            i_aligned <= s_aligned;
        end if;
    end process;
    
InstVIO:entity work.vio_0
    port map(
    clk => clk_62M5,
    probe_out0 => inv_i_1,
    probe_out1 => inv_i_2,
    probe_out2 => gcu_sel,
    probe_out3(0) => v_reset_err,
    probe_out4 => v_period_i, --periodic trigger gen
    probe_out5 => v_en_trig_i,
    probe_out6 => v_threshold_i,
    probe_out7(0) => v_1588ptp_enable,
    probe_out8(0) => use_vio,
    probe_out9 => v_hit_mask,
    probe_out10(0) => trig_vio,
    probe_out11(0) => reset_event,
    probe_out12 => inv_o_1,
    probe_out13 => v_1588ptp_period,
    probe_out14 => clk_phs1,
    probe_out15 => clk_phs2,
    probe_out16 => clk_phs3,
    probe_out17(0) => s_tap_calib_enable
    );
    gcu_no <= to_integer(unsigned(gcu_sel));
TP_Header <= (others => '0');
TP_O(3 downto 2) <= '0' & s_global_time(10);
TP_O(1 downto 0) <= gcu2bec_2_i(gcu_no) & gcu2bec_1_i(gcu_no);
SMA_O <= l1a_i;
end Behavioral;
