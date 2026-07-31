library ieee;
use ieee.std_logic_1164.all;

entity hex_to_sseg is
    port (
        hex  : in  std_logic_vector(3 downto 0);
        dp   : in  std_logic;
        sseg : out std_logic_vector(7 downto 0)
    );
end entity hex_to_sseg;

architecture hex_to_sseg_arch of hex_to_sseg is
begin
    with hex select
        sseg(6 downto 0) <=
            "0000001" when "0000", -- 0
            "1001111" when "0001", -- 1
            "0010010" when "0010", -- 2
            "0000110" when "0011", -- 3
            "1001100" when "0100", -- 4
            "0100100" when "0101", -- 5
            "0100000" when "0110", -- 6
            "0001111" when "0111", -- 7
            "0000000" when "1000", -- 8
            "0000100" when "1001", -- 9
            "0001000" when "1010", -- A
            "1100000" when "1011", -- b
            "0110001" when "1100", -- C
            "1000010" when "1101", -- d
            "0110000" when "1110", -- E
            "0111000" when "1111", -- F
            "1111111" when others;

    sseg(7) <= dp;
end architecture hex_to_sseg_arch;
