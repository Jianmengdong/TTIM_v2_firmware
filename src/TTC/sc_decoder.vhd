----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2019/04/16 10:48:55
-- Design Name: 
-- Module Name: sc_decoder - Behavioral
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
use work.TTIM_v2_pack.all;

entity sc_decoder is
    generic(
        g_Hamming          : boolean  := true;
        g_TTC_memory_deep  : positive := 25
    );
    Port ( 
    sc_from_gcu : in STD_LOGIC;
    clk_i : in STD_LOGIC;
    rst_i : in std_logic;
    ttcrx_coarse_delay_i	: in std_logic_vector(4 downto 0);
    gcuid_i: in std_logic_vector(15 downto 0);
    brd_command_vector_o : out t_brd_command;
    l1a_time_o                    : out  std_logic_vector (47 downto 0);
    synch_o                       : out  std_logic_vector (47 downto 0);
    delay_o                       : out  std_logic_vector (47 downto 0);						
	ttc_ctrl_o                    : out t_ttc_ctrl;
	delay_req_o                   : out std_logic;
	synch_req_o                   : out std_logic;
	byte5_o                       : out std_logic;
	-- Error counters
    reset_err                     : in std_logic;
	single_bit_err_o              : out std_logic_vector(31 downto 0);
	duble_bit_err_o               : out std_logic_vector(31 downto 0);
	comm_err_o                    : out std_logic_vector(31 downto 0);
	--== ttc decoder aux flags ==--
	ready_o						  : out std_logic;	-- ready_o flag -- MMCM locked delayed		
	no_errors_o                   : out std_logic;
	aligned_o                     : out std_logic;
	not_in_table_o                : out std_logic
    );
end sc_decoder;

architecture Behavioral of sc_decoder is

    signal sc_delay,sc_i            : std_logic;
    signal s_chB_data				: std_logic_vector(38 downto 0);
	signal s_chB_data_rdy			: std_logic_vector(1 downto 0);
	signal s_single_bit_error		: std_logic;
	signal s_double_bit_error		: std_logic;
	signal s_channelB_comm_error	: std_logic;
	signal s_cha					: std_logic;
	signal s_chb					: std_logic;
	signal s_cdrdata_d				: std_logic;  -- after coarse delay
	signal s_chb_strobe			    : std_logic;
	signal s_q31_unused				: std_logic;
	
	signal u_1bit_err_count       : unsigned(31 downto 0);
    signal u_2bit_err_count       : unsigned(31 downto 0);
    signal u_comm_err_count       : unsigned(31 downto 0);
	
	signal s_brc_cmd              : std_logic_vector(5 downto 0);
	signal s_brc_strobe           : std_logic;
	signal s_brc_rst_t            : std_logic;
	signal s_brc_rst_e            : std_logic;
	signal s_rst_errors   	      : std_logic;
	signal s_1bit_err             : std_logic;
	signal s_2bit_err             : std_logic;
	signal s_comm_err             : std_logic;
	signal s_add_strb             : std_logic;
	signal s_add_a16              : std_logic_vector(15 downto 0);
    signal s_add_s8               : std_logic_vector(7 downto 0);
    signal s_add_d8               : std_logic_vector(7 downto 0);
	signal s_ttc_mem_addr         : std_logic_vector(7 downto 0);
    signal s_ttc_mem_data         : std_logic_vector(7 downto 0);
    signal s_ttc_mem_we           : std_logic;
	signal s_aligned              : std_logic;
	signal s_idle                 : std_logic;

begin
--===================================================--	
--                   Coarse delay
--===================================================--
rx_coarse_delay: SRLC32E
   generic map (
      INIT => X"00000000")
   port map (
      Q   => sc_delay,          -- SRL data output
      Q31 => open,         -- SRL cascade output pin
      A   => ttcrx_coarse_delay_i, -- 5-bit shift depth select input
      CE  => '1',                  -- Clock enable input
      CLK => clk_i,          -- Clock input
      D   => sc_from_gcu             -- SRL data input
   );
--===================================================--	
--                   Descramble data
--===================================================--
Inst_descrambler:entity work.descrambler
    port map(
    clk_i => clk_i,
    reset_i => rst_i,
    D => sc_delay,
    Q => sc_i
    );
