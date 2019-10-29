----------------------------------------------------------------------------------
-- Company:        Tsinghua University
-- Create Date:    15:49:47 02/07/2019  
-- Module Name:    BEC_1588_ptp - Behv 
-- Project Name:   TTIM
-- Tool versions:  Vivado 2018.1
-- Revision 2 - changed the FSM of old BEC_1588_ptp
-- Description:
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.TTIM_v2_pack.all;

entity BEC_1588_ptp_v2 is
    port ( clk_i        : in  std_logic;
    clk_div2 : in std_logic;
    rst_i        : in  std_logic;
	ttcrx_ready  : in  std_logic_vector (47 downto 0);
    enable_i     : in  std_logic;
    period_i     : in  std_logic_vector (31 downto 0);
    delay_req_i  : in  std_logic_vector (47 downto 0);
    chb_grant_i  : in  std_logic;
    local_time_i : in  std_logic_vector (47 downto 0);
    chb_req_o    : out  std_logic;
	fsm_debug_o  : out  std_logic_vector (4 downto 0);
	gcu_id_i     : in t_array16(47 downto 0);
	ttc_long_o   : out t_ttc_long_frame;
    current_gcu : out std_logic_vector(5 downto 0);
    catch_time : out std_logic_vector (47 downto 0);
    s_go_o : out std_logic
	);
end BEC_1588_ptp_v2;

architecture Behavioral of BEC_1588_ptp_v2 is
type t_BEC_1588 is (st0_idle,            -- 0x00
                    st0_verify_rxready,  -- 0x1f
                    st1_chb_req,         -- 0x01
					st2_tx_time,         -- 0x02
                    st3_synch_byte_0,    -- 0x03
                    st4_chb_req,	        -- 0x04
                    st5_synch_byte_1,    -- 0x05
                    st6_chb_req,		     -- 0x06	  
                    st7_synch_byte_2,    -- 0x07
					st8_chb_req,		     -- 0x08	  
                    st9_synch_byte_3,    -- 0x09
					st10_chb_req,	     -- 0x0a		  
                    st11_synch_byte_4,   -- 0x0b
					st12_chb_req,	     -- 0x0c		  
                    st13_synch_byte_5,   -- 0x0d
					st14_wait_delay_req, -- 0x0e
					st15_rx_time,        -- 0x0f
					st16_chb_req,		  -- 0x10	  
                    st17_delay_byte_0,   -- 0x11
					st18_chb_req,		  -- 0x12				  
                    st19_delay_byte_1,   -- 0x13
					st20_chb_req,		  -- 0x14	  
                    st21_delay_byte_2,   -- 0x15
					st22_chb_req,		  -- 0x16	  
                    st23_delay_byte_3,   -- 0x17
					st24_chb_req,		  -- 0x18	  
                    st25_delay_byte_4,   -- 0x19
					st26_chb_req,		  -- 0x1a	  
                    st27_delay_byte_5,   -- 0x1b
					st28_rr_update,       -- 0x1c
                    st29_wait_update,
                    st30_load_counter
						 );
type t_gcuid_array is array (47 downto 0) of std_logic_vector (15 downto 0);
signal s_state : t_BEC_1588;
signal s_catch_time    : std_logic;
signal s_load          : std_logic;
signal s_go            : std_logic;
signal s_en_rise_edge  : std_logic;
signal s_strobe        : std_logic;
signal s_time          : std_logic_vector(47 downto 0);
signal s_count         : std_logic_vector(31 downto 0);
signal load_period, s_go_en : std_logic;
signal s_delay_req_vec : std_logic_vector(47 downto 0);
signal s_rx_ready_vec  : std_logic_vector(47 downto 0);
signal s_delay_req     : std_logic;
signal s_rx_ready      : std_logic;
signal u_gcu_sel       : unsigned(f_log2(48) - 1 downto 0);
signal s_gcu_id        : t_gcuid_array;
signal s_rr_update     : std_logic;
signal timeout     : std_logic;
signal timeout_count : std_logic_vector(11 downto 0);
signal timeout_go,timeout_en : std_logic;
signal wait_cycle      : unsigned(1 downto 0);

begin

s_delay_req_vec <= delay_req_i;
s_rx_ready_vec <= ttcrx_ready;

