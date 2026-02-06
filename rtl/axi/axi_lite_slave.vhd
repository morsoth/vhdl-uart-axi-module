library ieee;
use ieee.std_logic_1164.all;

entity axi_lite_slave is
    generic (
        DATA_BITS : positive := 8
    );
    port(
        clk : in std_logic;
        rst : in std_logic;

        -------------------------------------
        -- AXI4 LITE INTERFACE             --
        -------------------------------------

        -- Write addr
        aw_addr  : in std_logic_vector(7 downto 0);
        aw_valid : in std_logic;
        aw_ready : out std_logic;

        -- Write data
        w_data   : in std_logic_vector(31 downto 0);
        w_valid  : in std_logic;
        w_ready  : out std_logic;

        -- Write response
        b_resp   : out std_logic_vector(1 downto 0);
        b_valid  : out std_logic;
        b_ready  : in std_logic;

        -- Read addr
        ar_addr  : in std_logic_vector(7 downto 0);
        ar_valid : in std_logic;
        ar_ready : out std_logic;

        -- Read data & response
        r_data   : out std_logic_vector(31 downto 0);
        r_resp   : out std_logic_vector(1 downto 0);
        r_valid  : out std_logic;
        r_ready  : in std_logic;
        
        -------------------------------------
        -- REGFILE INTERFACE               --
        -------------------------------------

        wr_addr : out std_logic_vector(7 downto 0);
		wr_data : out std_logic_vector(DATA_BITS-1 downto 0);
		wr_en   : out std_logic;

		rd_addr : out std_logic_vector(7 downto 0);
		rd_data : in std_logic_vector(DATA_BITS-1 downto 0);
		rd_en   : out std_logic
    );
end entity;

architecture rtl of axi_lite_slave is
    constant RESP_OKAY : std_logic_vector(1 downto 0) := "00";

    signal have_aw : std_logic := '0';
    signal have_w : std_logic := '0';

begin
    aw_ready <= '1' when b_valid = '0' and have_aw = '0' else '0';
    w_ready  <= '1' when b_valid = '0' and have_w = '0' else '0';
    ar_ready <= '1' when r_valid = '0' else '0';

    r_resp <= RESP_OKAY;
    b_resp <= RESP_OKAY;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                have_aw <= '0';
                have_w <= '0';

                rd_en <= '0';
                wr_en <= '0';
                
                rd_addr <= (others => '0');
                wr_addr <= (others => '0');
                wr_data <= (others => '0');

                r_data  <= (others => '0');
                r_valid <= '0';
                b_valid <= '0';

            else
                rd_en <= '0';
                wr_en <= '0';

                if ar_valid = '1' and ar_ready = '1' then
                    rd_addr <= ar_addr;
                    rd_en <= '1';

                    r_data <= (others => '0');
                    r_data(DATA_BITS-1 downto 0) <= rd_data;

                    r_valid <= '1';
                end if;

                if r_valid = '1' and r_ready = '1' then
                    r_valid <= '0';
                end if;

                if aw_valid = '1' and aw_ready = '1' then
                    wr_addr <= aw_addr;

                    if have_w = '1' then
                        wr_en <= '1';

                        b_valid <= '1';

                        have_w <= '0';
                    else
                        have_aw <= '1';
                    end if;
                end if;

                if w_valid = '1' and w_ready = '1' then
                    wr_data <= w_data(DATA_BITS-1 downto 0);
                    
                    if have_aw = '1' then
                        wr_en <= '1';
                        
                        b_valid <= '1';
                        
                        have_aw <= '0';
                    else
                        have_w <= '1';
                    end if;
                end if;

                if b_valid = '1' and b_ready = '1' then
                    b_valid <= '0';
                end if;

			end if;

		end if;

    end process;

end architecture;