--===================================================--
--            Deserializer + Error Correction
--===================================================--
Inst_deserializer :entity work.serialb_com
    generic map (
	   include_hamming => g_Hamming)  
    port map(   
	   clk_i                 => clk_i,
	   reset_n_i             => not rst_i,
       chb_i                 => sc_i,    -- serial stream 
       chb_strobe_i          => '1',
       single_bit_error_o    => s_single_bit_error,
       double_bit_error_o    => s_double_bit_error,
       communication_error_o => s_channelB_comm_error,
       data_ready_o          => s_chB_data_rdy,
       data_out_o            => s_chB_data
       );
--=============================================================================--
-- output mapping - 62.5 MHz synchronization (data updated every 16ns)
--=============================================================================--
process(clk_i, rst_i)
begin
   if rst_i = '1' then 
	   s_brc_strobe       <= '0';
		s_add_strb         <= '0';
		s_brc_cmd             <= (others => '0');
		s_brc_rst_e           <= '0';
		s_brc_rst_t           <= '0';
		s_add_a16             <= (others => '0');
		s_add_s8              <= (others => '0');
		s_add_d8              <= (others => '0');
		s_1bit_err            <= '0';
		s_2bit_err            <= '0';
		s_comm_err            <= '0';
		ready_o               <= '0';
   elsif rising_edge(clk_i) then
		s_brc_strobe <= s_chB_data_rdy(0);
		s_add_strb   <= s_chB_data_rdy(1);
		--SSSSSSEB
		if s_chB_data_rdy(0) = '1' then
		   s_brc_cmd       <= s_chB_data(12 downto 7);   
		   s_brc_rst_e		 <= s_chB_data(6); 
		   s_brc_rst_t		 <= s_chB_data(5); 
      else
		   s_brc_cmd	    <= (others =>'0');  
		   s_brc_rst_e		 <= '0'; 
		   s_brc_rst_t		 <= '0'; 
		end if;
		
		--AAAAAAAAAAAAAAAASSSSSSSSDDDDDDDD
		if s_chB_data_rdy(1) = '1' then
		   s_add_a16	 <= s_chB_data(38 downto 23);
		   s_add_s8	    <= s_chB_data(22 downto 15);
		   s_add_d8	    <= s_chB_data(14 downto 7);
		else
		   s_add_a16	 <= (others =>'0');
		   s_add_s8	    <= (others =>'0');
		   s_add_d8	    <= (others =>'0');
		end if;
		s_1bit_err    <= s_single_bit_error;
		s_2bit_err    <= s_double_bit_error;
		s_comm_err    <= s_channelB_comm_error; 
	   ready_o       <= not rst_i;
	end if;
end process;

--===================================================--
--                Broadcast Command Decoder
--===================================================--

Inst_BrdCommandDecoder: entity work.BrdCommandDecoder 
   port map(
		clk_i            => clk_i,
		brd_strobe_i     => s_brc_strobe,
		ttcrx_ready_i    => not rst_i,
		rx_brd_cmd_i     => s_brc_cmd,
		aligned_o        => s_idle,
		supernova_o      => brd_command_vector_o.supernova,
		test_pulse_o     => brd_command_vector_o.test_pulse,
		time_request_o   => brd_command_vector_o.time_request,
		rst_errors_o     => s_rst_errors,
		auto_trigger_o   => brd_command_vector_o.autotrigger,
		not_in_table_o   => not_in_table_o,
		en_acquisition_o => brd_command_vector_o.en_acquisition
	  );

brd_command_vector_o.rst_errors     <= s_rst_errors;
brd_command_vector_o.rst_time       <= s_brc_rst_t;
brd_command_vector_o.rst_event      <= s_brc_rst_e;
brd_command_vector_o.rst_time_event <= s_brc_rst_e and s_brc_rst_t;
brd_command_vector_o.idle <= s_idle;
--===================================================--
--                Addressed Command Decoder
--===================================================--

