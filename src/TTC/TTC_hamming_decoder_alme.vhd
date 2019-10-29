-------------------------------------------------------------------------------
-- Title      : Serial B Communication Module
-- Project    : RCU Trigger Receiver
-------------------------------------------------------------------------------
-- File             : $RCSfile: serialb_com.vhd,v $
-- Last edited by   : $Author: alme $
-- Last update      : $Date: 2006/02/24 13:44:01 $
-- Current Revision : $Revision: 1.2 $
-------------------------------------------------------------------------------
-- Description: Deserializer and hamming decoder for the Serial B line.
-------------------------------------------------------------------------------
-- Revision History : 
-- http://www.ift.uib.no/kjekscgi-bin/viewcvs.cgi/vhdlcvs/trigger_receiver/
-- DATE:        25/11/2016
-- VERSION:     2.0
-- AUTHOR:      Davide Pedretti, INFN LNL
-- DESCRIPTION: changed vhdl coding style, design architecture review + changed 
--              the Hamming encoding/decoding functions.
-------------------------------------------------------------------------------
--
-- This file is property of and copyright by the Instrumentation and 
-- Electronics Section, Dep. of Physics and Technology
-- University of Bergen, Norway, 2005
-- This file has been written by Johan Alme, Knut Ove Nyg�rd & Olav Torheim
-- Johan.Alme@ift.uib.no
--
-- Permission to use, copy, modify and distribute this firmware and its  
-- documentation strictly for non-commercial purposes is hereby granted  
-- without fee, provided that the above copyright notice appears in all  
-- copies and that both the copyright notice and this permission notice  
-- appear in the supporting documentation. The authors make no claims    
-- about the suitability of this firmware for any purpose. It is         
-- provided "as is" without express or implied warranty.                 
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.TTIM_v2_pack.all;

entity serialb_com is
  generic (
    include_hamming : boolean
  );
  port(
    clk_i                 : in  std_logic;
	 reset_n_i             : in  std_logic;
    chb_i                 : in  std_logic;    -- serial stream 
    chb_strobe_i          : in  std_logic;
    single_bit_error_o    : out std_logic;
    double_bit_error_o    : out std_logic;
    communication_error_o : out std_logic;
    data_ready_o          : out std_logic_vector(1 downto 0);
    data_out_o            : out std_logic_vector(38 downto 0)
  );
end serialb_com;

architecture rtl of serialb_com is

  type t_state is (st1_idle, st2_fmt, st3_get_data, st3_get_broadcast, st4_stop, st5_error);

  signal s_received_word        : std_logic_vector(38 downto 0);
  signal s_brc_rdy              : std_logic;
  signal s_dta_rdy              : std_logic;
  signal next_state             : t_state;
  signal s_comm_err             : std_logic;
  
begin
communication_error_o <= s_comm_err;
------------------------------------------------------------------------------------------------
-- include hamming
------------------------------------------------------------------------------------------------
hamming : if include_hamming generate
  signal d_adr                : t_coded_ham_32bit;  
  signal d_br                 : t_coded_ham_8bit;   
  signal hmg_br               : t_parity_ham_8bit;
  signal hmg_adr              : t_parity_ham_32bit;   
  signal s_single_bit_error   : std_logic;
  signal s_double_bit_error	: std_logic;
  
begin

single_bit_error_o <= s_single_bit_error;
double_bit_error_o <= s_double_bit_error and s_comm_err;

------------------------------------------------------------------------------------
d_br <=  s_received_word(12 downto 0);
d_adr <= s_received_word(38 downto 0);
------------------------------------------------------------------------------------
process(d_br,d_adr)
   variable v_hmg_br           : t_parity_ham_8bit;
   variable v_hmg_adr          : t_parity_ham_32bit;
   begin
      -- Calculating the hamming bits for the broadcast word:
      p_hamming_decoder_8bit(d_br,v_hmg_br);
      hmg_br <= v_hmg_br;
      ------------------------------------------------------------------------------------
      -- Calculating the hamming bits for the addressed word:
      p_hamming_decoder_32bit(d_adr,v_hmg_adr);
      hmg_adr <= v_hmg_adr;
end process;

