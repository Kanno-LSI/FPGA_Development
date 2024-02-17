library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity decoder is
    --定数関係
    Generic(
        data_dim : integer := 1024 ; --入力・出力層の大きさ(32×32=1024)
        hide_dim : integer := 32 ; --隠れ層の大きさ
        data_bit : integer := 8 ; --入力データのbit数
        weight_bit : integer := 16 ; --重みデータのbit数
        bias_bit : integer := 16 ;  --バイアスデータのbit数
        hide_bit : integer := 24 --隠れ層のbit数
    ) ;   
    --入出力線関係        
    Port ( 
        CLK : in STD_LOGIC ;
        RESET : in STD_LOGIC ;
        input_data : in STD_LOGIC_VECTOR ((24 * 32)-1 downto 0) ;
        output_data : out STD_LOGIC_VECTOR(8 * 1024 -1 downto 0) ;
        decoder_end : out STD_LOGIC
    ) ;
end decoder;

architecture Behavioral of decoder is


---もろもろのデータを入れているモジュール---
component decoder_weight_bram is
    Port (
    CLK : in STD_LOGIC;
    addr : in std_logic_vector(9 downto 0);
    weight_out : out std_logic_vector(511 downto 0)
    );
end component decoder_weight_bram;

component decoder_bias_bram is
    Port (
    CLK : in STD_LOGIC;
    addr : in std_logic_vector(9 downto 0);
    bias_out : out std_logic_vector(15 downto 0)
    );
end component decoder_bias_bram;
--------------------------------------------------------------

---符号付加算器のモジュール---
component Adder_out is
	port(
	   CLK : in STD_LOGIC;
	   RESET : in STD_LOGIC;
	   addin : in  std_logic_vector((8+16)*32-1 downto 0);
	   addout : out std_logic_vector(23 downto 0)
	   );
end component Adder_out;
-----------------------------------------------------------------------------------

---符号付乗算器のモジュール---
component Multiplier_out is
    Port (
        CLK : in STD_LOGIC;
        RESET : in STD_LOGIC;
		Multinput : in std_logic_vector(767 downto 0);
		Multweight : in std_logic_vector(511 downto 0);
		Multout : out std_logic_vector(767 downto 0) := (others => '0')
	);
end component Multiplier_out;
-------------------------------------------------------------------------------------------------

---内部信号-----------------------------------------
signal weight_data : STD_LOGIC_VECTOR(16 * 1024 * 32 -1 downto 0) ;
signal bias_data : STD_LOGIC_VECTOR(16 * 1024 -1 downto 0) ;

type bias_matrix is array(1 to 1024) of std_logic_vector(16-1 downto 0);
signal bias : bias_matrix := (others => (others => '0'));

type output_b_matrix is array(1 to 1024) of std_logic_vector(23 downto 0);
signal output_b : output_b_matrix := (others => (others => '0'));

type tempbias_matrix is array(1 to 1024) of std_logic_vector(23 downto 0);
signal tempbias : tempbias_matrix := (others => (others => '0'));

type output_matrix is array(1 to 1024) of std_logic_vector(23 downto 0);
signal output : output_matrix := (others => (others => '0'));

signal sinedinput_data : std_logic_vector(24*32-1 downto 0):= (others => '0');

signal multiplier_weight_temp : std_logic_vector(511 downto 0):= (others => '0');

signal in_wh_adder_temp : std_logic_vector(767 downto 0):= (others => '0');

signal output_b_temp : std_logic_vector(23 downto 0):= (others => '0');

signal counter2048 : integer:= 0;

signal bram_counter_w : std_logic_vector(9 downto 0):= (others => '0');
     
signal bram_counter_b : std_logic_vector(9 downto 0):= (others => '0');

signal output_b_temp_counter : integer:= 0;
signal bias_counter : integer:= 1;

signal bram_bias : std_logic_vector(15 downto 0):= (others => '0');

type state is ( IDLE,        -- This is the initial/idle state                    
                CALCULATION  -- This state initializes the counter
               ); 
-- State variable   
signal  counter_state : state:=IDLE;
signal  dec_end: std_logic:='0';
-------------------------------------------------------------------------------------------------

begin


---カウンタ-------------------------------
process(CLK)
begin
    if(rising_edge(CLK)) then
        if(RESET = '1')then
            counter2048 <= 0;
            counter_state <= CALCULATION;
        else
            if counter2048 = 1050 then
                counter2048 <= 0;
                counter_state <= IDLE;
            else
                counter2048 <= counter2048 + 1;
            end if;
        end if;
    end if;
end process;
-------------------------------------------



---入力データを保持--------------------------------------------------------
process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(counter2048 = 0)then
            if(RESET = '0')then
	           sinedinput_data <= input_data;
		    --リセットで初期化    
            elsif (RESET = '1') then 
	           sinedinput_data <= (others => '0');
	        end if;
        end if;       
    end if;
end process;
-----------------------------------------------------------------------------

---バイアス、重みデータの読み込み-----------------------
decoderweightbram : decoder_weight_bram 
    port map(
        CLK => CLK,
        addr => bram_counter_w,
        weight_out  => multiplier_weight_temp
    ); 

