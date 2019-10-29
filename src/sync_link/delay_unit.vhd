----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2018/12/07 14:41:25
-- Design Name: 
-- Module Name: delay_unit - Behavioral
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

entity delay_unit is
    Port (
           clk_i : in STD_LOGIC;
           data_i : in STD_LOGIC;
           data_o : out STD_LOGIC;
           tap_en_i : in STD_LOGIC;
           ld_i : in STD_LOGIC;
           tap_cnt_o : out STD_LOGIC_VECTOR (6 downto 0);
           tap_cnt_i : in std_logic_vector(6 downto 0)
           );
end delay_unit;

architecture Behavioral of delay_unit is
    signal tap1,tap2,tap3,tap4,tap_count1,tap_count2,tap_count3,tap_count4 : std_logic_vector(4 downto 0);
    signal tap_cnt,tap2_r,tap3_r,tap4_r : std_logic_vector(6 downto 0);
    signal tap_en1,tap_en2,data_d,data_d2,data_d3,tap_load_i,tap_en: std_logic;
begin
load_r_detect: entity work.r_edge_detect
	generic map(
		 g_clk_rise  => "TRUE"
		 )
	port map(
		 clk_i => clk_i,
		 sig_i => ld_i,
		 sig_o => tap_load_i
		 );
tap_r_detect: entity work.r_edge_detect
	generic map(
		 g_clk_rise  => "TRUE"
		 )
	port map(
		 clk_i => clk_i,   
		 sig_i => tap_en_i,
		 sig_o => tap_en
		 );
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if unsigned(tap_cnt_i) <= 31 then
                tap1 <= tap_cnt_i(4 downto 0);
                tap2 <= (others => '0');
                --tap3 <= (others => '0');
                --tap4 <= (others => '0');
            elsif unsigned(tap_cnt_i) <= 62 then
                tap1 <= "11111";
                tap2_r <= std_logic_vector(unsigned(tap_cnt_i) - 31);
                tap2 <= tap2_r(4 downto 0);
                --tap3 <= (others => '0');
                --tap4 <= (others => '0');
            -- elsif unsigned(tap_cnt_i) <= 93 then
                -- tap1 <= "11111";
                -- tap2 <= "11111";
                -- tap3_r <= std_logic_vector(unsigned(tap_cnt_i) - 62);
                -- tap3 <= tap3_r(4 downto 0);
                --tap4 <= (others => '0');
            -- else
                -- tap1 <= "11111";
                -- tap2 <= "11111";
                -- tap3 <= "11111";
                -- tap4_r <= std_logic_vector(unsigned(tap_cnt_i) - 93);
                -- tap4 <= tap4_r(4 downto 0);
            end if;
        end if;
    end process;
    tap_cnt_o <= tap_cnt;
    tap_cnt <= std_logic_vector(unsigned("00"&tap_count1) + unsigned("00"&tap_count2));-- + unsigned("00"&tap_count3)); --+ unsigned("00"&tap_count4));
    
IDELAYE2_1 : IDELAYE2
    generic map (
      CINVCTRL_SEL => "FALSE",          -- Enable dynamic clock inversion (FALSE, TRUE)
      DELAY_SRC => "IDATAIN",            -- Delay input (IDATAIN, DATAIN)
      HIGH_PERFORMANCE_MODE => "TRUE",  -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
      IDELAY_TYPE => "VAR_LOAD",        -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
      IDELAY_VALUE => 0,                -- Input delay tap setting (0-31)
      PIPE_SEL => "FALSE",              -- Select pipelined mode, FALSE, TRUE
      REFCLK_FREQUENCY => 200.0,        -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
      SIGNAL_PATTERN => "DATA"          -- DATA, CLOCK input signal
    )
    port map (
      CNTVALUEOUT => tap_count1,         -- 5-bit output: Counter value output
      DATAOUT     => data_d,       -- 1-bit output: Delayed data output
      C           => clk_i,      -- 1-bit input: Clock input
      CE          => tap_en1,          -- 1-bit input: Active high enable increment/decrement input
      CINVCTRL    => '0',                  -- 1-bit input: Dynamic clock inversion input
      CNTVALUEIN  => tap1,              -- 5-bit input: Counter value input
      DATAIN      => '0',         -- 1-bit input: Internal delay data input
      IDATAIN     => data_i,                  -- 1-bit input: Data input from the I/O
      INC         => '1',           -- 1-bit input: Increment / Decrement tap delay input
      LD          => tap_load_i,  -- 1-bit input: Load IDELAY_VALUE input
      LDPIPEEN    => '0',                  -- 1-bit input: Enable PIPELINE register to load data input
      REGRST      => '0'                   -- 1-bit input: Active-high reset tap-delay input
    );
    
