library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity timers is
  generic (
    TICK_DIV : integer := 1000   
  );
  port (clk:   in std_logic;
    rst:       in std_logic;
    write_dt:  in std_logic;
    write_st:  in std_logic;
    timer_val: in std_logic_vector(7 downto 0);
    out_dt:    out std_logic_vector(7 downto 0)
  );
end entity;

architecture Behavioral of timers is
    signal tick_counter: integer range 0 to TICK_DIV := 0;
    signal dt: std_logic_vector(7 downto 0) := (others => '0');
    signal st: std_logic_vector(7 downto 0) := (others => '0');
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                dt <= (others => '0');
                st <= (others => '0');
                tick_counter <= 0;
            else
                if tick_counter = TICK_DIV - 1 then
                    tick_counter <= 0;
                    if unsigned(dt) > 0 then
                        dt <= std_logic_vector(unsigned(dt) - 1);
                    end if;
                    if unsigned(st) > 0 then
                        st <= std_logic_vector(unsigned(st) - 1);
                    end if;
                else
                    tick_counter <= tick_counter + 1;
                end if;
                if write_dt = '1' then
                    dt <= timer_val;
                elsif write_st = '1' then
                    st <= timer_val;
                end if;
            end if;
        end if;
    end process;
    out_dt <= dt;
    
end architecture;