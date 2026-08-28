library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use IEEE.std_logic_misc.all;
  use work.chip8_pkg.all;
entity cpu is
 generic (
    TICK_DIV : integer := 1000   
  );
  port (
    clk: in std_logic;
    rst: in std_logic;
    keys: in std_logic_vector(15 downto 0);
  );
end entity;

architecture Behavioral of cpu is

  function to_bcd(bin : unsigned(7 downto 0)) return std_logic_vector is
      variable temp     : unsigned(7 downto 0) := bin;
      variable bcd      : unsigned(11 downto 0) := (others => '0');
      variable j       : integer;
  begin
      for j in 0 to 7 loop
          if bcd(3 downto 0) >= 5 then
              bcd(3 downto 0) := bcd(3 downto 0) + 3;
          end if;
          if bcd(7 downto 4) >= 5 then
              bcd(7 downto 4) := bcd(7 downto 4) + 3;
          end if;
          if bcd(11 downto 8) >= 5 then
              bcd(11 downto 8) := bcd(11 downto 8) + 3;
          end if;
          bcd := bcd(10 downto 0) & temp(7);
          temp := temp(6 downto 0) & '0';
      end loop;
      return std_logic_vector(bcd);
  end function;
    type reg_t is array (0 to 15) of std_logic_vector(7 downto 0);
    type stack_t is array (0 to 15) of std_logic_vector(15 downto 0);
    
    type status_t is (FETCH_HI, FETCH_LO, DECODE, EX_CLS, EX_RET, EX_JP, EX_CALL, EX_SE3, EX_SNE, 
    EX_SE5, EX_LD, EX_ADD7, EX_LD8, EX_8_NO_VF, EX_8_VF, EX_SNE9, 
    EX_LDA, EX_JPB, EX_RAND, EX_DRW, EX_SKP, EX_SKNP, EX_LDF7, EX_WAITKEY, EX_LDF15, EX_LDF18, EX_ADD1E, EX_LD29, EX_LD33, EX_LD55, EX_LD65);
    signal tick_counter: integer range 0 to TICK_DIV := 0;
    signal curr_status: status_t := FETCH_HI;
    signal op: std_logic_vector(3 downto 0)  := (others => '0');
    signal a: std_logic_vector(7 downto 0)   := (others => '0');
    signal b: std_logic_vector(7 downto 0)   := (others => '0');
    signal res: std_logic_vector(7 downto 0) := (others => '0');
    signal carry: std_logic                  := '0';
    signal opcode: std_logic_vector(15 downto 0) := (others => '0');
    signal pc: std_logic_vector(15 downto 0) := x"0200";
    signal dt: std_logic_vector(7 downto 0) := (others => '0');
    signal st: std_logic_vector(7 downto 0) := (others => '0');
    
    signal write_addr: std_logic_vector(11 downto 0);
    signal read_addr: std_logic_vector(11 downto 0);
    signal we: std_logic := '0';
    signal write_data: std_logic_vector(7 downto 0);
    signal read_data: std_logic_vector(7 downto 0);
    signal wb_vf: std_logic;

    signal v_reg: reg_t := (others => (others => '0'));
    signal stack: stack_t := (others => (others => '0'));
    signal gfx: framebuffer_t := (others => (others => '0'));
    signal sp: std_logic_vector(7 downto 0) := (others => '0');
    signal i: std_logic_vector(15 downto 0) := (others => '0');
    signal n: std_logic_vector(3 downto 0);
    signal vx: std_logic_vector(7 downto 0);
    signal vy: std_logic_vector(7 downto 0);
    signal kk: std_logic_vector(7 downto 0);
    signal nnn: std_logic_vector(11 downto 0);
    signal family: std_logic_vector(3 downto 0);
    signal rand: std_logic_vector(7 downto 0);
    signal key_found: std_logic;
    signal key_idx:  integer range 0 to 16;
    signal curr_idx: integer range 0 to 63 := 0;
    signal bcd : std_logic_vector(11 downto 0);
    
