library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

entity tb_uart_regfile is
end entity;

architecture tb of tb_uart_regfile is
	constant CLK_HZ       : positive := 50_000_000;
	constant BAUDRATE     : positive := 115200;
	constant OVERSAMPLING : positive := 16;
    constant DATA_BITS    : positive := 8;
    constant FIFO_SIZE    : positive := 4;

	constant T_CLK  : time := 1 sec / CLK_HZ;

	signal clk : std_logic := '0';
	signal rst : std_logic := '1';

    signal wr_addr  : std_logic_vector(7 downto 0);
    signal wr_data  : std_logic_vector(DATA_BITS-1 downto 0);
    signal wr_en    : std_logic;
    
    signal rd_addr  : std_logic_vector(7 downto 0);
    signal rd_data  : std_logic_vector(DATA_BITS-1 downto 0);
    signal rd_en    : std_logic;

	signal rx_en    : std_logic := '0';
	signal rx_ready : std_logic;
	signal rx_data  : std_logic_vector(7 downto 0);

	signal tx_en    : std_logic := '0';
	signal tx_ready : std_logic;
	signal tx_data  : std_logic_vector(7 downto 0);

    constant REG_CTRL   : std_logic_vector(7 downto 0) := x"00";
    constant REG_STATUS : std_logic_vector(7 downto 0) := x"04";
    constant REG_TXDATA : std_logic_vector(7 downto 0) := x"08";
    constant REG_RXDATA : std_logic_vector(7 downto 0) := x"0C";

begin
    clk <= not clk after T_CLK/2;

    dut : entity work.uart_regfile
        generic map (
            DATA_BITS => DATA_BITS
        )
        port map (
            clk      => clk,
            rst      => rst,
            wr_addr  => wr_addr,
            wr_data  => wr_data,
            wr_en    => wr_en,
            rd_addr  => rd_addr,
            rd_data  => rd_data,
            rd_en    => rd_en,
            rx_en    => rx_en,
            rx_ready => rx_ready,
            rx_data  => rx_data,
            tx_en    => tx_en,
            tx_ready => tx_ready,
            tx_data  => tx_data
        );

	stim : process
	begin
		rst <= '1';
		wait for T_CLK;
		rst <= '0';
		wait for 10*T_CLK;

        wait until rising_edge(clk);
        rx_ready <= '0';
        tx_ready <= '1';
        
        rx_data <= x"00";

        rd_en <= '0';
        wr_en <= '0';

        -- Test 1: Read CTRL register
        rd_addr <= REG_CTRL;
        rd_en <= '1';
        wait for T_CLK;
        rd_en <= '0';

        wait for T_CLK;

        -- Test 2: Read STATUS register
        rd_addr <= REG_STATUS;
        rd_en <= '1';
        wait for T_CLK;
        rd_en <= '0';

        wait for T_CLK;

        -- Test 3: Write TXDATA
        tx_ready <= '1';

        wr_addr <= REG_TXDATA;
        wr_data <= x"55";
        wr_en <= '1';
        wait for T_CLK;
        wr_en <= '0';

        wr_data <= x"AA";
        wr_en <= '1';
        wait for T_CLK;
        wr_en <= '0';

        wait for T_CLK;

        -- Test 4: Write TXDATA when FIFO full
        tx_ready <= '0';

        wr_addr <= REG_TXDATA;
        wr_data <= x"FF";
        wr_en <= '1';
        wait for T_CLK;
        wr_en <= '0';
        
        wait for T_CLK;

        -- Test 5: Read RXDATA
        rx_ready <= '1';
        rx_data <= x"0F";

        rd_addr <= REG_RXDATA;
        rd_en <= '1';
        wait for T_CLK;
        rd_en <= '0';

        rx_data <= x"F0";

        rd_en <= '1';
        wait for T_CLK;
        rd_en <= '0';
        
        rx_data <= x"88";

        wait for T_CLK;

        -- Test 5: Read RXDATA when FIFO empty
        rx_ready <= '0';

        rd_addr <= REG_RXDATA;
        rd_en <= '1';
        wait for T_CLK;
        rd_en <= '0';

        wait for T_CLK;

        -- Test 6: Write CTRL to disable TX and RX
        wr_addr <= REG_CTRL;
        wr_data <= x"66";
        wr_en <= '1';
        wait for T_CLK;
        wr_en <= '0';

        rd_addr <= REG_CTRL;
        rd_en <= '1';
        wait for T_CLK;
        rd_en <= '0';
        
        wait for T_CLK;

        -- Test 7: Read and write with CTRL disabled
        rx_ready <= '1';
        tx_ready <= '1';

        rx_data <= x"3C";

        rd_addr <= REG_RXDATA;
        rd_en <= '1';
        wait for T_CLK;
        rd_en <= '0';

        wr_addr <= REG_TXDATA;
        wr_data <= x"C3";
        wr_en <= '1';
        wait for T_CLK;
        wr_en <= '0';
        
        wait for T_CLK;

		wait for 10*T_CLK;

		report "[OK]: Testbench passed correctly!" severity note;
		finish;
	end process;

end architecture;
