
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.TTIM_v2_pack.all;
entity sync_links is
    generic(
    g_Hamming : boolean  := true;
    g_TTC_memory_deep  : positive := 25
    );
    Port ( 
    -- hardware interface
    BEC2GCU_1_P : out std_logic_vector(48 downto 1);
    BEC2GCU_1_N : out std_logic_vector(48 downto 1);
    BEC2GCU_2_P : out std_logic_vector(48 downto 1);
    BEC2GCU_2_N : out std_logic_vector(48 downto 1);
    GCU2BEC_1_P : in std_logic_vector(48 downto 1);
    GCU2BEC_1_N : in std_logic_vector(48 downto 1);
    GCU2BEC_2_P : in std_logic_vector(48 downto 1);
    GCU2BEC_2_N : in std_logic_vector(48 downto 1);
    -- internal signals
    clk_i : in STD_LOGIC;
    clk_x2_i : in STD_LOGIC;
    clk_200 : in std_logic;
    sys_clk_lock : in std_logic;
    reset_i : in std_logic;
    test_mode_i : in std_logic_vector(47 downto 0);
    l1a_i : in std_logic;
    nhit_gcu_o : out t_array2(47 downto 0);
    timestamp_i : in std_logic_vector(47 downto 0);
    ch_mask_i : in std_logic_vector(47 downto 0);
    ch_ready_o : out std_logic_vector(47 downto 0);
    tx2_en : in std_logic_vector(47 downto 0);
    tx1_sel : in std_logic_vector(47 downto 0);
    inv_o_1 : in std_logic_vector(47 downto 0);
    ch_sel_i : in std_logic_vector(5 downto 0);
    tap_cnt_i : in std_logic_vector(6 downto 0);
    ld_i : in std_logic_vector(1 downto 0);
    inj_err : in std_logic;
    pair_swap : in std_logic;
    ttctx_ready : out std_logic;
    error_time1_o : out std_logic_vector(47 downto 0);
    error_time2_o : out std_logic_vector(47 downto 0);
    error_counter1_o : out std_logic_vector(31 downto 0);
    error_counter2_o : out std_logic_vector(31 downto 0);
    s_1588ptp_period : in std_logic_vector(31 downto 0) := x"20000000"
    );
end sync_links;

architecture Behavioral of sync_links is

    signal clko_i,bec2gcu_2_i,gcu2bec_1_i,gcu2bec_2_i : std_logic_vector(47 downto 0);
    signal prbs_o,ttc_stream,inj_err_r,err_inj : std_logic;
    signal gcu2bec_1_d,gcu2bec_2_d,prbs_r : std_logic_vector(47 downto 0);
    signal ch_i :integer range 0 to 47;
    signal error_counter1,error_counter2,err_cnt_1,err_cnt_2 : t_uarray32(47 downto 0);
    signal single_bit_err_cnt,comm_err_cnt: t_array32(47 downto 0);
    signal s_cmd_pulse_vector : t_brd_command;
    signal s_long_frame_in1,s_long_frame_in2 : t_ttc_long_frame;
    signal chb_busy_o,chb_grant1_o,s_chb_grant3,chb_req1_i,s_chb_req3,s_ttctx_ready : std_logic;
    signal gcuid_i : t_array16(47 downto 0);
    signal s_aligned,aligned,s_delay_req : std_logic_vector(47 downto 0);
    signal ch_sel : integer range 0 to 47;
    signal error_time1,error_time2 :t_array48(47 downto 0);
    signal sc_in,hit_in : std_logic_vector(47 downto 0);
    signal nhit_gcu : t_array2(47 downto 0);
begin
--  buff the differential signals
i_channel_map:entity work.channel_map
    port map(
    BEC2GCU_1_P =>BEC2GCU_1_P,
    BEC2GCU_1_N => BEC2GCU_1_N,
    clko_i => clko_i,
    BEC2GCU_2_P => BEC2GCU_2_P,
    BEC2GCU_2_N => BEC2GCU_2_N,
    datao_i => bec2gcu_2_i,
    --======================--
    GCU2BEC_1_P => GCU2BEC_1_P,
    GCU2BEC_1_N => GCU2BEC_1_N,
    data1i_o => gcu2bec_1_i,
    GCU2BEC_2_P => GCU2BEC_2_P,
    GCU2BEC_2_N => GCU2BEC_2_N,
    data2i_o => gcu2bec_2_i,
    --======================--
    --inv_o_1 => inv_o_1,
    --tx1_sel => tx1_sel,
    tx2_en => tx2_en
    );
g_tx1:for i in 47 downto 0 generate
    clko_i(i) <= clk_i when tx1_sel(i) = '0' else prbs_r(i);
    prbs_r(i) <= prbs_o when inv_o_1(i) = '0' else not prbs_o;
    bec2gcu_2_i(i) <= ttc_stream when test_mode_i(i) = '0' else prbs_o;
end generate;
i_channel_delay:entity work.channel_delay
    port map(
    clk_i => clk_x2_i,
    clk_200_i => clk_200,
    ready => open,
    data2_i => gcu2bec_1_i,
    data3_i => gcu2bec_2_i,
    data2_o => gcu2bec_1_d,
    data3_o => gcu2bec_2_d,
    ch_i => ch_sel,
    tap_cnt_i => tap_cnt_i,
    ld_i => ld_i
    );
    ch_sel <= to_integer(unsigned(ch_sel_i));
-- prbs generator and checker in test_mode
process(clk_x2_i)
begin
    if rising_edge(clk_x2_i) then
        inj_err_r <= inj_err;
        if inj_err = '1' and inj_err_r = '0' then
            err_inj <= '1';
        else
            err_inj <= '0';
        end if;
    end if;
