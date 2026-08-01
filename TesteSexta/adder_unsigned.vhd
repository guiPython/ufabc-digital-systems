library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_unsigned is
    port (
        -- 13 bits numbers [sign | exp => [11..8] | frac => [7..0]]
        a, b : in unsigned (12 downto 0);

        -- 13 bits numbers [sign | exp => [11..8] | frac => [7..0]]
        res : out unsigned (12 downto 0)
    );
end adder_unsigned;

architecture arch of adder_unsigned is

    -- Funções auxiliares de extração
    function sig(n : unsigned(12 downto 0)) return std_logic is
    begin
        return n(12);
    end function;

    function expoent(n : unsigned(12 downto 0)) return unsigned is
    begin
        return n(11 downto 8);
    end function;

    function fractional(n : unsigned(12 downto 0)) return unsigned is
    begin
        return n(7 downto 0);
    end function;

begin

    process (a, b)
        -- Variáveis locais para etapas combinacionais seguras
        variable big, small : unsigned(12 downto 0);
        variable exp_big, exp_small : integer;
        variable diff : integer;
        variable frac_big, frac_small_aligned : unsigned(7 downto 0);
        variable sum_temp : signed(9 downto 0); -- signed para suportar subtração segura
        variable abs_sum : unsigned(8 downto 0);
        variable res_sign : std_logic;
        variable l_zeros : integer;
        variable new_exp : integer;
        variable final_frac : unsigned(7 downto 0);
        variable final_exp : unsigned(3 downto 0);
    begin
        -- 1st stage : sort to find the larger number (comparando valor absoluto / expoente + fração)
        if (expoent(a) & fractional(a)) >= (expoent(b) & fractional(b)) then
            big := a;
            small := b;
        else
            big := b;
            small := a;
        end if;

        exp_big   := to_integer(expoent(big));
        exp_small := to_integer(expoent(small));
        res_sign  := sig(big); -- O sinal do resultado pré-assume o do maior

        -- 2nd stage : align smaller number
        diff := exp_big - exp_small;
        if diff > 8 then
            -- Se a diferença for muito grande, o menor número vira zero perto do maior
            frac_small_aligned := (others => '0');
        else
            frac_small_aligned := shift_right(fractional(small), diff);
        end if;

        frac_big := fractional(big);

        -- 3rd stage : add / subtract based on signs
        if sig(big) = sig(small) then
            -- Soma se os sinais forem iguais
            abs_sum := ('0' & frac_big) + ('0' & frac_small_aligned);
            res_sign := sig(big);
        else
            -- Subtração se os sinais forem diferentes
            if frac_big >= frac_small_aligned then
                abs_sum := ('0' & frac_big) - ('0' & frac_small_aligned);
                res_sign := sig(big);
            else
                abs_sum := ('0' & frac_small_aligned) - ('0' & frac_big);
                -- Inverte o sinal se o menor (subtraído) for maior que o big em magnitude
                if sig(big) = '0' then
                    res_sign := '1';
                else
                    res_sign := '0';
                end if;
            end if;
        end if;

        -- Se a soma for zero, zera tudo de forma limpa
        if abs_sum = 0 then
            res <= (others => '0');
        else
            -- 4th stage : count leading zeros in abs_sum (olhando os 8 bits mais baixos de abs_sum)
            l_zeros := 0;
            if abs_sum(7) = '1' then l_zeros := 0;
            elsif abs_sum(6) = '1' then l_zeros := 1;
            elsif abs_sum(5) = '1' then l_zeros := 2;
            elsif abs_sum(4) = '1' then l_zeros := 3;
            elsif abs_sum(3) = '1' then l_zeros := 4;
            elsif abs_sum(2) = '1' then l_zeros := 5;
            elsif abs_sum(1) = '1' then l_zeros := 6;
            else l_zeros := 7;
            end if;

            -- 5th stage : normalize with overflow and underflow checks
            if abs_sum(8) = '1' then
                -- Houve estouro para cima (carry out)
                new_exp := exp_big + 1;
                if new_exp > 15 then
                    -- Overflow máximo do expoente de 4 bits
                    final_exp := "1111";
                    final_frac := "11111111";
                else
                    final_exp := to_unsigned(new_exp, 4);
                    final_frac := abs_sum(8 downto 1); -- desloca pra direita para compensar o exp
                end if;
            else
                -- Normalização por leading zeros
                new_exp := exp_big - l_zeros;
                if new_exp < 0 then
                    -- Underflow (expoente negativo geraria número menor que o suporte)
                    final_exp := (others => '0');
                    final_frac := (others => '0');
                else
                    final_exp := to_unsigned(new_exp, 4);
                    -- Desloca à esquerda para normalizar
                    if l_zeros <= exp_big then
                        final_frac := shift_left(abs_sum(7 downto 0), l_zeros);
                    else
                        final_frac := shift_left(abs_sum(7 downto 0), exp_big);
                    end if;
                end if;
            end if;

            -- Montagem final do resultado [sign | exp (11..8) | frac (7..0)]
            res(12) <= res_sign;
            res(11 downto 8) <= final_exp;
            res(7 downto 0) <= final_frac;
        end if;
    end process;

end arch;