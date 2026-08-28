library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.chip8_pkg.all;   -- donde este framebuffer_t

entity cpu_tb is
end entity;

architecture sim of cpu_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal gfx : framebuffer_t;

    constant CLK_PERIOD : time := 10 ns;
    signal sim_done : boolean := false;

    -- imprime el framebuffer como ASCII art
    procedure dump_gfx(fb : framebuffer_t) is
        variable l : line;
    begin
        for row in 0 to 31 loop
            for col in 0 to 63 loop
                -- col 0 = bit 63 (izquierda), consistente con tu barrel shifter
                if fb(row)(63 - col) = '1' then
                    write(l, string'("*"));
                else
                    write(l, string'("."));
                end if;
            end loop;
            writeline(output, l);
        end loop;
    end procedure;

begin
    dut: entity work.cpu
        generic map (
            INIT_FILE => "C:/Users/isaig/chip8/roms/ibm_logo.hex"
        )
        port map (
            clk     => clk,
            rst     => rst
          
        );

    -- reloj
    clk_gen: process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD/2;
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    -- estimulo
    stim: process
    begin
        rst <= '1';
        wait for CLK_PERIOD * 5;
        rst <= '0';

        -- deja correr suficientes ciclos para que dibuje el logo
        wait for CLK_PERIOD * 2000;

        report "=== FRAMEBUFFER ===";
        dump_gfx(gfx);

        sim_done <= true;
        wait;
    end process;
end architecture;