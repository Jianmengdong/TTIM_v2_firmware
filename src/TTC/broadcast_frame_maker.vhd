--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Company:                CERN (PH-ESE-BE)                                                         
-- Engineer:               Sophie Baron (sophie.baron@cern.ch)
--                                                                                                 
-- Project Name:           TTC                                                            
-- Module Name:            broadcast_frame_maker                                         
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
--                         22/11/2016   1.1       Davide Pedretti    - Hamming generation and check
--                                                                     matrix changes. Test command
--                                                                     bits merged with data bits
--=================================================================================================--
--=================================================================================================--

--=================================================================================================--
--==================================== Additional Comments ========================================--
--=================================================================================================-- 
	--
	-- TTC 
	--
	-- Short Broadcast, 16 bits:
	-- 00SSSSSSEBHHHHH1: S=Command, 6 bits. E=Event Counter Reset, 1 bit. B=Local Time Counter Reset, 1 bit. 
	-- H=Hamming Code, 5 bits.
	--
	-- ttc hamming encoding for broadcast (d8/h5)
	-- /* build Hamming bits */
	-- hmg[0] = d[0]^d[1]^d[3]^d[4]^d[6];
	-- hmg[1] = d[0]^d[2]^d[3]^d[5]^d[6];
	-- hmg[2] = d[1]^d[2]^d[3]^d[7];
	-- hmg[3] = d[4]^d[5]^d[6]^d[7];
	-- hmg[4] =hmg[0]^hmg[1]^hmg[2]^hmg[3]^d[0]^d[1]^d[2]^d[3]^d[4]^d[5]^d[6]^d[7]; 

--=================================================================================================--
--======================================= Module Body =============================================-- 
--=================================================================================================--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.TTIM_v2_pack.all;

entity broadcast_frame_maker is
--generic (<>: integer:= 100000);
port 
(
      reset_i           : in  std_logic;
      clk_i             : in std_logic;   -- 62.5 MHz
      -- Broadcast frame:
	   -- a '1' either in ecntrst_i, bcntrst_i or brdcst_strobe_i triggers a broadcast command 
      ---------------------------------------------------------------------------------
		brdcst_cmd_i      : in std_logic_vector(5 downto 0);
	   ecntrst_i         : in std_logic;  
	   bcntrst_i         : in std_logic;  
	   brdcst_strobe_i   : in std_logic; 
		strobe_o          : out std_logic;
	   brdcst_frame_o    : out std_logic_vector(15 downto 0)
);
end broadcast_frame_maker;

architecture rtl of broadcast_frame_maker is

   signal s_broadcast_data    : std_logic_vector(7 downto 0);  
   signal s_broadcast_strobe  : std_logic;
   signal s_hmg               : t_parity_ham_8bit;
	
           --===================================================--
begin      --================== Architecture Body ==================-- 
           --===================================================--

 
   s_broadcast_strobe <= brdcst_strobe_i or ecntrst_i or bcntrst_i;
   s_broadcast_data   <= brdcst_cmd_i & ecntrst_i & bcntrst_i;      -- SSSSSSEB
   
   s_hmg <= f_hamming_encoder_8bit(s_broadcast_data);
	
   process(clk_i,reset_i)
   begin
	   if reset_i = '1' then
			brdcst_frame_o <= (others => '0');
	   elsif rising_edge(clk_i) then
		   if s_broadcast_strobe = '1' then
   		   brdcst_frame_o <= '0' & '0' & s_broadcast_data & s_hmg & '1'; -- 00SSSSSSEBHHHHH1
		   end if;
	   end if;
   end process;

   process(clk_i,reset_i)
   begin
	   if reset_i = '1' then
			strobe_o <= '0';
	   elsif rising_edge(clk_i) then
			strobe_o <= s_broadcast_strobe;
	   end if;
   end process;
   
 end rtl;