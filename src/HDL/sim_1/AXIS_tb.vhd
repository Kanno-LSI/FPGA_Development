----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/12/31 16:14:52
-- Design Name: 
-- Module Name: S_AXIS_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
--use IEEE.std_logic_unsigned.ALL;
--use IEEE.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity AXIS_tb is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXIS
		S00_AXIS_TDATA_WIDTH	: integer	:= 64;

		-- Parameters of Axi Master Bus Interface M00_AXIS
		M00_AXIS_TDATA_WIDTH	: integer	:= 64;
		M00_AXIS_START_COUNT	: integer	:= 32
	);
	port( 
	      axis_aclk	: out std_logic;
	      axis_aresetn	: out std_logic;
	       
	      --write
		  -- Ports of Axi Slave Bus Interface S00_AXIS
		  --s00_axis_aclk	: out std_logic;
		  --s00_axis_aresetn	: out std_logic;
		  s00_axis_tready	: in std_logic;
		  s00_axis_tdata	: out std_logic_vector(S00_AXIS_TDATA_WIDTH-1 downto 0);
		  s00_axis_tstrb	: out std_logic_vector((S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		  s00_axis_tlast	: out std_logic;
		  s00_axis_tvalid	: out std_logic;
          
          --read
		  -- Ports of Axi Master Bus Interface M00_AXIS
		  --m00_axis_aclk	: out std_logic;
		  --m00_axis_aresetn	: out std_logic;
		  m00_axis_tvalid	: in std_logic;
		  m00_axis_tdata	: in std_logic_vector(M00_AXIS_TDATA_WIDTH-1 downto 0);
		  m00_axis_tstrb	: in std_logic_vector((M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		  m00_axis_tlast	: in std_logic;
		  m00_axis_tready	: out std_logic
	);
end AXIS_tb;

architecture Behavioral of AXIS_tb is


begin

--main
process begin
m00_axis_tready <= '0';
s00_axis_tdata <= (others => '0');
s00_axis_tstrb <= (others => '0');
s00_axis_tlast <='0';
s00_axis_tvalid <= '0';

wait for 102 ns;
wait for 2 ps;

s00_axis_tvalid <= '1';
for i in 1 to 128 loop
    s00_axis_tdata <= std_logic_vector(to_unsigned(i, 64));
    wait for 4 ns;
end loop;
for i in 129 to 256 loop
    s00_axis_tdata <= std_logic_vector(to_unsigned(i, 64));
    wait for 4 ns;
end loop;
for i in 1 to 128 loop
    s00_axis_tdata <= std_logic_vector(to_unsigned(i, 64));
    wait for 4 ns;
end loop;
for i in 129 to 256 loop
    s00_axis_tdata <= std_logic_vector(to_unsigned(i, 64));
    wait for 4 ns;
end loop;
s00_axis_tvalid <= '0';
s00_axis_tlast <= '1';
s00_axis_tdata <= std_logic_vector(to_unsigned(0, 64));
wait for 40 ns;


wait for 20000 ns;

m00_axis_tready <= '1';
for i in 0 to 127-4 loop
    wait for 4 ns;
end loop;
m00_axis_tready <= '0';
wait for 100 ns;

m00_axis_tready <= '1';
for i in 0 to 127-4 loop
    wait for 4 ns;
end loop;
m00_axis_tready <= '0';

wait for 100 ns;

m00_axis_tready <= '1';
for i in 0 to 127-4 loop
    wait for 4 ns;
end loop;
m00_axis_tready <= '0';

wait for 100 ns;

m00_axis_tready <= '1';
for i in 0 to 127-4 loop
    wait for 4 ns;
end loop;
m00_axis_tready <= '0';

wait for 1000 ns;
end process;

--clk
process begin
axis_aclk <= '0';
wait for 2 ns;
axis_aclk <= '1';
wait for 2 ns;
end process;

--reset
process begin
axis_aresetn <= '0';
wait for 10 ns;
axis_aresetn <= '1';
wait;
end process;

end Behavioral;
