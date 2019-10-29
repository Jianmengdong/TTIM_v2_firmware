
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity clk_time is
    Port ( 
    SYS_CLK_P : in STD_LOGIC;
    SYS_CLK_N : in STD_LOGIC;
    clk_o : out std_logic;
    clk_x2_o : out std_logic;
    clk_200 : out std_logic;
    locked_o : out std_logic;
    pps_i : in std_logic;
    timestamp_o : out std_logic_vector(47 downto 0)
    );
end clk_time;

architecture Behavioral of clk_time is
signal  time_count : signed(47 downto 0);
signal clk_x2_i,locked: std_logic;
signal clk_i,clk_inv,pps_r,pps_r1,pps_b : std_logic;
begin
Inst_clk_gen:entity work.clk_wiz_0
   port map ( 
   clk_out1 => clk_i,
   clk_out2 => clk_x2_i,
   clk_out3 => clk_200,                
   clk_out4 => clk_inv,                
   locked => locked,
   clk_in1_p => SYS_CLK_P,
   clk_in1_n => SYS_CLK_N
 );
locked_o <= locked;
clk_x2_o <= clk_x2_i;
-- sample pps with 125M clock
process(clk_x2_i)
begin
    if rising_edge(clk_x2_i) then
        pps_b <= pps_i;
    end if;
end process;
-- find pps rising edge with 62.5M clock
process(clk_i)
begin
if rising_edge(clk_i) then
    pps_r1 <= pps_i;
    if pps_i = '1' and pps_r1 = '0' then
        pps_r <= pps_b;
    end if;
end if;
end process;
-- choose 62.5M clock with pps rising edge
clk_o <= clk_i when pps_r = '1' else clk_inv;
-- local time counter
p_time_counter : process(clk_x2_i)
begin
   if rising_edge(clk_x2_i) then
      if locked = '0' then
         time_count <= (others => '0');
      else
         time_count <= time_count + 1;
      end if;
   end if;
end process p_time_counter;
timestamp_o <= std_logic_vector(time_count);
end Behavioral;
