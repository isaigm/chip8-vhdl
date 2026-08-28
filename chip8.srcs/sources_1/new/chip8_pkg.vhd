library IEEE;
use IEEE.STD_LOGIC_1164.all;

package chip8_pkg is
  constant ALU_ADD_WITH_CARRY: std_logic_vector(3 downto 0) := "0000";
  constant ALU_SUB: std_logic_vector(3 downto 0)            := "0001";
  constant ALU_ADD: std_logic_vector(3 downto 0)            := "0010";
  constant ALU_OR:  std_logic_vector(3 downto 0)            := "0011";
  constant ALU_AND: std_logic_vector(3 downto 0)            := "0100";
  constant ALU_XOR: std_logic_vector(3 downto 0)            := "0101";
  constant ALU_SHR: std_logic_vector(3 downto 0)            := "0111";
  constant ALU_SHL: std_logic_vector(3 downto 0)            := "1000";
  constant ALU_SUBN:std_logic_vector(3 downto 0)            := "1001";
  type framebuffer_t is array (0 to 31) of std_logic_vector(63 downto 0);
end package;