-- broadcast command encoder
--
-- 
--
-- INFN - LNL, December 2016
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.TTIM_v2_pack.all;

entity BrdCommandEncoder is
    Port ( clk_i           : in  std_logic;
           ttctx_ready_i   : in  std_logic;
           brdcst_cmd_o    : out  std_logic_vector (5 downto 0);
           ecntrst_o       : out  std_logic;
           bcntrst_o       : out  std_logic;
           brdcst_strobe_o : out  std_logic;
           tx_brd_vector_i : t_brd_command
			  );
end BrdCommandEncoder;

architecture rtl of BrdCommandEncoder is
signal s_select : std_logic_vector (9 downto 0);
begin
      s_select(0) <= tx_brd_vector_i.idle;
		s_select(1) <= tx_brd_vector_i.rst_time;
		s_select(2) <= tx_brd_vector_i.rst_event;
		s_select(3) <= tx_brd_vector_i.rst_time_event;
		s_select(4) <= tx_brd_vector_i.supernova;
		s_select(5) <= tx_brd_vector_i.test_pulse;
		s_select(6) <= tx_brd_vector_i.time_request;
		s_select(7) <= tx_brd_vector_i.rst_errors;
		s_select(8) <= tx_brd_vector_i.autotrigger;
		s_select(9) <= tx_brd_vector_i.en_acquisition;

p_brd_command_table : process(clk_i,ttctx_ready_i)
begin
   if ttctx_ready_i = '0' then
	   brdcst_cmd_o    <= (others => '0');
		ecntrst_o       <= '0';
		bcntrst_o       <= '0';
		brdcst_strobe_o <= '0';
   elsif rising_edge(clk_i) then
	
	   brdcst_strobe_o <= tx_brd_vector_i.idle or tx_brd_vector_i.rst_time 
		                   or tx_brd_vector_i.rst_event or tx_brd_vector_i.rst_time_event 
								 or tx_brd_vector_i.supernova or tx_brd_vector_i.test_pulse
								 or tx_brd_vector_i.time_request or tx_brd_vector_i.rst_errors 
 								 or tx_brd_vector_i.autotrigger or  tx_brd_vector_i.en_acquisition;

		case s_select is
		    -------
          when "0000000001" => -- idle
             brdcst_cmd_o    <= "111111";
		       ecntrst_o       <= '0';
		       bcntrst_o       <= '0';   
          -------
          when "0000000010" => -- rst local time
             brdcst_cmd_o    <= "111111";
		       ecntrst_o       <= '0';
		       bcntrst_o       <= '1';
			 -------
          when "0000000100" => -- rst event counter
             brdcst_cmd_o    <= "111111";
		       ecntrst_o       <= '1';
		       bcntrst_o       <= '0';
		    -------
			 when "0000001000" => -- rst local time + event counter
             brdcst_cmd_o    <= "111111";
		       ecntrst_o       <= '1';
		       bcntrst_o       <= '1';
			 -------
			 when "0000010000" => -- supernova
             brdcst_cmd_o    <= "111110";
		       ecntrst_o       <= '0';
		       bcntrst_o       <= '0';
		    -------
			 when "0000100000" => -- test pulse
             brdcst_cmd_o    <= "111101";
		       ecntrst_o       <= '0';
		       bcntrst_o       <= '0';
		    -------
			 when "0001000000" => -- time request
             brdcst_cmd_o    <= "111100";
		       ecntrst_o       <= '0';
		       bcntrst_o       <= '0';
		    -------
			 when "0010000000" => -- reset communication errors
             brdcst_cmd_o    <= "111011";
		       ecntrst_o       <= '0';
		       bcntrst_o       <= '0';
		    -------
			 when "0100000000" => -- autotrigger
             brdcst_cmd_o    <= "111010";
		       ecntrst_o       <= '0';
		       bcntrst_o       <= '0';
		    -------
			 when "1000000000" => -- enable acquisition
             brdcst_cmd_o    <= "111001";
		       ecntrst_o       <= '0';
		       bcntrst_o       <= '0';
		    -------
          when others =>               
             brdcst_cmd_o    <= (others => '0');
		       ecntrst_o       <= '0';
		       bcntrst_o       <= '0';
			 -------  
       end case;
   end if;
end process p_brd_command_table;

end rtl;

