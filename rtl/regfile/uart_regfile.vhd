library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_regfile_min is
  generic (
    DATA_BITS : positive := 8
  );
  port (
    clk : in  std_logic;
    rst : in  std_logic;

    rx_en    : in std_logic;
    rx_ready : out std_logic;
    rx_data  : out std_logic_vector(DATA_BITS-1 downto 0);

    tx_en    : in std_logic;
    tx_ready : out std_logic;
    tx_data  : in std_logic_vector(DATA_BITS-1 downto 0)
  );
end entity;

architecture rtl of uart_regfile_min is
  constant REG_CTRL   : std_logic_vector(7 downto 0) := x"00";
  constant REG_STATUS : std_logic_vector(7 downto 0) := x"04";
  constant REG_TXDATA : std_logic_vector(7 downto 0) := x"08";
  constant REG_RXDATA : std_logic_vector(7 downto 0) := x"0C";

  ------------------------------------------------------------------------------
  -- Internal stored state (CTRL bits)
  ------------------------------------------------------------------------------
  signal ctrl_rx_en : std_logic;   -- CTRL bit0
  signal ctrl_tx_en : std_logic;   -- CTRL bit1

  ------------------------------------------------------------------------------
  -- One-cycle pulse outputs to uart_core
  ------------------------------------------------------------------------------
  signal rx_pop_i  : std_logic;
  signal tx_push_i : std_logic;

  ------------------------------------------------------------------------------
  -- Data register to hold TX byte during tx_push pulse
  ------------------------------------------------------------------------------
  signal tx_byte : std_logic_vector(DATA_BITS-1 downto 0);

  ------------------------------------------------------------------------------
  -- Optional internal read-mux signal (handy)
  ------------------------------------------------------------------------------
  signal rx_byte : std_logic_vector(31 downto 0);

begin

  ------------------------------------------------------------------------------
  -- READ PATH (combinational)
  -- Build rd_data_i based on rd_addr:
  --  - CTRL   -> bits [0]=ctrl_rx_en, [1]=ctrl_tx_en
  --  - STATUS -> bits [0]=rx_ready,   [1]=tx_ready
  --  - RXDATA -> bits [7:0]=rx_data (optionally 0 if rx_ready=0)
  --  - others -> 0
  ------------------------------------------------------------------------------
  p_read_mux : process(all)
  begin
    -- rd_data_i <= (others => '0');

    -- TODO: case rd_addr is ...
    -- when REG_CTRL   => ...
    -- when REG_STATUS => ...
    -- when REG_RXDATA => ...
    -- when others     => ...
  end process;

  ------------------------------------------------------------------------------
  -- WRITE PATH + SIDE EFFECTS (sequential)
  --
  -- On each rising clk:
  -- 1) default pulses to 0: rx_pop_i<=0, tx_push_i<=0
  -- 2) handle reset: ctrl_rx_en<=1, ctrl_tx_en<=1
  -- 3) CTRL write: update enables if wr_en & wr_addr==REG_CTRL & wr_strb(0)=1
  -- 4) TXDATA write side-effect:
  --    if wr_en & wr_addr==REG_TXDATA & wr_strb(0)=1
  --      if ctrl_tx_en=1 and tx_ready=1:
  --        tx_data_r <= wr_data(DATA_BITS-1 downto 0)
  --        tx_push_i <= 1 (one cycle)
  --      else ignore
  -- 5) RXDATA read side-effect:
  --    if rd_en & rd_addr==REG_RXDATA:
  --      if ctrl_rx_en=1 and rx_ready=1:
  --        rx_pop_i <= 1 (one cycle)
  --      else ignore
  ------------------------------------------------------------------------------
  p_seq : process(clk)
  begin
    if rising_edge(clk) then

      -- TODO: default pulses low every cycle
      -- rx_pop_i  <= '0';
      -- tx_push_i <= '0';

      if rst = '1' then
        -- TODO: reset stored state
        -- ctrl_rx_en <= '1';
        -- ctrl_tx_en <= '1';
        -- tx_data_r  <= (others => '0');
        -- rx_pop_i   <= '0';
        -- tx_push_i  <= '0';
      else
        -- TODO: CTRL write decode
        -- TODO: TXDATA write side-effect (push)
        -- TODO: RXDATA read side-effect (pop)
      end if;

    end if;
  end process;

end architecture;