end process;
i_prbs_gen:entity work.PRBS_ANY
    generic map(
    CHK_MODE => FALSE,
    INV_PATTERN => FALSE,
    POLY_LENGHT => 7,
    POLY_TAP => 3,
    NBITS => 1
    )
    port map(
    RST => '0',
    CLK => clk_x2_i,
    DATA_IN(0) => err_inj,
    EN => '1',
    DATA_OUT(0) => prbs_o
    );
i_prbs_chk:entity work.prbs_check
    port map(
    clk_i => clk_x2_i,
    reset_i => reset_i,
    en_i => test_mode_i,
    global_time_i => timestamp_i,
    prbs_i1 => gcu2bec_1_d,
    prbs_i2 => gcu2bec_2_d,
    prbs_err1_o => open,
    prbs_err2_o => open,
    err_cnt_1_o => err_cnt_1,
    err_cnt_2_o => err_cnt_2,
    error_time1 => error_time1,
    error_time2 => error_time2
    );
    error_counter1_o <= std_logic_vector(error_counter1(ch_sel));
    error_counter2_o <= std_logic_vector(error_counter2(ch_sel));
    error_time1_o <= error_time1(ch_sel);
    error_time2_o <= error_time2(ch_sel);
--  link logic when normal running
 -- ttc encoder
Inst_ttc_encoder : entity work.ttc_encoder
    generic map(
      g_pll_locked_delay => 200
      )
    port map(
    locked_i         => sys_clk_lock,
    ttc_sys_clock_i  => clk_i,
    clk_x2_i         => clk_x2_i,
    brd_cmd_vector_i => s_cmd_pulse_vector,
    l1a_i            => l1a_i,
    long_frame1_i    => s_long_frame_in1,
    long_frame2_i    => s_long_frame_in2,
    ttc_stream_o     => ttc_stream, --TTC up link
    chb_busy_o       => chb_busy_o,
    chb_grant1_o     => chb_grant1_o, --brd cmd channel
    chb_grant2_o     => open,
    chb_grant3_o     => s_chb_grant3, 
    chb_req1_i       => chb_req1_i,
    chb_req2_i       => '0',
    chb_req3_i       => s_chb_req3,
    ready_o          => s_ttctx_ready,
    sbit_err_inj_i   => '0',
    dbit_err_inj_i   => '0',
    err_pos1_i       => "000000",
    err_pos2_i       => "000000"
    );
    ttctx_ready <= s_ttctx_ready;
Inst_brd_cmd:entity work.brd_cmd_generator
    port map(
    clk_i => clk_i,
    rst_i => not s_ttctx_ready,
    period => timestamp_i(10),
    rst_event => '0',
    chb_busy_i => chb_busy_o,
    chb_req_o => chb_req1_i,
    chb_grant_i => chb_grant1_o,
    brd_cmd_vector => s_cmd_pulse_vector
    );
 -- ttc decoders
hit_in <= gcu2bec_1_d when pair_swap = '0' else gcu2bec_2_d;
sc_in <= gcu2bec_2_d when pair_swap = '0' else gcu2bec_1_d;
genGCUupLink:for i in 47 downto 0 generate
    gcuid_i(i) <= std_logic_vector(to_unsigned(i + 1, 16));
    ----Hit receiver, recognize hit from GCU
    Inst_hit_recognizer:entity work.hit_recognizer
        port map(
        hit_from_gcu => hit_in(i),
        clk_i => clk_i,
        clk_x2_i => clk_x2_i,
        rst_i => not sys_clk_lock or test_mode_i(i),
        --aligned_o => open,
        hit_o => nhit_gcu(i)
        );
        nhit_gcu_o(i) <= nhit_gcu(i) when ch_mask_i(i) = '0' else (others => '0');

    Inst_sc_decoder:entity work.sc_decoder
        generic map(
        g_Hamming => g_Hamming,
        g_TTC_memory_deep => g_TTC_memory_deep
        )
        port map(
        sc_from_gcu          => sc_in(i),
        clk_i                => clk_i,
        rst_i                => not sys_clk_lock or test_mode_i(i),
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
        duble_bit_err_o      => open,
        comm_err_o           => comm_err_cnt(i),
        ready_o              => open,
        reset_err            => reset_i,
        no_errors_o          => open,
        aligned_o            => aligned(i),
        not_in_table_o       => open
        );
        s_aligned(i) <= aligned(i) when ch_mask_i(i) = '0' else '0';
    error_counter1(i) <= err_cnt_1(i) when test_mode_i(i) = '1' else unsigned(single_bit_err_cnt(i));
    error_counter2(i) <= err_cnt_2(i) when test_mode_i(i) = '1' else unsigned(comm_err_cnt(i));
end generate;
ch_ready_o <= s_aligned;
---------------------------------1588 ptp protocol BEC side-------------------------
Inst_bec_1588_ptp:entity work.BEC_1588_ptp_v2
    port map(
    clk_i   => clk_x2_i,
    clk_div2 => clk_i,
    rst_i   => not sys_clk_lock,
    ttcrx_ready => s_aligned,
    enable_i    => s_ttctx_ready,
    period_i    => s_1588ptp_period,--x"20000000", --32b time interval for ptp check
    delay_req_i => s_delay_req,
    chb_grant_i => s_chb_grant3,
    local_time_i=> timestamp_i, --48b local time
    chb_req_o   => s_chb_req3,
    fsm_debug_o => open,
    current_gcu => open,
    catch_time => open,
    s_go_o => open,
    gcu_id_i    => gcuid_i, --GCU IDs in parallel
    ttc_long_o  => s_long_frame_in2 --ttc long format to encoder
    );
end Behavioral;
