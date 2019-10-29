----------------------------------------------------------------------------------
------------------------------------PISO Register---------------------------------
----------------------------------------------------------------------------------
-- Left shift register. PISO architecture. Load pin. Reset pin. Shift pin.
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity piso is
   generic(g_width : integer := 8;
	        g_clk_rise  : string  := "TRUE"
	        );
   port(
        clk_i   : in std_logic;  
		  reset_i : in std_logic; 
		  load_i  : in std_logic; 
		  shift_i : in std_logic; 
        p_i     : in std_logic_vector(g_width -1 downto 0);  
        s_o     : out std_logic  
        );
end piso;
architecture rtl of piso is

signal s_int : std_logic_vector(g_width -1 downto 0);

begin

-------------------rise edge process------------------
G1 : if (g_clk_rise = "TRUE") generate
     begin
	     process(clk_i,reset_i)
        begin
		     if reset_i = '1' then
			     s_int <= (others => '1');
	        elsif rising_edge(clk_i) then
			     if load_i = '1' then
				     s_int <= p_i;
				  elsif shift_i = '1' then
				     s_int <= s_int(g_width -2 downto 0) & '1';
			     end if;
	        end if;
        end process;
end generate G1;

-------------------fall edge process------------------
G2 : if (g_clk_rise = "FALSE") generate
     begin
	     process(clk_i,reset_i)
        begin
		     if reset_i = '1' then
			     s_int <= (others => '1');
	        elsif falling_edge(clk_i) then
			     if load_i = '1' then
				     s_int <= p_i;
				  elsif shift_i = '1' then
				     s_int <= s_int(g_width -1 downto 1) & '1';
			     end if;
	        end if;
        end process;
end generate G2;
s_o <= s_int(g_width -1);
end rtl;