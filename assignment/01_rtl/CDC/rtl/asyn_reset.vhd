
----------------------------------------------------------------------------------
-- Reset Architecture
--
-- Description:
--   Asynchronous assertion and synchronous de-assertion reset controller.
--
--   - reset_n = '0' asserts the local reset immediately.
--   - Reset de-assertion occurs only on the active clock edge.
--   - De-assertion can be delayed by a configurable number of clock cycles.
--   - reset_done indicates that the local reset has been released.
--
--   This module is intended to be instantiated separately for each
--   independent clock domain.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reset_architecture is

    generic (
        DEASSERT_DELAY : positive := 4
    );

    port (
        clk           : in  std_logic;
        reset_n       : in  std_logic;

        local_reset_n : out std_logic;
        reset_active  : out std_logic;
        reset_done    : out std_logic
    );

end reset_architecture;


architecture RTL of reset_architecture is

    signal delay_count : natural range 0 to DEASSERT_DELAY := 0;

    signal reset_reg   : std_logic := '0';

begin

    process(clk, reset_n)
    begin

        -- ---------------------------------------------------------
        -- Asynchronous assertion
        -- ---------------------------------------------------------
        if reset_n = '0' then

            delay_count <= 0;

            reset_reg   <= '0';

        -- ---------------------------------------------------------
        -- Synchronous de-assertion
        -- ---------------------------------------------------------
        elsif rising_edge(clk) then

            if delay_count < DEASSERT_DELAY then

                delay_count <= delay_count + 1;

                reset_reg   <= '0';

            else

                reset_reg   <= '1';

            end if;

        end if;

    end process;


    -- Active-low local reset
    local_reset_n <= reset_reg;

    -- Reset is active while local reset is asserted
    reset_active <= not reset_reg;

    -- Reset-done is the inverse of reset-active
    reset_done <= reset_reg;


end RTL;

