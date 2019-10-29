library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity countdown is
   generic(g_width : integer := 8;
	        g_clk_rise  : string  := "TRUE"
	        );
   port(
        clk_i    : in std_logic;  
		  reset_i  : in std_logic; 
		  load_i   : in std_logic; 
		  enable_i : in std_logic; 
        p_i      : in std_logic_vector(g_width -1 downto 0);  
        p_o      : out std_logic_vector(g_width -1 downto 0)   
        );
end countdown;
architecture rtl of countdown is

signal s_int : unsigned(g_width -1 downto 0);

begin

-------------------rise edge process------------------
G1 : if (g_clk_rise = "TRUE") generate
     begin
	     process(clk_i,reset_i)
        begin
		     if reset_i = '1' then
			     s_int <= (others => '0');
	        elsif rising_edge(clk_i) then
			     if load_i = '1' then
				     s_int <= unsigned(p_i);
				  elsif enable_i = '1' then
				     s_int <= s_int -1;
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
			     s_int <= (others => '0');
	        elsif falling_edge(clk_i) then
			     if load_i = '1' then
				     s_int <= unsigned(p_i);
				  elsif enable_i = '1' then
				     s_int <= s_int -1;
			     end if;
	        end if;
        end process;
end generate G2;
p_o <= std_logic_vector(s_int);
end rtl;