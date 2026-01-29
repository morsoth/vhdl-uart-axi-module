library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

entity tb_uart_rx is
end entity;

architecture tb of tb_uart_rx is
	constant CLK_HZ       : positive := 50_000_000;
	constant BAUDRATE     : positive := 115200;
	constant OVERSAMPLING : positive := 16;
	constant DATA_BITS    : positive := 8;

	constant T_CLK  : time := 1 sec / CLK_HZ;

	constant DIV    : positive := CLK_HZ / (BAUDRATE * OVERSAMPLING);
	constant T_TICK : time := DIV * T_CLK;
	constant T_BIT  : time := OVERSAMPLING * T_TICK;

	signal clk : std_logic := '0';
	signal rst : std_logic := '1';

	signal rx : std_logic := '1';
	signal rx_valid : std_logic;
	signal rx_data  : std_logic_vector(DATA_BITS-1 downto 0);

begin
	dut : entity work.uart_rx
		generic map (
            CLK_HZ       => CLK_HZ,
            BAUDRATE     => BAUDRATE,
            OVERSAMPLING => OVERSAMPLING,
            DATA_BITS => DATA_BITS
		)
		port map (
			clk      => clk,
			rst      => rst,
			rx       => rx,
			rx_valid => rx_valid,
			rx_data  => rx_data
		);

	clk <= not clk after T_CLK/2;

	stim : process
		variable data : std_logic_vector(7 downto 0);
	begin
		rst <= '1';
		wait for T_CLK;
		rst <= '0';
		wait for 10 us;

		-- Test 1: Long idle --
		rx <= '1';
		wait for 9*T_BIT;

		-- Test 2: 0x55 --
		wait until rising_edge(clk);
		data := x"55";
		
		rx <= '0';
		wait for T_BIT;

		for i in 0 to 7 loop
			rx <= data(i);
			wait for T_BIT;
		end loop;

		rx <= '1';
		wait for T_BIT/2;

		if rx_valid = '0' then
			wait until rx_valid /= '0';
		end if;

		assert rx_data = data
			report "[TB][ERROR] rx_data mismatch. expected=" & to_hstring(data) & " got=" & to_hstring(rx_data)
			severity failure;

		wait for T_BIT/2 - 3*T_CLK;

		wait for 2*T_BIT;

		-- Test 3: Back-to-back --
		wait until rising_edge(clk);
		data := x"12";
		
		rx <= '0';
		wait for T_BIT;

		for i in 0 to 7 loop
			rx <= data(i);
			wait for T_BIT;
		end loop;

		rx <= '1';
		wait for T_BIT/2;

		if rx_valid = '0' then
			wait until rx_valid /= '0';
		end if;

		assert rx_data = data
			report "[TB][ERROR] rx_data mismatch. expected=" & to_hstring(data) & " got=" & to_hstring(rx_data)
			severity failure;

		wait for T_BIT/2 - 3*T_CLK;

		data := x"34";
		
		rx <= '0';
		wait for T_BIT;

		for i in 0 to 7 loop
			rx <= data(i);
			wait for T_BIT;
		end loop;

		rx <= '1';
		wait for T_BIT/2;

		if rx_valid = '0' then
			wait until rx_valid /= '0';
		end if;

		assert rx_data = data
			report "[TB][ERROR] rx_data mismatch. expected=" & to_hstring(data) & " got=" & to_hstring(rx_data)
			severity failure;

		wait for T_BIT/2;
		
		wait for 2*T_BIT;

		-- Test 4: Invalid Stop bit --
		wait until rising_edge(clk);
		data := x"99";
		
		rx <= '0';
		wait for T_BIT;

		for i in 0 to 7 loop
			rx <= data(i);
			wait for T_BIT;
		end loop;

		rx <= '1';
		wait for T_BIT/4;

		rx <= '0';
		wait for T_CLK;

		assert rx_valid = '0'
			report "[ERROR]: data shouldn't be valid"
			severity error;

		rx <= '1';

		wait for 2*T_BIT;

		-- Test 5: Invalid Start bit --
		wait until rising_edge(clk);
		
		rx <= '0';
		wait for T_BIT/4;

		rx <= '1';

		wait for 2*T_BIT;

		-- Test 6: Reset while reception (trash byte) --
		wait until rising_edge(clk);
		data := x"55";
		
		rx <= '0';
		wait for T_BIT;

		for i in 0 to 7 loop
			if i = 4 then
				rst <= '1';
			elsif i = 6 then
				rst <= '0';
			end if;

			rx <= data(i);
			wait for T_BIT;
		end loop;

		rx <= '1';
		wait for T_BIT - 3*T_CLK;

		wait for 9*T_BIT;

		wait for 10 us;

		report "[OK]: Testbench passed correctly!" severity note;
		finish;
  	end process;

end architecture;
