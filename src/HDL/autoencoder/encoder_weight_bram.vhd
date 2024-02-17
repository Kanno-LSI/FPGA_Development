library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use std.textio.all;

entity encoder_weight_bram is
    Generic(
    RAMaddressbit : integer := 10;
    RAMaddressnum : integer := 1024;
    data_bit : integer := 32*16
    );
    Port (
    CLK : in STD_LOGIC;
    addr : in std_logic_vector(10 -1 downto 0);
    weight_out : out std_logic_vector(32*16 - 1 downto 0)
    --weight_out : out std_logic_vector(16 - 1 downto 0)
    );
end encoder_weight_bram;

architecture Behavioral of encoder_weight_bram is
    --for ram--
    type rom_type is array(0 to 1024 -1) of std_logic_vector(32*16 -1 downto 0);
    --type rom_type is array(0 to 1024 -1) of std_logic_vector(16 -1 downto 0);
    --type rom_type is array(0 to 32 -1) of signed(32*8 -1 downto 0);

    impure function store_rom_data return rom_type is
       -- file text_file : text is in "encoder_weight.txt";
        file text_file : text is in "tsunami_encoder_weight.txt";
        variable text_line : line;
        variable rom_content : rom_type;  
        variable line_bit : bit_vector(32*16 -1 downto 0);
        --variable line_bit : bit_vector(16 -1 downto 0);
        
    begin
        for i in 0 to 1024 -1 loop
            readline(text_file, text_line); 
            read(text_line, line_bit); 
            rom_content(i) := std_logic_vector(to_stdlogicvector(line_bit));
            --rom_content(i) := signed(to_stdlogicvector(line_bit));
            
        end loop;  


        return rom_content;
    end function;

    signal rom_temp : rom_type := store_rom_data;
    attribute RAM_STYLE : string;
    attribute RAM_STYLE of rom_temp : signal is "block";
    signal weight_data : std_logic_vector(511 downto 0) := (others => '0');
    --signal weight_data : std_logic_vector(16-1 downto 0) := (others => '0');
    
begin
    weight_out <= weight_data;

    process(CLK)
    begin
        if(rising_edge(CLK)) then
            weight_data <= rom_temp(to_integer(unsigned(addr)));
        end if;
    end process;
end Behavioral;
