----------------------------------------------------------------------------------
-- Company:        INFN - LNL
-- Create Date:    11:23:29 01/24/2017 
-- Design Name:    TTC Test
-- Module Name:    addressed_command_decoder - rtl  
-- Project Name:   GCU
-- Tool versions:  ISE 14.7
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.TTIM_v2_pack.all;
library unisim;
use unisim.vcomponents.all;


entity addressed_command_decoder is
    Port ( clk_i         : in  std_logic;
           rst_n_i       : in  std_logic;
			  gcu_id_i      : in  std_logic_vector(15 downto 0);
           add_a16_i     : in  std_logic_vector(15 downto 0);
           add_s8_i      : in  std_logic_vector(7 downto 0);
           add_d8_i      : in  std_logic_vector(7 downto 0);
           long_strobe_i : in  std_logic;
           add_s8_o      : out  std_logic_vector(7 downto 0);
           add_d8_o      : out  std_logic_vector(7 downto 0);
           we_o          : out  std_logic);
end addressed_command_decoder;

architecture rtl of addressed_command_decoder is

signal s_addressed : std_logic;
signal s_broadcast : std_logic;
signal s_we        : std_logic;
constant c_zero    : std_logic_vector(15 downto 0) := x"0000";

begin

process(add_a16_i,gcu_id_i)
   variable v_equal : std_logic;
   begin
   p_address_compare(add_a16_i,gcu_id_i,v_equal); 
   s_addressed <= v_equal;
end process;

process(add_a16_i)
   variable v_equal : std_logic;
   begin
   p_address_compare(add_a16_i,c_zero,v_equal);
	s_broadcast <= v_equal;
end process;

s_we <= (s_addressed or s_broadcast) and long_strobe_i;

p_registers: process(clk_i, rst_n_i)
begin
   if rst_n_i = '0' then
	   we_o     <= '0';
		add_d8_o <= (others => '0');
		add_s8_o <= (others => '0');
	elsif rising_edge(clk_i) then
	   we_o     <= s_we;
		add_d8_o <= add_d8_i;
		add_s8_o <= add_s8_i;
	end if; 
end process p_registers;
	
end rtl;

