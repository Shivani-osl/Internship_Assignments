----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.09.2026 14:01:09
-- Design Name: 
-- Module Name: gray_pointer_sync - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity gray_pointer_sync is
generic(width:integer:=4 );
port( rd_clk,wr_clk,reset_n:in std_logic;
bin_ptr,syn_bptr:out std_logic_vector(width-1 downto 0)

);
end gray_pointer_sync;

architecture Behavioral of gray_pointer_sync is
signal gray_ptr,gray_ptr_mid,gray_ptr_syn:std_logic_vector(width-1 downto 0);
signal bin_ptr_i:unsigned (width-1 downto 0);
attribute ASYNC_REG : string;
attribute ASYNC_REG of gray_ptr_mid : signal is "TRUE";
attribute ASYNC_REG of gray_ptr_syn : signal is "TRUE";
begin
process(wr_clk, reset_n)
begin
    if reset_n = '0' then
        bin_ptr_i <= (others => '0');
        bin_ptr   <= (others => '0');

    elsif rising_edge(wr_clk) then
        bin_ptr   <= std_logic_vector(bin_ptr_i);
        bin_ptr_i <= bin_ptr_i + 1;
    end if;
end process;
      ---binary to gray conversion     
     gray_ptr <=std_logic_vector( bin_ptr_i xor ('0' & bin_ptr_i(WIDTH-1 downto 1))); 
     
        process(rd_clk,reset_n)
          begin
           if(reset_n='0')then
              gray_ptr_mid<=(others=>'0');
               gray_ptr_syn<=(others=>'0');
               elsif rising_edge(rd_clk) then
                    gray_ptr_mid<=gray_ptr;
                    gray_ptr_syn<=gray_ptr_mid;
                    end if;
          end process;
          
     process(gray_ptr_syn)
    variable g_to_b : std_logic_vector(width-1 downto 0);
begin

    g_to_b(width-1) := gray_ptr_syn(width-1);

    bin_cal : for i in width-2 downto 0 loop
        g_to_b(i) := g_to_b(i+1) xor gray_ptr_syn(i);
    end loop bin_cal;

    syn_bptr <= g_to_b;

end process;
            
end Behavioral;
