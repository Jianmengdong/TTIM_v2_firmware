----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2019/06/11 17:46:44
-- Design Name: 
-- Module Name: trigger_gen - Behavioral
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
library work;
use work.TTIM_v2_pack.all;

entity trigger_gen is
    generic(
    g_number_of_GCU : integer := 24
    );
    Port ( 
    clk_i : in STD_LOGIC;
    reset_i : in std_logic;
    reset_event_cnt_i : in std_logic;
    --=========================================--
    en_trig_i : in STD_LOGIC_vector(4 downto 0);
    -- => en_trig_i(4): enable trigger from CTU
    -- => en_trig_i(3): enable TT trigger
    -- => en_trig_i(2): enable VETO trigger
    -- => en_trig_i(1): enable periodic trigger
    -- => en_trig_i(0): enable physics trigger
    --=========================================--
    ext_trig_i : in std_logic_vector(1 downto 0);
    -- => ext_trig_i(2): calibration trigger
    -- => ext_trig_i(1): TT trigger
    -- => ext_trig_i(0): VETO trigger
    --=========================================--
    trig_i : in std_logic_vector(15 downto 0);
    l1a_o : out std_logic;
    global_time_i : in std_logic_vector(47 downto 0);
    period_i : in std_logic_vector(31 downto 0); --x03B9 ACA0 => 1Hz  x0000F424 => 1KHz
    threshold_i : in std_logic_vector(7 downto 0);
    hit_i : in t_array2(47 downto 0);
    nhit_o : out std_logic_vector(7 downto 0);
    rst_event : out std_logic
    --trig_info_o : out std_logic_vector(127 downto 0)
    );
end trigger_gen;

architecture Behavioral of trigger_gen is

    signal trig_per,trig_per_i,trig_phy,trig_phy_i,accept,load_i,trig_ctu : std_logic;
    signal nhit,nhit_th : unsigned(7 downto 0);
    signal trig_th : std_logic_vector(7 downto 0);
    signal hit_ch,hit_i_r,hit_i_r2,hit_ch_i : t_uarray8(47 downto 0);
    signal hit_ch_u : t_array8(47 downto 0);
    signal hit_0 : t_uarray8(5 downto 0);
    signal trig_time : std_logic_vector(47 downto 0);
    signal trig_cnt,downcnt_u : unsigned(31 downto 0);
    signal trig_info,trig_info_i : std_logic_vector(127 downto 0);
    signal ext_trig_r,ext_trig : std_logic_vector(1 downto 0);
    signal downcnt : std_logic_vector(31 downto 0);
    signal r_en_trig_i,dead_time : std_logic;
    signal dead_cnt : unsigned(3 downto 0);
    signal st : unsigned(1 downto 0);

begin
l1a_o <= accept when dead_time = '0' else '0';
rst_event <= trig_cnt(8);
process(clk_i)
begin
    if rising_edge(clk_i) then
        ext_trig_r <= ext_trig_i;
        if en_trig_i(2) = '1' then
            if ext_trig_r(0) = '0' and ext_trig_i(0) = '1' then
                ext_trig(0) <= '1';
            else
                ext_trig(0) <= '0';
            end if;
        end if;
        if en_trig_i(3) = '1' then
            if ext_trig_r(1) = '0' and ext_trig_i(1) = '1' then
                ext_trig(1) <= '1';
            else
                ext_trig(1) <= '0';
            end if;
        end if;
    end if;
end process;
--generate trig and catch trigger time, count trigger numbers
process(clk_i)
begin
    if reset_i = '1' then
        accept <= '0';
        trig_time <= (others => '0');
        trig_cnt <= (others => '0');
    elsif rising_edge(clk_i) then
        accept <= trig_ctu or ext_trig(1) or ext_trig(0) or trig_per or trig_phy;
        if accept = '1' then
            trig_time <= global_time_i;
            if reset_event_cnt_i = '1' then
                trig_cnt <= (others => '0');
            else
                trig_cnt <= trig_cnt + 1;
            end if;
        end if;
    end if;
end process;
process(clk_i)
begin
    if reset_i = '1' then
        dead_time <= '0';
        dead_cnt <= (others => '0');
    elsif rising_edge(clk_i) then
        case st is 
            when "00" =>
                if accept = '1' then
                    st <= "01";
                    dead_time <= '1';  --2019/6/28: changed to avoid 2 clk width trig_o
                    dead_cnt <= (others => '0');
                end if;
            when "01" =>
                dead_cnt <= dead_cnt + 1;
                if dead_cnt = 10 then
                    dead_time <= '0'; --2019/6/28: changed to avoid 2 clk width trig_o
                    st <= "00";
                end if;
            when others =>
                st <= "00";
        end case;
    end if;
