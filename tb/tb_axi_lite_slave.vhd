library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

entity tb_axi_lite_slave is
end entity;

architecture tb of tb_axi_lite_slave is
    constant CLK_HZ    : positive := 50_000_000;
    constant DATA_BITS : positive := 8;
    constant T_CLK     : time := 1 sec / CLK_HZ;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    -------------------------------------
    -- AXI4 LITE INTERFACE             --
    -------------------------------------
    signal aw_addr  : std_logic_vector(7 downto 0) := (others => '0');
    signal aw_valid : std_logic := '0';
    signal aw_ready : std_logic;

    signal w_data   : std_logic_vector(31 downto 0) := (others => '0');
    signal w_valid  : std_logic := '0';
    signal w_ready  : std_logic;

    signal b_resp   : std_logic_vector(1 downto 0);
    signal b_valid  : std_logic;
    signal b_ready  : std_logic := '0';

    signal ar_addr  : std_logic_vector(7 downto 0) := (others => '0');
    signal ar_valid : std_logic := '0';
    signal ar_ready : std_logic;

    signal r_data   : std_logic_vector(31 downto 0);
    signal r_resp   : std_logic_vector(1 downto 0);
    signal r_valid  : std_logic;
    signal r_ready  : std_logic := '0';

    -------------------------------------
    -- REGFILE INTERFACE               --
    -------------------------------------
    signal wr_addr : std_logic_vector(7 downto 0);
    signal wr_data : std_logic_vector(DATA_BITS-1 downto 0);
    signal wr_en   : std_logic;

    signal rd_addr : std_logic_vector(7 downto 0);
    signal rd_data : std_logic_vector(DATA_BITS-1 downto 0) := (others => '0');
    signal rd_en   : std_logic;

    constant REG_CTRL   : std_logic_vector(7 downto 0) := x"00";
    constant REG_STATUS : std_logic_vector(7 downto 0) := x"04";
    constant REG_TXDATA : std_logic_vector(7 downto 0) := x"08";
    constant REG_RXDATA : std_logic_vector(7 downto 0) := x"0C";

begin
    clk <= not clk after T_CLK/2;

    dut : entity work.axi_lite_slave
        generic map (
            DATA_BITS => DATA_BITS
        )
        port map (
            clk      => clk,
            rst      => rst,
            aw_addr  => aw_addr,
            aw_valid => aw_valid,
            aw_ready => aw_ready,
            w_data   => w_data,
            w_valid  => w_valid,
            w_ready  => w_ready,
            b_resp   => b_resp,
            b_valid  => b_valid,
            b_ready  => b_ready,
            ar_addr  => ar_addr,
            ar_valid => ar_valid,
            ar_ready => ar_ready,
            r_data   => r_data,
            r_resp   => r_resp,
            r_valid  => r_valid,
            r_ready  => r_ready,
            wr_addr  => wr_addr,
            wr_data  => wr_data,
            wr_en    => wr_en,
            rd_addr  => rd_addr,
            rd_data  => rd_data,
            rd_en    => rd_en
        );

    stim : process
    begin
        rst <= '1';
		wait for T_CLK;
		rst <= '0';
		wait for 10*T_CLK;

        wait until rising_edge(clk);
        aw_valid <= '0';
        w_valid  <= '0';
        b_ready  <= '0';
        ar_valid <= '0';
        r_ready  <= '0';
        rd_data  <= x"00";

        -- Test 1: Read register
        rd_data <= x"55";

        ar_addr <= REG_CTRL;
        ar_valid <= '1';
        wait for T_CLK;

        while ar_ready /= '1' loop
			wait until rising_edge(clk);
		end loop;

        ar_valid <= '0';
        r_ready <= '1';
        wait for T_CLK;

        while r_valid /= '1' loop
			wait until rising_edge(clk);
		end loop;
        
        r_ready <= '0';

        wait for T_CLK;

        -- Test 2: Write with AW before W
        aw_addr <= REG_TXDATA;
        aw_valid <= '1';
        wait for T_CLK;

        while aw_ready /= '1' loop
			wait until rising_edge(clk);
		end loop;

        aw_valid <= '0';

        wait for 5*T_CLK;

        w_data <= x"000000A5";
        w_valid <= '1';
        wait for T_CLK;

        while w_valid /= '1' loop
			wait until rising_edge(clk);
		end loop;

        w_valid <= '0';
        b_ready <= '1';

        while b_valid /= '1' loop
			wait until rising_edge(clk);
		end loop;
        
        b_ready <= '0';

        wait for T_CLK;

        -- Test 3: Write with W before AW
        w_data <= x"000000C3";
        w_valid <= '1';
        wait for T_CLK;

        while w_valid /= '1' loop
			wait until rising_edge(clk);
		end loop;

        w_valid <= '0';

        wait for T_CLK;

        aw_addr <= REG_CTRL;
        aw_valid <= '1';
        wait for T_CLK;

        while aw_ready /= '1' loop
			wait until rising_edge(clk);
		end loop;

        aw_valid <= '0';

        wait for 5*T_CLK;
        
        b_ready <= '1';

        while b_valid /= '1' loop
			wait until rising_edge(clk);
		end loop;
        
        b_ready <= '0';

        wait for T_CLK;

		wait for 10*T_CLK;

		report "[OK]: Testbench passed correctly!" severity note;
        finish;
    end process;

end architecture;
