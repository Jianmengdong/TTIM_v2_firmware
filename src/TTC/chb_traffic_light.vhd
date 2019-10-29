----------------------------------------------------------------------------------
-- Company:        INFN - LNL
-- Create Date:    14:50:38 02/10/2017 
-- Design Name:    GCU ReadOut
-- Module Name:    chb_traffic_light - rtl 
-- Project Name:   GCU
-- Tool versions:  ISE 14.7
-- Revision: 
-- Revision 0.01 - File Created
-- Description:
-- this fsm grants access to the chb. The priority is handled like this:
-- lower number = higher priority.
-- IDLE = chb is free.
-- state other than IDLE = chb is taken.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


entity chb_traffic_light is
    port ( clk_i          : in  std_logic;
           rst_i          : in  std_logic;
           chb_released_i : in  std_logic;
           chb_req1_i     : in  std_logic;
           chb_req2_i     : in  std_logic;
           chb_req3_i     : in  std_logic;
           chb_grant1_o   : out  std_logic;
           chb_grant2_o   : out  std_logic;
           chb_grant3_o   : out  std_logic;
           chb_busy_o     : out  std_logic
			  );
end chb_traffic_light;

architecture rtl of chb_traffic_light is

type t_chb_grant is (idle, 
                   grant1, 
						 grant2, 
                   grant3
						 );
						 
signal s_state : t_chb_grant;

begin

p_update_state : process(clk_i,rst_i)  
  begin  
    if rst_i = '1' then
	    s_state <= idle;
    elsif rising_edge(clk_i) then 
       case s_state is
		    
          when idle =>
             if chb_req1_i = '1' then
                s_state <= grant1;
             elsif chb_req2_i = '1' then
                s_state <= grant2;
				 elsif chb_req3_i = '1' then
                s_state <= grant3; 
             end if; 
				 
          when grant1 =>
			    if chb_released_i = '1' then
                s_state <= idle;
				 end if;
				 
			 when grant2 =>
			    if chb_released_i = '1' then
                s_state <= idle;
				 end if;	 
				 
			 when grant3 =>
			    if chb_released_i = '1' then
                s_state <= idle;
				 end if;

          when others =>               
             s_state <= idle;
				 
       end case;
    end if;
end process;

p_update_fsm_out : process(s_state)  
  begin  
     case s_state is
		    -------
          when idle =>
				 chb_busy_o   <= '0';
				 chb_grant1_o <= '0';
				 chb_grant2_o <= '0';
				 chb_grant3_o <= '0';
			 -------
          when grant1 =>
				 chb_busy_o <= '1';
				 chb_grant1_o <= '1';
				 chb_grant2_o <= '0';
				 chb_grant3_o <= '0';
			 -------
			 when grant2 =>
				 chb_busy_o <= '1';
				 chb_grant1_o <= '0';
				 chb_grant2_o <= '1';
				 chb_grant3_o <= '0';
			 -------
			 when grant3 =>
				 chb_busy_o <= '1';
				 chb_grant1_o <= '0';
				 chb_grant2_o <= '0';
				 chb_grant3_o <= '1';
		    -------
          when others =>               
				 chb_busy_o <= '1';
				 chb_grant1_o <= '0';
				 chb_grant2_o <= '0';
				 chb_grant3_o <= '0';
			 -------  
       end case;
			 
end process;  

end rtl;

