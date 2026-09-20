----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.09.2026 10:25:48
-- Design Name: 
-- Module Name: FWFT_adapter - Behavioral
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

entity FWFT_adapter is
generic(data_width:integer:=8);
Port (fifo_empty,rd_clk,reset_n:in std_logic ;--from fifo
      receiver_ready:in std_logic;--from reciever
      fifo_data:in std_logic_vector (data_width-1 downto 0) ;
      fifo_rd_en:out std_logic;--to fifo
      data_read:out std_logic_vector (data_width-1 downto 0);--to reciever
      empty_o:out std_logic--to reciever
      );
end FWFT_adapter;

architecture Behavioral of FWFT_adapter is

signal fifo_stage    : std_logic_vector(data_width-1 downto 0);
signal middle_stage  : std_logic_vector(data_width-1 downto 0);
signal output_stage  : std_logic_vector(data_width-1 downto 0);

signal dout_valid       : std_logic;
signal fifo_data_valid  : std_logic;
signal middle_valid     : std_logic;
signal fifo_valid       : std_logic;

signal stage_space      : std_logic;
signal move_to_middle   : std_logic;
signal move_to_out      : std_logic;
signal consume_out      : std_logic;

signal fifo_rd_en_i     : std_logic;

begin

    fifo_rd_en <= fifo_rd_en_i;

    fifo_rd_en_i <= '1'
        when fifo_empty = '0'
         and stage_space = '1'
         and fifo_data_valid = '0'
        else '0';

    consume_out <= '1'
        when dout_valid = '1'
         and receiver_ready = '1'
        else '0';

    move_to_out <= '1'
        when middle_valid = '1'
         and (dout_valid = '0' or consume_out = '1')
        else '0';

    move_to_middle <= '1'
        when fifo_valid = '1'
         and (middle_valid = '0' or move_to_out = '1')
        else '0';

    stage_space <= '1'
        when dout_valid = '0'
          or fifo_valid = '0'
          or middle_valid = '0'
        else '0';

    empty_o  <= not dout_valid;
    data_read <= output_stage;


    process(rd_clk, reset_n)
    begin

        if reset_n = '0' then

            fifo_stage       <= (others => '0');
            middle_stage     <= (others => '0');
            output_stage     <= (others => '0');

            fifo_data_valid  <= '0';
            fifo_valid       <= '0';
            middle_valid     <= '0';
            dout_valid       <= '0';

        elsif rising_edge(rd_clk) then

            ------------------------------------------------
            -- FIFO read request completed
            ------------------------------------------------
            fifo_data_valid <= fifo_rd_en_i;

            if fifo_data_valid = '1' then
                fifo_stage <= fifo_data;
                fifo_valid <= '1';
            end if;


            ------------------------------------------------
            -- FIFO stage -> middle stage
            ------------------------------------------------
            if move_to_middle = '1' then

                middle_stage <= fifo_stage;
                middle_valid <= '1';

                fifo_valid <= '0';

            end if;


            ------------------------------------------------
            -- Middle stage -> output stage
            ------------------------------------------------
            if move_to_out = '1' then

                output_stage <= middle_stage;
                dout_valid   <= '1';

                middle_valid <= '0';

            elsif consume_out = '1' then

                dout_valid <= '0';

            end if;

        end if;

    end process;

end Behavioral;
