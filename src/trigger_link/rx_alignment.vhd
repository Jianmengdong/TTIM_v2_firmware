----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2019/08/09 15:52:53
-- Design Name: 
-- Module Name: rx_alignment - Behavioral
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

entity rx_alignment is
    generic(
    NUMBER_TO_ALIGN : integer range 0 to 100 := 10;
    LOSS_ALIGN : integer range 0 to 100 := 20
    );
    Port ( 
    clk_i : in STD_LOGIC;
    reset_i : in std_logic;
    slide_o : out std_logic;
    rx_data_i : in std_logic_vector(15 downto 0);
    aligned_o : out std_logic;
    re_align_i : in std_logic;
    debug_fsm : out std_logic_vector(3 downto 0)
    );
end rx_alignment;

architecture Behavioral of rx_alignment is
    signal align_cnt,loss_cnt : integer range 0 to 100 := 0;
    signal state : std_logic_vector(3 downto 0);
    signal wait_cnt: integer range 0 to 31 := 0;
    signal comma : std_logic_vector(7 downto 0);
begin
comma <= rx_data_i(7 downto 0);
process(clk_i)
begin
    if reset_i = '1' then
        state <= x"0";
        slide_o <= '0';
        aligned_o <= '0';
        align_cnt <= 0;
        wait_cnt <= 0;
        loss_cnt <= 0;
    elsif rising_edge(clk_i) then
        case state is 
            when x"0" =>
                slide_o <= '0';
                aligned_o <= '0';
                align_cnt <= 0;
                wait_cnt <= 0;
                loss_cnt <= 0;
                if comma = x"BC" then
                    state <= x"1";
                else
                    state <= x"2";
                    slide_o <= '1';
                end if;
            when x"1" => 
                if comma = x"BC" then
                    if align_cnt = NUMBER_TO_ALIGN then
                        state <= x"3";
                        loss_cnt <= 0;
                        align_cnt <= 0;
                    else
                        align_cnt <= align_cnt + 1;
                    end if;
                else
                    state <= x"0";
                end if;
            when x"2" =>
                slide_o <= '0';
                if wait_cnt = 31 then
                    state <= x"0";
                else
                    wait_cnt <= wait_cnt + 1;
                end if;
            when x"3" =>
                if re_align_i = '1' or loss_cnt = LOSS_ALIGN then
                    state <= x"0";
                elsif comma = x"BC" then
                    aligned_o <= '1';
                else
                    loss_cnt <= loss_cnt + 1;
                end if;
            when others =>
                state <= x"0";
        end case;
    end if;
end process;
debug_fsm <= state;
end Behavioral;
