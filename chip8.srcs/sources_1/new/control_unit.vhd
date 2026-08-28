library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.chip8_pkg.all;

entity control_unit is
    port (
        opcode: in std_logic_vector(15 downto 0);
        wb_vf: out std_logic;
        alu_op: out std_logic_vector(3 downto 0)
    );
end entity control_unit;

architecture Behavioral of control_unit is
signal family: std_logic_vector(3 downto 0) := (others => '0');
signal low_nibble: std_logic_vector(3 downto 0) := (others => '0');
begin
    family     <= opcode(15 downto 12);
    low_nibble <= opcode(3 downto 0);
    process(all)
    begin
        alu_op <= (others => '0');
        wb_vf <= '0';
        case family is
            when x"7" =>
                alu_op <= ALU_ADD;
            when x"8" =>
                case low_nibble is
                    when x"1" =>
                        alu_op <= ALU_OR;
                    when x"2" =>
                        alu_op <= ALU_AND;
                    when x"3" =>
                        alu_op <= ALU_XOR;
                    when x"4" =>
                        alu_op <= ALU_ADD_WITH_CARRY;
                        wb_vf <= '1';
                    when x"5" =>
                        alu_op <= ALU_SUB;
                        wb_vf <= '1';
                    when x"6" =>
                        alu_op <= ALU_SHR;
                        wb_vf <= '1';
                    when x"7" =>
                        alu_op <= ALU_SUBN;
                        wb_vf <= '1';
                    when x"E" =>
                        alu_op <= ALU_SHL;
                        wb_vf <= '1';
                    when others =>
                        
                end case;
            when others =>
                
        end case;
    end process;
end architecture;