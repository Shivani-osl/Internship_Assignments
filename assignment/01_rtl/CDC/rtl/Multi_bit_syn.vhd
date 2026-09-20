----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.09.2026 17:02:54
-- Design Name: 
-- Module Name: Multi_bit_syn_hs - Behavioral
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

entity Multi_bit_syn_hs is
generic(data_width: integer:=8);
Port (sclk,dclk,reset_n,sready,dbusy,sidle:in std_logic;
      data_in:in std_logic_vector (data_width-1 downto 0);
      dvalid:out std_logic;
      data_out:out std_logic_vector (data_width-1 downto 0));
end Multi_bit_syn_hs;

architecture Behavioral of Multi_bit_syn_hs is
TYPE state_type is(s_idle,s_req,s_wait_ack);
signal state:state_type;
signal sreq:std_logic:='0';
begin
process(reset_n,sclk)begin
 if reset='0'then
     data_out<=(others=>'0');
     elsif 
         rising_edge(sclk)then
            if(s_idle='1')
               then 
     
end process;
end Behavioral;