GEN_GCU_ID_ARRAY_1:
for I in 1 to 48 generate
	s_gcu_id(I - 1) <= gcu_id_i(I -1);
end generate GEN_GCU_ID_ARRAY_1;
--===================================================--	
--                     TIME SAMPLE
--===================================================--
p_time_sample : process(clk_i)
begin
   if rising_edge(clk_i) then
      if rst_i = '1' then
         s_time <= (others => '0');
      elsif s_catch_time = '1' then
         s_time <= local_time_i;
      end if;
   end if;
end process p_time_sample;
catch_time <= s_time;
--===================================================--	
--                STROBE PULSE GENERATOR
--===================================================--

Inst_strobe_rise_edge_detect : entity work.r_edge_detect
	generic map(
	    g_clk_rise  => "TRUE"
	    )
	port map(
	    clk_i => clk_div2,  
       sig_i => s_strobe,
       sig_o => ttc_long_o.long_strobe
	    );
--===================================================--	
--                       COUNTDOWN
--===================================================--
Inst_rst_rise_edge_detect : entity work.r_edge_detect
	generic map(
	    g_clk_rise  => "TRUE"
	    )
	port map(
	    clk_i => clk_i,  
       sig_i => enable_i,
       sig_o => s_en_rise_edge
	    );
s_load <= s_en_rise_edge or s_go or load_period;

Inst_countdown : entity work.countdown
     generic map(
		          g_width    => 32,
	             g_clk_rise => "TRUE"
                )
     port map(
		  clk_i    => clk_i,  
		  reset_i  => rst_i, 
		  load_i   => s_load, 
		  enable_i => s_go_en, 
        p_i      => period_i,  
        p_o      => s_count
		  );

p_go : process(clk_i)
begin
   if rising_edge(clk_i) then
      if s_count = x"00000001" then
         s_go <= '1';
      else 
		   s_go <= '0';
      end if;
   end if;
end process p_go;
s_go_o <= s_go;
--===================================================--	
--                  TIMEOUT COUNTER
--===================================================--
Inst_timeout_countdown : entity work.countdown
     generic map(
		g_width    => 12,
	    g_clk_rise => "TRUE"
        )
     port map(
		  clk_i    => clk_i,  
		  reset_i  => rst_i, 
		  load_i   => timeout, 
		  enable_i => timeout_en, 
        p_i      => x"1F4",  
        p_o      => timeout_count
		  );
p_timeout : process(clk_i)
begin
   if rising_edge(clk_i) then
      if timeout_count = x"001" then
            timeout_go <= '1';
      else 
		   timeout_go <= '0';
      end if;
   end if;