------------------------------------------------------------------------------------                
------------------------------------------------------------------------------------
-- purpose: receiving serial B messages by shifting them into a shift register.    
--          checking the hamming bits. Single bit error correction.      
p_driver: process(clk_i, reset_n_i)
begin
	if reset_n_i = '0' then
      next_state                   <= st1_idle;
      s_received_word(0)           <= '1';
      s_received_word(38 downto 1) <= (others => '0');
      data_ready_o                 <= "00";
      s_brc_rdy                    <= '0';
      s_dta_rdy                    <= '0';
      s_comm_err        <= '0';
      s_single_bit_error           <= '0';
      s_double_bit_error           <= '0';
      data_out_o                   <= (others => '0');
  	elsif rising_edge(clk_i) then
	   if chb_strobe_i = '1' then
	    -- assign default values
	       next_state                   <= st1_idle;
	       s_received_word(0)           <= '1';
	       s_received_word(38 downto 1) <= (others => '0');
	       data_ready_o                 <= "00";
	       s_brc_rdy                    <= '0';
	       s_dta_rdy                    <= '0';
	       s_comm_err        <= '0';
	       s_single_bit_error           <= '0';
	       s_double_bit_error           <= '0';
	       data_out_o                   <= s_received_word;
	
	       case next_state is
	          when st1_idle =>
	    	       if chb_i = '0' then     --start bit
	                next_state <= st2_fmt;
	             else
	                next_state <= st1_idle;
	             end if;
	      
	          when st2_fmt =>
	             if chb_i = '1' then         -- fmt bit is 1 for ttcrx long frame receive.
	                next_state <= st3_get_data;
	             else                        -- fmt bit is 0 for ttcrx broadcast commands
	                next_state <= st3_get_broadcast;
	             end if;
	      
	          when st3_get_data =>           -- shiftregister for serialB input
				    if s_received_word(38) = '1' then
    	             s_received_word(38 downto 1) <= s_received_word(37 downto 0);
    	             s_received_word(0)           <= chb_i;
	    			    s_dta_rdy                    <= '1';
    	             next_state                   <= st4_stop;
					 else
					    s_received_word(38 downto 1) <= s_received_word(37 downto 0);
    	             s_received_word(0)           <= chb_i;
						 next_state                   <= st3_get_data;
					 end if;
	      
	          when st3_get_broadcast =>      -- shiftregister for serialB input
				    if s_received_word(12) = '1' then
    	             s_received_word(38 downto 1) <= s_received_word(37 downto 0);
    	             s_received_word(0)           <= chb_i;
                   s_brc_rdy                    <= '1';
    	             next_state                   <= st4_stop;
    	          else
					    s_received_word(38 downto 1) <= s_received_word(37 downto 0);
    	             s_received_word(0)           <= chb_i;
						 next_state                   <= st3_get_broadcast;
    	          end if;
	      
	          when st4_stop =>
	             if chb_i = '0' then
	                next_state <= st5_error;
	             else         
	                if s_brc_rdy='1' then
	                   if (hmg_br(4) = '0' and (hmg_br(3 downto 0) /= "0000")) then
	                      s_double_bit_error <= '1';
	                      s_single_bit_error <= '0';				
	                      next_state <= st5_error; -- no correction possible
	                   else			
	                      next_state   <= st1_idle;
                         data_ready_o <= s_dta_rdy & s_brc_rdy; -- data valid with 1 bit correction:								 
		                   case hmg_br(3 downto 0) is
	                         when "0000" => -- no errors
	                            s_single_bit_error <= '0';		
	         	                s_double_bit_error <= '0';
	                         when "0011" => -- D0 wrong
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';
	                            data_out_o(5)      <= not s_received_word(5); -- bit correction
	                         when "0101" => -- D1 wrong
		                         s_single_bit_error <= '1';		
		                         s_double_bit_error <= '0';
		                         data_out_o(6)      <= not s_received_word(6); -- bit correction
		                      when "0110" =>	-- D2 wrong                 
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';
	                            data_out_o(7)      <= not s_received_word(7); -- bit correction
	                         when "0111" =>	-- D3 wrong      
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';
	                            data_out_o(8)      <= not s_received_word(8); -- bit correction
	                         when "1001" => -- D4 wrong
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';
	                            data_out_o(9)      <= not s_received_word(9); -- bit correction
	                         when "1010" => -- D5 wrong
	          	                s_single_bit_error <= '1';		
		                         s_double_bit_error <= '0';
		                         data_out_o(10)     <= not s_received_word(10); -- bit correction
	                         when "1011" => -- D6 Wrong
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';
	                            data_out_o(11)     <= not s_received_word(11); -- bit correction
	                         when "1100" => -- D7 Wrong
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';
	                            data_out_o(12)     <= not s_received_word(12); -- bit correction
									 when "0001" => -- P0 wrong
	          	                s_single_bit_error <= '1';		
		                         s_double_bit_error <= '0';
		                         data_out_o(0)     <= not s_received_word(0); -- bit correction
	                         when "0010" => -- P1 Wrong
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';
	                            data_out_o(1)     <= not s_received_word(1); -- bit correction
	                         when "0100" => -- P2 Wrong
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';
	                            data_out_o(2)     <= not s_received_word(2); -- bit correction
									 when "1000" => -- P3 Wrong
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';
	                            data_out_o(3)     <= not s_received_word(3); -- bit correction
	                         when others =>
	                            s_single_bit_error <= '1';
	                            s_double_bit_error <= '1';
	                            next_state <= st5_error;
                               data_ready_o <= "00";						
	                      end case;		                 	
		                end if;
		             elsif s_dta_rdy = '1' then
		                if hmg_adr(6)='0' and (hmg_adr(5 downto 0) /= "000000") then
	                      s_single_bit_error <= '0';
	                      s_double_bit_error <= '1';
	                      next_state         <= st5_error;			
	                   else
	                      next_state   <= st1_idle;
                         data_ready_o <= s_dta_rdy & s_brc_rdy; -- data valid with 1 bit correction:								 
	                      case hmg_adr(5 downto 0) is
	                         when "000000" =>                                  -- no errors
	                            s_single_bit_error <= '0';		
	                            s_double_bit_error <= '0';
	                         when "000011" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(7)      <= not s_received_word(7);	-- D0 bit correction	        		
	                         when "000101" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(8)      <= not s_received_word(8);	-- D1 bit correction	        	
	                         when "000110" =>
		                         s_single_bit_error <= '1';		
		                         s_double_bit_error <= '0';		        	
	                            data_out_o(9)      <= not s_received_word(9);	-- D2 bit correction	        	
	                         when "000111" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(10)     <= not s_received_word(10);	-- D3 bit correction	        	
	                         when "001001" =>
		                         s_single_bit_error <= '1';		
		                         s_double_bit_error <= '0';		        	
	                            data_out_o(11)     <= not s_received_word(11);	-- D4 bit correction	        			        			        			        			        			        	
	                         when "001010" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(12)     <= not s_received_word(12);	-- D5 bit correction	        	
	                         when "001011" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(13)     <= not s_received_word(13);	-- D6 bit correction	     
	                         when "001100" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(14)     <= not s_received_word(14);	-- D7 bit correction	        	
	                         when "001101" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(15)     <= not s_received_word(15);	-- D8 bit correction	        	
	                         when "001110" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(16)     <= not s_received_word(16);	-- D9 bit correction	        	
	                         when "001111" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(17)     <= not s_received_word(17); -- D10 bit correction
	                         when "010001" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(18)     <= not s_received_word(18);	-- D11 bit correction	        	
	                         when "010010" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(19)     <= not s_received_word(19); -- D12 bit correction		        			        			        			        			        			        			        			        	
	                         when "010011" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(20)     <= not s_received_word(20);	-- D13 bit correction	        	
	                         when "010100" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(21)     <= not s_received_word(21);	-- D14 bit correction	        	
	                         when "010101" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(22)     <= not s_received_word(22);	-- D15 bit correction	        	
	                         when "010110" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(23)     <= not s_received_word(23);	-- D16 bit correction	        	
	                         when "010111" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(24)     <= not s_received_word(24);	-- D17 bit correction	        	
	                         when "011000" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(25)     <= not s_received_word(25);	-- D18 bit correction	        	
	                         when "011001" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(26)     <= not s_received_word(26);	-- D19 bit correction	        	
	                         when "011010" =>		        	
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(27)     <= not s_received_word(27);	-- D20 bit correction	        	
	                         when "011011" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(28)     <= not s_received_word(28);	-- D21 bit correction	        	
	                         when "011100" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(29)     <= not s_received_word(29);	-- D22 bit correction	        	
	                         when "011101" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(30)     <= not s_received_word(30);	-- D23 bit correction	        	
	                         when "011110" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(31)     <= not s_received_word(31);	-- D24 bit correction	        	
	                         when "011111" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(32)     <= not s_received_word(32);	-- D25 bit correction	        	
	                         when "100001" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(33)     <= not s_received_word(33); -- D26 bit correction
	                         when "100010" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(34)     <= not s_received_word(34);	-- D27 bit correction	        	
	                         when "100011" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(35)     <= not s_received_word(35);	-- D28 bit correction	        	
	                         when "100100" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(36)     <= not s_received_word(36);	-- D29 bit correction	        	
	                         when "100101" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(37)     <= not s_received_word(37); -- D30 bit correction
	                         when "100110" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(38)     <= not s_received_word(38);	-- D31 bit correction
                            when "000001" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(0)     <= not s_received_word(0);	-- P0 bit correction	        	
	                         when "000010" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(1)     <= not s_received_word(1);   -- P1 bit correction
	                         when "000100" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(2)     <= not s_received_word(2);	-- P2 bit correction	        	
	                         when "001000" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(3)     <= not s_received_word(3);	-- P3 bit correction	        	
	                         when "010000" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(4)     <= not s_received_word(4);	-- P4 bit correction	        	
	                         when "100000" =>
	                            s_single_bit_error <= '1';		
	                            s_double_bit_error <= '0';		        	
	                            data_out_o(5)     <= not s_received_word(5);   -- P5 bit correction								 
	                         when others =>
	                            s_single_bit_error <= '1';
	                            s_double_bit_error <= '1';
	                            next_state       <= st5_error;
                               data_ready_o <= "00";										 
	                      end case;
	                   end if;	             
	                end if;	        
	             end if;         	
	 
	          when st5_error =>
	             s_comm_err <= '1';
			       s_single_bit_error	  <= s_single_bit_error;
			       s_double_bit_error	  <= s_double_bit_error;
	             next_state            <= st1_idle;
	          when others =>
	    	       s_comm_err <= '0';
	    	       s_single_bit_error    <= '1';
	    	       s_double_bit_error    <= '1';
	             next_state            <= st5_error;
	       end case;
	    end if; -- chb_strobe_i
	 end if; -- rising_egde(clk)/reset_n_i