IDELAYE2_2 : IDELAYE2
    generic map (
      CINVCTRL_SEL => "FALSE",          -- Enable dynamic clock inversion (FALSE, TRUE)
      DELAY_SRC => "DATAIN",            -- Delay input (IDATAIN, DATAIN)
      HIGH_PERFORMANCE_MODE => "TRUE",  -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
      IDELAY_TYPE => "VAR_LOAD",        -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
      IDELAY_VALUE => 0,                -- Input delay tap setting (0-31)
      PIPE_SEL => "FALSE",              -- Select pipelined mode, FALSE, TRUE
      REFCLK_FREQUENCY => 200.0,        -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
      SIGNAL_PATTERN => "DATA"          -- DATA, CLOCK input signal
    )
    port map (
      CNTVALUEOUT => tap_count2,         -- 5-bit output: Counter value output
      DATAOUT     => data_o,       -- 1-bit output: Delayed data output
      C           => clk_i,      -- 1-bit input: Clock input
      CE          => tap_en2,          -- 1-bit input: Active high enable increment/decrement input
      CINVCTRL    => '0',                  -- 1-bit input: Dynamic clock inversion input
      CNTVALUEIN  => tap2,              -- 5-bit input: Counter value input
      DATAIN      => data_d,         -- 1-bit input: Internal delay data input
      IDATAIN     => '0',                  -- 1-bit input: Data input from the I/O
      INC         => '1',           -- 1-bit input: Increment / Decrement tap delay input
      LD          => tap_load_i,  -- 1-bit input: Load IDELAY_VALUE input
      LDPIPEEN    => '0',                  -- 1-bit input: Enable PIPELINE register to load data input
      REGRST      => '0'                   -- 1-bit input: Active-high reset tap-delay input
    );
    
-- IDELAYE2_3 : IDELAYE2
    -- generic map (
      -- CINVCTRL_SEL => "FALSE",          -- Enable dynamic clock inversion (FALSE, TRUE)
      -- DELAY_SRC => "DATAIN",            -- Delay input (IDATAIN, DATAIN)
      -- HIGH_PERFORMANCE_MODE => "TRUE",  -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
      -- IDELAY_TYPE => "VAR_LOAD",        -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
      -- IDELAY_VALUE => 0,                -- Input delay tap setting (0-31)
      -- PIPE_SEL => "FALSE",              -- Select pipelined mode, FALSE, TRUE
      -- REFCLK_FREQUENCY => 200.0,        -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
      -- SIGNAL_PATTERN => "DATA"          -- DATA, CLOCK input signal
    -- )
    -- port map (
      -- CNTVALUEOUT => tap_count3,         -- 5-bit output: Counter value output
      -- DATAOUT     => data_o,       -- 1-bit output: Delayed data output
      -- C           => clk_i,      -- 1-bit input: Clock input
      -- CE          => tap_en2,          -- 1-bit input: Active high enable increment/decrement input
      -- CINVCTRL    => '0',                  -- 1-bit input: Dynamic clock inversion input
      -- CNTVALUEIN  => tap3,              -- 5-bit input: Counter value input
      -- DATAIN      => data_d2,         -- 1-bit input: Internal delay data input
      -- IDATAIN     => '0',                  -- 1-bit input: Data input from the I/O
      -- INC         => '1',           -- 1-bit input: Increment / Decrement tap delay input
      -- LD          => tap_load_i,  -- 1-bit input: Load IDELAY_VALUE input
      -- LDPIPEEN    => '0',                  -- 1-bit input: Enable PIPELINE register to load data input
      -- REGRST      => '0'                   -- 1-bit input: Active-high reset tap-delay input
    -- );
    
-- IDELAYE2_4 : IDELAYE2
    -- generic map (
      -- CINVCTRL_SEL => "FALSE",          -- Enable dynamic clock inversion (FALSE, TRUE)
      -- DELAY_SRC => "DATAIN",            -- Delay input (IDATAIN, DATAIN)
      -- HIGH_PERFORMANCE_MODE => "TRUE",  -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
      -- IDELAY_TYPE => "VAR_LOAD",        -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
      -- IDELAY_VALUE => 0,                -- Input delay tap setting (0-31)
      -- PIPE_SEL => "FALSE",              -- Select pipelined mode, FALSE, TRUE
      -- REFCLK_FREQUENCY => 200.0,        -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
      -- SIGNAL_PATTERN => "DATA"          -- DATA, CLOCK input signal
    -- )
    -- port map (
      -- CNTVALUEOUT => tap_count4,         -- 5-bit output: Counter value output
      -- DATAOUT     => data_o,       -- 1-bit output: Delayed data output
      -- C           => clk_i,      -- 1-bit input: Clock input
      -- CE          => tap_en2,          -- 1-bit input: Active high enable increment/decrement input
      -- CINVCTRL    => '0',                  -- 1-bit input: Dynamic clock inversion input
      -- CNTVALUEIN  => tap4,              -- 5-bit input: Counter value input
      -- DATAIN      => data_d3,         -- 1-bit input: Internal delay data input
      -- IDATAIN     => '0',                  -- 1-bit input: Data input from the I/O
      -- INC         => '1',           -- 1-bit input: Increment / Decrement tap delay input
      -- LD          => tap_load_i,  -- 1-bit input: Load IDELAY_VALUE input
      -- LDPIPEEN    => '0',                  -- 1-bit input: Enable PIPELINE register to load data input
      -- REGRST      => '0'                   -- 1-bit input: Active-high reset tap-delay input
    -- );
tap_en1 <= tap_en and (not tap_cnt(5));
tap_en2 <= tap_en and tap_cnt(5);
end Behavioral;
