library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--library UNISIM;
--use UNISIM.VComponents.all;

package TTIM_v2_pack is

    type t_array2 is array (integer range<>) of std_logic_vector(1 downto 0);
    type t_array8 is array (integer range<>) of std_logic_vector(7 downto 0);
    type t_array16 is array (integer range<>) of std_logic_vector(15 downto 0);
    type t_array32 is array (integer range<>) of std_logic_vector(31 downto 0);
    type t_array48 is array (integer range<>) of std_logic_vector(47 downto 0);
    type t_uarray8 is array (integer range<>) of unsigned(7 downto 0);
    type t_uarray32 is array (integer range<>) of unsigned(31 downto 0);
    
    constant    g_number_of_GCU : integer := 48;
------------------------------types and subtypes----------------------------------
subtype t_parity_ham_8bit  is std_logic_vector(4 downto 0); 
subtype t_parity_ham_32bit is std_logic_vector(6 downto 0);
subtype t_data_ham_8bit    is std_logic_vector(7 downto 0); 
subtype t_data_ham_32bit   is std_logic_vector(31 downto 0);
subtype t_coded_ham_8bit   is std_logic_vector(12 downto 0);  -- DDDDDDDDHHHHH
subtype t_coded_ham_32bit  is std_logic_vector(38 downto 0);  -- DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDHHHHHHH

    type t_ttc_long_frame is
  record
    long_address : std_logic_vector(15 downto 0);
    long_subadd  : std_logic_vector(7 downto 0);
    long_data    : std_logic_vector(7 downto 0);
	 long_strobe  : std_logic;
  end record;

  type t_brd_command is
  record
    idle           : std_logic;    
    rst_time       : std_logic;
	 rst_event      : std_logic;
	 rst_time_event : std_logic;
	 supernova      : std_logic;
	 test_pulse     : std_logic;
	 time_request   : std_logic;
	 rst_errors     : std_logic;
	 autotrigger    : std_logic;
	 en_acquisition : std_logic;
  end record;

  type t_ttc_ctrl is
  record
    en_acquisition    : std_logic;    
    backpressure      : std_logic;
	 autotrigger       : std_logic;
  end record;
  -------------------------------subprograms----------------------------------------
function f_hamming_encoder_8bit(data_in:t_data_ham_8bit) return t_parity_ham_8bit;
procedure p_hamming_decoder_8bit(data_coded_in : in t_coded_ham_8bit; 
                                 check_parity : out t_parity_ham_8bit);
procedure p_hamming_decoder_32bit(data_coded_in : in t_coded_ham_32bit; 
                                 check_parity : out t_parity_ham_32bit);
function f_hamming_encoder_32bit(data_in:t_data_ham_32bit) return t_parity_ham_32bit; 
procedure p_address_compare(add1 : in std_logic_vector(15 downto 0);
                            add2 : in std_logic_vector(15 downto 0);
									 equal : out std_logic); 
function f_log2 (A : natural) return natural;
end TTIM_v2_pack;

package body TTIM_v2_pack is
---------------------------- 
-- HAMMING 8 BITS ENCODER -- 
---------------------------- 
	
function f_hamming_encoder_8bit(data_in:t_data_ham_8bit) return t_parity_ham_8bit  is 
	variable parity : t_parity_ham_8bit; 
begin 		
	parity(0)	:=	data_in(0) xor data_in(1) xor data_in(3) xor data_in(4) xor data_in(6);
	parity(1)	:=	data_in(0) xor data_in(2) xor data_in(3) xor data_in(5) xor data_in(6);
	parity(2)	:=	data_in(1) xor data_in(2) xor data_in(3) xor data_in(7);
	parity(3)	:=	data_in(4) xor data_in(5) xor data_in(6) xor data_in(7);
	parity(4)	:=	parity(0) xor parity(1) xor parity(2) xor parity(3) xor data_in(0) 
	               xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(5)
						xor data_in(6) xor data_in(7);
	return parity; 
end; 
 
----------------------------- 
-- HAMMING 32 BITS ENCODER -- 
----------------------------- 
function f_hamming_encoder_32bit(data_in:t_data_ham_32bit) return t_parity_ham_32bit  is 
	variable parity: t_parity_ham_32bit; 
