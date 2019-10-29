
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
use work.lite_bus_pack.all;
use work.TTIM_v2_pack.all;
--library UNISIM;
--use UNISIM.VComponents.all;

entity control_registers is
    Port ( 
    sys_clk_i : in STD_LOGIC;
    reset_i : in std_logic;
    lite_bus_w : in t_lite_wbus_arry(NSLV - 1 downto 0);
    lite_bus_r : out t_lite_rbus_arry(NSLV - 1 downto 0);
    register_o : out t_array48(NSLV - 1 downto 0);
    register_i : in t_array48(NSLV - 1 downto 0)
    );
end control_registers;

architecture Behavioral of control_registers is
signal registers : t_array48(NSLV - 1 downto 0);
begin
Gen_registers:for i in NSLV - 1 downto 0 generate
begin
    process(sys_clk_i)
    begin
    if rising_edge(sys_clk_i) then
        if lite_bus_w(i).strobe = '1' then
            if lite_bus_w(i).wr_rd = '1' then
                registers(i) <= lite_bus_w(i).data;
            end if;
        end if;
    end if;
    end process;
    lite_bus_r(i).ack <= lite_bus_w(i).strobe;
    lite_bus_r(i).head <= lite_bus_w(i).head & '0';
    lite_bus_r(i).data <= lite_bus_w(i).addr & register_i(i);
end generate;
register_o <= registers;
end Behavioral;
