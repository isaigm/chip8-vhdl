library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.chip8_pkg.all;

entity alu is
    Port (op: in std_logic_vector(3 downto 0);
        a: in std_logic_vector(7 downto 0);
        b: in std_logic_vector(7 downto 0);
        res: out std_logic_vector(7 downto 0);
        carry: out std_logic
     );
end alu;

architecture Behavioral of alu is

begin
    process(a, b, op)
    variable temp: unsigned(8 downto 0) := (others => '0');
    begin
        res <= (others => '0');
        carry <= '0';
        case op is
            when ALU_ADD_WITH_CARRY  =>
                temp := unsigned('0' & a) + unsigned('0' & b);
                if temp > 255 then
                    carry <= '1';
                end if;
                res <= std_logic_vector(temp(7 downto 0));
            when ALU_SUB => 
                if unsigned(a) >= unsigned(b) then 
                    carry <= '1';
                end if;
                res <= std_logic_vector(unsigned(a) - unsigned(b));
            when ALU_ADD =>
                res <= std_logic_vector(unsigned(a) + unsigned(b));
            when ALU_OR => 
                res <= a or b;
            when ALU_AND =>
                res <= a and b;
            when ALU_XOR =>
                res <= a xor b;
            when ALU_SHR =>
                carry <= a(0);
                res <= '0' & a(7 downto 1);
            when ALU_SHL =>
                carry <= a(7);
                res <= a(6 downto 0) & '0';
            when ALU_SUBN =>
                if unsigned(b) >= unsigned(a) then
                    carry <= '1';
                end if;
                res <= std_logic_vector(unsigned(b) - unsigned(a));
            when others =>
                null;
        
        end case;
    end process;

end Behavioral;
