library ieee;
use ieee.std_logic_1164.all;

entity hex_to_sseg is
    port (
        -- Entrada: 4 bits representando um numero de 0 a F (0 a 15)
        hex_in : in  std_logic_vector(3 downto 0);
        -- Saida: 7 bits para os segmentos (A, B, C, D, E, F, G)
        sseg_out : out std_logic_vector(6 downto 0)
    );
end hex_to_sseg;

architecture arch of hex_to_sseg is
begin
    -- Tabela verdade do display da DE10-Lite (0 acende, 1 apaga)
    process(hex_in)
    begin
        case hex_in is
            when "0000" => sseg_out <= "1000000"; -- 0
            when "0001" => sseg_out <= "1111001"; -- 1
            when "0010" => sseg_out <= "0100100"; -- 2
            when "0011" => sseg_out <= "0110000"; -- 3
            when "0100" => sseg_out <= "0011001"; -- 4
            when "0101" => sseg_out <= "0010010"; -- 5
            when "0110" => sseg_out <= "0000010"; -- 6
            when "0111" => sseg_out <= "1111000"; -- 7
            when "1000" => sseg_out <= "0000000"; -- 8
            when "1001" => sseg_out <= "0010000"; -- 9
            when "1010" => sseg_out <= "0001000"; -- A
            when "1011" => sseg_out <= "0000011"; -- b
            when "1100" => sseg_out <= "1000110"; -- C
            when "1101" => sseg_out <= "0100001"; -- d
            when "1110" => sseg_out <= "0000110"; -- E
            when "1111" => sseg_out <= "0001110"; -- F
            when others => sseg_out <= "1111111"; -- Apagado
        end case;
    end process;
end arch;