library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_level is
end tb_top_level;

architecture behavior of tb_top_level is
    -- Declarando o Top Level atualizado
    component top_level
    port(
        SW   : in  std_logic_vector(9 downto 0);
        HEX0 : out std_logic_vector(6 downto 0);
        HEX1 : out std_logic_vector(6 downto 0);
        HEX2 : out std_logic_vector(6 downto 0);
        HEX3 : out std_logic_vector(6 downto 0)
    );
    end component;

    -- Entradas
    signal tb_sw : std_logic_vector(9 downto 0) := (others => '0');

    -- Saídas (Os displays virtuais)
    signal tb_hex0 : std_logic_vector(6 downto 0);
    signal tb_hex1 : std_logic_vector(6 downto 0);
    signal tb_hex2 : std_logic_vector(6 downto 0);
    signal tb_hex3 : std_logic_vector(6 downto 0);

begin
    -- Conectando os fios virtuais na nossa placa
    dut: top_level port map (
        SW   => tb_sw,
        HEX0 => tb_hex0,
        HEX1 => tb_hex1,
        HEX2 => tb_hex2,
        HEX3 => tb_hex3
    );

    -- Processo de estímulo (O "dedo" mexendo nas chaves)
    stim_proc: process
    begin
        -- Teste 1: Todas as chaves em zero
        tb_sw <= "0000000000";
        wait for 10 ns;

        -- Teste 2: Ligando algumas chaves (ex: 0x180 = 0110000000)
        tb_sw <= "0110000000";
        wait for 10 ns;

        -- Teste 3: Outra combinacao de chaves (ex: 0x2AA = 1010101010)
        tb_sw <= "1010101010";
        wait for 10 ns;

        wait;
    end process;
end behavior;