begin

	parity(0) := data_in(0) xor data_in(1) xor data_in(3) xor data_in(4) xor data_in(6) 
	            xor data_in(8) xor data_in(10) xor data_in(11) xor data_in(13) xor data_in(15)
					xor data_in(17) xor data_in(19) xor data_in(21) xor data_in(23) xor data_in(25)
					xor data_in(26) xor data_in(28) xor data_in(30); 
					
	parity(1) := data_in(0) xor data_in(2) xor data_in(3) xor data_in(5) xor data_in(6) xor data_in(9) 
	            xor data_in(10) xor data_in(12) xor data_in(13) xor data_in(16) xor data_in(17) 
					xor data_in(20) xor data_in(21) xor data_in(24) xor data_in(25) xor data_in(27) 
					xor data_in(28) xor data_in(31);
					
	parity(2) := data_in(1) xor data_in(2) xor data_in(3) xor data_in(7) xor data_in(8) xor data_in(9)
               xor data_in(10) xor data_in(14) xor data_in(15) xor data_in(16) xor data_in(17) 
					xor data_in(22) xor data_in(23) xor data_in(24) xor data_in(25) xor data_in(29)
					xor data_in(30) xor data_in(31);
					
	parity(3) := data_in(4) xor data_in(5) xor data_in(6) xor data_in(7) xor data_in(8) xor data_in(9)
               xor data_in(10) xor data_in(18) xor data_in(19) xor data_in(20) xor data_in(21) 
					xor data_in(22) xor data_in(23) xor data_in(24) xor data_in(25);
					
	parity(4) := data_in(11) xor data_in(12) xor data_in(13) xor data_in(14) xor data_in(15) 
	            xor data_in(16) xor data_in(17) xor data_in(18) xor data_in(19) xor data_in(20) 
					xor data_in(21) xor data_in(22) xor data_in(23) xor data_in(24) xor data_in(25);
					
	parity(5) := data_in(26) xor data_in(27) xor data_in(28) xor data_in(29) xor data_in(30) 
	            xor data_in(31);
					
	parity(6) := parity(0) xor parity(1) xor parity(2) xor parity(3) xor parity(4) xor parity(5) 
	            xor data_in(0) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(4) 
					xor data_in(5) xor data_in(6) xor data_in(7) xor data_in(8) xor data_in(9) 
					xor data_in(10) xor data_in(11) xor data_in(12) xor data_in(13) xor data_in(14) 
					xor data_in(15) xor data_in(16) xor data_in(17) xor data_in(18) xor data_in(19) 
					xor data_in(20) xor data_in(21) xor data_in(22) xor data_in(23) xor data_in(24) 
					xor data_in(25) xor data_in(26) xor data_in(27) xor data_in(28) xor data_in(29) 
					xor data_in(30) xor data_in(31);	
	
	return parity; 
end;  
 
---------------------------- 
-- HAMMING 8 BITS DECODER -- 
---------------------------- 

procedure p_hamming_decoder_8bit(data_coded_in : in t_coded_ham_8bit; 
                                 check_parity : out t_parity_ham_8bit) is  

begin 

check_parity(0) := data_coded_in(0) xor data_coded_in(5) xor data_coded_in(6) xor data_coded_in(8)
                  xor data_coded_in(9) xor data_coded_in(11);

check_parity(1) := data_coded_in(1) xor data_coded_in(5) xor data_coded_in(7) xor data_coded_in(8)
                  xor data_coded_in(10) xor data_coded_in(11);
						
check_parity(2) := data_coded_in(2) xor data_coded_in(6) xor data_coded_in(7) xor data_coded_in(8)
                  xor data_coded_in(12);
						
check_parity(3) := data_coded_in(3) xor data_coded_in(9) xor data_coded_in(10) xor data_coded_in(11)
                  xor data_coded_in(12);

check_parity(4) := data_coded_in(0) xor data_coded_in(1) xor data_coded_in(2) xor data_coded_in(3)
                  xor data_coded_in(4) xor data_coded_in(5) xor data_coded_in(6) xor data_coded_in(7)
						xor data_coded_in(8) xor data_coded_in(9) xor data_coded_in(10) xor data_coded_in(11)
						xor data_coded_in(12);

end procedure p_hamming_decoder_8bit; 

---------------------------- 
-- HAMMING 32 BITS DECODER -- 
---------------------------- 

procedure p_hamming_decoder_32bit(data_coded_in : in t_coded_ham_32bit; 
                                 check_parity : out t_parity_ham_32bit) is

begin

check_parity(0) := data_coded_in(0) xor data_coded_in(7) xor data_coded_in(8) 
                   xor data_coded_in(10) xor data_coded_in(11) xor data_coded_in(13) 
	                xor data_coded_in(15) xor data_coded_in(17) xor data_coded_in(18) 
						 xor data_coded_in(20) xor data_coded_in(22) xor data_coded_in(24) 
						 xor data_coded_in(26) xor data_coded_in(28) xor data_coded_in(30) 
						 xor data_coded_in(32) xor data_coded_in(33) xor data_coded_in(35) 
						 xor data_coded_in(37);

check_parity(1) := data_coded_in(1) xor data_coded_in(7) xor data_coded_in(9) 
                   xor data_coded_in(10) xor data_coded_in(12) xor data_coded_in(13)
                   xor data_coded_in(16) xor data_coded_in(17) xor data_coded_in(19) 
						 xor data_coded_in(20) xor data_coded_in(23) xor data_coded_in(24) 
					    xor data_coded_in(27) xor data_coded_in(28) xor data_coded_in(31) 
						 xor data_coded_in(32) xor data_coded_in(34) xor data_coded_in(35) 
						 xor data_coded_in(38);	

