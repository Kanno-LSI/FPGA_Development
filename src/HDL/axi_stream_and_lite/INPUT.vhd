library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.all;
--use IEEE.NUMERIC_STD.ALL;

entity INPUT is

    Generic(
        RAMaddressbit : integer := 13;
        RAMaddressnum : integer := 8192;
        axi_bit : integer := 64;--PC�ʐM���̓��o�̓f�[�^��bit���B32bit�Œ�B
        data_dim : integer := 1024 ; --���́E�o�͑w�̑傫��(32�~32=1024)
        hide_dim : integer := 32 ; --�B��w�̑傫��
        data_bit : integer := 8 ; --���o�̓f�[�^��bit��
        weight_bit : integer := 8 ; --�d�݃f�[�^��bit��
        bias_bit : integer := 8 ;  --�o�C�A�X�f�[�^��bit��
        hide_bit : integer := 16; --�B��w�f�[�^��bit��        
        x_count_max : integer := 32*32*8/64-1 --�P���̉摜�̕�����(���͑w���~�r�b�g��/AXI�̃r�b�g��)

    );

    Port (CLK    : in std_logic;
          RSTN   : in std_logic;
          Din    : in std_logic_vector(axi_bit-1 downto 0);
          empty  : in std_logic;
          ENCODE_ENABLE  : in std_logic;

          fifoa_rden : out std_logic;
          X          : out std_logic_vector(data_dim * data_bit -1 downto 0);
          ENCODE_START   : out std_logic          
          );
end INPUT;

architecture Behavioral of INPUT is


    signal tmp_x  : std_logic_vector(data_dim * data_bit -1 downto 0):=CONV_STD_LOGIC_VECTOR(0,data_dim * data_bit);

    --��ԊǗ��p�M��
    signal INPUT_TIMING     : std_logic:='0';--���X��1
    signal full             : std_logic:='0';
    signal stay             : integer range 0 to 2 := 0;
    signal x_count          : integer range 0 to x_count_max := 0;
    signal tmp_x_en         : std_logic:='0';
    signal x_en             : std_logic:='0';

    --encoder����p�M��
    signal encode_st : std_logic:='0';


begin

    
    INPUT_TIMING  <= (not empty) and (not x_en);
    fifoa_rden <= INPUT_TIMING;
   
    
    ENCODE_START <= encode_st;
    
    process(CLK)begin
        if(rising_edge(CLK))then
            if(RSTN = '0')then
                X <= (others => '0');
            else                        
                if(INPUT_TIMING  = '1')then
                    tmp_x(x_count * axi_bit + axi_bit-1 downto x_count * axi_bit+0) <= Din(axi_bit-1 downto 0);
            
                    if(x_count = x_count_max)then--tmp_x�ɒl���������ꍇ�Ɏ��̃Z�b�g��
                        x_count <= 0;
                        tmp_x_en <= '1';
                    else
                        x_count <= x_count + 1;
                    end if;
                end if;
                
                if(tmp_x_en = '1')then--tmp_x�ɒl����������X�̒l���X�V
                    X <= tmp_x;
                    tmp_x_en <= '0';
                    x_en <= '1';                
                end if;
                          
                if(x_en = '1' and ENCODE_ENABLE = '1')then--autoencder�̏������ł��Ă������encoder��H��start�M���iready�v��Ȃ���΂����͕s�v�����j
                    encode_st <= '1';                
                    x_en <= '0';
                else
                    encode_st <= '0';                            
                end if;
            end if;      
        end if;
             
    end process;

    
end Behavioral;
