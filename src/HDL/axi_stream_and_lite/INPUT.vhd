library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.all;
--use IEEE.NUMERIC_STD.ALL;

entity INPUT is

    Generic(
        RAMaddressbit : integer := 13;
        RAMaddressnum : integer := 8192;
        axi_bit : integer := 64;--PC通信時の入出力データのbit数。32bit固定。
        data_dim : integer := 1024 ; --入力・出力層の大きさ(32×32=1024)
        hide_dim : integer := 32 ; --隠れ層の大きさ
        data_bit : integer := 8 ; --入出力データのbit数
        weight_bit : integer := 8 ; --重みデータのbit数
        bias_bit : integer := 8 ;  --バイアスデータのbit数
        hide_bit : integer := 16; --隠れ層データのbit数        
        x_count_max : integer := 32*32*8/64-1 --１枚の画像の分割数(入力層数×ビット数/AXIのビット幅)

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

    --状態管理用信号
    signal INPUT_TIMING     : std_logic:='0';--元々は1
    signal full             : std_logic:='0';
    signal stay             : integer range 0 to 2 := 0;
    signal x_count          : integer range 0 to x_count_max := 0;
    signal tmp_x_en         : std_logic:='0';
    signal x_en             : std_logic:='0';

    --encoder制御用信号
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
            
                    if(x_count = x_count_max)then--tmp_xに値が揃った場合に次のセットへ
                        x_count <= 0;
                        tmp_x_en <= '1';
                    else
                        x_count <= x_count + 1;
                    end if;
                end if;
                
                if(tmp_x_en = '1')then--tmp_xに値が揃ったらXの値を更新
                    X <= tmp_x;
                    tmp_x_en <= '0';
                    x_en <= '1';                
                end if;
                          
                if(x_en = '1' and ENCODE_ENABLE = '1')then--autoencderの準備ができていたらのencoder回路にstart信号（ready要らなければここは不要かも）
                    encode_st <= '1';                
                    x_en <= '0';
                else
                    encode_st <= '0';                            
                end if;
            end if;      
        end if;
             
    end process;

    
end Behavioral;
