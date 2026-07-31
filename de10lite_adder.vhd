library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_fp_adder is
    port (
        clk      : in  std_logic;                    
        reset_n  : in  std_logic;                    
        bt_clear : in  std_logic;                    
        bt_adv   : in  std_logic;                    
        sw       : in  std_logic_vector(9 downto 0); 
        hex0, hex1, hex2, hex3, hex4, hex5 : out std_logic_vector(7 downto 0) 
    );
end entity top_fp_adder;

architecture rtl of top_fp_adder is

    type state_type is (SET_SIGN_A, SET_FRAC_A, SET_EXP_A, 
                        SET_SIGN_B, SET_FRAC_B, SET_EXP_B, 
                        SHOW_RESULT);
    signal current_state : state_type;

    signal reg_a, reg_b : unsigned(12 downto 0) := (others => '0');
    signal result       : unsigned(12 downto 0);

    signal adv_edge, clear_edge : std_logic;

    component hex_to_sseg is
        port (
            hex  : in  std_logic_vector(3 downto 0);
            dp   : in  std_logic;
            sseg : out std_logic_vector(7 downto 0)
        );
    end component;

    component adder_unsigned is
        port (
            a, b : in unsigned (12 downto 0);
            res  : out unsigned (12 downto 0)
        );
    end component;

    signal disp_h0, disp_h1, disp_h2, disp_h3, disp_h4, disp_h5 : std_logic_vector(3 downto 0);

begin

    adder_inst : adder_unsigned
        port map (
            a   => reg_a,
            b   => reg_b,
            res => result
        );

    -- Detecção de borda para os botões (ativos em '0')
    process(clk)
        variable adv_reg, clear_reg : std_logic_vector(1 downto 0) := "11";
    begin
        if rising_edge(clk) then
            adv_reg := adv_reg(0) & bt_adv;
            clear_reg := clear_reg(0) & bt_clear;
        end if;
        adv_edge   <= '1' when (adv_reg = "10") else '0';
        clear_edge <= '1' when (clear_reg = "10") else '0';
    end process;

    -- FSM de Transição
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            current_state <= SET_SIGN_A;
            reg_a         <= (others => '0');
            reg_b         <= (others => '0');
        elsif rising_edge(clk) then
            if clear_edge = '1' then
                case current_state is
                    when SET_FRAC_A  => current_state <= SET_SIGN_A;
                    when SET_EXP_A   => current_state <= SET_FRAC_A;
                    when SET_SIGN_B  => current_state <= SET_EXP_A;
                    when SET_FRAC_B  => current_state <= SET_SIGN_B;
                    when SET_EXP_B   => current_state <= SET_FRAC_B;
                    when SHOW_RESULT => current_state <= SET_EXP_B;
                    when others      => current_state <= SET_SIGN_A;
                end case;
            elsif adv_edge = '1' then
                case current_state is
                    when SET_SIGN_A =>
                        reg_a(12) <= sw(9);
                        current_state <= SET_FRAC_A;
                    when SET_FRAC_A =>
                        reg_a(7 downto 0) <= unsigned(sw(7 downto 0));
                        current_state <= SET_EXP_A;
                    when SET_EXP_A =>
                        reg_a(11 downto 8) <= unsigned(sw(3 downto 0));
                        current_state <= SET_SIGN_B;
                    when SET_SIGN_B =>
                        reg_b(12) <= sw(9);
                        current_state <= SET_FRAC_B;
                    when SET_FRAC_B =>
                        reg_b(7 downto 0) <= unsigned(sw(7 downto 0));
                        current_state <= SET_EXP_B;
                    when SET_EXP_B =>
                        reg_b(11 downto 8) <= unsigned(sw(3 downto 0));
                        current_state <= SHOW_RESULT;
                    when SHOW_RESULT =>
                        current_state <= SET_SIGN_A;
                end case;
            end if;
        end if;
    end process;

    -- Lógica de exibição nos displays
    process(current_state, sw, result)
    begin
        -- Limpa padrão
        disp_h4 <= "0000"; disp_h3 <= "0000"; 
        disp_h2 <= "0000"; disp_h1 <= "0000"; disp_h0 <= "0000";

        case current_state is
            when SET_SIGN_A =>
                disp_h5 <= "0001"; -- Mostra '1' no HEX5 (Etapa 1: Sinal de A)
                disp_h0 <= "0000" & sw(9); -- Mostra o estado atual do switch de sinal (0 ou 1)

            when SET_FRAC_A =>
                disp_h5 <= "0010"; -- Mostra '2' no HEX5 (Etapa 2: Fração de A)
                disp_h1 <= "00" & sw(7 downto 6); -- Dividindo os 8 bits nos displays
                disp_h0 <= sw(5 downto 2);        -- (Exemplo de visualização em nibbles)
                -- Nota: Você pode ajustar como prefere espalhar os 8 bits de sw nos displays inferiores

            when SET_EXP_A =>
                disp_h5 <= "0011"; -- Mostra '3' no HEX5 (Etapa 3: Expoente de A)
                disp_h0 <= "00" & sw(3 downto 2); -- Mostra os 4 switches do expoente

            when SET_SIGN_B =>
                disp_h5 <= "0100"; -- Mostra '4' no HEX5 (Etapa 4: Sinal de B)
                disp_h0 <= "0000" & sw(9);

            when SET_FRAC_B =>
                disp_h5 <= "0101"; -- Mostra '5' no HEX5 (Etapa 5: Fração de B)
                disp_h1 <= "00" & sw(7 downto 6);
                disp_h0 <= sw(5 downto 2);

            when SET_EXP_B =>
                disp_h5 <= "0110"; -- Mostra '6' no HEX5 (Etapa 6: Expoente de B)
                disp_h0 <= "00" & sw(3 downto 2);

            when SHOW_RESULT =>
                disp_h5 <= "1110"; -- Mostra 'E' ou 'r' (1110 = 'E') indicando Resultado
                disp_h3 <= "00" & std_logic_vector(result(11 downto 10));
                disp_h2 <= std_logic_vector(result(9 downto 8));
                disp_h1 <= std_logic_vector(result(7 downto 4));
                disp_h0 <= std_logic_vector(result(3 downto 0));
        end case;
    end process;

    -- Mapeamento dos 6 displays
    sseg0 : hex_to_sseg port map (hex => disp_h0, dp => '1', sseg => hex0);
    sseg1 : hex_to_sseg port map (hex => disp_h1, dp => '1', sseg => hex1);
    sseg2 : hex_to_sseg port map (hex => disp_h2, dp => '1', sseg => hex2);
    sseg3 : hex_to_sseg port map (hex => disp_h3, dp => '1', sseg => hex3);
    sseg4 : hex_to_sseg port map (hex => disp_h4, dp => '1', sseg => hex4);
    sseg5 : hex_to_sseg port map (hex => disp_h5, dp => '1', sseg => hex5);

end architecture rtl;