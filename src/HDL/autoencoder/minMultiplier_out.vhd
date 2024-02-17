library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity minMultiplier_out is
    Port (
	   CLK : in STD_LOGIC;
	   multin1 : in std_logic_vector(23 downto 0);
	   multin2 : in std_logic_vector(15 downto 0);
	   multout : out std_logic_vector(39 downto 0)
	   );
end minMultiplier_out;

architecture Behavioral of minMultiplier_out is

begin
process(CLK) begin
	if (rising_edge(CLK)) then
	   multout <= multin1 * multin2;
	end if;
end process;
	
end Behavioral;
