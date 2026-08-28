
  library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
  
  entity bcd is
    port (
        bin: in std_logic_vector(7 downto 0);
        bcd_out: out std_logic_vector(11 downto 0)
    );
  end entity;
  architecture Behavioral of bcd is
    
  begin
    
    process(bin)
        variable temp     : unsigned(7 downto 0) := unsigned(bin);
        variable bcd_v    : unsigned(11 downto 0) := (others => '0');
        variable j        : integer;
    begin
        bcd_out <= (others => '0');
        for j in 0 to 7 loop
          if bcd_v(3 downto 0) >= 5 then
              bcd_v(3 downto 0) := bcd_v(3 downto 0) + 3;
          end if;
          if bcd_v(7 downto 4) >= 5 then
              bcd_v(7 downto 4) := bcd_v(7 downto 4) + 3;
          end if;
          if bcd_v(11 downto 8) >= 5 then
              bcd_v(11 downto 8) := bcd_v(11 downto 8) + 3;
          end if;
          bcd_v := bcd_v(10 downto 0) & temp(7);
          temp := temp(6 downto 0) & '0';
        end loop;
        bcd_out <= std_logic_vector(bcd_v);
    end process;
    
  end architecture Behavioral;