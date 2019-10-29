
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity trigger_link is
    Port ( 
    clk_i : in STD_LOGIC;
    reset_i : in std_logic;
    SFP_RX_P : in std_logic;
    SFP_RX_N : in std_logic;
    SFP_TX_P : out std_logic;
    SFP_TX_N : out std_logic;
    REF_CLK_P : in std_logic;
    REF_CLK_N : in std_logic;
    trig_o : out std_logic_vector(15 downto 0);
    nhit_i : in std_logic_vector(7 downto 0);
    rx_aligned : out std_logic
    );
end trigger_link;

architecture Behavioral of trigger_link is

    signal tx_data_i,rx_data_i : std_logic_vector(15 downto 0);
    signal gtrefclk,clk_sys,gt0_rxoutclk_out,gt0_rxusrclk_in : std_logic;
    signal tx_charisk,rxcharisk_i : std_logic_vector(1 downto 0);
    signal rx_resetdone,rx_slide_i : std_logic;

begin
ibufds_instq0_clk0 : IBUFDS_GTE2  
    port map(
    O               => gtrefclk,
    ODIV2           => open,
    CEB             => '0',
    I               => REF_CLK_P,
    IB              => REF_CLK_N
    );
-- Inst_sys_clk: BUFG
    -- port map(
    -- I => gt0_txoutclk_out,
    -- O => clk_sys
    -- );
    clk_sys <= clk_i;
Inst_rx_clk: BUFG
    port map(
    I => gt0_rxoutclk_out,
    O => gt0_rxusrclk_in
    );
Inst_trig_link :entity work.gtwizard_0
    port map(
    SYSCLK_IN                       =>      clk_i,
    SOFT_RESET_TX_IN                =>      reset_i,
    SOFT_RESET_RX_IN                =>      reset_i,
    DONT_RESET_ON_DATA_ERROR_IN     =>      '1',
    GT0_TX_FSM_RESET_DONE_OUT => open,
    GT0_RX_FSM_RESET_DONE_OUT => rx_resetdone,
    GT0_DATA_VALID_IN => '1',

    --_________________________________________________________________________
    --GT0  (X0Y0)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
        gt0_cplllockdetclk_in           =>      clk_i,
        gt0_cpllreset_in                =>      '0',
    -------------------------- Channel - Clocking Ports ------------------------
        gt0_gtrefclk0_in                =>      gtrefclk,
        gt0_gtrefclk1_in                =>      '0',
    ---------------------------- Channel - DRP Ports  --------------------------
        gt0_drpaddr_in                  =>      (others => '0'),
        gt0_drpclk_in                   =>      clk_i,
        gt0_drpdi_in                    =>      (others => '0'),
        gt0_drpen_in                    =>      '0',
        gt0_drpwe_in                    =>      '0',
    --------------------- RX Initialization and Reset Ports --------------------
        gt0_eyescanreset_in             =>      '0',
        gt0_rxuserrdy_in                =>      '1',
        gt0_eyescantrigger_in           =>      '0',
        gt0_rxmonitorsel_in             => (others => '0'),
    ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        gt0_rxusrclk_in                 =>      gt0_rxusrclk_in,
        gt0_rxusrclk2_in                =>      gt0_rxusrclk_in,
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
        gt0_rxdata_out                  =>      rx_data_i,
    --------------------------- Receive Ports - RX AFE -------------------------
        gt0_gtxrxp_in                   =>      SFP_RX_P,
    ------------------------ Receive Ports - RX AFE Ports ----------------------
        gt0_gtxrxn_in                   =>      SFP_RX_N,
    --------------------- Receive Ports - RX Equalizer Ports -------------------
        gt0_rxdfelpmreset_in            =>      '0',
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
        gt0_rxoutclk_out                =>      gt0_rxoutclk_out,
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
        gt0_gtrxreset_in                =>      '0',
        gt0_rxpmareset_in               =>      '0',
    ----------------- Receive Ports - RX Polarity Control Ports ----------------
        gt0_rxpolarity_in               =>      '0',
    ---------------------- Receive Ports - RX gearbox ports --------------------
        gt0_rxslide_in                  =>      rx_slide_i,
    ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        gt0_rxcharisk_out               =>      rxcharisk_i,
    --------------------- TX Initialization and Reset Ports --------------------
        gt0_gttxreset_in                =>      '0',
        gt0_txuserrdy_in                =>      '1',
    ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        gt0_txusrclk_in                 =>      clk_sys,
        gt0_txusrclk2_in                =>      clk_sys,
    ------------------ Transmit Ports - TX Data Path interface -----------------
        gt0_txdata_in                   =>      tx_data_i,
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        gt0_gtxtxn_out                  =>      SFP_TX_N,
        gt0_gtxtxp_out                  =>      SFP_TX_P,
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        gt0_txoutclk_out                =>      open,
    --------------------- Transmit Ports - TX Gearbox Ports --------------------
        gt0_txcharisk_in                =>      tx_charisk,
    ----------------- Transmit Ports - TX Polarity Control Ports ---------------
        gt0_txpolarity_in               =>      '0',


    --____________________________COMMON PORTS________________________________
     GT0_QPLLOUTCLK_IN  => '0',
     GT0_QPLLOUTREFCLK_IN => '0' 
);
process(clk_i)
begin
    if rising_edge(clk_i) then
        trig_o <= rx_data_i;
    end if;
end process;
tx_data_i <= nhit_i & x"BC";
charisk_gen:process(clk_i, reset_i)
variable i: integer:=0;
begin
	if reset_i = '1' then
		tx_charisk <= "00";
		i:=1;
	elsif rising_edge(clk_i) then
		if(i=65535) then --Insertion of comma after count value reached
			i:=1;
			tx_charisk <= "01";
		else
			tx_charisk <= "00";
			i:= i + 1;
		end if;
	end if;
end process;
Inst_manual_align:entity work.rx_alignment
    generic map(
    NUMBER_TO_ALIGN => 10,
    LOSS_ALIGN => 20
    )
    port map(
    clk_i => gt0_rxusrclk_in,
    reset_i => not rx_resetdone,
    slide_o => rx_slide_i,
    rx_data_i => rx_data_i,
    aligned_o => rx_aligned,
    re_align_i => '0',
    debug_fsm => open
    );
end Behavioral;
