library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

entity tb_uart_rx is
end entity;

architecture tb of tb_uart_rx is
	constant CLK_HZ       : natural := 50_000_000;
	constant BAUDRATE     : natural := 115200;
	constant OVERSAMPLING : natural := 16;
	constant DATA_BITS    : natural := 8;

	constant T_CLK  : time := 1 sec / CLK_HZ;

	constant DIV    : positive := CLK_HZ / (BAUDRATE * OVERSAMPLING);
	constant T_TICK : time := DIV * T_CLK;
	constant T_BIT  : time := OVERSAMPLING * T_TICK;

	signal clk       : std_logic := '0';
	signal rst       : std_logic := '1';
	signal uart_tick : std_logic := '0';

	signal rx        : std_logic := '1';
	signal rx_valid  : std_logic;
	signal rx_data   : std_logic_vector(DATA_BITS-1 downto 0);

	signal data_to_send : std_logic_vector(DATA_BITS-1 downto 0);

	procedure send_uart_frame(
		signal rx_line : out std_logic;
		signal data : in std_logic_vector(DATA_BITS-1 downto 0)
	) is
	begin
		rx_line <= '0';
		wait for T_BIT;
		
		for i in 0 to DATA_BITS-1 loop
			rx_line <= data(i);
			wait for T_BIT;
		end loop;

		rx_line <= '1';
		wait for T_BIT;

		wait until rx_valid = '1';
		
		assert rx_data = data
			report "[ERROR]: expected " & to_hstring(data) & ", got " & to_hstring(rx_data) severity error;
	end procedure;

begin
	u_baudgen: entity work.uart_baudgen
		generic map (
			CLK_HZ       => CLK_HZ,
			BAUDRATE     => BAUDRATE,
			OVERSAMPLING => OVERSAMPLING
		)
		port map (
			clk 	  => clk,
			rst 	  => rst,
			uart_tick => uart_tick			
		);
	
	u_rx: entity work.uart_rx
		generic map (
			DATA_BITS => DATA_BITS,
			OVERSAMPLING => OVERSAMPLING
		)
		port map (
			clk 	  => clk,
			rst 	  => rst,
			uart_tick => uart_tick,
			rx		  => rx,
			rx_valid  => rx_valid,
			rx_data	  => rx_data
		);

  	clk <= not clk after T_CLK/2;

	p_tb : process
	begin
		rst <= '1';
		wait for T_CLK;
		rst <= '0';
		wait for 10 us;

		-- Test 1: Long idle
        for i in 0 to 9 loop            
			assert rx_valid = '0'
				report "[ERROR]: rx_valid active on idle"
				severity error;

            wait for T_BIT;
		end loop;

		-- Test 2: 0x5A --
		data_to_send <= x"5A";
		send_uart_frame(rx, data_to_send);
		wait for 5*T_CLK;

		-- Test 3: 0x00 --
		data_to_send <= x"00";
		send_uart_frame(rx, data_to_send);
		wait for 5*T_CLK;

		-- Test 4: 0xFF --
		data_to_send <= x"FF";
		send_uart_frame(rx, data_to_send);
		wait for 5*T_CLK;

		-- Test 5: 0xAA --
		data_to_send <= x"AA";
		send_uart_frame(rx, data_to_send);
		wait for 5*T_CLK;

		-- Test 6: LSB only (0x01) --
		data_to_send <= x"01";
		send_uart_frame(rx, data_to_send);
		wait for 5*T_CLK;

		-- Test 7: MSB only (0x80) --
		data_to_send <= x"80";
		send_uart_frame(rx, data_to_send);
		wait for 5*T_CLK;

		-- Test 8: Back-to-back (no idle) --
		data_to_send <= x"12";
		send_uart_frame(rx, data_to_send);
		data_to_send <= x"34";
		send_uart_frame(rx, data_to_send);
		wait for 5*T_CLK;

		-- Test 9: False start --
		data_to_send <= (others => '0');

		rx <= '0';
		wait for T_BIT/4;
		rx <= '1';
		wait for 2*T_BIT;
		assert rx_valid = '0'
			report "[ERROR]: rx_valid active after false start"
			severity error;

		-- Test 10: Stop bit at 0 --
		data_to_send <= x"A5";

		rx <= '0';
		wait for T_BIT;

		for i in 0 to DATA_BITS-1 loop
			rx <= data_to_send(i);
			wait for T_BIT;
		end loop;

		rx <= '0';
		wait for T_BIT;
		
		data_to_send <= (others => '0');

		rx <= '1';
		wait for 3*T_BIT;

		assert rx_valid = '0'
			report "[ERROR]: rx_valid active with stop bit at 0"
			severity error;

		-- Test 11: Reset while reception --
		data_to_send <= x"99";

		rx <= '0';
		wait for T_BIT;

		rx <= '1';
		wait for T_BIT;
		rx <= '0';
		wait for T_BIT;

		rst <= '1';
		wait for 2*T_CLK;
		rst <= '0';

		rx <= '1';
		wait for 5*T_BIT;

		assert rx_valid = '0'
			report "[ERROR]: rx_valid active after reset"
			severity error;

		-- Test 12: Recovery from reset --
		data_to_send <= x"E3";
		send_uart_frame(rx, data_to_send);

		data_to_send <= (others => '0');

		wait for 10 us;
		report "[OK]: Testbench passed correctly!" severity note;
		finish;
	end process;

end architecture;
