library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity scrambler is
  Port ( 
    clk_i : in std_logic;
    RESET : in std_logic;
    D : in std_logic;
    Q : out std_logic
  );
end scrambler;

architecture Behavioral of scrambler is

    signal LSR : std_logic_vector(6 downto 0);

begin
process(clk_i)
begin
    if RESET = '1' then
        LSR <= "1011011";
        Q <= '1';
    elsif rising_edge(clk_i) then
        LSR(6 downto 1) <= LSR(5 downto 0);
        LSR(0) <= D xor LSR(2) xor LSR(6);
        Q <= D xor LSR(2) xor LSR(6);
    end if;
end process;

end Behavioral;