----------------------------------------------------------------------------------
-------------------------------Falling edge detection-----------------------------
----------------------------------------------------------------------------------
-- Description: falling edge detection.
-- Generate a Tclk wide pulse on the input falling edge
--
--                  
--             _   _   _   _   _   _   _  
-- clk_i     _/ \_/ \_/ \_/ \_/ \_/ \_/ \...
--           ______________
-- sig_i                   \_____________...     
--                              ___      
-- sig_o     __________________/   \_____...
--   
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity f_edge_detect is
   generic( g_clk_rise : string := "TRUE"
	        );
   port(
        clk_i : in std_logic;  
        sig_i : in std_logic;  
        sig_o : out std_logic  
        );
end f_edge_detect;

architecture rtl of f_edge_detect is

signal s_int : std_logic;

begin
G1 : if (g_clk_rise = "TRUE") generate
     begin
        process(clk_i)
        begin
           if rising_edge(clk_i) then
		  	     s_int <= sig_i;
			     if s_int = '1' and sig_i = '0' then
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
			     if s_int = '1' and sig_i = '0' then
				     sig_o <= '1';
			     else
				     sig_o <= '0';
			     end if;
		     end if;
        end process; 
end generate G2;

end rtl;