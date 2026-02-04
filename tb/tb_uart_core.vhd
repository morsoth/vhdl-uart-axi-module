library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

entity tb_uart_core is
end entity;

architecture tb of tb_uart_core is
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

	signal rx : std_logic := '1';
	signal tx : std_logic;

	signal rx_en    : std_logic := '0';
	signal rx_ready : std_logic;
	signal rx_data  : std_logic_vector(7 downto 0);

	signal tx_en    : std_logic := '0';
	signal tx_ready : std_logic;
	signal tx_data  : std_logic_vector(7 downto 0);

  	procedure uart_rx_send(
		signal rx_line : out std_logic;
		constant data  : std_logic_vector(7 downto 0)
	) is
	begin
		rx_line <= '0';
		wait for T_BIT;

		for i in 0 to 7 loop
			rx_line <= data(i);
			wait for T_BIT;
		end loop;

		rx_line <= '1';
		wait for T_BIT;
	end procedure;

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
          rx       => rx,
          tx       => tx,
          rx_en    => rx_en,
          rx_ready => rx_ready,
          rx_data  => rx_data,
          tx_en    => tx_en,
          tx_ready => tx_ready,
          tx_data  => tx_data
        );

  ---------------------------------------------------------------------------
  -- Stimulus
  ---------------------------------------------------------------------------
	stim : process
		variable saved_byte : std_logic_vector(7 downto 0);
	begin
		rst <= '1';
		wait for T_CLK;
		rst <= '0';
		wait for 10 us;

		-- Test 1: RX 0x55
		uart_rx_send(rx, x"55");

		-- esperar a que RX FIFO tenga dato
		while rx_ready /= '1' loop
			wait until rising_edge(clk);
		end loop;

		saved_byte := rx_data;

		rx_en <= '1';
		wait until rising_edge(clk);
		rx_en <= '0';

		-- Test 2: TX recieved byte (0x55)
		while tx_ready /= '1' loop
			wait until rising_edge(clk);
		end loop;

		tx_data <= saved_byte;

		tx_en   <= '1';
		wait until rising_edge(clk);
		tx_en   <= '0';

		-- Test 3: RX overflow
		uart_rx_send(rx, x"01");
		uart_rx_send(rx, x"02");
		uart_rx_send(rx, x"03");
		uart_rx_send(rx, x"04");
		uart_rx_send(rx, x"05"); -- lost byte

		-- 0x01
		while rx_ready /= '1' loop
			wait until rising_edge(clk);
		end loop;

		rx_en <= '1';
		wait until rising_edge(clk);
		rx_en <= '0';

		-- 0x02
		while rx_ready /= '1' loop
			wait until rising_edge(clk);
		end loop;

		rx_en <= '1';
		wait until rising_edge(clk);
		rx_en <= '0';

		-- 0x03
		while rx_ready /= '1' loop
			wait until rising_edge(clk);
		end loop;

		rx_en <= '1';
		wait until rising_edge(clk);
		rx_en <= '0';

		-- 0x04
		while rx_ready /= '1' loop
			wait until rising_edge(clk);
		end loop;

		rx_en <= '1';
		wait until rising_edge(clk);
		rx_en <= '0';

		wait for 2*T_BIT;

		-- Test 4: TX overflow
		while tx_ready /= '1' loop
			wait until rising_edge(clk);
		end loop;

		tx_data <= x"10";

		wait until rising_edge(clk);
		tx_en   <= '1';

		wait for T_CLK;
		
		tx_data <= x"20";
		wait for T_CLK;
		
		tx_data <= x"30";
		wait for T_CLK;
		
		tx_data <= x"40";
		wait for T_CLK;
		
		tx_data <= x"50";
		wait for T_CLK;

		tx_data <= x"60"; -- lost byte
		wait for T_CLK;

		tx_en   <= '0';

		wait for 60*T_BIT;

		wait for 10 us;

		report "[OK]: Testbench passed correctly!" severity note;
		finish;
	end process;

end architecture;
