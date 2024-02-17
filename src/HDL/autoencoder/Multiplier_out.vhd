library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;


entity Multiplier_out is
    Port (
        CLK : in STD_LOGIC;
        RESET : in STD_LOGIC;
		Multinput : in std_logic_vector(767 downto 0); --24bitの入力データが32個
		Multweight : in std_logic_vector(511 downto 0); --16bitの重みデータが32個
		Multout : out std_logic_vector(767 downto 0) := (others => '0') --24bitの出力データが32個
	);
end Multiplier_out;

architecture Behavioral of Multiplier_out is

component minMultiplier_out is
	port(
	   CLK : in STD_LOGIC;
	   multin1 : in std_logic_vector(23 downto 0);
	   multin2 : in std_logic_vector(15 downto 0);
	   multout : out std_logic_vector(39 downto 0)
	   );
end component minMultiplier_out;

type data_input_matrix is array(1 to 32) of std_logic_vector(23 downto 0); 
signal data_input : data_input_matrix := (others => (others => '0'));
type data_weight_matrix is array(1 to 32) of std_logic_vector(15 downto 0);
signal data_weight : data_weight_matrix := (others => (others => '0'));

type data_output_matrix is array(1 to 32) of std_logic_vector(39 downto 0);
signal data_output : data_output_matrix := (others => (others => '0'));


begin

process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0')then
            for i in 1 to 32 loop
	           data_input(i) <= Multinput((i*24)-1 downto (i*24)-24);
		    end loop;               
            for i in 1 to 32 loop
	           data_weight(i) <= Multweight((i*16)-1 downto (i*16)-16);
		    end loop;   
        elsif (RESET = '1') then 
	       data_input <=(others => (others => '0'));
	       data_weight <=(others => (others => '0'));
	    end if;
    end if;
end process;

min_Multiplier_out: for i in 1 to 32 generate
	Multiplier : minMultiplier_out
		port map (
		    CLK => CLK,
			multin1 => data_input(i),
			multin2 => data_weight(i),
			multout => data_output(i)
		);
end generate min_Multiplier_out;

process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0')then
            for i in 1 to 32 loop
                Multout((i*24)-1 downto i*24-24) <= data_output(i)(34 downto 11);                     
            end loop;
	    end if;
    end if;
end process;

end Behavioral;
