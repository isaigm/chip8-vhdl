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
  type reg_t is array (0 to 15) of std_logic_vector(7 downto 0);
    
    type status_t is (FETCH_HI, FETCH_LO, DECODE, EX_CLS, EX_RET, EX_JP, EX_CALL, EX_SE3, EX_SNE, 
    EX_SE5, EX_LD, EX_ADD7, EX_LD8, EX_8_NO_VF, EX_8_VF, EX_SNE9, 
    EX_LDA, EX_JPB, EX_RAND, EX_DRW, EX_SKP, EX_SKNP, EX_LDF7, EX_WAITKEY, EX_LDF15, EX_LDF18, EX_ADD1E, EX_LD29, EX_LD33, EX_LD55, EX_LD65);
end package;