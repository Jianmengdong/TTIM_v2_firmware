
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.lite_bus_pack.all;
entity wr_interface is
    Port ( 
    sys_clk_i : in STD_LOGIC;
    reset_i : in std_logic;
    PDATA_RX : in std_logic_vector(9 downto 0);
    PDATA_TX : inout std_logic_vector(9 downto 0);
    lite_bus_w : out t_lite_wbus_arry(NSLV - 1 downto 0);
    lite_bus_r : in t_lite_rbus_arry(NSLV - 1 downto 0);
    PPS_IN_P : in std_logic;
    PPS_IN_N : in std_logic;
    pps_o : out std_logic
    --debug_fsm : out std_logic_vector(3 downto 0)
    );
end wr_interface;

architecture Behavioral of wr_interface is

    signal sel :integer;
    signal wr_rx_ctrl : std_logic_vector(1 downto 0);
    signal wr_rx_data,wr_tx_data,wr_rx_data_i : std_logic_vector(7 downto 0);
    signal wr_tx_cts,wr_tx_vld : std_logic;
    signal data_buf,data_send,data_tx : std_logic_vector(63 downto 0);
    type t_state is (st0_idle,st1_get_data,st2_assmble_data,
                    st3_wait_respond,st4_respond,st5_error);
    signal state : t_state;
    signal ack,data_valid : std_logic;
    signal debug_fsm : std_logic_vector(3 downto 0);
    
begin
Ibuf:IBUFDS
port map(
I => PPS_IN_P,
IB => PPS_IN_N,
O => pps_o
);
p_latch_wr_data:process(sys_clk_i)
begin
    if rising_edge(sys_clk_i) then
        wr_rx_ctrl <= PDATA_RX(9 downto 8);
        wr_rx_data <= PDATA_RX(3 downto 0) & PDATA_RX(7 downto 4);
        wr_rx_data_i <= wr_rx_data;
        PDATA_TX <= wr_tx_vld & 'Z' & wr_tx_data;
        wr_tx_cts <= PDATA_TX(8);
    end if;
end process;
process(sys_clk_i)
variable cnt : integer range 0 to 8;
variable time_out_cnt : integer range 0 to 65535;
begin
    if reset_i = '1' then
        state <= st0_idle;
        data_buf <= (others => '0');
    elsif rising_edge(sys_clk_i) then
        case state is
            when st0_idle =>
                data_buf <= (others => '0');
                data_valid <= '0';
                wr_tx_vld <= '0';
                if wr_rx_ctrl = "01" and wr_rx_data(7 downto 4) = "0100" then
                    state <= st1_get_data;
                    data_buf(7 downto 0) <= wr_rx_data;
                end if;
                debug_fsm <= x"0";
            when st1_get_data =>
                data_buf <= data_buf(55 downto 0) & wr_rx_data;
                if wr_rx_ctrl = "10" then
                    state <= st2_assmble_data;
                elsif wr_rx_ctrl = "11" then
                    state <= st5_error;
                end if;
                debug_fsm <= x"1";
            when st2_assmble_data =>
                data_valid <= '1';
                state <= st3_wait_respond;
                debug_fsm <= x"2";
            when st3_wait_respond =>
                time_out_cnt := time_out_cnt + 1;
                if time_out_cnt <= TIME_OUT then
                    if sel = 99 then
                        state <= st5_error;
                    elsif ack = '1' then
                        data_send <= data_tx;
                        state <= st4_respond;
                    end if;
                else
                    state <= st5_error;
                end if;
                cnt := 0;
                debug_fsm <= x"3";
            when st4_respond =>
                if wr_tx_cts = '1' then
                    if cnt < 8 then
                        wr_tx_vld <= '1';
                        wr_tx_data <= data_send(63 downto 56);
                        data_send <= data_send(55 downto 0) & x"00";
                        cnt := cnt + 1;
                    else
                        cnt := 0;
                        wr_tx_vld <= '0';
                        data_valid <= '0';
                        state <= st0_idle;
                    end if;
                end if;
                debug_fsm <= x"4";
            when st5_error =>
                if wr_tx_cts = '1' then
                    wr_tx_vld <= '1';
                    wr_tx_data <= data_buf(63 downto 57) & '1';
                    state <= st0_idle;
                end if;
                debug_fsm <= x"5";
            when others =>
                state <= st0_idle;
        end case;
    end if;
end process;
process(sys_clk_i)
begin
    if rising_edge(sys_clk_i) then
        ack <= lite_bus_r(sel).ack;
    end if;
end process;
data_tx <= lite_bus_r(sel).head & lite_bus_r(sel).data;

process(data_buf)
begin
    sel <= f_lite_bus_addr_sel(data_buf(55 downto 48));
end process;
Gen_slaves:for i in NSLV - 1 downto 0 generate
begin
    lite_bus_w(i).strobe <= '1' when sel = i and data_valid = '1' else '0';
    lite_bus_w(i).wr_rd <= data_buf(56); --1 for write, 0 for read
    lite_bus_w(i).data <= data_buf(47 downto 0);
    lite_bus_w(i).head <= data_buf(63 downto 57);
    lite_bus_w(i).addr <= data_buf(55 downto 48);
end generate;
-- i_ila:entity work.ila_0
    -- port map(
    -- clk => sys_clk_i,
    -- probe0 => wr_rx_ctrl,
    -- probe1 => wr_rx_data,
    -- probe2(0) => wr_tx_cts,
    -- probe3 => wr_tx_data,
    -- probe4(0) => wr_tx_vld,
    -- probe5 => data_buf,
    -- probe6 => data_send,
    -- probe7 => debug_fsm
    -- );
end Behavioral;
