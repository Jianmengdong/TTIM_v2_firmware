-- broadcast command decoder
--
-- 
--
-- INFN - LNL, December 2016
-- 
----------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity BrdCommandDecoder is
    Port ( clk_i            : in  std_logic;
	        brd_strobe_i     : in  std_logic;
           ttcrx_ready_i    : in  std_logic;
           rx_brd_cmd_i     : in  std_logic_vector (5 downto 0);
           aligned_o        : out  std_logic;
           supernova_o      : out  std_logic;
           test_pulse_o     : out  std_logic;
           time_request_o   : out  std_logic;
           rst_errors_o     : out  std_logic;
			  not_in_table_o   : out  std_logic;
           auto_trigger_o   : out  std_logic;
           en_acquisition_o : out  std_logic
			  );
end BrdCommandDecoder;

architecture rtl of BrdCommandDecoder is

begin

p_brd_command_decoder : process(clk_i,ttcrx_ready_i)
begin
   if ttcrx_ready_i = '0' then
	   aligned_o          <= '0';
		supernova_o        <= '0';
		test_pulse_o       <= '0';
		time_request_o     <= '0';
		rst_errors_o       <= '0';
		auto_trigger_o     <= '0';
		not_in_table_o     <= '0';
		en_acquisition_o   <= '0';
   elsif rising_edge(clk_i) then
	   aligned_o          <= '0';
		supernova_o        <= '0';
		test_pulse_o       <= '0';
		time_request_o     <= '0';
		rst_errors_o       <= '0';
		not_in_table_o     <= '0';
		auto_trigger_o     <= '0';
		en_acquisition_o   <= '0';
		if brd_strobe_i = '1' then
		   case rx_brd_cmd_i is
		      -------
            when "111111" => -- idle
               aligned_o        <= '1';  
            -------
            when "111110" => -- 
               supernova_o      <= '1';
			   -------
            when "111101" => -- 
               test_pulse_o     <= '1';
		      -------
			   when "111100" => -- 
               time_request_o   <= '1';
			   -------
			   when "111011" => -- 
               rst_errors_o     <= '1';
		      -------
			   when "111010" => -- 
               auto_trigger_o    <= '1';
		      -------
			   when "111001" => -- 
               en_acquisition_o <= '1';    
		      -------
            when others => 
               not_in_table_o   <= '1';			 
			   -------  
         end case;
		end if;
   end if;
end process p_brd_command_decoder;

end rtl;

