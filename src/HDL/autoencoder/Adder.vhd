library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity Adder is
    Generic(
        data_dim : integer := 1024 ; 
        data_bit : integer := 24 
    ) ;   
    Port (
        CLK : in STD_LOGIC;
        RESET : in STD_LOGIC;
		addin : in std_logic_vector(24*1024-1 downto 0);
		addout : out std_logic_vector(23 downto 0) := (others => '0')
	);
end Adder;

architecture Behavioral of Adder is

---•„†•t‰ÁŽZŠí‚Ìƒ‚ƒWƒ…[ƒ‹---
component minAdder is
	port(
	   CLK : in STD_LOGIC;
	   addin1 : in std_logic_vector(23 downto 0);
	   addin2 : in std_logic_vector(23 downto 0);
	   addout : out std_logic_vector(23 downto 0)
	   );
end component minAdder;

type data_matrix is array(1 to data_dim) of std_logic_vector(23 downto 0); 
signal data : data_matrix := (others => (others => '0'));

--‰ÁŽZŠí”z—ñ
type layer1out_matrix is array(1 to 512) of std_logic_vector(23 downto 0); 
type layer2out_matrix is array(1 to 256) of std_logic_vector(23 downto 0); 
type layer3out_matrix is array(1 to 128) of std_logic_vector(23 downto 0); 
type layer4out_matrix is array(1 to 64) of std_logic_vector(23 downto 0); 
type layer5out_matrix is array(1 to 32) of std_logic_vector(23 downto 0); 
type layer6out_matrix is array(1 to 16) of std_logic_vector(23 downto 0); 
type layer7out_matrix is array(1 to 8) of std_logic_vector(23 downto 0); 
type layer8out_matrix is array(1 to 4) of std_logic_vector(23 downto 0); 
type layer9out_matrix is array(1 to 2) of std_logic_vector(23 downto 0); 

signal layer1out : layer1out_matrix := (others => (others => '0'));
signal layer2out : layer2out_matrix := (others => (others => '0'));
signal layer3out : layer3out_matrix := (others => (others => '0'));
signal layer4out : layer4out_matrix := (others => (others => '0'));
signal layer5out : layer5out_matrix := (others => (others => '0'));
signal layer6out : layer6out_matrix := (others => (others => '0'));
signal layer7out : layer7out_matrix := (others => (others => '0'));
signal layer8out : layer8out_matrix := (others => (others => '0'));
signal layer9out : layer9out_matrix := (others => (others => '0'));
--

begin

process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0')then
            for i in 1 to data_dim loop
                if(addin((i*data_bit)-1) = '0') then
	               data(i) <= "00000" & addin((i*data_bit)-1 downto i*data_bit-data_bit+5);
	            else
	               data(i) <= "11111" & addin((i*data_bit)-1 downto i*data_bit-data_bit+5);
	            end if;
		    end loop;   
        elsif (RESET = '1') then 
	       data <=(others => (others => '0'));
	    end if;
    end if;
end process;

min_Adder_layer1: for i in 1 to 512 generate
	Adder_1 : minAdder
		port map (
		    CLK => CLK,
			addin1 => data(i*2-1),
			addin2 => data(i*2),
			addout => layer1out(i)
		);
end generate min_Adder_layer1;

min_Adder_layer2: for i in 1 to 256 generate
	Adder_2 : minAdder
		port map (
		    CLK => CLK,
			addin1 => layer1out(i*2-1),
			addin2 => layer1out(i*2),
			addout => layer2out(i)
		);
end generate min_Adder_layer2;

min_Adder_layer3: for i in 1 to 128 generate
	Adder_3 : minAdder
		port map (
		    CLK => CLK,
			addin1 => layer2out(i*2-1),
			addin2 => layer2out(i*2),
			addout => layer3out(i)
		);
end generate min_Adder_layer3;

min_Adder_layer4: for i in 1 to 64 generate
	Adder_4 : minAdder
		port map (
		    CLK => CLK,
			addin1 => layer3out(i*2-1),
			addin2 => layer3out(i*2),
			addout => layer4out(i)
		);
end generate min_Adder_layer4;

min_Adder_layer5: for i in 1 to 32 generate
	Adder_5 : minAdder
		port map (
		    CLK => CLK,
			addin1 => layer4out(i*2-1),
			addin2 => layer4out(i*2),
			addout => layer5out(i)
		);
end generate min_Adder_layer5;

min_Adder_layer6: for i in 1 to 16 generate
	Adder_6 : minAdder
		port map (
		    CLK => CLK,
			addin1 => layer5out(i*2-1),
			addin2 => layer5out(i*2),
			addout => layer6out(i)
		);
end generate min_Adder_layer6;

min_Adder_layer7: for i in 1 to 8 generate
	Adder_7 : minAdder
		port map (
		    CLK => CLK,
			addin1 => layer6out(i*2-1),
			addin2 => layer6out(i*2),
			addout => layer7out(i)
		);
end generate min_Adder_layer7;

min_Adder_layer8: for i in 1 to 4 generate
	Adder_8 : minAdder
		port map (
		    CLK => CLK,
			addin1 => layer7out(i*2-1),
			addin2 => layer7out(i*2),
			addout => layer8out(i)
		);
end generate min_Adder_layer8;

min_Adder_layer9: for i in 1 to 2 generate
	Adder_9 : minAdder
		port map (
		    CLK => CLK,
			addin1 => layer8out(i*2-1),
			addin2 => layer8out(i*2),
			addout => layer9out(i)
		);
end generate min_Adder_layer9;

process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0')then
            addout <= layer9out(1) +  layer9out(2);
	    end if;
    end if;
end process;

end Behavioral;