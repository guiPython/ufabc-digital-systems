library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
    port (
        -- 10 chaves da placa
        SW   : in std_logic_vector(9 downto 0); 
        
        -- 4 Displays de 7 segmentos da DE10-Lite
        HEX0 : out std_logic_vector(6 downto 0);
        HEX1 : out std_logic_vector(6 downto 0);
        HEX2 : out std_logic_vector(6 downto 0);
        HEX3 : out std_logic_vector(6 downto 0)
    );
end top_level;

architecture arch of top_level is

    -- Declarando a classe do Somador
    component adder_unsigned is
        port (
            a, b : in unsigned(12 downto 0);
            res  : out unsigned(12 downto 0)
        );
    end component;

    -- Declarando a classe do Decodificador do Display
    component hex_to_sseg is
        port (
            hex_in   : in  std_logic_vector(3 downto 0);
            sseg_out : out std_logic_vector(6 downto 0)
        );
    end component;

    -- Variaveis internas
    signal operando_a : unsigned(12 downto 0) := (others => '0');
    signal operando_b : unsigned(12 downto 0) := (others => '0');
    signal resultado  : unsigned(12 downto 0) := (others => '0');
    
    -- Vetor extra para facilitar a quebra dos 13 bits para os displays
    signal res_logic  : std_logic_vector(15 downto 0) := (others => '0');

begin

    operando_a <= "0" & "0010" & "10000000";
    operando_b <= unsigned("0" & "00" & SW(9 downto 0));

    -- Instancia 1: O Somador
    somador_inst: adder_unsigned port map (
        a   => operando_a,
        b   => operando_b,
        res => resultado
    );

    -- Preenchendo com zeros a esquerda para fechar 16 bits (4 blocos de 4)
    res_logic <= "000" & std_logic_vector(resultado);

    -- Instancia 2: Display 0 (4 bits menos significativos)
    disp0: hex_to_sseg port map (
        hex_in   => res_logic(3 downto 0),
        sseg_out => HEX0
    );

    -- Instancia 3: Display 1
    disp1: hex_to_sseg port map (
        hex_in   => res_logic(7 downto 4),
        sseg_out => HEX1
    );

    -- Instancia 4: Display 2
    disp2: hex_to_sseg port map (
        hex_in   => res_logic(11 downto 8),
        sseg_out => HEX2
    );

    -- Instancia 5: Display 3 (Mais significativos)
    disp3: hex_to_sseg port map (
        hex_in   => res_logic(15 downto 12),
        sseg_out => HEX3
    );

end arch;