----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2019/07/28 17:23:14
-- Design Name: 
-- Module Name: prbs_check - Behavioral
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
use work.TTIM_v2_pack.all;

entity prbs_check is
    Port ( 
    clk_i : in STD_LOGIC;
    reset_i : in std_logic;
    en_i : in std_logic_vector(47 downto 0);
    global_time_i   : in std_logic_vector(47 downto 0);
    prbs_i1 : in std_logic_vector(47 downto 0);
    prbs_i2 : in std_logic_vector(47 downto 0);
    prbs_err1_o : out std_logic_vector(47 downto 0);
    prbs_err2_o : out std_logic_vector(47 downto 0);
    err_cnt_1_o : out t_uarray32(47 downto 0);
    err_cnt_2_o : out t_uarray32(47 downto 0);
    error_time1 : out t_array48(47 downto 0);
    error_time2 : out t_array48(47 downto 0)
    );
end prbs_check;

architecture Behavioral of prbs_check is

signal prbs_err1,prbs_err2 : std_logic_vector(47 downto 0);
signal prbs_i1_r,prbs_i1_r2,prbs_i2_r,prbs_i2_r2 : std_logic_vector(47 downto 0);
signal err_cnt_1,err_cnt_2 : t_uarray32(47 downto 0);

begin
process(clk_i)
begin
    if rising_edge(clk_i) then
        prbs_i1_r <= prbs_i1;
        prbs_i1_r2 <= prbs_i1_r;
        prbs_i2_r <= prbs_i2;
        prbs_i2_r2 <= prbs_i2_r;
    end if;
end process;
g_pbrs_chk: for i in 47 downto 0 generate
    i_prbs_chk1:entity work.PRBS_ANY
        generic map(
        CHK_MODE => TRUE,
        INV_PATTERN => FALSE,
        POLY_LENGHT => 7,
        POLY_TAP => 3,
        NBITS => 1
        )
        port map(
        RST => '0',
        CLK => clk_i,
        DATA_IN(0) => prbs_i1_r2(i),
        EN => en_i(i),
        DATA_OUT(0) => prbs_err1(i)
        );
    p_err_cnt1:process(clk_i)
    begin
        if reset_i = '1' or en_i(i) = '0' then
            err_cnt_1(i) <= (others => '0');
        elsif rising_edge(clk_i) then
            if prbs_err1(i) = '1' then
                err_cnt_1(i) <= err_cnt_1(i) + 1;
            end if;
        end if;
    end process;
    IerrorTime1:entity work.error_time
    port map(
    clk_i => clk_i,
    rst_i => reset_i or (not en_i(i)),
    local_time_i => global_time_i,
    error_i => prbs_err1(i),
    err_time_o => error_time1(i)
    );
    i_prbs_chk2:entity work.PRBS_ANY
        generic map(
        CHK_MODE => TRUE,
        INV_PATTERN => FALSE,
        POLY_LENGHT => 7,
        POLY_TAP => 3,
        NBITS => 1
        )
        port map(
        RST => '0',
        CLK => clk_i,
        DATA_IN(0) => prbs_i2_r2(i),
        EN => en_i(i),
        DATA_OUT(0) => prbs_err2(i)
        );
    p_err_cnt2:process(clk_i)
    begin
        if reset_i = '1'  or en_i(i) = '0' then
            err_cnt_2(i) <= (others => '0');
        elsif rising_edge(clk_i) then
            if prbs_err2(i) = '1' then
                err_cnt_2(i) <= err_cnt_2(i) + 1;
            end if;
        end if;
    end process;
    IerrorTime2:entity work.error_time
    port map(
    clk_i => clk_i,
    rst_i => reset_i or (not en_i(i)),
    local_time_i => global_time_i,
    error_i => prbs_err2(i),
    err_time_o => error_time2(i)
    );
end generate;
prbs_err1_o <= prbs_err1;
prbs_err2_o <= prbs_err2;
err_cnt_1_o <= err_cnt_1;
err_cnt_2_o <= err_cnt_2;
end Behavioral;