begin
    
    lfsr16_inst: entity work.lfsr16
    port map (
      clk  => clk,
      rst  => rst,
      rand => rand
    );
    alu_inst: entity work.alu
    port map (
      op    => op,
      a     => a,
      b     => b,
      res   => res,
      carry => carry
    );

    control_unit_inst: entity work.control_unit
    port map (
      opcode => opcode,
      wb_vf  => wb_vf,
      alu_op => op
    );
    ram_inst: entity work.ram
   
    port map (
      clk        => clk,
      we         => we,
      write_addr => write_addr,
      read_addr  => read_addr,
      write_data => write_data,
      read_data  => read_data
    );
    key_encoder: entity work.priority_encoder
    generic map (N => 16)
    port map (
        data_in => keys,
        found   => key_found,
        idx     => key_idx
    );
    read_addr <= pc(11 downto 0)                                                       when curr_status = FETCH_HI else
                std_logic_vector(unsigned(pc(11 downto 0)) + 1)                        when curr_status = FETCH_LO else
                std_logic_vector(unsigned(I(11 downto 0)) + to_unsigned(curr_idx, 12)) when (curr_status = EX_DRW or curr_status = EX_LD65) else
                pc(11 downto 0);
    write_addr <= std_logic_vector(unsigned(I(11 downto 0)) + to_unsigned(curr_idx, 12)) when (curr_status = EX_LD55 or curr_status = EX_LD33) else
    (others => '0');
    

    write_data <= v_reg(curr_idx mod 16) when curr_status = EX_LD55 else
              (x"0" & bcd(11 downto 8)) when (curr_status = EX_LD33 and curr_idx = 0) else
              (x"0" & bcd(7 downto 4))  when (curr_status = EX_LD33 and curr_idx = 1) else
              (x"0" & bcd(3 downto 0))  when (curr_status = EX_LD33 and curr_idx = 2) else
              (others => '0');
    we         <= '1' when (curr_status = EX_LD55 and curr_idx <= to_integer(unsigned(opcode(11 downto 8)))) else 
                  '1' when (curr_status = EX_LD33 and curr_idx <= 2) else '0';
    
    vx     <= v_reg(to_integer(unsigned(opcode(11 downto 8))));
    vy     <= v_reg(to_integer(unsigned(opcode(7 downto 4))));
    kk     <= opcode(7 downto 0);
    nnn    <= opcode(11 downto 0);
    n      <= opcode(3 downto 0);
    family <= opcode(15 downto 12);
    bcd    <= to_bcd(unsigned(vx));
    process(clk)
      variable sprite: std_logic_vector(63 downto 0) := (others => '0');
      variable collision_mask: std_logic_vector(63 downto 0) := (others => '0');
      variable vx_idx : integer range 0 to 15;
      variable vx_val : unsigned(7 downto 0);
      
    begin
        if rising_edge(clk) then
            if rst = '1' then
              pc            <= x"0200";
              curr_status   <= FETCH_HI;
              curr_idx      <= 0;
              tick_counter  <= 0;        
              dt            <= (others => '0');   
              st            <= (others => '0');
              sp            <= (others => '0');
              i             <= (others => '0');
              opcode        <= (others => '0');
              v_reg         <= (others => (others => '0'));
              gfx           <= (others => (others => '0'));
              stack         <= (others => (others => '0'));
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
                case curr_status is
                  when FETCH_HI =>
                    opcode(15 downto 8) <= read_data;
                    curr_status <= FETCH_LO;
                  when FETCH_LO =>                 
                    opcode(7 downto 0) <= read_data;
                    curr_status <= DECODE;
                  when DECODE =>
                    pc <= std_logic_vector(unsigned(pc) + 2);
                    case family is
                      when x"0" =>
                        if n = x"0"    then
                          curr_status <= EX_CLS;
                        elsif n = x"E" then
                          curr_status <= EX_RET;
                        else
                          curr_status <= FETCH_HI;
                        end if;
                      when x"1" =>
                        curr_status <= EX_JP;
                      when x"2" =>
                        curr_status <= EX_CALL;
                      when x"3" =>
                        curr_status <= EX_SE3;
                      when x"4" =>
                        curr_status <= EX_SNE;
                      when x"5" => 
                        curr_status <= EX_SE5;
                      when x"6" =>
                        curr_status <= EX_LD;
                      when x"7" =>
                        curr_status <= EX_ADD7;
                        a <= vx;
                        b <= kk;
                      when x"8" =>
                        if n = x"0" then
                          curr_status <= EX_LD8;
                        elsif wb_vf = '1' then
                          curr_status <= EX_8_VF;
                        else 
                          curr_status <= EX_8_NO_VF;
                        end if;
                        a <= vx;
                        b <= vy;
                      when x"9" =>
                        curr_status <= EX_SNE9;
                      when x"A" =>
                        curr_status <= EX_LDA;
                      when x"B" =>
                        curr_status <= EX_JPB;
                      when x"C" =>
                        curr_status <= EX_RAND;
                      when x"D" =>
                        curr_status <= EX_DRW;
                        v_reg(15) <= (others => '0');
                      when x"E" =>
                        if kk = x"9E" then
                          curr_status <= EX_SKP;
                        elsif kk = x"A1" then
                          curr_status <= EX_SKNP;
                        else
                          curr_status <= FETCH_HI; 
                        end if;
                      when x"F" =>
                        case kk is
                          when x"07" =>
                            curr_status <= EX_LDF7;
                          when x"0A" =>
                            curr_status <= EX_WAITKEY;
                          when x"15" =>
                            curr_status <= EX_LDF15;
                          when x"18" =>
                            curr_status <= EX_LDF18;
                          when x"1E" =>
                            curr_status <= EX_ADD1E;
                          when x"29" =>
                            curr_status <= EX_LD29;
                          when x"33" =>
                            curr_status <= EX_LD33;
                          when x"55" =>
                            curr_status <= EX_LD55;
                          when x"65" =>
                            curr_status <= EX_LD65;  
                                                 
                          when others => curr_status <= FETCH_HI;
                        end case;
                      when others => curr_status <= FETCH_HI;
                    end case;
                  when EX_CLS =>
                    gfx <= (others => (others => '0'));
                    curr_status <= FETCH_HI;
                  when EX_RET =>
                    pc <= stack(to_integer(unsigned(sp) - 1));
                    sp <= std_logic_vector(unsigned(sp) - 1);
                    curr_status <= FETCH_HI;
                  when EX_JP =>
                    pc(11 downto 0) <= nnn;
                    curr_status <= FETCH_HI;
                  when EX_CALL =>
                    sp <= std_logic_vector(unsigned(sp) + 1);
                    stack(to_integer(unsigned(sp))) <= pc;
                    pc(11 downto 0) <= nnn;
                    curr_status <= FETCH_HI;
                  when EX_SE3 =>
                    if vx = kk then
                      pc <= std_logic_vector(unsigned(pc) + 2);
                    end if;
                    curr_status <= FETCH_HI;
                  when EX_SNE =>
                    if vx /= kk then
                      pc <= std_logic_vector(unsigned(pc) + 2);
                    end if;
                    curr_status <= FETCH_HI;
                  when EX_SE5 =>
                    if vx = vy then
                      pc <= std_logic_vector(unsigned(pc) + 2);
                    end if;
                    curr_status <= FETCH_HI;
                  when EX_LD =>
                    v_reg(to_integer(unsigned(opcode(11 downto 8)))) <= kk;
                    curr_status <= FETCH_HI;
                  when EX_ADD7 =>
                    v_reg(to_integer(unsigned(opcode(11 downto 8)))) <= res;
                    curr_status <= FETCH_HI;
                  when EX_LD8 =>
                    v_reg(to_integer(unsigned(opcode(11 downto 8)))) <= vy;
                    curr_status <= FETCH_HI;
                  when EX_8_NO_VF =>
                    if to_integer(unsigned(opcode(11 downto 8))) /= 15 then
                      v_reg(to_integer(unsigned(opcode(11 downto 8)))) <= res;
                    end if;
                    v_reg(15) <= (others => '0');   
                    curr_status <= FETCH_HI;
                  when EX_8_VF =>
                    if to_integer(unsigned(opcode(11 downto 8))) /= 15 then
                      v_reg(to_integer(unsigned(opcode(11 downto 8)))) <= res;
                    end if;
                    v_reg(15) <= b"0000000" & carry;
                    curr_status <= FETCH_HI;

                  when EX_SNE9 =>
                    if vx /= vy then
                      pc <= std_logic_vector(unsigned(pc) + 2);
                    end if;
                    curr_status <= FETCH_HI;

                  when EX_LDA =>
                    i(11 downto 0) <= nnn;
                    curr_status <= FETCH_HI;

                  when EX_JPB =>
                    pc(11 downto 0) <= std_logic_vector(unsigned(nnn) + unsigned(v_reg(0)));
                    curr_status <= FETCH_HI;

                  when EX_RAND =>
                    v_reg(to_integer(unsigned(opcode(11 downto 8)))) <= rand and kk;
                    curr_status <= FETCH_HI;

                  when EX_DRW =>
                    if curr_idx = to_integer(unsigned(n)) then
                      curr_idx <= 0;
                      curr_status <= FETCH_HI;
                    else
                      if (to_integer(unsigned(vy(4 downto 0))) + curr_idx) < 32 then
                        sprite         := (others => '0');
                        collision_mask := (others => '0');
                        sprite(63 downto 56) := read_data;
                        sprite := std_logic_vector(shift_right(unsigned(sprite), to_integer(unsigned(vx(5 downto 0)))));
                        collision_mask := gfx(to_integer(unsigned(vy(4 downto 0))) + curr_idx) and sprite;
                        gfx(to_integer(unsigned(vy(4 downto 0))) + curr_idx) <=
                        gfx(to_integer(unsigned(vy(4 downto 0))) + curr_idx) xor sprite;
                        if or_reduce(collision_mask) = '1' then
                            v_reg(15) <= x"01";   
                        end if;
                      end if;
                      curr_idx <= curr_idx + 1;
                    end if;                 
                  when EX_SKP =>
                    if keys(to_integer(unsigned(vx))) = '1' then
                      pc <= std_logic_vector(unsigned(pc) + 2);
                    end if;
                    curr_status <= FETCH_HI;
                  when EX_SKNP =>
                    if keys(to_integer(unsigned(vx))) = '0' then
                      pc <= std_logic_vector(unsigned(pc) + 2);
                    end if;
                    curr_status <= FETCH_HI;
                  when EX_LDF7 =>
                    v_reg(to_integer(unsigned(opcode(11 downto 8)))) <= dt;
                    curr_status <= FETCH_HI;
                  when EX_WAITKEY =>
                    if key_found = '1' then
                        v_reg(to_integer(unsigned(opcode(11 downto 8)))) <= std_logic_vector(to_unsigned(key_idx, 8));
                        curr_status <= FETCH_HI;
                    end if;
                  when EX_LDF15 =>
                    dt <= vx;
                    curr_status <= FETCH_HI;
                  when EX_LDF18 =>
                    st <= vx;
                    curr_status <= FETCH_HI;
                  when EX_ADD1E =>
                    I <= std_logic_vector(unsigned(I) + resize(unsigned(vx), 16));
                    curr_status <= FETCH_HI;    
                  when EX_LD29 =>
                    vx_idx := to_integer(unsigned(opcode(11 downto 8)));
                    vx_val := unsigned(v_reg(vx_idx));
                    I <= std_logic_vector(to_unsigned(16#50#, 16) + resize(shift_left(vx_val, 2), 16) + resize(vx_val, 16));
                    curr_status <= FETCH_HI;
                  when EX_LD33 =>
                    if curr_idx > 2 then
                      curr_idx <= 0;
                      curr_status <= FETCH_HI;                     
                    else 
                      curr_idx <= curr_idx + 1;
                    end if;
                  when EX_LD55 =>
                    if curr_idx > unsigned(opcode(11 downto 8)) then
                      I <= std_logic_vector(unsigned(I) + curr_idx);
                      curr_idx <= 0;
                      curr_status <= FETCH_HI;
                    else 
                      curr_idx <= curr_idx + 1;
                    end if;
                  when EX_LD65 =>
                    if curr_idx > unsigned(opcode(11 downto 8)) then
                      I <= std_logic_vector(unsigned(I) + curr_idx);
                      curr_idx <= 0;
                      curr_status <= FETCH_HI;
                    else 
                      v_reg(curr_idx) <= read_data;
                      curr_idx <= curr_idx + 1;
                    end if;
                end case;
            end if;
        end if;
    end process;
end architecture;