library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity Adder_out is
    Generic(
        hide_dim : integer := 32 ; 
        data_bit : integer := 24  
    ) ;   
    Port (
        CLK : in STD_LOGIC;
        RESET : in STD_LOGIC;
		addin : in std_logic_vector(data_bit*hide_dim-1 downto 0);
		addout : out std_logic_vector(23 downto 0) := (others => '0')
	);
end Adder_out;

architecture Behavioral of Adder_out is

---•„†•t‰ÁŽZŠí‚Ìƒ‚ƒWƒ…[ƒ‹---
component minAdder is
	port(
	   CLK : in STD_LOGIC;
	   addin1 : in std_logic_vector(23 downto 0);
	   addin2 : in std_logic_vector(23 downto 0);
	   addout : out std_logic_vector(23 downto 0)
	   );
end component minAdder;

type data_matrix is array(1 to hide_dim) of std_logic_vector(23 downto 0); 
signal data : data_matrix := (others => (others => '0'));

--‰ÁŽZŠí”z—ñ
type layer1out_matrix is array(1 to 16) of std_logic_vector(23 downto 0); 
type layer2out_matrix is array(1 to 8) of std_logic_vector(23 downto 0); 
type layer3out_matrix is array(1 to 4) of std_logic_vector(23 downto 0); 
type layer4out_matrix is array(1 to 2) of std_logic_vector(23 downto 0); 
signal layer1out : layer1out_matrix := (others => (others => '0'));
signal layer2out : layer2out_matrix := (others => (others => '0'));
signal layer3out : layer3out_matrix := (others => (others => '0'));
signal layer4out : layer4out_matrix := (others => (others => '0'));
--

begin

process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0')then
            for i in 1 to hide_dim loop
	           data(i) <= addin((i*data_bit)-1 downto i*data_bit-data_bit);
		    end loop;   
        elsif (RESET = '1') then 
	       data <=(others => (others => '0'));
	    end if;
    end if;
end process;

min_Adder_layer1: for i in 1 to 16 generate
	Adder_1 : minAdder
		port map (
		    CLK => CLK,
			addin1 => data(i*2-1),
			addin2 => data(i*2),
			addout => layer1out(i)
		);
end generate min_Adder_layer1;

min_Adder_layer2: for i in 1 to 8 generate
	Adder_2 : minAdder
		port map (
		    CLK => CLK,
			addin1 => layer1out(i*2-1),
			addin2 => layer1out(i*2),
			addout => layer2out(i)
		);
end generate min_Adder_layer2;

min_Adder_layer3: for i in 1 to 4 generate
	Adder_3 : minAdder
		port map (
		    CLK => CLK,
			addin1 => layer2out(i*2-1),
			addin2 => layer2out(i*2),
			addout => layer3out(i)
		);
end generate min_Adder_layer3;

min_Adder_layer4: for i in 1 to 2 generate
	Adder_4 : minAdder
		port map (
		    CLK => CLK,
			addin1 => layer3out(i*2-1),
			addin2 => layer3out(i*2),
			addout => layer4out(i)
		);
end generate min_Adder_layer4;

process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0')then
            addout <= layer4out(1) + layer4out(2);
	    end if;
    end if;
end process;

end Behavioral;
