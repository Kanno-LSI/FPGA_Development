----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2021/05/28 13:48:58
-- Design Name: 
-- Module Name: fifo - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.math_real.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fifo is
    generic (
        WIDTH : integer := 64;
        DEPTH : integer := 8192);

    Port ( 
        clk : in std_logic;
	    srst : in std_logic;
	    full : out std_logic;
	    din : in std_logic_vector(WIDTH - 1 downto 0);
	    wr_en : in std_logic;
	    empty : out std_logic;
	    dout : out std_logic_vector(WIDTH - 1 downto 0);
	    rd_en : in std_logic);

end fifo;

architecture Behavioral of fifo is
    


constant DEPTH_BIT : integer := integer(ceil(log2(real(DEPTH))));


type ROM is array (0 to DEPTH - 1) of std_logic_vector(WIDTH - 1 downto 0);
signal fifo : ROM := (others => (others => '0'));

signal rptr : std_logic_vector(DEPTH_BIT - 1 downto 0);
signal wptr : std_logic_vector(DEPTH_BIT - 1 downto 0);

signal full_flag : std_logic;
signal empty_flag : std_logic;

signal almost_full : std_logic;
signal almost_empty : std_logic;

signal dout_reg : std_logic_vector(WIDTH - 1 downto 0);


begin

full <= full_flag;
empty <= empty_flag;

almost_full <= '1' when (unsigned(rptr)= (unsigned(wptr) + 1)) else '0';
almost_empty <= '1' when ((unsigned(rptr) + 1)= unsigned(wptr)) else '0';


dout <= dout_reg;


--output
process(clk)begin
    if(rising_edge(clk))then
        if(srst = '1')then
            --dout_reg <= (others => '0');
            dout_reg <= (others => '1');
        elsif((rd_en = '1') and (empty_flag = '0'))then
            dout_reg <= fifo(to_integer(unsigned(rptr)));
        else
            dout_reg <= dout_reg;
        end if;
    end if;
end process;

--input
process(clk)begin
    if(rising_edge(clk))then
        if((wr_en = '1') and (full_flag = '0'))then
        
            fifo(to_integer(unsigned(wptr))) <= din;

        end if;
    end if;
end process;
            
--write pointer
process(clk)begin
    if(rising_edge(clk))then
        if(srst = '1')then
            wptr <= (others => '0');
        elsif((wr_en = '1') and (full_flag = '0'))then
            wptr <= std_logic_vector(unsigned(wptr) + 1);
        else
            wptr <= wptr;
        end if;
    end if;
end process;

--read pointer
process(clk)begin
    if(rising_edge(clk))then
        if(srst = '1')then
            rptr <= (others => '0');
        elsif((rd_en = '1') and (empty_flag = '0'))then
            rptr <= std_logic_vector(unsigned(rptr) + 1);
        else
            rptr <= rptr;
        end if;
    end if;
end process;

--empty flag state
process(clk)begin
    if(rising_edge(clk))then
        if(srst = '1')then
            empty_flag <= '1';
        elsif(wr_en = '1')then
            empty_flag <= '0';
        elsif((almost_empty = '1') and (rd_en = '1'))then
            empty_flag <= '1';
        else
            empty_flag <= empty_flag;
        end if;
    end if;
end process;

--full flag state
process(clk)begin
    if(rising_edge(clk))then
        if(srst = '1')then
            full_flag <= '0';
        elsif(rd_en = '1')then
            full_flag <= '0';
        elsif((almost_full = '1') and (wr_en = '1'))then
            full_flag <= '1';
        else
            full_flag <= full_flag;
        end if;
    end if;
end process;

end Behavioral;
