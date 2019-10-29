----------------------------------------------------------------------------------
-- Company:        INFN - LNL
-- Create Date:    14:04:19 01/24/2017 
-- Design Name:    TTC Test
-- Module Name:    TTC_register_stack - rtl 
-- Project Name:   GCU
-- Tool versions:  ISE 14.7
-- Revision 0.01 - File Created
-- Description:
-- 0x00 --> control register
-- 0x01 --> l1a time byte 0
-- 0x02 --> l1a time byte 1
-- 0x03 --> l1a time byte 2
-- 0x04 --> l1a time byte 3
-- 0x05 --> l1a time byte 4
-- 0x06 --> l1a time byte 5
-- 0x07 --> l1a time byte 6
-- 0x08 --> l1a time byte 7
-- 0x09 --> synch byte 0
-- 0x0a --> synch byte 1
-- 0x0b --> synch byte 2
-- 0x0c --> synch byte 3
-- 0x0d --> synch byte 4
-- 0x0e --> synch byte 5
-- 0x0f --> reserved
-- 0x10 --> reserved
-- 0x11 --> delay byte 0
-- 0x12 --> delay byte 1
-- 0x13 --> delay byte 2
-- 0x14 --> delay byte 3
-- 0x15 --> delay byte 4
-- 0x16 --> delay byte 5
-- 0x17 --> reserved
-- 0x18 --> reserved
-- 0x19 --> delay request
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.TTIM_v2_pack.all;

entity TTC_register_stack is
    generic(
	        g_TTC_memory_deep : positive := 26
	        );
    Port ( clk_i               : in  std_logic;
           we_i                : in  std_logic;
           rst_n_i             : in  std_logic;
           addr_i              : in  std_logic_vector (7 downto 0);
           data_i              : in  std_logic_vector (7 downto 0);
           ctrl_o              : out t_ttc_ctrl;
           l1a_time_o          : out  std_logic_vector (47 downto 0);
           synch_byte_o        : out  std_logic_vector (47 downto 0);
           delay_byte_o        : out  std_logic_vector (47 downto 0));
end TTC_register_stack;

architecture rtl of TTC_register_stack is

-------------------type declarations---------------------------------------
type t_TTC_memory_space is array(g_TTC_memory_deep - 1 downto 0) of std_logic_vector(7 downto 0);

signal s_register : t_TTC_memory_space;
signal s_we       : std_logic_vector(g_TTC_memory_deep - 1 downto 0);
signal s_select   : std_logic_vector(g_TTC_memory_deep - 1 downto 0);

begin

p_registers : process (clk_i) 
begin
	for I in 0 to g_TTC_memory_deep - 1 loop
	   if rst_n_i = '0' then 
			s_register(I) <= (others => '0');
	   elsif rising_edge(clk_i) then
		   if s_we(I) = '1' then
			   s_register(I) <= data_i;
			end if;
      end if;
   end loop;
end process p_registers;

-----------------------------------------------------------------------------------
------------------------------------Decoder----------------------------------------
GEN_DECODER:
for I in 0 to g_TTC_memory_deep - 1 generate
	s_select(I) <= '1' when (addr_i = std_logic_vector(to_unsigned(I,addr_i'length))) else '0';
end generate GEN_DECODER;					

-----------------------------------------------------------------------------------
-------------------------------------wren------------------------------------------

GEN_WR_EN:
for I in 0 to g_TTC_memory_deep - 1 generate
	s_we(I) <= (s_select(I) and we_i);
end generate GEN_WR_EN;

-----------------------------------------------------------------------------------
--------------------------------------OUT------------------------------------------

ctrl_o.en_acquisition      <= s_register(0)(0);
ctrl_o.backpressure        <= s_register(0)(1);
ctrl_o.autotrigger         <= s_register(0)(2);
l1a_time_o(7 downto 0)     <= s_register(1);
l1a_time_o(15 downto 8)    <= s_register(2);
l1a_time_o(23 downto 16)   <= s_register(3);
l1a_time_o(31 downto 24)   <= s_register(4);
l1a_time_o(39 downto 32)   <= s_register(5);
l1a_time_o(47 downto 40)   <= s_register(6);
synch_byte_o(7 downto 0)   <= s_register(9);
synch_byte_o(15 downto 8)  <= s_register(10);
synch_byte_o(23 downto 16) <= s_register(11);
synch_byte_o(31 downto 24) <= s_register(12);
synch_byte_o(39 downto 32) <= s_register(13);
synch_byte_o(47 downto 40) <= s_register(14);
delay_byte_o(7 downto 0)   <= s_register(17);
delay_byte_o(15 downto 8)  <= s_register(18);
delay_byte_o(23 downto 16) <= s_register(19);
delay_byte_o(31 downto 24) <= s_register(20);
delay_byte_o(39 downto 32) <= s_register(21);
delay_byte_o(47 downto 40) <= s_register(22);


end rtl;

