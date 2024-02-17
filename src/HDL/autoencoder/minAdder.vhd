library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity minAdder is
    Port (
        CLK : in STD_LOGIC;
		addin1 : in std_logic_vector(23 downto 0);
		addin2 : in std_logic_vector(23 downto 0);
		addout : out std_logic_vector(23 downto 0)
	);
end minAdder;

architecture Behavioral of minAdder is

begin
process(CLK) begin
	if (rising_edge(CLK)) then
	   addout <= addin1 + addin2;
	end if;
end process;
	
end Behavioral;

