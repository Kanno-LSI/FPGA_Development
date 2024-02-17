library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.all;
--use IEEE.NUMERIC_STD.ALL;

entity AUTOENCODER is
    Generic(
        axi_bit : integer := 64;--PC�ʐM���̓��o�̓f�[�^��bit���B32bit�Œ�B
        data_dim : integer := 1024 ; --���́E�o�͑w�̑傫��(32�~32=1024)
        hide_dim : integer := 32 ; --�B��w�̑傫��
        data_bit : integer := 8 ; --���o�̓f�[�^��bit��
        weight_bit : integer := 16 ; --�d�݃f�[�^��bit��
        bias_bit : integer := 16 ;  --�o�C�A�X�f�[�^��bit��
        hide_bit : integer := 24 --�B��w�f�[�^��bit��
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
---�R���|�[�l���g------------------------------- 
component encoder
    Port(
        CLK : in STD_LOGIC ;
        RESET : in STD_LOGIC ;
        input_data : in STD_LOGIC_VECTOR (8192 -1 downto 0) ;--8bit�~1024 ����1����  
        encoder_end : out STD_LOGIC;
        output_data : out STD_LOGIC_VECTOR(768 -1 downto 0)--16bit�~32 �o��1����
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
        encoder_out : in STD_LOGIC_VECTOR(768 -1 downto 0);--16bit�~32 �o��1����
        
        ENCODE_ENABLE  : out std_logic;
        decoder_start: out std_logic;
        decoder_in :  out STD_LOGIC_VECTOR(768 -1 downto 0)--16bit�~32 �o��1���� 
    );
end component; 
---------------------------------------------------------------   

    signal encoder_out : STD_LOGIC_VECTOR(768 -1 downto 0):=(others => '0');--16bit�~32 �o��1����
    signal decoder_in : STD_LOGIC_VECTOR(768 -1 downto 0):=(others => '0');--16bit�~32 �o��1����

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