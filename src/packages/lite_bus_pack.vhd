library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--library UNISIM;
--use UNISIM.VComponents.all;
package lite_bus_pack is
    constant TIME_OUT : integer range 0 to 65535 := 65535;
    constant NSLV : integer range 0 to 255 := 20;
    type t_lite_rbus is
        record
        ack : std_logic;
        head : std_logic_vector(7 downto 0);
        data : std_logic_vector(55 downto 0);
        end record;
    type t_lite_wbus is
        record
        strobe : std_logic;
        wr_rd : std_logic;
        head : std_logic_vector(6 downto 0);
        addr : std_logic_vector(7 downto 0);
        data : std_logic_vector(47 downto 0);
        end record;
    type t_lite_rbus_arry is array (integer range<>) of t_lite_rbus;
    type t_lite_wbus_arry is array (integer range<>) of t_lite_wbus;
    
    function f_lite_bus_addr_sel(signal addr : std_logic_vector(7 downto 0)) 
                return integer;

end lite_bus_pack;

package body lite_bus_pack is

function f_lite_bus_addr_sel(signal addr : std_logic_vector(7 downto 0)) return integer is
    variable sel : integer;
    begin
        if    std_match(addr, "01000001") then
            sel := 0;
        elsif std_match(addr, "01000010") then
            sel := 1;
        elsif std_match(addr, "01000011") then
            sel := 2;
        elsif std_match(addr, "01000100") then
            sel := 3;
        elsif std_match(addr, "01000101") then
            sel := 4;
        elsif std_match(addr, "01000110") then
            sel := 5;
        elsif std_match(addr, "01000111") then
            sel := 6;
        elsif std_match(addr, "01001000") then
            sel := 7;
        elsif std_match(addr, "01001001") then
            sel := 8;
        elsif std_match(addr, "01001010") then
            sel := 9;
        elsif std_match(addr, "01001011") then
            sel := 10;
        elsif std_match(addr, "01001100") then
            sel := 11;
        elsif std_match(addr, "01001110") then
            sel := 12;
        elsif std_match(addr, "01001111") then
            sel := 13;
        elsif std_match(addr, "01010000") then
            sel := 14;
        elsif std_match(addr, "01010001") then
            sel := 15;
        elsif std_match(addr, "01010010") then
            sel := 16;
        elsif std_match(addr, "01010011") then
            sel := 17;
        elsif std_match(addr, "01010100") then
            sel := 18;
        elsif std_match(addr, "01010101") then
            sel := 19;
        
        else
            sel := 99;
        end if;
        return sel;
    end f_lite_bus_addr_sel;

end lite_bus_pack;
