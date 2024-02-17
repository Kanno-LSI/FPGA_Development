library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.all;
--use IEEE.NUMERIC_STD.ALL;

entity AUTOENCODER is
    Generic(
        axi_bit : integer := 64;--PC通信時の入出力データのbit数。32bit固定。
        data_dim : integer := 1024 ; --入力・出力層の大きさ(32×32=1024)
        hide_dim : integer := 32 ; --隠れ層の大きさ
        data_bit : integer := 8 ; --入出力データのbit数
        weight_bit : integer := 16 ; --重みデータのbit数
        bias_bit : integer := 16 ;  --バイアスデータのbit数
        hide_bit : integer := 24 --隠れ層データのbit数
    );

    Port(
        CLK : in std_logic;
        X : in std_logic_vector(8192 -1 downto 0);
        ENCODE_START : in std_logic;
        ENCODE_ENABLE  : out std_logic;
        Y : out std_logic_vector(8192 -1 downto 0);
        Y_ENABLE : out std_logic;
        
        slv_reg3_out : out std_logic_vector(31 downto 0)
    );
end AUTOENCODER;

architecture Behavioral of AUTOENCODER is
---コンポーネント------------------------------- 
component encoder
    Port(
        CLK : in STD_LOGIC ;
        RESET : in STD_LOGIC ;
        input_data : in STD_LOGIC_VECTOR (8192 -1 downto 0) ;--8bit×1024 入力1次元  
        encoder_end : out STD_LOGIC;
        output_data : out STD_LOGIC_VECTOR(768 -1 downto 0)--16bit×32 出力1次元
    );
end component;   

component decoder
    Port(
        CLK : in STD_LOGIC ;
        RESET : in STD_LOGIC ;
        input_data : in STD_LOGIC_VECTOR (768-1 downto 0);
        decoder_end : out STD_LOGIC;
        output_data : out STD_LOGIC_VECTOR(8192 -1 downto 0)
    ); 
end component;

component state_machine
    Port(
        CLK : in std_logic;
        ENCODE_START : in std_logic;
        encoder_end : in std_logic;
        decoder_end : in std_logic;
        encoder_out : in STD_LOGIC_VECTOR(768 -1 downto 0);--16bit×32 出力1次元
        
        ENCODE_ENABLE  : out std_logic;
        decoder_start: out std_logic;
        decoder_in :  out STD_LOGIC_VECTOR(768 -1 downto 0)--16bit×32 出力1次元 
    );
end component; 
---------------------------------------------------------------   

    signal encoder_out : STD_LOGIC_VECTOR(768 -1 downto 0):=(others => '0');--16bit×32 出力1次元
    signal decoder_in : STD_LOGIC_VECTOR(768 -1 downto 0):=(others => '0');--16bit×32 出力1次元

    signal  encoder_end : std_logic:='0';
    signal  decoder_start: std_logic:='0';
    signal  decoder_end : std_logic:='0';

begin

process(CLK)begin
    if(rising_edge(CLK))then
        if(encoder_end = '1')then
            slv_reg3_out <= encoder_out(31 downto 0);
        end if;
    end if;
end process;


Y_ENABLE <= decoder_end;

encoder_inst : encoder
port map(
    CLK => CLK,
    RESET => ENCODE_START,
    input_data => X,
    encoder_end => encoder_end,
    output_data => encoder_out
    );
 
decoder_inst : decoder
port map(
    CLK => CLK,
    RESET => decoder_start,
    input_data => decoder_in,    
    decoder_end => decoder_end,
    output_data => Y
    );

state_machine_inst : state_machine
port map(
    CLK => CLK,
    ENCODE_START => ENCODE_START,
    encoder_end => encoder_end, 
    decoder_end => decoder_end,
    encoder_out => encoder_out,
    ENCODE_ENABLE => ENCODE_ENABLE,
    decoder_start => decoder_start,
    decoder_in => decoder_in
    );   
        
end Behavioral
;