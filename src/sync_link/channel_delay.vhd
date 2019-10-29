----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2019/07/28 16:53:18
-- Design Name: 
-- Module Name: channel_delay - Behavioral
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

entity channel_delay is
    generic(
    --inv_o_2 : std_logic_vector(47 downto 0) := x"D516525F5689";
    inv_i_1 : std_logic_vector(47 downto 0) := x"9F57EBBE7AAF";
    inv_i_2 : std_logic_vector(47 downto 0) := x"9F35ADAB1A80"
    );
    Port ( 
    clk_i : in STD_LOGIC;
    clk_200_i : in STD_LOGIC;
    ready   : out std_logic;
    data2_i : in std_logic_vector(47 downto 0);
    data3_i : in std_logic_vector(47 downto 0);
    data2_o : out std_logic_vector(47 downto 0);
    data3_o : out std_logic_vector(47 downto 0);
    ch_i    : in integer range 0 to 47;
    ld_i    : in std_logic_vector(1 downto 0);
    tap_cnt_i : in std_logic_vector(6 downto 0)
    );
end channel_delay;

architecture Behavioral of channel_delay is

    signal ld_2,ld_3 : std_logic_vector(47 downto 0);
    signal data2_d,data3_d : std_logic_vector(47 downto 0);

begin
i_delay_ctrl: IDELAYCTRL
        port map(
        REFCLK => clk_200_i,
        RDY => ready,
        RST => '0'
        );
g_delay_module: for i in 47 downto 0 generate
    i_delay1:entity work.delay_unit
        port map(
        clk_i => clk_i,
        data_i => data2_i(i),
        data_o => data2_d(i),
        tap_en_i => '0',
        ld_i => ld_2(i),
        tap_cnt_o => open,--tap_cnt_o1(i),
        tap_cnt_i => tap_cnt_i--tap_cnt_i1(i)
        );
    ld_2(i) <= ld_i(0) when ch_i = i else '0';
    data2_o(i) <= data2_d(i) when inv_i_1(i) = '0' else not data2_d(i);
    i_delay2:entity work.delay_unit
        port map(
        clk_i => clk_i,
        data_i => data3_i(i),
        data_o => data3_d(i),
        tap_en_i => '0',
        ld_i => ld_3(i),
        tap_cnt_o => open,--tap_cnt_o2(i),
        tap_cnt_i => tap_cnt_i--tap_cnt_i2(i)
        );
    ld_3(i) <= ld_i(1) when ch_i = i else '0';
    data3_o(i) <= data3_d(i) when inv_i_2(i) = '0' else not data3_d(i);
end generate;

end Behavioral;
