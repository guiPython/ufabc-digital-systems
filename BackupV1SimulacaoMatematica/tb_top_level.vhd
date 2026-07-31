library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_level is
    -- Um Testbench não tem portas de entrada ou saída
end tb_top_level;

architecture sim of tb_top_level is

    -- 1. Declaramos o componente que vamos testar (nosso Top Level)
    component top_level is
        port (
            SW : in std_logic_vector(9 downto 0);
            RESULTADO_OUT : out std_logic_vector(12 downto 0)
        );
    end component;

    -- 2. Criamos sinais (fios virtuais) para conectar na placa virtual
    signal tb_SW : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_RESULTADO : std_logic_vector(12 downto 0);

begin

    -- 3. Instanciamos a placa (DUT - Device Under Test)
    DUT: top_level port map (
        SW => tb_SW,
        RESULTADO_OUT => tb_RESULTADO
    );

    -- 4. Processo de estímulo: Simula o usuário mexendo nas chaves (SW)
    estimulos: process
    begin
        -- Cenário 1: Todas as chaves desligadas
        tb_SW <= "0000000000";
        wait for 10 ns;

        -- Cenário 2: Ligando algumas chaves (Alterando o Operando B)
        tb_SW <= "0110000000";
        wait for 10 ns;

        -- Cenário 3: Ligando outras chaves
        tb_SW <= "1010101010";
        wait for 10 ns;

        -- Pausa a simulação
        wait;
    end process;

end sim;