end process;
---- trigger enable----------
trig_ctu <= trig_i(15) when en_trig_i(4) = '1' else '0';
trig_per <= trig_per_i when en_trig_i(1) = '1' else '0';
trig_phy <= trig_phy_i when en_trig_i(0) = '1' else '0';
---- resize the hit from GCU
g_resize: for i in 47 downto 0 generate
    hit_ch_u(i) <= "000000" & hit_i(i);
    hit_ch_i(i) <= unsigned(hit_ch_u(i));
end generate;

-- process(clk_i)
-- begin
    -- if rising_edge(clk_i) then
        -- hit_i_r <= hit_ch_i;
        -- hit_i_r2 <= hit_i_r;
    -- end if;
-- end process;
-- g_trig_window:for i in 47 downto 0 generate
    -- hit_ch(i) <= hit_ch_i(i) + hit_i_r(i) + hit_i_r2(i);
-- end generate;
hit_ch <= hit_ch_i;
---- trig_phy generate. if nhit >= threshold, generate an accept signal
nhit_th <= unsigned(threshold_i);
p_trig_phy: process(clk_i)
begin
    if reset_i = '1' then
        hit_0 <= (others => (others => '0'));
        nhit <= (others => '0');
    elsif rising_edge(clk_i) then
        hit_0(0) <= hit_ch(0) + hit_ch(1) + hit_ch(2) + hit_ch(3) + hit_ch(4) + hit_ch(5) + hit_ch(6) + hit_ch(7);
        hit_0(1) <= hit_ch(8) + hit_ch(9) + hit_ch(10) + hit_ch(11) + hit_ch(12) + hit_ch(13) + hit_ch(14) + hit_ch(15);
        hit_0(2) <= hit_ch(16) + hit_ch(17) + hit_ch(18) + hit_ch(19) + hit_ch(20) + hit_ch(21) + hit_ch(22) + hit_ch(23);
        hit_0(3) <= hit_ch(24) + hit_ch(25) + hit_ch(26) + hit_ch(27) + hit_ch(28) + hit_ch(29) + hit_ch(30) + hit_ch(31);
        hit_0(4) <= hit_ch(32) + hit_ch(33) + hit_ch(34) + hit_ch(35) + hit_ch(36) + hit_ch(37) + hit_ch(38) + hit_ch(39);
        hit_0(5) <= hit_ch(40) + hit_ch(41) + hit_ch(42) + hit_ch(43) + hit_ch(44) + hit_ch(45) + hit_ch(46) + hit_ch(47);
        nhit <= hit_0(0) + hit_0(1) + hit_0(2) + hit_0(3) + hit_0(4) + hit_0(5);
        if nhit < nhit_th then
            trig_phy_i <= '0';
        else
            trig_phy_i <= '1';
            trig_th <= std_logic_vector(nhit_th);
        end if;
    end if;
end process;
nhit_o <= std_logic_vector(nhit);
---- trig_per generate. Accept signal is generated periodicly. The period is set by period_i.

p_trig_per:process(clk_i)
variable cnt : unsigned(31 downto 0);
begin
    if reset_i = '1' then
        trig_per_i <= '0';
        cnt := (others => '0');
    elsif rising_edge(clk_i) then
        if cnt <= unsigned(period_i) then
            trig_per_i <= '0';
            cnt := cnt + 1;
        else
            trig_per_i <= '1';
            cnt := (others => '0');
        end if;
    end if;
end process;

---- trigger information assembling
--      trig_en(5b) trig souce(5b) trig_cnt(32b) trig_time(48b) threshold(6b) nhit(6b)
-- trig_info <= "00000" & en_trig_i & "00000" & ext_trig & trig_per & trig_phy & std_logic_vector(nhit) & trig_th &
             -- std_logic_vector(trig_cnt) &
             -- x"0000" & trig_time(47 downto 32) &
             -- trig_time(31 downto 0);-- & 
             -- --x"0000" & hit_mask_i(47 downto 32) &
             -- --hit_mask_i(31 downto 0);
-- p_trig_info:process(clk_i)
-- begin
    -- if reset_i = '1' then
        -- trig_info_i <= (others => '0');
    -- elsif rising_edge(clk_i) then
        -- trig_info_i <= trig_info;
    -- end if;
-- end process;
-- trig_info_o <= trig_info_i;

end Behavioral;
