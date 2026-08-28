library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity stack is
  port (clk: in std_logic;
        rst: in std_logic;
        in_data: in std_logic_vector(15 downto 0);
        push: in std_logic;
        pop: in std_logic;
        out_data: out std_logic_vector(15 downto 0));
end entity;
architecture Behavioral of stack is
  type stack_t is array (0 to 15) of std_logic_vector(15 downto 0);
  signal st: stack_t := (others => (others => '0'));
  signal sp: unsigned(3 downto  0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                st <= (others => (others => '0'));
                sp <= (others => '0');
            else 
                if push = '1' then
                    st(to_integer(sp)) <= in_data;
                    sp <= sp + 1;
                elsif pop = '1' then 
                    sp <= sp - 1;
                end if;
            end if;
        end if;
    end process;
    out_data <= st(to_integer(sp) - 1) when sp /= 0 else (others => '0');
end architecture;