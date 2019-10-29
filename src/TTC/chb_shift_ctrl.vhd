----------------------------------------------------------------------------------
-- Company: INFN LNL/PD - University of Padova
-- Create Date:    18:34:24 11/22/2016 
-- Design Name:    TTCTest
-- Module Name:    chb_shift_ctrl - rtl 
-- Project Name:   GCU 
-- Tool versions: ISE 14.7
-- Revision 1.0 - File Created
-- Author: Davide Pedretti
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity chb_shift_ctrl is
     generic(
	        g_cnt_width : integer := 6
	        );
     port (clk_i           : in  std_logic;
           reset_i         : in  std_logic;
           brdcst_strobe_i : in  std_logic;
           long_strobe_i   : in  std_logic;
			  -------------------------------
		     sbit_err_inj_i   : in std_logic;
		     dbit_err_inj_i   : in std_logic;
		     err_pos1_i       : in std_logic_vector(5 downto 0);
		     err_pos2_i       : in std_logic_vector(5 downto 0);
           -------------------------------
			  brdcst_frame_i  : in  std_logic_vector(15 downto 0);
           long_frame_i    : in  std_logic_vector(41 downto 0);
           chb_o           : out  std_logic;
			  chb_busy_o      : out  std_logic
			  );
end chb_shift_ctrl;

architecture rtl of chb_shift_ctrl is

component piso
   generic(g_width : integer := 8;
	        g_clk_rise  : string  := "TRUE"
	        );
   port(
        clk_i   : in std_logic;  
		  reset_i : in std_logic; 
		  load_i  : in std_logic; 
		  shift_i : in std_logic; 
        p_i     : in std_logic_vector(g_width -1 downto 0);  
        s_o     : out std_logic   
        );
end component;

component countdown
   generic(g_width : integer := 8;
	        g_clk_rise  : string  := "TRUE"
	        );
   port(
        clk_i    : in std_logic;  
		  reset_i  : in std_logic; 
		  load_i   : in std_logic; 
		  enable_i : in std_logic; 
        p_i      : in std_logic_vector(g_width -1 downto 0);  
        p_o      : out std_logic_vector(g_width -1 downto 0) 
        );
end component;

type t_chb_fsm is (st1_idle, 
                   st2_load_brdcst, 
						 st2_load_long, 
                   st3_shift
						 );
						 
signal s_state        : t_chb_fsm;
signal s_end          : std_logic;
signal s_shift        : std_logic;
signal s_load         : std_logic;
signal s_cnt          : std_logic_vector(g_cnt_width - 1 downto 0);
signal s_cnt_init     : std_logic_vector(g_cnt_width - 1 downto 0);
signal s_frame        : std_logic_vector(41 downto 0);
signal s_pos_1        : std_logic_vector(41 downto 0);
signal s_pos_2        : std_logic_vector(41 downto 0);
signal s_sel          : std_logic_vector(41 downto 0);
signal s_brd_frame    : std_logic_vector(15 downto 0);
signal s_long_frame   : std_logic_vector(41 downto 0);

constant c_brd_count   : integer := 14;
constant c_long_count  : integer := 40;

begin
------------------------------error injection process----------------------------
GEN_DECODER1:
for I in 0 to 41 generate
	s_pos_1(I) <= '1' when (err_pos1_i = std_logic_vector(to_unsigned(I,err_pos1_i'length))) else '0';
end generate GEN_DECODER1;

GEN_DECODER2:
for I in 0 to 41 generate
	s_pos_2(I) <= '1' when (err_pos2_i = std_logic_vector(to_unsigned(I,err_pos2_i'length))) else '0';
end generate GEN_DECODER2;

GEN_SELECT:
for I in 0 to 41 generate
	s_sel(I) <= '1' when (((sbit_err_inj_i = '1' or dbit_err_inj_i = '1')and s_pos_1(I) = '1') or (dbit_err_inj_i = '1' and s_pos_2(I) = '1')) else '0';
end generate GEN_SELECT;

GEN_BRD_FRAME:
for I in 0 to 15 generate
	s_brd_frame(I) <= brdcst_frame_i(I) when (s_sel(I) = '0') else not brdcst_frame_i(I);
end generate GEN_BRD_FRAME;

GEN_LONG_FRAME:
for I in 0 to 41 generate
	s_long_frame(I) <= long_frame_i(I) when (s_sel(I) = '0') else not long_frame_i(I);
end generate GEN_LONG_FRAME;

p_delay_1tclk : process(clk_i,reset_i)  
  begin  
    if reset_i = '1' then
	    s_frame <= (others => '1');
		 s_cnt_init <= (others => '0');
    elsif rising_edge(clk_i) then 
	    if brdcst_strobe_i = '1' then
		    s_frame <= s_brd_frame & x"ffffff" & '1' & '1';
			 s_cnt_init <= std_logic_vector(to_unsigned(c_brd_count, g_cnt_width));
	    elsif long_strobe_i = '1' then
	       s_frame <= s_long_frame;
			 s_cnt_init <= std_logic_vector(to_unsigned(c_long_count, g_cnt_width));
		 end if;
	 end if;
end process;

------------------------------Moore Finite State Machine--------------------------
p_update_state : process(clk_i,reset_i)  
  begin  
    if reset_i = '1' then
	    s_state <= st1_idle;
    elsif rising_edge(clk_i) then 
       case s_state is
		    -------
          when st1_idle =>
             if brdcst_strobe_i = '1' then
              s_state <= st2_load_brdcst;
             elsif long_strobe_i = '1' then
              s_state <= st2_load_long;
             end if;       
          -------
          when st2_load_brdcst =>
			    s_state <= st3_shift;
			 -------
			 when st2_load_long =>
			    s_state <= st3_shift;
			 -------
			 when st3_shift =>
			    if s_end = '1' then
                s_state <= st1_idle;
             end if;
		    -------
          when others =>               
              s_state <= st1_idle;
			 -------  
       end case;
    end if;
end process;

p_update_fsm_out : process(s_state)  
  begin  
     case s_state is
		    -------
          when st1_idle =>
			    s_shift    <= '0';
				 s_load     <= '0';
				 chb_busy_o <= '0';
			 -------
          when st2_load_brdcst =>
			    s_shift    <= '0';
				 s_load     <= '1';
				 chb_busy_o <= '1';
			 -------
			 when st2_load_long =>
			    s_shift    <= '0';
				 s_load     <= '1';
				 chb_busy_o <= '1';
			 -------
			 when st3_shift =>
			    s_shift    <= '1';
				 s_load     <= '0';
				 chb_busy_o <= '1';
		    -------
          when others =>               
             s_shift    <= '0';
				 s_load     <= '0';
				 chb_busy_o <= '1';
			 -------  
       end case;
			 
end process;  

Inst_piso_register : piso
					      generic map(
								  g_width     => 42,                           
								  g_clk_rise  => "TRUE"
								  )
						   port map(
								  clk_i   => clk_i,  
		                    reset_i => reset_i, 
		                    load_i  => s_load, 
		                    shift_i => s_shift, 
                          p_i     => s_frame,  
                          s_o     => chb_o
								  );

Inst_countdown : countdown
					      generic map(
								  g_width     => g_cnt_width,                           
								  g_clk_rise  => "TRUE"
								  )
						   port map(
								  clk_i    => clk_i,  
		                    reset_i  => reset_i, 
		                    load_i   => s_load, 
		                    enable_i => s_shift, 
                          p_i      => s_cnt_init,  
                          p_o      => s_cnt
								  );
							  
   s_end <= '1' when unsigned(s_cnt) = 0 else 
            '0';								  


end rtl;

