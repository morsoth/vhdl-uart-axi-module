library ieee;
use ieee.std_logic_1164.all;

entity uart_baudgen is
    generic (
        CLK_HZ       : positive := 50_000_000;
        BAUDRATE     : positive := 115200;
        OVERSAMPLING : positive := 16
    );

    port(
        clk       : in std_logic;
        rst       : in std_logic;
        uart_tick : out std_logic
    );
end entity;

architecture rtl of uart_baudgen is
    constant DIV : positive := CLK_HZ / (BAUDRATE * OVERSAMPLING);

    signal count : natural range 0 to DIV-1 := 0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            uart_tick <= '0';
            
            if rst = '1' then
                count <= 0;

            elsif count = DIV-1 then
                count <= 0;
                uart_tick <= '1';

            else
                count <= count + 1;
            end if;
        end if;

    end process;

end architecture;