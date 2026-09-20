----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.09.2026 10:45:32
-- Design Name: 
-- Module Name: syn_fifo - Behavioral
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
use ieee.math_real.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

 
entity syn_fifo is
generic(width :integer:=8;
        fifo_depth:integer:=8;
        threshold:integer:=2;
        RAM_TYPE:string:="block");
 Port (Wr_en,Rd_en,clk,reset_n:in std_logic ;
        Full,Empty,almost_full,almost_emp:out std_logic;
        data_out:out std_logic_vector (width-1 downto 0);
        data_in:in std_logic_vector (width-1 downto 0);
        occupancy_count : out std_logic_vector(positive(ceil(log2(real(fifo_depth+1))))-1 downto 0));
        
end syn_fifo;

architecture Behavioral of syn_fifo is
--counter size declaration
constant count_bit : positive := positive(ceil(log2(real(fifo_depth+1))));
constant PTR_BIT : positive := positive(ceil(log2(real(fifo_depth)))); 

--internal signal declaration
signal occupancy_count_i:unsigned (0 to count_bit-1);
signal almost_emp_i:std_logic;
signal almost_full_i:std_logic;
signal full_i  : std_logic;
signal empty_i : std_logic;
signal write_accept : std_logic;
signal read_accept  : std_logic;

--read and write pointer
signal wr_pointer:unsigned (PTR_BIT-1 downto 0 );
signal rd_pointer:unsigned (PTR_BIT-1 downto 0 );

--fifo size declaration
type fifo is array (fifo_depth-1 downto 0) of std_logic_vector (width-1 downto 0); 
signal memory:fifo;
attribute ram_style : string;
attribute ram_style of memory : signal is RAM_TYPE;
begin
--occupancy count logic
almost_emp_i<='1' when occupancy_count_i<=to_unsigned(threshold,occupancy_count_i'length) else '0';
almost_full_i<='1' when occupancy_count_i>=to_unsigned(fifo_depth-threshold,occupancy_count_i'length) else '0';
almost_emp  <= almost_emp_i;
almost_full <= almost_full_i;
full<=full_i;
empty<=empty_i;
occupancy_count <= std_logic_vector(occupancy_count_i);
--full and empty calculations
full_i<='1' when occupancy_count_i=to_unsigned(fifo_depth,occupancy_count_i'length)else '0';
empty_i<='1' when occupancy_count_i=to_unsigned(0,occupancy_count_i'length) else '0';

---read and write accept logic
write_accept <= Wr_en and
                (not full_i or (Rd_en and not empty_i));

read_accept  <= Rd_en and not empty_i;



--write and read operation logic

process(clk)
 begin
 if rising_edge(clk)then
        ---reset condition
        if reset_n ='0' then
        occupancy_count_i<=(others=>'0');
        wr_pointer<=(others=>'0');
        rd_pointer<=(others=>'0');
        
        else
         --fifo write block
         if write_accept = '1' then
          memory(to_integer(wr_pointer)) <= data_in;
          if wr_pointer=fifo_depth-1 then
          wr_pointer <=(others=>'0');
          else
          wr_pointer <= wr_pointer + 1;
          end if;
         end if;
          
          --read block
            if read_accept = '1' then
            data_out <= memory(to_integer(rd_pointer));
            if rd_pointer = fifo_depth-1 then
            rd_pointer <= (others => '0');
            else
            rd_pointer <= rd_pointer + 1;
            end if;
            end if;
         ----occupancy calc logic
           if write_accept = '1' and read_accept = '0' then
           occupancy_count_i <= occupancy_count_i + 1;

           elsif read_accept = '1' and write_accept = '0' then
           occupancy_count_i <= occupancy_count_i - 1;
             end if;
           end if;
         end if ;
      end process;
end Behavioral;
