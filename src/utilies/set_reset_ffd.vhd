library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity set_reset_ffd is
   generic( g_clk_rise : string := "TRUE"
	        );
   port(
        clk_i   : in std_logic;  
  		  set_i   : in std_logic;
		  reset_i : in std_logic;
        q_o     : out std_logic  
        );
end set_reset_ffd;

architecture rtl of set_reset_ffd is

begin
G1 : if (g_clk_rise = "TRUE") generate
     begin
        process(clk_i)
        begin
           if rising_edge(clk_i) then
		  	     if (reset_i = '1') then
				     q_o <= '0';
				  elsif (set_i = '1') then
				     q_o <= '1';
				  end if;
		     end if;
        end process; 
end generate G1;

G2 : if (g_clk_rise = "FALSE") generate
     begin
        process(clk_i)
        begin
           if falling_edge(clk_i) then
		  	    if (reset_i = '1') then
				     q_o <= '0';
				  elsif (set_i = '1') then
				     q_o <= '1';
				  end if;
		     end if;
        end process; 
end generate G2;

end rtl;