Inst_AddressedCommandDecoder: entity work.addressed_command_decoder
   port map( 
	        clk_i         => clk_i,
           rst_n_i       => not rst_i,
			  gcu_id_i      => gcuid_i,
           add_a16_i     => s_add_a16,
           add_s8_i      => s_add_s8,
           add_d8_i      => s_add_d8,
           long_strobe_i => s_add_strb,
           add_s8_o      => s_ttc_mem_addr,
           add_d8_o      => s_ttc_mem_data,
           we_o          => s_ttc_mem_we
			  );

--===================================================--
--                TTC register stack
--===================================================--
			  
Inst_TTC_register_stack: entity work.TTC_register_stack
   generic map(
	        g_TTC_memory_deep  => g_TTC_memory_deep
	        )
   port map( 
	        clk_i               => clk_i,
           we_i                => s_ttc_mem_we,
           rst_n_i             => not rst_i,
           addr_i              => s_ttc_mem_addr,
           data_i              => s_ttc_mem_data,
           ctrl_o              => ttc_ctrl_o,
           l1a_time_o          => l1a_time_o,
           synch_byte_o        => synch_o,
           delay_byte_o        => delay_o
			  );		  
--===================================================--
--       addressed command delay request pulse
--===================================================--			  
p_delay_req : process(clk_i)
begin
   if rising_edge(clk_i) then
      if s_ttc_mem_addr = x"19" and s_ttc_mem_we = '1' then
         delay_req_o <= '1';
      else
         delay_req_o <= '0';
      end if;
   end if;
end process p_delay_req;

--===================================================--
--       addressed command synch request pulse
--===================================================--			  
p_synch_req : process(clk_i)
begin
   if rising_edge(clk_i) then
      if (s_ttc_mem_addr = x"09") and s_ttc_mem_we = '1' then
         synch_req_o <= '1';
      else
         synch_req_o <= '0';
      end if;
   end if;
end process p_synch_req;

--===================================================--
--       addressed command byte 5 pulse
--===================================================--			  
p_byte5 : process(clk_i)
begin
   if rising_edge(clk_i) then
      if (s_ttc_mem_addr = x"16" or s_ttc_mem_addr = x"0e") and s_ttc_mem_we = '1' then
         byte5_o <= '1';
      else
         byte5_o <= '0';
      end if;
   end if;
end process p_byte5;

--===================================================--
--                 Error Counters
--===================================================--

p_1bit_error_counter : process(clk_i)
begin
   if rising_edge(clk_i) then
      if reset_err = '1' or s_rst_errors = '1' then
         u_1bit_err_count <= (others => '0');
      elsif s_1bit_err = '1' then
         u_1bit_err_count <= u_1bit_err_count + 1;
      end if;
   end if;
end process p_1bit_error_counter;
single_bit_err_o <= std_logic_vector(u_1bit_err_count);


p_2bit_error_counter : process(clk_i)
begin
   if rising_edge(clk_i) then
      if reset_err = '1' or s_rst_errors = '1' then
         u_2bit_err_count <= (others => '0');
      elsif s_2bit_err = '1' then
         u_2bit_err_count <= u_2bit_err_count + 1;
      end if;
   end if;
end process p_2bit_error_counter;
duble_bit_err_o <= std_logic_vector(u_2bit_err_count);


p_comm_error_counter : process(clk_i)
begin
   if rising_edge(clk_i) then
      if reset_err = '1' or s_rst_errors = '1' then
         u_comm_err_count <= (others => '0');
      elsif s_comm_err = '1' then
         u_comm_err_count <= u_comm_err_count + 1;
      end if;
   end if;
end process p_comm_error_counter;
comm_err_o <= std_logic_vector(u_comm_err_count);

no_errors_o <= '1' when u_comm_err_count = 0 else
               '0';
					
--===================================================--
--         Set Reset FF - Channel Aligned flag
--===================================================--					
Inst_aligned_SR: entity work.set_reset_ffd
   generic map(
	        g_clk_rise  => "TRUE"
	        )
   port map( 
	        clk_i   => clk_i,  
  		     set_i   => s_idle,
		     reset_i => rst_i,
           q_o     => s_aligned
           );
aligned_o <= s_aligned;
end Behavioral;
