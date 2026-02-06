library ieee;
use ieee.std_logic_1164.all;

entity uart_tx is
    generic (
        CLK_HZ       : positive := 50_000_000;
        BAUDRATE     : positive := 115200;
        DATA_BITS    : positive := 8
    );
    port(
        clk       : in std_logic;
        rst       : in std_logic;

        tx        : out std_logic;

        tx_start  : in std_logic;
        tx_data   : in std_logic_vector(DATA_BITS-1 downto 0);

        tx_busy   : out std_logic;
        tx_accept : out std_logic
    );
end entity;

architecture rtl of uart_tx is
    type state_t is (IDLE_ST, START_ST, DATA_ST, STOP_ST);
    signal state : state_t := IDLE_ST;

    signal data_idx : natural range 0 to DATA_BITS-1 := 0;

    signal data_reg : std_logic_vector(DATA_BITS-1 downto 0) := (others => '0');

    signal uart_baud_en : std_logic := '0';
    signal uart_baud : std_logic := '0';
    
    constant DIV : positive := CLK_HZ / BAUDRATE;
    signal div_count : natural range 0 to DIV-1 := 0;

begin
    assert (CLK_HZ > BAUDRATE)
        report "uart_tx: CLK_HZ too low for this baudrate"
        severity failure;
    
    uart_baud <= '1' when (uart_baud_en = '1') and (div_count = DIV-1) else '0';

    tx_busy <= '1' when state /= IDLE_ST else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE_ST;

                data_idx <= 0;

                data_reg <= (others => '0');

                uart_baud_en <= '0';
                div_count <= 0;
                
                tx <= '1';
                tx_accept <= '0';

            else
                tx_accept <= '0';

                -- Baud Generator
                if uart_baud_en = '1' then
                    if div_count = DIV-1 then
                        div_count <= 0;
                    else
                        div_count <= div_count + 1;
                    end if;
                else
                    div_count <= 0;
                end if;

                -- Frame Start Detection
                if state = IDLE_ST then
                    tx <= '1';
                    uart_baud_en <= '0';
                    data_idx <= 0;

                    if tx_start = '1' then
                        tx_accept <= '1';
                        data_reg <= tx_data;
                        state <= START_ST;
                        tx <= '0';
                        uart_baud_en <= '1';
                        div_count <= 0;
                    end if;
                end if;

                -- State Machine
                if uart_baud = '1' then
                    case state is
                        when IDLE_ST =>
                            null;

                        when START_ST =>
                            state <= DATA_ST;
                            tx <= data_reg(0);
                            data_idx <= 0;

                        when DATA_ST =>
                            if data_idx = DATA_BITS-1 then
                                state <= STOP_ST;
                                tx <= '1';
                                data_idx <= 0;
                            else
                                data_idx <= data_idx + 1;
                                tx <= data_reg(data_idx + 1);
                            end if;

                        when STOP_ST =>
                            if tx_start = '1' then
                                tx_accept <= '1';
                                data_reg <= tx_data;

                                state <= START_ST;
                                tx <= '0';
                                uart_baud_en <= '1';
                                div_count <= 0;
                            else
                                state <= IDLE_ST;
                                tx <= '1';
                                uart_baud_en <= '0';
                                div_count <= 0;
                            end if;

                        when others => state <= IDLE_ST;

                    end case;
                end if;
            end if;
        end if;

    end process;

end architecture;