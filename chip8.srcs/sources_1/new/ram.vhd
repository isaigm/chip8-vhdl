library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity ram is
    Port (clk: in std_logic;
        we: in std_logic;
        write_addr: in std_logic_vector(11 downto 0);
        read_addr: in std_logic_vector(11 downto 0);
        write_data: in std_logic_vector(7 downto 0);
        read_data: out std_logic_vector(7 downto 0)
     );
end ram;

architecture Behavioral of ram is
    type ram_t is array (0 to 4095) of std_logic_vector(7 downto 0);

    -- IBM logo cargado a partir de 0x200 (512), resto en ceros
    signal mem: ram_t := (
        512 => x"00", 513 => x"e0", 514 => x"a2", 515 => x"2a",
        516 => x"60", 517 => x"0c", 518 => x"61", 519 => x"08",
        520 => x"d0", 521 => x"1f", 522 => x"70", 523 => x"09",
        524 => x"a2", 525 => x"39", 526 => x"d0", 527 => x"1f",
        528 => x"a2", 529 => x"48", 530 => x"70", 531 => x"08",
        532 => x"d0", 533 => x"1f", 534 => x"70", 535 => x"04",
        536 => x"a2", 537 => x"57", 538 => x"d0", 539 => x"1f",
        540 => x"70", 541 => x"08", 542 => x"a2", 543 => x"66",
        544 => x"d0", 545 => x"1f", 546 => x"70", 547 => x"08",
        548 => x"a2", 549 => x"75", 550 => x"d0", 551 => x"1f",
        552 => x"12", 553 => x"28", 554 => x"ff", 555 => x"00",
        556 => x"ff", 557 => x"00", 558 => x"3c", 559 => x"00",
        560 => x"3c", 561 => x"00", 562 => x"3c", 563 => x"00",
        564 => x"3c", 565 => x"00", 566 => x"ff", 567 => x"00",
        568 => x"ff", 569 => x"ff", 570 => x"00", 571 => x"ff",
        572 => x"00", 573 => x"38", 574 => x"00", 575 => x"3f",
        576 => x"00", 577 => x"3f", 578 => x"00", 579 => x"38",
        580 => x"00", 581 => x"ff", 582 => x"00", 583 => x"ff",
        584 => x"80", 585 => x"00", 586 => x"e0", 587 => x"00",
        588 => x"e0", 589 => x"00", 590 => x"80", 591 => x"00",
        592 => x"80", 593 => x"00", 594 => x"e0", 595 => x"00",
        596 => x"e0", 597 => x"00", 598 => x"80", 599 => x"f8",
        600 => x"00", 601 => x"fc", 602 => x"00", 603 => x"3e",
        604 => x"00", 605 => x"3f", 606 => x"00", 607 => x"3b",
        608 => x"00", 609 => x"39", 610 => x"00", 611 => x"f8",
        612 => x"00", 613 => x"f8", 614 => x"03", 615 => x"00",
        616 => x"07", 617 => x"00", 618 => x"0f", 619 => x"00",
        620 => x"bf", 621 => x"00", 622 => x"fb", 623 => x"00",
        624 => x"f3", 625 => x"00", 626 => x"e3", 627 => x"00",
        628 => x"43", 629 => x"e0", 630 => x"00", 631 => x"e0",
        632 => x"00", 633 => x"80", 634 => x"00", 635 => x"80",
        636 => x"00", 637 => x"80", 638 => x"00", 639 => x"80",
        640 => x"00", 641 => x"e0", 642 => x"00", 643 => x"e0",
        others => x"00"
    );
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                mem(to_integer(unsigned(write_addr))) <= write_data;
            end if;
        end if;
    end process;

    read_data <= mem(to_integer(unsigned(read_addr)));
end Behavioral;