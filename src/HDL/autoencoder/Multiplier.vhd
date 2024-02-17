library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity Multiplier is
    Port (
        CLK : in STD_LOGIC;
        RESET : in STD_LOGIC;
		Multinput : in std_logic_vector(287 downto 0);
		Multweight : in std_logic_vector(511 downto 0);
		Multout : out std_logic_vector(767 downto 0) := (others => '0')
	);
end Multiplier;

architecture Behavioral of Multiplier is

component minMultiplier is
	port(
	   CLK : in STD_LOGIC;
	   multin1 : in std_logic_vector(8 downto 0);
	   multin2 : in std_logic_vector(15 downto 0);
	   multout : out std_logic_vector(24 downto 0)
	   );
end component minMultiplier;

type data_input_matrix is array(1 to 32) of std_logic_vector(8 downto 0); 
signal data_input : data_input_matrix := (others => (others => '0'));
type data_weight_matrix is array(1 to 32) of std_logic_vector(15 downto 0);
signal data_weight : data_weight_matrix := (others => (others => '0'));
type data_output_matrix is array(1 to 32) of std_logic_vector(24 downto 0);
signal data_output : data_output_matrix := (others => (others => '0'));


begin

process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0')then
            for i in 1 to 32 loop
	           data_input(i) <= Multinput((i*9)-1 downto i*9-9);
	           data_weight(i) <= Multweight((i*16)-1 downto i*16-16);
		    end loop;   
        elsif (RESET = '1') then 
	       data_input <=(others => (others => '0'));
	       data_weight <=(others => (others => '0'));
	    end if;
    end if;
end process;

min_Multiplier: for i in 1 to 32 generate
	Multiplier : minMultiplier
		port map (
		    CLK => CLK,
			multin1 => data_input(i),
			multin2 => data_weight(i),
			multout => data_output(i)
		);
end generate min_Multiplier;

process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0')then
            for i in 1 to 32 loop
                Multout((i*24)-1 downto i*24-24) <= data_output(i)(23 downto 0);
            end loop;
	    end if;
    end if;
end process;
end Behavioral;