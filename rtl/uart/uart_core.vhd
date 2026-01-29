library ieee;
use ieee.std_logic_1164.all;

entity uart_core is
    generic (
        CLK_HZ       : positive := 50_000_000;
        BAUDRATE     : positive := 115200;
        OVERSAMPLING : positive := 16;
        DATA_BITS    : natural := 8;
        FIFO_SIZE    : natural := 4
    );
    port(
        clk      : in std_logic;
        rst      : in std_logic;

        rx       : in std_logic;
        tx       : out std_logic;

        rx_en    : in std_logic;
        rx_ready : out std_logic;
        rx_data  : out std_logic_vector(DATA_BITS-1 downto 0);

        tx_en    : in std_logic;
        tx_ready : out std_logic;
        tx_data  : in std_logic_vector(DATA_BITS-1 downto 0)
    );
end entity;

architecture rtl of uart_core is
    signal rx_wr_en   : std_logic;
    signal rx_wr_data : std_logic_vector(DATA_BITS-1 downto 0);

    signal rx_empty   : std_logic;
    signal rx_full    : std_logic;

    signal tx_rd_data : std_logic_vector(DATA_BITS-1 downto 0);

    signal tx_empty   : std_logic;
    signal tx_full    : std_logic;

    signal tx_accept  : std_logic;
    signal tx_busy    : std_logic;

begin
    -- RX UART
    u_rx : entity work.uart_rx
        generic map (
            CLK_HZ       => CLK_HZ,
            BAUDRATE     => BAUDRATE,
            OVERSAMPLING => OVERSAMPLING,
            DATA_BITS => DATA_BITS
        )
        port map (
            clk       => clk,
            rst       => rst,
            rx        => rx,
            rx_valid  => rx_wr_en,
            rx_data   => rx_wr_data
        );

    -- RX FIFO
    u_rx_fifo : entity work.fifo_sync
        generic map (
            DATA_BITS => DATA_BITS,
            SIZE      => FIFO_SIZE
        )
        port map (
            clk     => clk,
            rst     => rst,
            rd_en   => rx_en,
            rd_data => rx_data,
            wr_en   => rx_wr_en,
            wr_data => rx_wr_data,
            full    => rx_full,
            empty   => rx_empty
        );

    -- TX UART
    u_tx : entity work.uart_tx
        generic map (
            CLK_HZ       => CLK_HZ,
            BAUDRATE     => BAUDRATE,
            DATA_BITS => DATA_BITS
        )
        port map (
            clk       => clk,
            rst       => rst,
            tx        => tx,
            tx_start  => not tx_empty,
            tx_data   => tx_rd_data,
            tx_busy   => tx_busy,
            tx_accept => tx_accept
        );

    -- TX FIFO
    u_tx_fifo : entity work.fifo_sync
        generic map (
            DATA_BITS => DATA_BITS,
            SIZE      => FIFO_SIZE
        )
        port map (
            clk     => clk,
            rst     => rst,
            rd_en   => tx_accept,
            rd_data => tx_rd_data,
            wr_en   => tx_en,
            wr_data => tx_data,
            full    => tx_full,
            empty   => tx_empty
        );

    rx_ready <= not rx_empty;
    tx_ready <= not tx_full;

end architecture;
