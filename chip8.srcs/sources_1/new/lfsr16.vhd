library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lfsr16 is
    port (
        clk  : in  std_logic;
        rst  : in  std_logic;                
        rand : out std_logic_vector(7 downto 0)  
    );
end entity lfsr16;

architecture Behavioral of lfsr16 is
    signal lfsr     : std_logic_vector(15 downto 0) := x"ACE1";  
    signal feedback : std_logic;
begin
    feedback <= lfsr(0) xor lfsr(2) xor lfsr(3) xor lfsr(5);

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                lfsr <= x"ACE1";
            else
                lfsr <= feedback & lfsr(15 downto 1); 
            end if;
        end if;
    end process;

    rand <= lfsr(7 downto 0);
end architecture Behavioral;