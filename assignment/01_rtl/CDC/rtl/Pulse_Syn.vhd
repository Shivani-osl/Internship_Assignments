----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.09.2026 15:15:37
-- Design Name: 
-- Module Name: Pulse_Syn - Behavioral
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

entity Pulse_Syn is
Port (clk_tx,clk_rx,Pin,reset_n:in std_logic;
      Pout:out std_logic );
end Pulse_Syn;

architecture Behavioral of Pulse_Syn is
signal x1:std_logic :='0';
signal x1_out:std_logic;
signal syn_out:std_logic;
signal q1:std_logic;

begin

x1_out<=x1;

process(clk_tx,reset_n)
begin
 if (reset_n='0') then
     x1<='0';
      elsif rising_edge(clk_tx) then
    if Pin = '1' then
        x1 <= not x1;
    end if;
end if;
end process;
clock_syn : entity work.clock_synchronizer port map (clk=>clk_rx,reset_n=>reset_n,din=>x1_out,syn_out=>syn_out);

process(clk_rx,reset_n)begin
 if(reset_n='0')then
    q1<='0';
     elsif rising_edge(clk_rx)then
        q1<=syn_out;
        end if;
    end process;
    
    Pout<=syn_out xor q1;    
        

end Behavioral;