end process;
--===================================================--	
--                       FSM
--===================================================--	
p_update_state : process(clk_i,rst_i)  
  begin  
    if rst_i = '1' then
	    s_state <= st0_idle;
    elsif rising_edge(clk_i) then 
        case s_state is
            when st0_idle =>
                if s_go = '1' or s_en_rise_edge = '1' then
                    s_state <= st0_verify_rxready;
                end if;
            when st0_verify_rxready =>
                if s_rx_ready = '1' then
                    s_state <= st1_chb_req;
                else
                    s_state <= st28_rr_update;
                end if;
            when st1_chb_req =>
                if chb_grant_i = '1' then
                    s_state <= st2_tx_time;
                end if;
            when st2_tx_time =>
                s_state <= st3_synch_byte_0;
            when st3_synch_byte_0 =>
                if chb_grant_i = '0' then
                    s_state <= st4_chb_req;
                end if;
            when st4_chb_req =>
                if chb_grant_i = '1' then
                    s_state <= st5_synch_byte_1;
                end if;
            when st5_synch_byte_1 =>
                if chb_grant_i = '0' then
                    s_state <= st6_chb_req;
                end if;
            when st6_chb_req =>
			    if chb_grant_i = '1' then
                    s_state <= st7_synch_byte_2;
				end if;
            when st7_synch_byte_2 =>
			    if chb_grant_i = '0' then
                    s_state <= st8_chb_req;
				end if;
            when st8_chb_req =>
			    if chb_grant_i = '1' then
                    s_state <= st9_synch_byte_3;
				end if;
            when st9_synch_byte_3 =>
			    if chb_grant_i = '0' then
                    s_state <= st10_chb_req;
				end if;
            when st10_chb_req =>
			    if chb_grant_i = '1' then
                    s_state <= st11_synch_byte_4;
				end if;
            when st11_synch_byte_4 =>
			    if chb_grant_i = '0' then
                    s_state <= st12_chb_req;
				end if;
            when st12_chb_req =>
			    if chb_grant_i = '1' then
                    s_state <= st13_synch_byte_5;
				 end if;
            when st13_synch_byte_5 =>
			    if chb_grant_i = '0' then
                    s_state <= st14_wait_delay_req;
				end if;
            when st14_wait_delay_req =>
			    if s_delay_req = '1' then
                    s_state <= st15_rx_time;
                elsif timeout_go = '1' then           ----wait delay_req for a certain time
				    s_state <= st28_rr_update;  ----if timeout, change to next GCU
                end if;
            when st15_rx_time =>
                s_state <= st16_chb_req;
            when st16_chb_req =>
			    if chb_grant_i = '1' then
                    s_state <= st17_delay_byte_0;
                end if;
            when st17_delay_byte_0 =>
			    if chb_grant_i = '0' then
                    s_state <= st18_chb_req;
                end if;
            when st18_chb_req =>
			    if chb_grant_i = '1' then
                s_state <= st19_delay_byte_1;
                end if;
			when st19_delay_byte_1 =>
			    if chb_grant_i = '0' then
                    s_state <= st20_chb_req;
				end if; 
			when st20_chb_req =>
			    if chb_grant_i = '1' then
                    s_state <= st21_delay_byte_2;
				end if;
			when st21_delay_byte_2 =>
			    if chb_grant_i = '0' then
                    s_state <= st22_chb_req;
				end if; 
            when st22_chb_req =>
			    if chb_grant_i = '1' then
                    s_state <= st23_delay_byte_3;
				end if;
			when st23_delay_byte_3 =>
			    if chb_grant_i = '0' then
                    s_state <= st24_chb_req;
				end if;
			when st24_chb_req =>
			    if chb_grant_i = '1' then
                    s_state <= st25_delay_byte_4;
				end if;
			when st25_delay_byte_4 =>
			    if chb_grant_i = '0' then
                    s_state <= st26_chb_req;
				end if;
			when st26_chb_req =>
			    if chb_grant_i = '1' then
                    s_state <= st27_delay_byte_5;
				end if;
            when st27_delay_byte_5 =>
			    if chb_grant_i = '0' then
				    s_state <= st28_rr_update;
				end if;
            when st28_rr_update =>
                s_state <= st29_wait_update;
            when st29_wait_update =>
                if u_gcu_sel <= 47 then
                    s_state <= st0_verify_rxready;
                else
                    s_state <= st30_load_counter;
                end if;
            when st30_load_counter =>
                s_state <= st0_idle;
            when others =>
                s_state <= st0_idle;
        end case;
    end if;
end process;

