----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2019/04/01 13:09:19
-- Design Name: 
-- Module Name: descrambler - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity descrambler is
  Port ( 
    clk_i : in std_logic;
    reset_i : in std_logic;
    D : in std_logic;
    Q : out std_logic
  );
end descrambler;

architecture Behavioral of descrambler is

    signal LSR : std_logic_vector(6 downto 0);

begin
process(clk_i)
begin
    if reset_i = '1' then
        LSR <= (others => '0');
        Q <= '1';
    elsif rising_edge(clk_i) then
        LSR(6 downto 1) <= LSR(5 downto 0);
        LSR(0) <= D;
        Q <= D xor LSR(2) xor LSR(6);
    end if;
end process;
end Behavioral;
