----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2019/04/16 17:33:15
-- Design Name: 
-- Module Name: brd_cmd_generator - Behavioral
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
use work.TTIM_v2_pack.all;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity brd_cmd_generator is
    Port ( 
    clk_i : in STD_LOGIC;
    rst_i : in std_logic;
    period : in std_logic;
    rst_event : in std_logic;
    chb_busy_i : in std_logic;
    chb_req_o : out std_logic;
    chb_grant_i : in std_logic;
    brd_cmd_vector : out t_brd_command
    );
end brd_cmd_generator;

architecture Behavioral of brd_cmd_generator is

    signal  period_r,idle : std_logic;
    signal  st : std_logic_vector(2 downto 0);
    signal  rst_event_r,rst_event_a,rst_event_i : std_logic;

begin
Inst_rise_edge: entity work.r_edge_detect
    generic map(
      g_clk_rise => "TRUE"
      )
    port map(
      clk_i => clk_i,
      sig_i => period,
      sig_o => period_r
    );
process(clk_i)
begin
    if rising_edge(clk_i) then
        rst_event_r <= rst_event;
    end if;
end process;
rst_event_a <= rst_event xor rst_event_r;
process(clk_i)
begin
    if rst_i = '1' then
        st <= "000";
        idle <= '0';
        chb_req_o <= '0';
    elsif rising_edge(clk_i) then
        case st is 
        when "000" => 
            chb_req_o <= '0';
            idle <= '0';
            rst_event_i <= '0';
            if rst_event_a = '1' and chb_busy_i = '0' then
                chb_req_o <= '1';
                st <= "001";
            elsif rst_event_a = '1' and chb_busy_i = '1' then
                st <= "010";
            elsif period_r = '1' and chb_busy_i = '0' then
                chb_req_o <= '1';
                st <= "011";
            end if;
        when "001" => 
            if chb_grant_i = '1' then
                idle <= '0';
                rst_event_i <= '1';
                chb_req_o <= '0';
                st <= "111";
            end if;
        when "010" => 
            if chb_busy_i = '0' then
                chb_req_o <= '1';
                st <= "001";
            end if;
        when "011" => 
            if chb_grant_i = '1' then
                if rst_event_a = '1' then
                    idle <= '0';
                    rst_event_i <= '1';
                    chb_req_o <= '0';
                    st <= "111";
                else
                    idle <= '1';
                    rst_event_i <= '0';
                    chb_req_o <= '0';
                    st <= "111";
                end if;
            end if;
        when "111" => 
            idle <= '0';
            rst_event_i <= '0';
            if rst_event_a = '1' then
                st <= "010";
            else
                st <= "000";
            end if;
        when others =>
            st <= "000";
        end case;
    end if;
end process;
brd_cmd_vector.idle           <= idle;
brd_cmd_vector.rst_time       <= '0';
brd_cmd_vector.rst_event      <= rst_event_i;
brd_cmd_vector.rst_time_event <= '0';
brd_cmd_vector.supernova      <= '0';
brd_cmd_vector.test_pulse     <= '0';
brd_cmd_vector.time_request   <= '0';
brd_cmd_vector.rst_errors     <= '0';
brd_cmd_vector.autotrigger    <= '0';
brd_cmd_vector.en_acquisition <= '0';
end Behavioral;