check_parity(2) := data_coded_in(2)	xor data_coded_in(8) xor data_coded_in(9) 
                   xor data_coded_in(10) xor data_coded_in(14) xor data_coded_in(15) 
						 xor data_coded_in(16) xor data_coded_in(17) xor data_coded_in(21) 
						 xor data_coded_in(22) xor data_coded_in(23) xor data_coded_in(24) 
					    xor data_coded_in(29) xor data_coded_in(30) xor data_coded_in(31) 
						 xor data_coded_in(32) xor data_coded_in(36) xor data_coded_in(37) 
						 xor data_coded_in(38);

check_parity(3) := data_coded_in(3)	xor data_coded_in(11) xor data_coded_in(12) 
                   xor data_coded_in(13) xor data_coded_in(14) xor data_coded_in(15) 
						 xor data_coded_in(16) xor data_coded_in(17) xor data_coded_in(25) 
						 xor data_coded_in(26) xor data_coded_in(27) xor data_coded_in(28) 
					    xor data_coded_in(29) xor data_coded_in(30) xor data_coded_in(31) 
						 xor data_coded_in(32);					 

check_parity(4) := data_coded_in(4) xor data_coded_in(18) xor data_coded_in(19) 
                   xor data_coded_in(20) xor data_coded_in(21) xor data_coded_in(22) 
	                xor data_coded_in(23) xor data_coded_in(24) xor data_coded_in(25) 
						 xor data_coded_in(26) xor data_coded_in(27) xor data_coded_in(28) 
						 xor data_coded_in(29) xor data_coded_in(30) xor data_coded_in(31) 
						 xor data_coded_in(32);
					
check_parity(5) := data_coded_in(5) xor data_coded_in(33) xor data_coded_in(34) 
                   xor data_coded_in(35) xor data_coded_in(36) xor data_coded_in(37) 
	                xor data_coded_in(38);
						 
check_parity(6) := data_coded_in(0) xor data_coded_in(1) xor data_coded_in(2) 
                   xor data_coded_in(3) xor data_coded_in(4) xor data_coded_in(5) 
	                xor data_coded_in(6) xor data_coded_in(7) xor data_coded_in(8) 
						 xor data_coded_in(9) xor data_coded_in(10) xor data_coded_in(11) 
						 xor data_coded_in(12) xor data_coded_in(13) xor data_coded_in(14) 
						 xor data_coded_in(15) xor data_coded_in(16) xor data_coded_in(17)
						 xor data_coded_in(18) xor data_coded_in(19) xor data_coded_in(20) 
					    xor data_coded_in(21) xor data_coded_in(22) xor data_coded_in(23) 
						 xor data_coded_in(24) xor data_coded_in(25) xor data_coded_in(26) 
						 xor data_coded_in(27) xor data_coded_in(28) xor data_coded_in(29) 
						 xor data_coded_in(30) xor data_coded_in(31) xor data_coded_in(32) 
						 xor data_coded_in(33) xor data_coded_in(34) xor data_coded_in(35) 
					    xor data_coded_in(36) xor data_coded_in(37) xor data_coded_in(38);	


end procedure p_hamming_decoder_32bit;

function f_log2 (A : natural) return natural is
  begin
    for I in 1 to 64 loop     -- Works for up to 64 bits
      if (2**I >= A) then
        return(I);
      end if;
    end loop;
    return(63);
  end function f_log2;
 
procedure p_address_compare(add1  : in std_logic_vector(15 downto 0);
                            add2  : in std_logic_vector(15 downto 0);
									 equal : out std_logic) is

variable v_int : std_logic_vector(15 downto 0);

begin

v_int(0) := add1(0) xnor add2(0);
v_int(1) := add1(1) xnor add2(1);
v_int(2) := add1(2) xnor add2(2);
v_int(3) := add1(3) xnor add2(3);
v_int(4) := add1(4) xnor add2(4);
v_int(5) := add1(5) xnor add2(5);
v_int(6) := add1(6) xnor add2(6);
v_int(7) := add1(7) xnor add2(7);
v_int(8) := add1(8) xnor add2(8);
v_int(9) := add1(9) xnor add2(9);
v_int(10) := add1(10) xnor add2(10);
v_int(11) := add1(11) xnor add2(11);
v_int(12) := add1(12) xnor add2(12);
v_int(13) := add1(13) xnor add2(13);
v_int(14) := add1(14) xnor add2(14);
v_int(15) := add1(15) xnor add2(15);


equal := v_int(0) and v_int(1) and v_int(2) and v_int(3) and v_int(4) 
         and v_int(5) and v_int(6) and v_int(7) and v_int(8) and v_int(9)
			and v_int(10) and v_int(11) and v_int(12) and v_int(13) 
			and v_int(14) and v_int(15);

end procedure p_address_compare;

end TTIM_v2_pack;