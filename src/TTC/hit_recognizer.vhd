----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2019/04/16 10:48:55
-- Design Name: 
-- Module Name: hit_recognizer - Behavioral
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

entity hit_recognizer is
    generic(
    ALIGN_MIN : integer := 6
    );
    Port ( hit_from_gcu : in STD_LOGIC;
           clk_i : in STD_LOGIC;
           clk_x2_i : in std_logic;
           rst_i : in std_logic;
           --aligned_o : out std_logic;
           hit_o : out std_logic_vector(1 downto 0)
           );
end hit_recognizer;

architecture Behavioral of hit_recognizer is

    signal hit_s : std_logic;
    signal hit_i,hit_r,hit : std_logic_vector(1 downto 0);
    signal align,slide : std_logic;
    signal st : std_logic_vector(1 downto 0);
    signal align_cnt : integer range 0 to 15;

begin
Inst_descrambler:entity work.descrambler
    port map(
    clk_i => clk_x2_i,
    reset_i => rst_i,
    D => hit_from_gcu,
    Q => hit_s
    );
    
de_serialize:process(clk_x2_i)
begin
    if rst_i = '1' then
        hit_i <= "00";
    elsif rising_edge(clk_x2_i) then
        hit_i(0) <= hit_s;
        hit_i(1) <= hit_i(0);
    end if;
end process;
cross_time_domain:process(clk_i)
begin
    if rst_i = '1' then
        hit_r <= "00";
    elsif rising_edge(clk_i) then
        hit_r <= hit_i;
        --hit <= hit_r when slide = '0' else (hit_r(0) & hit_i(1));
    end if;
end process;
hit_o <= hit_r;

-- alignHit:process(clk_i)
-- begin
    -- if rst_i = '1' then
        -- align_cnt <= 0;
        -- align <= '0';
        -- slide <= '0';
        -- st <= "00";
    -- elsif rising_edge(clk_i) then
        -- case st is 
            -- when "00" => 
                -- align_cnt <= 0;
                -- align <= '0';
                -- if hit = "01" then
                    -- st <= "01";
                    -- slide <= '0';
                -- elsif hit = "10" then
                    -- st <= "01";
                    -- slide <= '1';
                -- end if;
            -- when "01" =>
                -- if hit = "01" then
                    -- if align_cnt >= ALIGN_MIN then
                        -- align <= '1';
                        -- st <= "10";
                    -- else
                        -- align_cnt <= align_cnt + 1;
                    -- end if;
                -- else
                    -- st <= "00";
                -- end if;
            -- when "10" => 
                -- if rst_i = '1' then
                    -- st <= "00";
                -- end if;
            -- when others => 
                -- st <= "00";
        -- end case;
    -- end if;
-- end process;

end Behavioral;
