----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.09.2026 22:19:29
-- Design Name: 
-- Module Name: gray_pointer_syn_fifo - Behavioral
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gray_pointer_sync_fifo is
generic(
    width : integer := 4
);

port(
    wr_clk    : in  std_logic;
    rd_clk    : in  std_logic;
    reset_n   : in  std_logic;

    bin_ptr   : in  std_logic_vector(width-1 downto 0);
    syn_bptr  : out std_logic_vector(width-1 downto 0)
);

end gray_pointer_sync_fifo;


architecture Behavioral of gray_pointer_sync_fifo is

    signal gray_ptr     : std_logic_vector(width-1 downto 0);
    signal gray_ptr_mid : std_logic_vector(width-1 downto 0);
    signal gray_ptr_syn : std_logic_vector(width-1 downto 0);

    attribute ASYNC_REG : string;

    attribute ASYNC_REG of gray_ptr_mid : signal is "TRUE";
    attribute ASYNC_REG of gray_ptr_syn : signal is "TRUE";

begin

    ----------------------------------------------------------------
    -- Binary pointer -> Gray pointer
    ----------------------------------------------------------------
    gray_ptr <= bin_ptr xor
                ('0' & bin_ptr(width-1 downto 1));


    ----------------------------------------------------------------
    -- Gray pointer synchronization
    -- wr_clk = source clock
    -- rd_clk = destination clock
    ----------------------------------------------------------------
    process(rd_clk, reset_n)
    begin

        if reset_n = '0' then

            gray_ptr_mid <= (others => '0');
            gray_ptr_syn <= (others => '0');

        elsif rising_edge(rd_clk) then

            gray_ptr_mid <= gray_ptr;
            gray_ptr_syn <= gray_ptr_mid;

        end if;

    end process;


    ----------------------------------------------------------------
    -- Gray -> Binary
    ----------------------------------------------------------------
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
