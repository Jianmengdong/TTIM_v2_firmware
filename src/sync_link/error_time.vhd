----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2018/11/28 13:42:58
-- Design Name: 
-- Module Name: error_time - Behavioral
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

entity error_time is
 Port ( 
    clk_i : in std_logic;
    rst_i : in std_logic;
    local_time_i : in std_logic_vector(47 downto 0);
    error_i : in std_logic;
    err_time_o : out std_logic_vector(47 downto 0)
 );
end error_time;

architecture Behavioral of error_time is

signal st : std_logic;

begin

process(clk_i)
begin
    if rst_i = '1' then
        err_time_o <= (others => '0');
        st <= '0';
    elsif rising_edge(clk_i) then
        case st is
            when '0' =>
                if error_i = '1' then
                    err_time_o <= local_time_i;
                    st <= '1';
                end if;
            when '1' => 
                null;
            when others =>
                st <= '0';
        end case;
    end if;
end process;

end Behavioral;
