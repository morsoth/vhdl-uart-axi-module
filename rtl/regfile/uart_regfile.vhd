library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_regfile is
    generic (
      	DATA_BITS : positive := 8
    );
    port (
		clk : in  std_logic;
		rst : in  std_logic;
		
        -------------------------------------
        -- AXI ADAPTER                     --
        -------------------------------------

		wr_addr : in std_logic_vector(7 downto 0);
		wr_data : in std_logic_vector(DATA_BITS-1 downto 0);
		wr_en   : in std_logic;

		rd_addr : in std_logic_vector(7 downto 0);
		rd_data : out std_logic_vector(DATA_BITS-1 downto 0);
		rd_en   : in std_logic;

        -------------------------------------
        -- UART CORE                       --
        -------------------------------------

      	rx_data  : in std_logic_vector(DATA_BITS-1 downto 0);
		rx_en    : out std_logic;
		rx_ready : in std_logic;

		tx_data  : out std_logic_vector(DATA_BITS-1 downto 0);
		tx_en    : out std_logic;
		tx_ready : in std_logic
    );
end entity;

architecture rtl of uart_regfile is
    constant REG_CTRL   : std_logic_vector(7 downto 0) := x"00";
    constant REG_STATUS : std_logic_vector(7 downto 0) := x"04";
    constant REG_TXDATA : std_logic_vector(7 downto 0) := x"08";
    constant REG_RXDATA : std_logic_vector(7 downto 0) := x"0C";

    -- CTRL bits
    signal ctrl_rx_en : std_logic := '1'; -- bit 0
    signal ctrl_tx_en : std_logic := '1'; -- bit 1

begin
	process(all)
		variable data : std_logic_vector(DATA_BITS-1 downto 0);
	begin
		data := (others => '0');

		if rd_en = '1'then
			case rd_addr is
				when REG_CTRL =>
					data(0) := ctrl_rx_en;
					data(1) := ctrl_tx_en;

				when REG_STATUS =>
					data(0) := rx_ready;
					data(1) := tx_ready;

				when REG_RXDATA =>
					if  ctrl_rx_en = '1' and rx_ready = '1' then 
						data := rx_data;
					end if;

				when others => null;

			end case;
		end if;

		rd_data <= data;
	end process;

	process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
				ctrl_rx_en <= '1';
				ctrl_tx_en <= '1';

				rx_en <= '0';
				tx_en <= '0';

				tx_data <= (others => '0');

            else
				rx_en <= '0';
				tx_en <= '0';

				if rd_en = '1' and rd_addr = REG_RXDATA then
					if ctrl_rx_en = '1' and rx_ready = '1' then
						rx_en <= '1';
					end if;
				end if;

				if wr_en = '1' then
					case wr_addr is
						when REG_CTRL =>
							ctrl_rx_en <= wr_data(0);
							ctrl_tx_en <= wr_data(1);

						when REG_TXDATA =>
							if ctrl_tx_en = '1' and tx_ready = '1' then
								tx_data <= wr_data;
								tx_en <= '1';
							end if;

						when others => null;
					
					end case;
				end if;

			end if;

		end if;

    end process;

end architecture;
