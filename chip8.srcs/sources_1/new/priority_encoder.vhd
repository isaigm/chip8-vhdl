library ieee;
use ieee.std_logic_1164.all;

entity priority_encoder is
    generic (
        N : positive := 16
    );
    port (
        data_in : in  std_logic_vector(N - 1 downto 0);
        found   : out std_logic;
        idx     : out integer range 0 to N
    );
end entity;

architecture rtl of priority_encoder is
    constant MID     : natural := N / 2;
    constant HI_SIZE : natural := N - MID;
    constant LO_SIZE : natural := MID;
begin

    gen_base: if N = 1 generate
        found <= data_in(0);
        idx   <= 0;
    end generate gen_base;

    gen_rec: if N > 1 generate
        signal left_found  : std_logic;
        signal right_found : std_logic;
        signal hi_idx      : integer range 0 to HI_SIZE;
        signal lo_idx      : integer range 0 to LO_SIZE;
    begin
        
        priority_encoder_hi : entity work.priority_encoder
            generic map (
                N => HI_SIZE
            )
            port map (
                data_in => data_in(N - 1 downto MID),
                found   => left_found,
                idx     => hi_idx
            );

        priority_encoder_low : entity work.priority_encoder
            generic map (
                N => LO_SIZE
            )
            port map (
                data_in => data_in(MID - 1 downto 0),
                found   => right_found,
                idx     => lo_idx
            );

        process(right_found, left_found, hi_idx, lo_idx)
        begin
            if right_found = '1' then
                idx <= lo_idx;
            elsif left_found = '1' then
                idx <= MID + hi_idx; 
            else
                idx <= 0;
            end if;
        end process;

        found <= right_found or left_found;
        
    end generate gen_rec;

end architecture rtl;