decoderbiasbram : decoder_bias_bram 
    port map(
        CLK => CLK,
        addr => bram_counter_b,
        bias_out  => bram_bias
    ); 
process(CLK)
    variable delay_counter : integer := 0;
begin
    if(rising_edge(CLK))then
        if(RESET = '1')then
            bram_counter_b <= (others => '0');
            delay_counter := 1;
        else
            if delay_counter < 1 then
                delay_counter := delay_counter + 1;
            else
                if counter2048 = 1050 then
                    bram_counter_b <= (others => '0');
                else
                    bram_counter_b <= bram_counter_b + 1;
                end if;
            end if;
        end if;
    end if;
end process;


process(CLK)
    variable delay_counter : integer := 0;
begin
    if(rising_edge(CLK))then
        if(RESET = '1')then
            bram_counter_w <= (others => '0');
            delay_counter := 0;
        else
            if counter2048 = 1050 then
               bram_counter_w <= (others => '0');
            else
                bram_counter_w <= bram_counter_w + 1;
            end if;
        end if;
    end if;
end process;
------------------------------------------------

---バイアスデータを格納------------------------------------
process(CLK)
    variable delay_counter : integer := 0;
begin
    if(rising_edge(CLK))then
        if(RESET = '1')then
            bias_counter <= 1;
            delay_counter := 0;
        else
            if delay_counter < 1 then
                delay_counter := delay_counter + 1;
            else
                if counter2048 = 1050 then
                    bias_counter <= 1;
                else
                    if bias_counter > 1023 then
                        bias_counter <= bias_counter;
                    else
                        bias_counter <= bias_counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

--process(CLK, RESET)
--    variable delay_counter : integer := 0;
--begin
--    if RESET = '1' then
--        bias_counter <= 1;
--        delay_counter := 0;
--    elsif rising_edge(CLK) then
--        if delay_counter < 1 then
--            delay_counter := delay_counter + 1;
--        else
--            if counter2048 = 1050 then
--                bias_counter <= 1;
--            else
--                if bias_counter > 31 then
--                    bias_counter <= bias_counter;
--                else
--                    bias_counter <= bias_counter + 1;
--                end if;
--            end if;
--        end if;
--    end if;
--end process;




process(CLK)
begin
    bias(bias_counter) <= bram_bias;
end process;
---------------------------------------------------------------

---入力データと重みデータの掛け合わせ-------------------------------------
Multiplier_out_32 : Multiplier_out
    port map (
        CLK => CLK,
        RESET => RESET, 
		Multinput => sinedinput_data,
		Multweight => multiplier_weight_temp,
		Multout => in_wh_adder_temp
        );
-------------------------------------------------------------------------------------

---加算器に入れて隠れ層を計算------------------------------------
Adder32to1 : Adder_out
    port map (
        RESET => RESET,
        CLK => CLK,
        addin => in_wh_adder_temp,
        addout => output_b_temp
        );
------------------------------------------------------------------

---加算器からのデータを格納---------------------------------------------------------
process(CLK)
    variable delay_counter : integer := 0;
begin
    if(rising_edge(CLK))then
        if(RESET = '1')then
            output_b_temp_counter <= 0;
            delay_counter := 0;
        else
            if delay_counter < 11 then
                delay_counter := delay_counter + 1;
            else
                if counter2048 = 1050 then
                    output_b_temp_counter <= 0;
                else
                    output_b_temp_counter <= output_b_temp_counter + 1;
                end if;
            end if;
        end if;
    end if;
end process;


process(CLK)
begin
    if output_b_temp_counter > 1023 then
    else
        output_b(output_b_temp_counter + 1) <= output_b_temp;
    end if;
end process;
------------------------------------------------------------------------------------------

---biasを16bitにする(16bitの精度で送ってもいいかも)---------------------
process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0')then
            for i in 1 to 1024 loop
                if(bias(i)(15) = '0') then
                    tempbias(i) <= "0" & bias(i) & "0000000";
                else
                    tempbias(i) <= "1" & bias(i) & "0000000";
                end if;
		    end loop;   
        elsif (RESET = '1') then 
	       tempbias <=(others => (others => '0'));
	    end if;
    end if;
end process;
--------------------------------------------------------------------------


---biasを足す---------------------------------------------
process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0')then
            for i in 1 to 1024 loop
                output(i) <= output_b(i) + tempbias(i);
		    end loop;   
        elsif (RESET = '1') then 
	       output <= (others => (others => '0'));
	    end if;
    end if;
end process;
------------------------------------------------------------------

---ReLU関数を通したのち1次元で出力---------------------------
decoder_end <= dec_end;
process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0'and counter2048 = 1049 and counter_state = CALCULATION)then
            for i in 1 to 1024 loop
                if(output(i)(23) = '0') then
                    output_data((i*8)-1 downto i*8-8) <= output(i)(21 downto 14);
                else
                    output_data((i*8)-1 downto i*8-8) <= "00000000";
                end if;
		    end loop;   
		    dec_end <= '1';   
        elsif (RESET = '1') then 
	       output_data <= (others => '0');
	       dec_end <= '0';
	    else
	       dec_end <= '0';
	    end if;
    end if;
end process;
----------------------------------------------------------------

end Behavioral;
