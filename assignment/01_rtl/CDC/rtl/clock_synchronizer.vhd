----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.09.2026 14:52:01
-- Design Name: 
-- Module Name: clock_synchronizer - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clock_synchronizer is
Port ( clk,din,reset_n: in std_logic;
        syn_out:out std_logic);
end clock_synchronizer;

architecture Behavioral of clock_synchronizer is
signal q1:std_logic:='0';
signal q2:std_logic:='0';
attribute ASYNC_REG : string;
attribute ASYNC_REG of q1 : signal is "TRUE";
attribute ASYNC_REG of q2 : signal is "TRUE";
begin
process(clk,reset_n)
 
 begin
 if(reset_n='0')then
  q1<='0';
  q2<='0';
  elsif rising_edge(clk) then
   q1<=din;
   q2<=q1;
   end if;

  end process;
 syn_out<=q2;
end Behavioral;
