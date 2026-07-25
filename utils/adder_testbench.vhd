library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_testbench is
end entity adder_testbench;

architecture test of adder_testbench is
    signal sign1, sign2 : std_logic := '0';
    signal exp1, exp2   : std_logic_vector(3 downto 0) := (others => '0');
    signal frac1, frac2 : std_logic_vector(7 downto 0) := (others => '0');

    signal sign_out : std_logic;
    signal exp_out  : std_logic_vector(3 downto 0);
    signal frac_out : std_logic_vector(7 downto 0);
begin
    uut : entity work.adder(arch)
        port map (
            sign1    => sign1,
            sign2    => sign2,
            exp1     => exp1,
            exp2     => exp2,
            frac1    => frac1,
            frac2    => frac2,
            sign_out => sign_out,
            exp_out  => exp_out,
            frac_out => frac_out
        );

    stimulus : process
    begin
        -- Case 1: Different exponents and opposite signs. (Sort | Allign | Subtraction)
        -- +0.10001010 * 2^3 + -0.11011110 * 2^4
        -- = -0.10011001 * 2^4
        sign1 <= '0';
        exp1  <= std_logic_vector(to_unsigned(3, exp1'length));
        frac1 <= std_logic_vector(to_unsigned(138, frac1'length));
        sign2 <= '1';
        exp2  <= std_logic_vector(to_unsigned(4, exp2'length));
        frac2 <= std_logic_vector(to_unsigned(222, frac2'length));

        -- +(bin(69) * 2ˆ4) -(bin(222) * 2ˆ4)
        -- +(bin(69) * 2ˆ4) -(bin(222) * 2ˆ4)
        -- -bin(222 - 69) * 2ˆ4
        -- -bin(153) * 2ˆ4
        wait for 200 ns;

        assert sign_out = '1' and
               unsigned(exp_out) = to_unsigned(4, exp_out'length) and
               unsigned(frac_out) = to_unsigned(153, frac_out'length)
            report "ERROR: expect -0.10011001 * 2^4"
            severity error;

        -- Case 2: Subtraction followed by a left shift. (Sort | Subtraction | Normalization)
        -- -0.10010000 * 2^3 + +0.10000000 * 2^3
        -- -0.10000000 * 2^0
        sign1 <= '1';
        exp1  <= std_logic_vector(to_unsigned(3, exp1'length));
        frac1 <= std_logic_vector(to_unsigned(144, frac1'length));
        sign2 <= '0';
        exp2  <= std_logic_vector(to_unsigned(3, exp2'length));
        frac2 <= std_logic_vector(to_unsigned(128, frac2'length));

        -- -(bin(144) * 2ˆ3) +(bin(128) * 2ˆ3)
        -- -bin(144 - 128) * 2ˆ4
        -- -bin(16) * 2ˆ0
        -- -(00010000) * 2ˆ3 => 3 leading zeros
        -- -bin(16 * 2ˆ3) * 2ˆ(3 - leading zeros)
        -- -bin(128) * 2ˆ0
        wait for 200 ns;

        assert sign_out = '1' and
               unsigned(exp_out) = to_unsigned(0, exp_out'length) and
               unsigned(frac_out) = to_unsigned(128, frac_out'length)
            report "ERROR: expect -0.10000000 * 2^0"
            severity error;

        -- Case 3: Underflow.
        -- -0.10000001 * 2^0 + +0.10000000 * 2^0
        -- -0.00000000 * 2^0
        sign1 <= '1';
        exp1  <= (others => '0');
        frac1 <= std_logic_vector(to_unsigned(129, frac1'length));
        sign2 <= '0';
        exp2  <= (others => '0');
        frac2 <= std_logic_vector(to_unsigned(128, frac2'length));
        wait for 200 ns;

        -- -bin(129 - 128) * 2ˆ0
        -- -bin(1) * 2ˆ0
        -- -00000001 * 2ˆ0 => 7 leading zeros [leading zeros > expoent => underflow]
        assert unsigned(exp_out) = to_unsigned(0, exp_out'length) and
               unsigned(frac_out) = to_unsigned(0, frac_out'length)
            report "ERROR: expect -0.00000000 * 2^0 (underflow)"
            severity error;

        -- Case 4: Addition with carry and right shift. (Sort | Sum | Overflow Normalization)
        -- +0.10010000 * 2^3 + +0.10000000 * 2^3
        -- +0.10001000 * 2^4
        sign1 <= '0';
        exp1  <= std_logic_vector(to_unsigned(3, exp1'length));
        frac1 <= std_logic_vector(to_unsigned(144, frac1'length));
        sign2 <= '0';
        exp2  <= std_logic_vector(to_unsigned(3, exp2'length));
        frac2 <= std_logic_vector(to_unsigned(128, frac2'length));
        wait for 200 ns;

        -- +bin(144 + 128) * 2ˆ3
        -- +bin(272) * 2ˆ3
        -- +100010000 * 2ˆ3 => bit[8] = 1 increase expoent and fractional bin(272/2)
        -- +bin(272/2) * 2ˆ(3 + 1)
        -- +bin(136) * 2ˆ4
        assert sign_out = '0' and
               unsigned(exp_out) = to_unsigned(4, exp_out'length) and
               unsigned(frac_out) = to_unsigned(136, frac_out'length)
            report "ERROR: expected +0.10001000 * 2^4 (overflow | carry)"
            severity error;

        report "All test cases passed."
            severity note;

        wait;
    end process stimulus;
end architecture test;
