library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
    port (
        SW : in std_logic_vector(9 downto 0);
        RESULTADO_OUT : out std_logic_vector(12 downto 0)
    );
end top_level;

architecture arch of top_level is

    component adder_unsigned is
        port (
            a, b : in unsigned(12 downto 0);
            res  : out unsigned(12 downto 0)
        );
    end component;

    -- A MAGICA ESTA AQUI: Inicializamos com 0 para evitar o estado U no tempo zero
    signal operando_a : unsigned(12 downto 0) := (others => '0');
    signal operando_b : unsigned(12 downto 0) := (others => '0');
    signal resultado  : unsigned(12 downto 0) := (others => '0');

begin

    operando_a <= "0" & "0010" & "10000000";
    operando_b <= unsigned("0" & "00" & SW(9 downto 0));

    somador_inst: adder_unsigned
        port map (
            a   => operando_a,
            b   => operando_b,
            res => resultado
        );

    RESULTADO_OUT <= std_logic_vector(resultado);

end arch;