p_update_fsm_output : process(s_state)  
begin  
    case s_state is
		    -------
    when st0_idle =>
        fsm_debug_o            <= b"00000";
        s_catch_time           <= '0';
        chb_req_o              <= '0';
        ttc_long_o.long_subadd <= x"00";
        ttc_long_o.long_data   <= x"00";
        s_strobe               <= '0';
        s_rr_update            <= '0';
        load_period <= '0';
        timeout_en <= '0';
        s_go_en <= '1';
    when st0_verify_rxready =>
        fsm_debug_o            <= b"11111";
		s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
        load_period <= '0';
        timeout_en <= '0';
        s_go_en <= '0';
    when st1_chb_req =>
		fsm_debug_o            <= b"00001";
		s_catch_time           <= '0';
		chb_req_o              <= '1';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
    when st2_tx_time =>
		fsm_debug_o            <= b"00010";
		s_catch_time           <= '1';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
    when st3_synch_byte_0 =>
		fsm_debug_o            <= b"00011";
		s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"09";
		ttc_long_o.long_data   <= s_time(7 downto 0);
		s_strobe               <= '1';
		s_rr_update            <= '0';
    when st4_chb_req =>
		fsm_debug_o            <= b"00100";
	    s_catch_time           <= '0';
        chb_req_o              <= '1';
        ttc_long_o.long_subadd <= x"00";
        ttc_long_o.long_data   <= x"00";
        s_strobe               <= '0';
        s_rr_update            <= '0';
    when st5_synch_byte_1 =>
		fsm_debug_o            <= b"00101";
	    s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"0a";
		ttc_long_o.long_data   <= s_time(15 downto 8);
		s_strobe               <= '1';
		s_rr_update            <= '0';
    when st6_chb_req =>
		fsm_debug_o            <= b"00110";
	    s_catch_time           <= '0';
		chb_req_o              <= '1';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
	when st7_synch_byte_2 =>
		fsm_debug_o            <= b"00111";
	    s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"0b";
		ttc_long_o.long_data   <= s_time(23 downto 16);
		s_strobe               <= '1';
		s_rr_update            <= '0';
	when st8_chb_req =>
		fsm_debug_o            <= b"01000";
	    s_catch_time           <= '0';
		chb_req_o              <= '1';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
    when st9_synch_byte_3 =>
		fsm_debug_o            <= b"01001";
	    s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"0c";
		ttc_long_o.long_data   <= s_time(31 downto 24);
		s_strobe               <= '1';
		s_rr_update            <= '0';
	when st10_chb_req =>
		fsm_debug_o            <= b"01010";
	    s_catch_time           <= '0';
		chb_req_o              <= '1';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
	when st11_synch_byte_4 =>
		fsm_debug_o            <= b"01011";
	    s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"0d";
		ttc_long_o.long_data   <= s_time(39 downto 32);
		s_strobe               <= '1';
		s_rr_update            <= '0';
	when st12_chb_req =>
		fsm_debug_o            <= b"01100";
	    s_catch_time           <= '0';
        chb_req_o              <= '1';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
		timeout <= '0';
        timeout_en <= '0';
	when st13_synch_byte_5 =>
		fsm_debug_o            <= b"01101";
	    s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"0e";
		ttc_long_o.long_data   <= s_time(47 downto 40);
		s_strobe               <= '1';
		s_rr_update            <= '0';
        timeout <= '1';
	when st14_wait_delay_req =>
		fsm_debug_o            <= b"01110";
	    s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
        timeout <= '0';
        timeout_en <= '1';
    when st15_rx_time =>
		fsm_debug_o            <= b"01111";
	    s_catch_time           <= '1';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
	when st16_chb_req =>
		fsm_debug_o            <= b"10000";
	    s_catch_time           <= '0';
		chb_req_o              <= '1';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
	when st17_delay_byte_0 =>
		fsm_debug_o            <= b"10001";
	    s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"11";
		ttc_long_o.long_data   <= s_time(7 downto 0);
		s_strobe               <= '1';
		s_rr_update            <= '0';
	when st18_chb_req =>
		fsm_debug_o            <= b"10010";
	    s_catch_time           <= '0';
		chb_req_o              <= '1';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
	when st19_delay_byte_1 =>
		fsm_debug_o            <= b"10011";
	    s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"12";
		ttc_long_o.long_data   <= s_time(15 downto 8);
		s_strobe               <= '1';
		s_rr_update            <= '0';
	when st20_chb_req =>
		fsm_debug_o            <= b"10100";
	    s_catch_time           <= '0';
		chb_req_o              <= '1';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
	when st21_delay_byte_2 =>
		fsm_debug_o            <= b"10101";
	    s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"13";
		ttc_long_o.long_data   <= s_time(23 downto 16);
		s_strobe               <= '1';
		s_rr_update            <= '0';
	when st22_chb_req =>
		fsm_debug_o            <= b"10110";
	    s_catch_time           <= '0';
		chb_req_o              <= '1';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
	when st23_delay_byte_3 =>
		fsm_debug_o            <= b"10111";
	    s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"14";
		ttc_long_o.long_data   <= s_time(31 downto 24);
		s_strobe               <= '1';
		s_rr_update            <= '0';
	when st24_chb_req =>
		fsm_debug_o            <= b"11000";
	    s_catch_time           <= '0';
		chb_req_o              <= '1';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
	when st25_delay_byte_4 =>
		fsm_debug_o            <= b"11001";
	    s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"15";
		ttc_long_o.long_data   <= s_time(39 downto 32);
		s_strobe               <= '1';
		s_rr_update            <= '0';
	when st26_chb_req =>
		fsm_debug_o            <= b"11010";
	    s_catch_time           <= '0';
		chb_req_o              <= '1';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '0';
	when st27_delay_byte_5 =>			 
		fsm_debug_o            <= b"11011";
		s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"16";
		ttc_long_o.long_data   <= s_time(47 downto 40);
		s_strobe               <= '1';
		s_rr_update            <= '0';
	when st28_rr_update =>			 
		fsm_debug_o            <= b"11100";
		s_catch_time           <= '0';
		chb_req_o              <= '0';
		ttc_long_o.long_subadd <= x"00";
		ttc_long_o.long_data   <= x"00";
		s_strobe               <= '0';
		s_rr_update            <= '1';
        s_go_en <= '0';
    when st29_wait_update =>			 
        fsm_debug_o            <= b"11101";
        s_catch_time           <= '0';
        chb_req_o              <= '0';
        ttc_long_o.long_subadd <= x"00";
        ttc_long_o.long_data   <= x"00";
        s_strobe               <= '0';
        s_rr_update            <= '0';
        load_period <= '1';
        s_go_en <= '0';
    when st30_load_counter =>
        fsm_debug_o            <= b"11110";
        s_catch_time           <= '0';
        chb_req_o              <= '0';
        ttc_long_o.long_subadd <= x"00";
        ttc_long_o.long_data   <= x"00";
        s_strobe               <= '0';
        s_rr_update            <= '0';
        load_period <= '1';
        s_go_en <= '0';
    when others =>
        fsm_debug_o            <= b"00000";
        s_catch_time           <= '0';
        chb_req_o              <= '0';
        ttc_long_o.long_subadd <= x"00";
        ttc_long_o.long_data   <= x"00";
        s_strobe               <= '0';
        s_rr_update            <= '0';
        load_period <= '0';
