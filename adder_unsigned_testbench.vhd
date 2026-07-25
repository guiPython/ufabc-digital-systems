library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_unsigned_testbench is
end entity adder_unsigned_testbench;

architecture test of adder_unsigned_testbench is
    signal a, b : unsigned(12 downto 0) := (others => '0');
    signal res  : unsigned(12 downto 0);

    -- Build a 13-bit number: [sign | exponent | fractional]
    function number(
        sig : std_logic;
        fractional : natural;
        expoent  : natural
    ) return unsigned is
        variable value : unsigned(12 downto 0);
    begin
        value(12)          := sig;
        value(11 downto 8) := to_unsigned(expoent, 4);
        value(7 downto 0)  := to_unsigned(fractional, 8);
        return value;
    end function;
begin
    uut : entity work.adder_unsigned(arch)
        port map (
            a   => a,
            b   => b,
            res => res
        );

    stimulus : process
    begin
        -- Case 1: Different exponents and opposite signs. (Sort | Align | Subtraction)
        -- +0.10001010 * 2^3 + -0.11011110 * 2^4
        -- = -0.10011001 * 2^4
        a <= number('0', 138, 3);
        b <= number('1', 222, 4);

        -- +(bin(138) * 2^3) -(bin(222) * 2^4)
        -- +(bin(69) * 2^4) -(bin(222) * 2^4)
        -- -bin(222 - 69) * 2^4
        -- -bin(153) * 2^4
        wait for 200 ns;

        assert res = number('1', 153, 4)
            report "ERROR: expect 1010010011001 = -0.10011001 * 2^4"
            severity error;

        -- Case 2: Subtraction followed by a left shift. (Sort | Subtraction | Normalization)
        -- -0.10010000 * 2^3 + +0.10000000 * 2^3
        -- = -0.10000000 * 2^0
        a <= number('1', 144, 3);
        b <= number('0', 128, 3);

        -- -(bin(144) * 2^3) +(bin(128) * 2^3)
        -- -bin(144 - 128) * 2^3
        -- -bin(16) * 2^3
        -- -(00010000) * 2^3 => 3 leading zeros
        -- -bin(16 * 2^3) * 2^(3 - 3)
        -- -bin(128) * 2^0
        wait for 200 ns;

        assert res = number('1', 128, 0)
            report "ERROR: expect 1000010000000 = -0.10000000 * 2^0"
            severity error;

        -- Case 3: Underflow.
        -- -0.10000001 * 2^0 + +0.10000000 * 2^0
        -- = -0.00000000 * 2^0
        a <= number('1', 129, 0);
        b <= number('0', 128, 0);

        -- -bin(129 - 128) * 2^0
        -- -bin(1) * 2^0
        -- -00000001 * 2^0 => 7 leading zeros
        -- leading zeros > exponent => underflow
        wait for 200 ns;

        assert res = number('1', 0, 0)
            report "ERROR: expect 1000000000000 = -0.00000000 * 2^0 (underflow)"
            severity error;

        -- Case 4: Addition with carry and right shift. (Sort | Sum | Overflow Normalization)
        -- +0.10010000 * 2^3 + +0.10000000 * 2^3
        -- = +0.10001000 * 2^4
        a <= number('0', 144, 3);
        b <= number('0', 128, 3);

        -- +bin(144 + 128) * 2^3
        -- +bin(272) * 2^3
        -- +100010000 * 2^3 => bit[8] = 1
        -- +bin(272 / 2) * 2^(3 + 1)
        -- +bin(136) * 2^4
        wait for 200 ns;

        assert res = number('0', 136, 4)
            report "ERROR: expect 0010010001000 = +0.10001000 * 2^4 (overflow | carry)"
            severity error;

        report "All test cases passed."
            severity note;

        wait;
    end process stimulus;
end architecture test;
