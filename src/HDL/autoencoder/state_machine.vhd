library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity state_machine is
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
        ENCODE_START : in std_logic;
        encoder_end : in std_logic;
        decoder_end : in std_logic;
        encoder_out : in STD_LOGIC_VECTOR(hide_bit * hide_dim -1 downto 0);--16bit�~32 �o��1����
        
        ENCODE_ENABLE  : out std_logic;
        decoder_start: out std_logic;
        decoder_in :  out STD_LOGIC_VECTOR(hide_bit * hide_dim -1 downto 0)--16bit�~32 �o��1����      
    );
end state_machine;

architecture Behavioral of state_machine is

    type state is ( IDLE,         -- �ҋ@�� / �f�[�^�ێ�����
                    STORE_DATA,   -- �ҋ@�� / ���o�̓f�[�^�ێ�                    
                    CALCULATION,  -- �v�Z�� / �f�[�^�ێ�����                    
                    CALC_AND_STORE-- �v�Z�� / ���o�̓f�[�^�ێ�
               ); 
    -- State variable                                     
    signal  encoder_state : state:=IDLE;
    signal  decoder_state : state:=IDLE;
    
    signal decoder_input : STD_LOGIC_VECTOR(hide_bit * hide_dim -1 downto 0):=(others => '0');--16bit�~32 �o��1����
    signal encoder_enable : std_logic:='1';

begin

ENCODE_ENABLE <= encoder_enable;


----����state_machine��
----�i�G���R�[�_�̕K�v�N���b�N���j<(�f�R�[�_�̕K�v�N���b�N��)
----�̏ꍇ�Ɏg����
----�t�̏ꍇ�̓f�[�^�ێ��̊T�O���v��Ȃ�
--decoder_in <= decoder_input;
--process(CLK)begin
--    if(rising_edge(CLK))then
--        --�G���R�[�_���̓X�^�[�g
--        --�G���R�[�_�X�^�[�g�M���͕K���ҋ@���̏ꍇ�ɂP�ɂȂ�
--        if(ENCODE_START = '1')then
--            if(encoder_state = IDLE)then
--                encoder_state <= CALCULATION;           
--            --store_data��Ԃ̏ꍇ�̓f�[�^�ێ����Ȃ���v�Z
--            elsif(encoder_state = STORE_DATA)then
--                encoder_state <= CALC_AND_STORE;
--            end if;
            
--            encoder_enable <= '0';
--        end if;
        
--        --�G���R�[�_�v�Z�I��
--        if(encoder_end = '1')then
--            encoder_state <= STORE_DATA;            
--            --input��H�ɃG���R�[�_�̏���������`����
--            encoder_enable <= '1';
--        end if;
        
--        --�f�R�[�_���̓X�^�[�g
--        --�f�R�[�_���v�Z���̏ꍇ�͏������Ȃ�
--        if(decoder_state = IDLE and (encoder_state = STORE_DATA or encoder_state = CALC_AND_STORE))then    
--            --�f�R�[�_�X�^�[�g�M��
--            decoder_start <= '1';
--            decoder_input <= encoder_out;
--            decoder_state <= CALCULATION;
            
--            if(encoder_state = STORE_DATA)then                
--                encoder_state <= IDLE;
--            --calc_and_store��Ԃ̏ꍇ�͌v�Z�݂̂�
--            elsif(encoder_state = CALC_AND_STORE)then
--                encoder_state <= CALCULATION;
--            end if;
--        else
--            --�f�R�[�_�X�^�[�g�M���̂�0�ɖ߂��K�v����
--            decoder_start <= '0';
--        end if;
        
--        --�f�R�[�_�v�Z����
--        if(decoder_end = '1')then
--            decoder_state <= IDLE;
--        end if;        
        
--    end if;
--end process;

--����state_machine��
--�i�G���R�[�_�̕K�v�N���b�N���j>(�f�R�[�_�̕K�v�N���b�N��)
--�̏ꍇ�Ɏg����
--�t�̏ꍇ�̓f�[�^�ێ��̊T�O���K�v
decoder_in <= encoder_out;
decoder_start <= encoder_end;
process(CLK)begin
    if(rising_edge(CLK))then
        --�G���R�[�_���̓X�^�[�g
        if(ENCODE_START = '1')then            
            encoder_enable <= '0';
        end if;
        
        --�G���R�[�_�v�Z�I��
        if(encoder_end = '1')then    
            --input��H�ɃG���R�[�_�̏���������`����
            encoder_enable <= '1';
        end if;
    end if;
 end process;

end Behavioral;