end case;
end process;
--===================================================--	
--                       Round Robin
--===================================================--
process(clk_i)
begin
   if rising_edge(clk_i) then
        if rst_i = '1' or s_go = '1' or s_en_rise_edge = '1' then 
		   u_gcu_sel <= (others => '0');
		elsif s_rr_update = '1' then
            if u_gcu_sel <= 47 then
                u_gcu_sel <= u_gcu_sel + 1;
            else
                u_gcu_sel <= (others => '0');
            end if;
		end if;
	end if;
end process;
current_gcu <= std_logic_vector(u_gcu_sel);
process(u_gcu_sel, s_delay_req_vec, s_gcu_id, s_rx_ready_vec)
begin
   case to_integer(u_gcu_sel) is
	   when 0 =>
         s_delay_req <= s_delay_req_vec(0);
         ttc_long_o.long_address <= s_gcu_id(0);
			s_rx_ready <= s_rx_ready_vec(0);
	   when 1 =>
         s_delay_req <= s_delay_req_vec(1);
         ttc_long_o.long_address <= s_gcu_id(1);
			s_rx_ready <= s_rx_ready_vec(1);
	   when 2 =>
         s_delay_req <= s_delay_req_vec(2);
         ttc_long_o.long_address <= s_gcu_id(2);
			s_rx_ready <= s_rx_ready_vec(2);
	   when 3 =>
         s_delay_req <= s_delay_req_vec(3);
         ttc_long_o.long_address <= s_gcu_id(3);
			s_rx_ready <= s_rx_ready_vec(3);
	   when 4 =>
         s_delay_req <= s_delay_req_vec(4);
         ttc_long_o.long_address <= s_gcu_id(4);
			s_rx_ready <= s_rx_ready_vec(4);
	   when 5 =>
         s_delay_req <= s_delay_req_vec(5);
         ttc_long_o.long_address <= s_gcu_id(5);
			s_rx_ready <= s_rx_ready_vec(5);
	   when 6 =>
         s_delay_req <= s_delay_req_vec(6);
         ttc_long_o.long_address <= s_gcu_id(6);
			s_rx_ready <= s_rx_ready_vec(6);
	   when 7 =>
         s_delay_req <= s_delay_req_vec(7);
         ttc_long_o.long_address <= s_gcu_id(7);
			s_rx_ready <= s_rx_ready_vec(7);
	   when 8 =>
         s_delay_req <= s_delay_req_vec(8);
         ttc_long_o.long_address <= s_gcu_id(8);
			s_rx_ready <= s_rx_ready_vec(8);
	   when 9 =>
         s_delay_req <= s_delay_req_vec(9);
         ttc_long_o.long_address <= s_gcu_id(9);
			s_rx_ready <= s_rx_ready_vec(9);
	   when 10 =>
         s_delay_req <= s_delay_req_vec(10);
         ttc_long_o.long_address <= s_gcu_id(10);
			s_rx_ready <= s_rx_ready_vec(10);
	   when 11 =>
         s_delay_req <= s_delay_req_vec(11);
         ttc_long_o.long_address <= s_gcu_id(11);
			s_rx_ready <= s_rx_ready_vec(11);
	   when 12 =>
         s_delay_req <= s_delay_req_vec(12);
         ttc_long_o.long_address <= s_gcu_id(12);
			s_rx_ready <= s_rx_ready_vec(12);
	   when 13 =>
         s_delay_req <= s_delay_req_vec(13);
         ttc_long_o.long_address <= s_gcu_id(13);
			s_rx_ready <= s_rx_ready_vec(13);
	   when 14 =>
         s_delay_req <= s_delay_req_vec(14);
         ttc_long_o.long_address <= s_gcu_id(14);
			s_rx_ready <= s_rx_ready_vec(14);
	   when 15 =>
         s_delay_req <= s_delay_req_vec(15);
         ttc_long_o.long_address <= s_gcu_id(15);
			s_rx_ready <= s_rx_ready_vec(15);
	   when 16 =>
         s_delay_req <= s_delay_req_vec(16);
         ttc_long_o.long_address <= s_gcu_id(16);
			s_rx_ready <= s_rx_ready_vec(16);
	   when 17 =>
         s_delay_req <= s_delay_req_vec(17);
         ttc_long_o.long_address <= s_gcu_id(17);
			s_rx_ready <= s_rx_ready_vec(17);
	   when 18 =>
         s_delay_req <= s_delay_req_vec(18);
         ttc_long_o.long_address <= s_gcu_id(18);
			s_rx_ready <= s_rx_ready_vec(18);
	   when 19 =>
         s_delay_req <= s_delay_req_vec(19);
         ttc_long_o.long_address <= s_gcu_id(19);
			s_rx_ready <= s_rx_ready_vec(19);
      when 20 =>
         s_delay_req <= s_delay_req_vec(20);
         ttc_long_o.long_address <= s_gcu_id(20);
			s_rx_ready <= s_rx_ready_vec(20);
	   when 21 =>
         s_delay_req <= s_delay_req_vec(21);
         ttc_long_o.long_address <= s_gcu_id(21);
			s_rx_ready <= s_rx_ready_vec(21);
	   when 22 =>
         s_delay_req <= s_delay_req_vec(22);
         ttc_long_o.long_address <= s_gcu_id(22);
			s_rx_ready <= s_rx_ready_vec(22);
	   when 23 =>
         s_delay_req <= s_delay_req_vec(23);
         ttc_long_o.long_address <= s_gcu_id(23);
			s_rx_ready <= s_rx_ready_vec(23);
	   when 24 =>
         s_delay_req <= s_delay_req_vec(24);
         ttc_long_o.long_address <= s_gcu_id(24);
			s_rx_ready <= s_rx_ready_vec(24);
	   when 25 =>
         s_delay_req <= s_delay_req_vec(25);
         ttc_long_o.long_address <= s_gcu_id(25);
			s_rx_ready <= s_rx_ready_vec(25);
	   when 26 =>
         s_delay_req <= s_delay_req_vec(26);
         ttc_long_o.long_address <= s_gcu_id(26);
			s_rx_ready <= s_rx_ready_vec(26);
	   when 27 =>
         s_delay_req <= s_delay_req_vec(27);
         ttc_long_o.long_address <= s_gcu_id(27);
			s_rx_ready <= s_rx_ready_vec(27);
	   when 28 =>
         s_delay_req <= s_delay_req_vec(28);
         ttc_long_o.long_address <= s_gcu_id(28);
			s_rx_ready <= s_rx_ready_vec(28);
	   when 29 =>
         s_delay_req <= s_delay_req_vec(29);
         ttc_long_o.long_address <= s_gcu_id(29);
			s_rx_ready <= s_rx_ready_vec(29);
	   when 30 =>
         s_delay_req <= s_delay_req_vec(30);
         ttc_long_o.long_address <= s_gcu_id(30);
			s_rx_ready <= s_rx_ready_vec(30);
	   when 31 =>
         s_delay_req <= s_delay_req_vec(31);
         ttc_long_o.long_address <= s_gcu_id(31);
			s_rx_ready <= s_rx_ready_vec(31);
	   when 32 =>
         s_delay_req <= s_delay_req_vec(32);
         ttc_long_o.long_address <= s_gcu_id(32);
			s_rx_ready <= s_rx_ready_vec(32);
	   when 33 =>
         s_delay_req <= s_delay_req_vec(33);
         ttc_long_o.long_address <= s_gcu_id(33);
			s_rx_ready <= s_rx_ready_vec(33);
	   when 34 =>
         s_delay_req <= s_delay_req_vec(34);
         ttc_long_o.long_address <= s_gcu_id(34);
			s_rx_ready <= s_rx_ready_vec(34);
	   when 35 =>
         s_delay_req <= s_delay_req_vec(35);
         ttc_long_o.long_address <= s_gcu_id(35);
			s_rx_ready <= s_rx_ready_vec(35);
	   when 36 =>
         s_delay_req <= s_delay_req_vec(36);
         ttc_long_o.long_address <= s_gcu_id(36);
			s_rx_ready <= s_rx_ready_vec(36);
	   when 37 =>
         s_delay_req <= s_delay_req_vec(37);
         ttc_long_o.long_address <= s_gcu_id(37);
			s_rx_ready <= s_rx_ready_vec(37);
	   when 38 =>
         s_delay_req <= s_delay_req_vec(38);
         ttc_long_o.long_address <= s_gcu_id(38);
			s_rx_ready <= s_rx_ready_vec(38);
	   when 39 =>
         s_delay_req <= s_delay_req_vec(39);
         ttc_long_o.long_address <= s_gcu_id(39);
         s_rx_ready <= s_rx_ready_vec(39);			
      when 40 =>
         s_delay_req <= s_delay_req_vec(40);
         ttc_long_o.long_address <= s_gcu_id(40);
			s_rx_ready <= s_rx_ready_vec(40);
	   when 41 =>
         s_delay_req <= s_delay_req_vec(41);
         ttc_long_o.long_address <= s_gcu_id(41);
			s_rx_ready <= s_rx_ready_vec(41);
	   when 42 =>
         s_delay_req <= s_delay_req_vec(42);
         ttc_long_o.long_address <= s_gcu_id(42);
			s_rx_ready <= s_rx_ready_vec(42);
	   when 43 =>
         s_delay_req <= s_delay_req_vec(43);
         ttc_long_o.long_address <= s_gcu_id(43);
			s_rx_ready <= s_rx_ready_vec(43);
	   when 44 =>
         s_delay_req <= s_delay_req_vec(44);
         ttc_long_o.long_address <= s_gcu_id(44);
			s_rx_ready <= s_rx_ready_vec(44);
	   when 45 =>
         s_delay_req <= s_delay_req_vec(45);
         ttc_long_o.long_address <= s_gcu_id(45);
			s_rx_ready <= s_rx_ready_vec(45);
	   when 46 =>
         s_delay_req <= s_delay_req_vec(46);
         ttc_long_o.long_address <= s_gcu_id(46);
			s_rx_ready <= s_rx_ready_vec(46);
	   when 47 =>
         s_delay_req <= s_delay_req_vec(47);
         ttc_long_o.long_address <= s_gcu_id(47);
			s_rx_ready <= s_rx_ready_vec(47);
      when others =>
		   s_delay_req <= '0';
         ttc_long_o.long_address <= x"ffff";
			s_rx_ready <= '0';
	end case;
end process;
end Behavioral;