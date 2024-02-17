library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity state_machine is
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
        ENCODE_START : in std_logic;
        encoder_end : in std_logic;
        decoder_end : in std_logic;
        encoder_out : in STD_LOGIC_VECTOR(hide_bit * hide_dim -1 downto 0);--16bit×32 出力1次元
        
        ENCODE_ENABLE  : out std_logic;
        decoder_start: out std_logic;
        decoder_in :  out STD_LOGIC_VECTOR(hide_bit * hide_dim -1 downto 0)--16bit×32 出力1次元      
    );
end state_machine;

architecture Behavioral of state_machine is

    type state is ( IDLE,         -- 待機中 / データ保持無し
                    STORE_DATA,   -- 待機中 / 未出力データ保持                    
                    CALCULATION,  -- 計算中 / データ保持無し                    
                    CALC_AND_STORE-- 計算中 / 未出力データ保持
               ); 
    -- State variable                                     
    signal  encoder_state : state:=IDLE;
    signal  decoder_state : state:=IDLE;
    
    signal decoder_input : STD_LOGIC_VECTOR(hide_bit * hide_dim -1 downto 0):=(others => '0');--16bit×32 出力1次元
    signal encoder_enable : std_logic:='1';

begin

ENCODE_ENABLE <= encoder_enable;


----このstate_machineは
----（エンコーダの必要クロック数）<(デコーダの必要クロック数)
----の場合に使える
----逆の場合はデータ保持の概念が要らない
--decoder_in <= decoder_input;
--process(CLK)begin
--    if(rising_edge(CLK))then
--        --エンコーダ入力スタート
--        --エンコーダスタート信号は必ず待機中の場合に１になる
--        if(ENCODE_START = '1')then
--            if(encoder_state = IDLE)then
--                encoder_state <= CALCULATION;           
--            --store_data状態の場合はデータ保持しながら計算
--            elsif(encoder_state = STORE_DATA)then
--                encoder_state <= CALC_AND_STORE;
--            end if;
            
--            encoder_enable <= '0';
--        end if;
        
--        --エンコーダ計算終了
--        if(encoder_end = '1')then
--            encoder_state <= STORE_DATA;            
--            --input回路にエンコーダの準備完了を伝える
--            encoder_enable <= '1';
--        end if;
        
--        --デコーダ入力スタート
--        --デコーダが計算中の場合は処理しない
--        if(decoder_state = IDLE and (encoder_state = STORE_DATA or encoder_state = CALC_AND_STORE))then    
--            --デコーダスタート信号
--            decoder_start <= '1';
--            decoder_input <= encoder_out;
--            decoder_state <= CALCULATION;
            
--            if(encoder_state = STORE_DATA)then                
--                encoder_state <= IDLE;
--            --calc_and_store状態の場合は計算のみに
--            elsif(encoder_state = CALC_AND_STORE)then
--                encoder_state <= CALCULATION;
--            end if;
--        else
--            --デコーダスタート信号のみ0に戻す必要あり
--            decoder_start <= '0';
--        end if;
        
--        --デコーダ計算完了
--        if(decoder_end = '1')then
--            decoder_state <= IDLE;
--        end if;        
        
--    end if;
--end process;

--このstate_machineは
--（エンコーダの必要クロック数）>(デコーダの必要クロック数)
--の場合に使える
--逆の場合はデータ保持の概念が必要
decoder_in <= encoder_out;
decoder_start <= encoder_end;
process(CLK)begin
    if(rising_edge(CLK))then
        --エンコーダ入力スタート
        if(ENCODE_START = '1')then            
            encoder_enable <= '0';
        end if;
        
        --エンコーダ計算終了
        if(encoder_end = '1')then    
            --input回路にエンコーダの準備完了を伝える
            encoder_enable <= '1';
        end if;
    end if;
 end process;

end Behavioral;
