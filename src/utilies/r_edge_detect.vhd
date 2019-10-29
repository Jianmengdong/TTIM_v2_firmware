----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2019/10/12 14:10:05
-- Design Name: 
-- Module Name: r_edge_detect - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity r_edge_detect is
    generic(
    g_clk_rise :string := "TRUE"
    );
    Port ( clk_i : in STD_LOGIC;
           sig_i : in STD_LOGIC;
           sig_o : out STD_LOGIC);
end r_edge_detect;

architecture Behavioral of r_edge_detect is
signal s_int : std_logic;
begin
G1 : if (g_clk_rise = "TRUE") generate
     begin
        process(clk_i)
        begin
           if rising_edge(clk_i) then
		  	     s_int <= sig_i;
			     if s_int = '0' and sig_i = '1' then
				     sig_o <= '1';
			     else
				     sig_o <= '0';
			     end if;
		     end if;
        end process; 
end generate G1;

G2 : if (g_clk_rise = "FALSE") generate
     begin
        process(clk_i)
        begin
           if falling_edge(clk_i) then
		  	     s_int <= sig_i;
			     if s_int = '0' and sig_i = '1' then
				     sig_o <= '1';
			     else
				     sig_o <= '0';
			     end if;
		     end if;
        end process; 
end generate G2;

end Behavioral;
