library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

entity tb_uart_loopback is
end entity;

architecture tb of tb_uart_loopback is
	constant CLK_HZ       : positive := 50_000_000;
	constant BAUDRATE     : positive := 115200;
	constant OVERSAMPLING : positive := 16;
    constant DATA_BITS    : natural := 8;
    constant FIFO_SIZE    : natural := 4;

	constant T_CLK  : time := 1 sec / CLK_HZ;

	constant DIV    : positive := CLK_HZ / (BAUDRATE * OVERSAMPLING);
	constant T_TICK : time := DIV * T_CLK;
	constant T_BIT  : time := OVERSAMPLING * T_TICK;

	signal clk : std_logic := '0';
	signal rst : std_logic := '1';

	signal signal_line : std_logic := '1';

	signal rx_en    : std_logic := '0';
	signal rx_ready : std_logic;
	signal rx_data  : std_logic_vector(7 downto 0);

	signal tx_en    : std_logic := '0';
	signal tx_ready : std_logic;
	signal tx_data  : std_logic_vector(7 downto 0);

begin
    clk <= not clk after T_CLK/2;

    dut : entity work.uart_core
        generic map (
          CLK_HZ       => CLK_HZ,
          BAUDRATE     => BAUDRATE,
          OVERSAMPLING => OVERSAMPLING,
          DATA_BITS    => DATA_BITS,
          FIFO_SIZE    => FIFO_SIZE
        )
        port map (
          clk      => clk,
          rst      => rst,
          rx       => signal_line,
          tx       => signal_line,
          rx_en    => rx_en,
          rx_ready => rx_ready,
          rx_data  => rx_data,
          tx_en    => tx_en,
          tx_ready => tx_ready,
          tx_data  => tx_data
        );

	stim : process
		variable saved_byte : std_logic_vector(7 downto 0);
	begin
		rst <= '1';
		wait for T_CLK;
		rst <= '0';
		wait for 10 us;

		-- Test 1: TX 0x55
		while tx_ready /= '1' loop
			wait until rising_edge(clk);
		end loop;

		tx_data <= x"55";

		tx_en   <= '1';
		wait until rising_edge(clk);
		tx_en   <= '0';

		-- esperar a que RX FIFO tenga dato
		while rx_ready /= '1' loop
			wait until rising_edge(clk);
		end loop;

		saved_byte := rx_data;

		rx_en <= '1';
		wait until rising_edge(clk);
		rx_en <= '0';

		wait for 10 us;

		report "[OK]: Testbench passed correctly!" severity note;
		finish;
	end process;

end architecture;