end process p_driver;

end generate hamming;
------------------------------------------------------------------------------------------------
-- END include hamming
------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------
-- NOT include hamming
------------------------------------------------------------------------------------------------
Nothamming : if include_hamming = false generate
   
begin

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- purpose: receiving serial B messages by shifting them into a shift register.    
--          checking the hamming bits.      
p_driver: process(clk_i, reset_n_i)
begin
  	if (reset_n_i = '0') then
      next_state                   <= st1_idle;
      s_received_word(0)           <= '1';
      s_received_word(38 downto 1) <= (others => '0');
      data_ready_o                 <= "00";
      s_brc_rdy                    <= '0';
      s_dta_rdy                    <= '0';
		single_bit_error_o           <= '0';
      double_bit_error_o           <= '0';
      s_comm_err        <= '0';
      data_out_o                   <= (others => '0');
  	elsif rising_edge(clk_i) then
	   if chb_strobe_i = '1' then
    	   -- assign default values
    	   next_state                   <= st1_idle;
    	   s_received_word(0)           <= '1';
    	   s_received_word(38 downto 1) <= (others => '0');
    	   data_ready_o                 <= "00";
    	   s_brc_rdy                    <= '0';
    	   s_dta_rdy                    <= '0';
    	   s_comm_err        <= '0';
			single_bit_error_o           <= '0';
         double_bit_error_o           <= '0';
    	   data_out_o                   <= s_received_word;

    	   case next_state is
    	      when st1_idle =>
    		      if chb_i = '0' then                       --start bit
    	            next_state <= st2_fmt;
    	         else
    	            next_state <= st1_idle;
    	         end if;
    	  
    	      when st2_fmt =>
    	         if chb_i = '1' then  -- fmt bit is 1 for ttcrx long frame (addr) receive.
    	            next_state <= st3_get_data;
    	         else                                          -- fmt bit is 0 for ttcrx broadcast commands
    	            next_state <= st3_get_broadcast;
    	         end if;
    	  
    	      when st3_get_data =>                             -- shiftregister for serialB input
				   if s_received_word(38) = '1' then
    	            s_received_word(38 downto 1) <= s_received_word(37 downto 0);
    	            s_received_word(0)           <= chb_i;
	    			   s_dta_rdy                    <= '1';
    	            next_state                   <= st4_stop;
					else
					   s_received_word(38 downto 1) <= s_received_word(37 downto 0);
    	            s_received_word(0)           <= chb_i;
						next_state                   <= st3_get_data;
					end if;
    	         
    	      when st3_get_broadcast =>   
				   if s_received_word(12) = '1' then
    	            s_received_word(38 downto 1) <= s_received_word(37 downto 0);
    	            s_received_word(0)           <= chb_i;
                  s_brc_rdy                    <= '1';
    	            next_state                   <= st4_stop;
    	         else
					   s_received_word(38 downto 1) <= s_received_word(37 downto 0);
    	            s_received_word(0)           <= chb_i;
						next_state                   <= st3_get_broadcast;
    	         end if;
				
    	      when st4_stop =>
    	         if chb_i = '0' then                             -- missed stop bit or shifting errors
    	            next_state <= st5_error;
    	         elsif chb_i = '1' then                          -- stop bit
    	            data_ready_o <= s_dta_rdy & s_brc_rdy;       -- data_out_o and data_ready_o are valid until 
						                                             -- next chb_strobe_i therefore for 16 ns
    	            next_state <= st1_idle;		                	
    	         end if;         	
 
    	      when st5_error =>
    	         s_comm_err <= '1';
    	         next_state            <= st1_idle;
    	      when others =>
    	         next_state            <= st5_error;
    	   end case;
	   end if; -- chb_strobe
   end if;    -- rising_edge(clk)/reset
end process p_driver;
------------------------------------------------------------------------------------

end generate Nothamming;
------------------------------------------------------------------------------------------------
-- NOT include hamming
------------------------------------------------------------------------------------------------
end rtl;