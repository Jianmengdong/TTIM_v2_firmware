--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Company:                CERN (PH-ESE-BE)                                                         
-- Engineer:               Sophie Baron (sophie.baron@cern.ch)
--                                                                                                 
-- Project Name:           TTC                                                            
-- Module Name:            long_frame_maker                                         
--                                                                                                 
-- Language:               VHDL'93                                                                  
--                                                                                                   
-- Target Device:          Kintex7 - KC705                                                         
-- Tool version:           ISE 14.5                                                                
--                                                                                                   
-- Version:                0.1                                                                      
--
-- Description:            
--
-- Versions history:       DATE         VERSION   AUTHOR            DESCRIPTION
--
--                         18/07/2013   1.0       Sophie BARON    	- First .vhd module definition           
--                         22/11/2016   1.1       Davide Pedretti    - new long frame proposal
--=================================================================================================--
--=================================================================================================--

--=================================================================================================--
--==================================== Additional Comments ========================================--
--=================================================================================================-- 
	--
	-- TTC FRAME 
	--
	-- Long Addressed, 42 bits
	-- 01AAAAAAAAAAAAAAE1SSSSSSSSDDDDDDDDHHHHHHH1: A= TTCrx address, 14 bits. E= internal(0)/External(1), 1 bit. S=SubAddress, 8 bits. D=Data, 8 bits. H=Hamming Code, 7 bits.
	-- 

	-- ttc hamming encoding for long addressed (d32/h7)
	-- /* build Hamming bits */
	-- hmg[0] = d[0]^d[1]^d[2]^d[3]^d[4]^d[5]; 
	-- hmg[1] = d[6]^d[7]^d[8]^d[9]^d[10]^d[11]^d[12]^d[13]^d[14]^d[15]^d[16]^d[17]^d[18]^d[19]^d[20];
	-- hmg[2] = d[6]^d[7]^d[8]^d[9]^d[10]^d[11]^d[12]^d[13]^d[21]^d[22]^d[23]^d[24]^d[25]^d[26]^d[27];
	-- hmg[3] = d[0]^d[1]^d[2]^d[6]^d[7]^d[8]^d[9]^d[14]^d[15]^d[16]^d[17]^d[21]^d[22]^d[23]^d[24]^d[28]^d[29]^d[30];
	-- hmg[4] = d[0]^d[3]^d[4]^d[6]^d[7]^d[10]^d[11]^d[14]^d[15]^d[18]^d[19]^d[21]^d[22]^d[25]^d[26]^d[28]^d[29]^d[31];
	-- hmg[5] = d[1]^d[3]^d[5]^d[6]^d[8]^d[10]^d[12]^d[14]^d[16]^d[18]^d[20]^d[21]^d[23]^d[25]^d[27]^d[28]^d[30]^d[31];
	-- hmg[6] = hmg[0]^hmg[1]^hmg[2]^hmg[3]^hmg[4]^hmg[5]^d[0]^d[1]^d[2]^d[3]^d[4]^d[5]^d[6]^d[7]^d[8]^d[9]^d[10]^d[11]^d[12]^d[13]^d[14]^d[15]^d[16]^d[17]^d[18]^d[19]^d[20]^d[21]^d[22]^d[23]^d[24]^d[25]^d[26]^d[27]^d[28]^d[29]^d[30]^d[31];
	-- /* build Hamming word */
	-- hamming = (hmg[0] | (hmg[1]<<1) | (hmg[2]<<2) | (hmg[3]<<3) | (hmg[4]<<4) | (hmg[5]<<5) | (hmg[6]<<6));
			   
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.TTIM_v2_pack.all;

entity long_frame_maker is
   port 
      (
      reset_i          	    : in  std_logic;
      clk_i     	          : in std_logic;
      long_address_i        : in std_logic_vector(15 downto 0); 
	   long_subadd_i       	 : in std_logic_vector(7 downto 0); 
	   long_data_i           : in std_logic_vector(7 downto 0);   
	   long_command_strobe_i : in std_logic;  	  
	   long_frame_o          : out std_logic_vector(41 downto 0);   
	   strobe_o					 : out std_logic	                   
      );
end long_frame_maker;

architecture rtl of long_frame_maker is
   
   signal s_long_frame   : std_logic_vector(31 downto 0);  
	signal s_hmg          : t_parity_ham_32bit;

        --=======================================================--
begin   --================== Architecture Body ==================-- 
        --=======================================================--

   -- AAAAAAAAAAAAAAAASSSSSSSSDDDDDDDD
   s_long_frame <= long_address_i & long_subadd_i & long_data_i;
	-- HHHHHHH
   s_hmg        <= f_hamming_encoder_32bit(s_long_frame);        
   
   
   process(clk_i,reset_i)
   begin
	   if reset_i = '1' then
			long_frame_o <= (others => '0');
	   elsif rising_edge(clk_i) then
		   if long_command_strobe_i = '1' then
   		   -- 01AAAAAAAAAAAAAAAASSSSSSSSDDDDDDDDHHHHHHH1
				long_frame_o <= '0' & '1' & s_long_frame & s_hmg & '1'; 
		   end if;
	   end if;
   end process;

   process(clk_i,reset_i)
   begin
	   if reset_i = '1' then
			strobe_o <= '0';
	   elsif rising_edge(clk_i) then   
			strobe_o <= long_command_strobe_i;
		end if;
   end process;
   
 end rtl;