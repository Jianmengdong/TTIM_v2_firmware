----------------------------------------------------------------------------------
-- Institute: Tsinghua University
-- Engineer: Jianmeng Dong
-- 
-- Create Date: 2019/07/28 16:01:30
-- Design Name: TTIM_v2
-- Module Name: channel_map - Behavioral
-- Project Name: TTIM_v2
-- Description: SYNC link channel mapping of TTIM_v2

-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity channel_map is
    generic(
    inv_o_2 : std_logic_vector(47 downto 0) := x"D516525F5689"
    -- inv_i_1 : std_logic_vector(47 downto 0) := x"9F57EBBE7AAF";
    -- inv_i_2 : std_logic_vector(47 downto 0) := x"9F35ADAB1A80"
    );
    Port ( 
    -- clock out, pair 1/2, color orange
    BEC2GCU_1_P : out std_logic_vector(47 downto 0);
    BEC2GCU_1_N : out std_logic_vector(47 downto 0);
    clko_i      : in std_logic_vector(47 downto 0);
    -- tx2 data, pair 4/5, color blue
    BEC2GCU_2_P : out std_logic_vector(47 downto 0);
    BEC2GCU_2_N : out std_logic_vector(47 downto 0);
    datao_i     : in std_logic_vector(47 downto 0);
    -- rx1 data, pair 3/6, color green
    GCU2BEC_1_P : in std_logic_vector(47 downto 0);
    GCU2BEC_1_N : in std_logic_vector(47 downto 0);
    data1i_o    : out std_logic_vector(47 downto 0);
    -- rx2 data, pair 7/8, color brown
    GCU2BEC_2_P : in std_logic_vector(47 downto 0);
    GCU2BEC_2_N : in std_logic_vector(47 downto 0);
    data2i_o    : out std_logic_vector(47 downto 0);
    -- control ports
    --inv_o_1     : in std_logic_vector(47 downto 0); --invert BEC2GCU_1, make no sense when BEC2GCU_1 is clk
    --tx1_sel     : in std_logic_vector(47 downto 0); --select BEC2GCU_1 source, default clock
    tx2_en      : in std_logic_vector(47 downto 0) --enbale BEC2GCU_2 output, default enabled
    );
end channel_map;

architecture Behavioral of channel_map is

    signal bec2gcu_1_i,bec2gcu_1_r : std_logic_vector(47 downto 0);
    signal bec2gcu_2_i,bec2gcu_2_r : std_logic_vector(47 downto 0);
    signal gcu2bec_1_i,gcu2bec_2_i : std_logic_vector(47 downto 0);

begin
g_sync_link: for i in 47 downto 0 generate
    i_bec2gcu1: OBUFDS
        generic map(
        SLEW => "SLOW"
        )
        port map(
        I => clko_i(i),
        O => BEC2GCU_1_P(i),
        OB => BEC2GCU_1_N(i)
        );
    --bec2gcu_1_r(i) <= datao_i(i) when inv_o_1(i) = '0' else not datao_i(i);
    --bec2gcu_1_i(i) <= clko_i when tx1_sel(i) = '0' else bec2gcu_1_r(i);
    i_bec2gcu2: OBUFDS
        generic map(
        SLEW => "SLOW"
        )
        port map(
        I => bec2gcu_2_i(i),
        O => BEC2GCU_2_P(i),
        OB => BEC2GCU_2_N(i)
        );
    bec2gcu_2_i(i) <= bec2gcu_2_r(i) when tx2_en(i) = '0' else '0';
    bec2gcu_2_r(i) <= datao_i(i) when inv_o_2(i) = '0' else not datao_i(i);
    i_gcu2bec1: IBUFDS
        port map(
        I => GCU2BEC_1_P(i),
        IB => GCU2BEC_1_N(i),
        O => gcu2bec_1_i(i)
        );
    data1i_o(i) <= gcu2bec_1_i(i);-- when inv_i_1(i) = '0' else not gcu2bec_1_i(i);
    i_gcu2bec2: IBUFDS
        port map(
        I => GCU2BEC_2_P(i),
        IB => GCU2BEC_2_N(i),
        O => gcu2bec_2_i(i)
        );
    data2i_o(i) <= gcu2bec_2_i(i);-- when inv_i_2(i) = '0' else not gcu2bec_2_i(i);
end generate;
end Behavioral;
