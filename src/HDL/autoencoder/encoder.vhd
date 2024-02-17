library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;
entity encoder is
    --�萔�֌W
    Generic(
        data_dim : integer := 1024 ; --���́E�o�͑w�̑傫��(16�~16=256)
        hide_dim : integer := 32 ; --�B��w�̑傫��
        data_bit : integer := 8 ; --���̓f�[�^��bit��
        weight_bit : integer := 16 ; --�d�݃f�[�^��bit��
        bias_bit : integer := 16 ;  --�o�C�A�X�f�[�^��bit��
        hide_bit : integer := 24 --�o��(�B��w)�f�[�^��bit��
    ) ;   
    --���o�͐��֌W        
    Port ( 
        CLK : in STD_LOGIC ;
        RESET : in STD_LOGIC ;
        input_data : in STD_LOGIC_VECTOR ((data_bit * 1024)-1 downto 0) ;--8bit�~1024 ����1����
        encoder_end : out STD_LOGIC;
        output_data : out STD_LOGIC_VECTOR(24 * 32 -1 downto 0)--16bit�~32 �o��1����       
    ) ;
end encoder;


architecture Behavioral of encoder is

---�������̃f�[�^�����Ă��郂�W���[��---
component encoder_weight_bram is
    Port (
    CLK : in STD_LOGIC;
    addr : in std_logic_vector(9 downto 0);
    weight_out : out std_logic_vector(511 downto 0)
    --weight_out : out std_logic_vector(16-1 downto 0)
    );
end component encoder_weight_bram;

component encoder_bias_bram is
    Port (
    CLK : in STD_LOGIC;
    addr : in std_logic_vector(9 downto 0);
    bias_out : out std_logic_vector(15 downto 0)
    );
end component encoder_bias_bram;
--------------------------------------------------------------


---�����t���Z��̃��W���[��---
component Adder is
	port(
	   CLK : in STD_LOGIC;
	   RESET : in STD_LOGIC;
	   addin : in  std_logic_vector((8+16)*1024-1 downto 0);
	   addout : out std_logic_vector(23 downto 0)
	   );
end component Adder;
-------------------------------------------------------------------------------

---�����t��Z��̃��W���[��---
component Multiplier is

    Port (
        CLK : in STD_LOGIC;
        RESET : in STD_LOGIC;
		Multinput : in std_logic_vector(287 downto 0);
		Multweight : in std_logic_vector(511 downto 0);
		Multout : out std_logic_vector(767 downto 0) := (others => '0')
	);
end component Multiplier;
---------------------------------------------------------------------------------------------------------------------------

---�����M��-----------------------------------------
signal weight_data : STD_LOGIC_VECTOR(16 * 1024 * 32 -1 downto 0) ;--16bit�~1024�~32 �d��1����


type input_matrix is array(1 to 1024) of std_logic_vector(8+1-1 downto 0); 
signal input : input_matrix := (others => (others => '0'));

type bias_matrix is array(1 to 32) of std_logic_vector(16-1 downto 0); 
signal bias : bias_matrix := (others => (others => '0'));

type hide_b_matrix is array(1 to 32) of std_logic_vector(24-1 downto 0);
signal hide_b : hide_b_matrix := (others => (others => '0'));

type tempbias_matrix is array(1 to 32) of std_logic_vector(24-1 downto 0);
signal tempbias : tempbias_matrix := (others => (others => '0'));

type hide_matrix is array(1 to 32) of std_logic_vector(24-1 downto 0);
signal hide : hide_matrix := (others => (others => '0'));

type sinedinput_data_matrix is array(1 to 32) of std_logic_vector(9 * 32 - 1 downto 0);
signal sinedinput_data : sinedinput_data_matrix := (others => (others => '0'));
--sinedinput_data 9bit�~1024�@��Z��ɑ���f�[�^�ɕ��������Ĉꎟ���ɂ�������

type multiplier_weight_matrix is array(1 to 32) of std_logic_vector(16*1024-1 downto 0); 
signal multiplier_weight : multiplier_weight_matrix := (others => (others => '0'));
--multiplier_weight(1�`32) 8bit�~1024�@��Z��ɑ���B��w1���������o���̂ɕK�v�ȏd�݈ꎟ���ɂ�������

signal multiplier_weight_temp : std_logic_vector(511 downto 0):= (others => '0');
--multiplier_weight_temp 8bit�~1024�@��Z��ɑ���B��w1���������ꎞ�����z��
--signal weight_test : std_logic_vector(16-1 downto 0):= (others => '0');

signal in_wh_adder : std_logic_vector(24575 downto 0):= (others => '0');

signal in_wh_adder_temp : std_logic_vector(767 downto 0):= (others => '0');

signal hide_b_temp : std_logic_vector(23 downto 0);

type state is ( IDLE,        -- This is the initial/idle state                    
                CALCULATION  -- This state initializes the counter
               ); 
-- State variable                                     
signal  counter_state : state:=IDLE;
--signal  init_st: std_logic:='0';
signal  enc_end: std_logic:='0';


signal counter2048 : integer:= 0;
signal bram_counter_b : std_logic_vector(9 downto 0):= (others => '0');
signal bram_counter_w : std_logic_vector(9 downto 0):= (others => '0');
signal sinedinput_data_counter : integer:= 0;
signal in_wh_adder_counter : integer:= 0;
signal bias_counter : integer:= 1;
signal hide_b_temp_counter : integer:= 0;
signal hide_b_counter : integer:= 0;
signal sinedinput_data_temp : std_logic_vector(9 * 32 - 1 downto 0);
signal adder_temp : std_logic_vector((8+16)*1024-1 downto 0):= (others => '0');
signal bram_bias : std_logic_vector(15 downto 0):= (others => '0');
signal output_data_reg : STD_LOGIC_VECTOR(24 * 32 -1 downto 0):= (others => '0');--16bit�~32 �o��1����     

---------------------------------------------------------------------------------------

begin

---�J�E���^-------------------------------
process(CLK)
begin
    if(rising_edge(CLK)) then
        if(RESET = '1')then
            counter2048 <= 0;
            counter_state <= CALCULATION;
        --else
        elsif(counter_state = CALCULATION)then
            if counter2048 = 1045 then
                counter2048 <= 0;
                counter_state <= IDLE;
            else
                counter2048 <= counter2048 + 1;
            end if;
        end if;
    end if;
end process;
-------------------------------------------

---���̓f�[�^�𕄍��t����--------------------------------
process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(counter2048 = 0)then
            if(RESET = '0')then
            --�e�f�[�^�̓ǂݍ���  
                --���̓f�[�^
                for i in 1 to 1024 loop--(1024����)
	               input(i) <= '0'&input_data(i*8-1 downto i*8-8);
		      end loop;
		  --���Z�b�g�ŏ�����    
            elsif (RESET = '1') then 
	           input <= (others => (others => '0'));
	        end if;
        end if;
    end if;
end process;
---------------------------------------------------------

---input��32�f�[�^���ɂ��Ĉꎟ����--------------------------
process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(counter2048 = 1)then
            if(RESET = '0')then
                for j in 1 to 32 loop --signed�p
                    for i in 1 to 32 loop --signed��32�����p
                        sinedinput_data(j)(i * 9 - 1 downto i * 9 - 9) <= input(32 * (j-1) + i);
                    end loop;
		      end loop;
            elsif (RESET = '1') then 
	           sinedinput_data <= (others => (others => '0'));
	       end if;
        end if;
    end if;
end process;
----------------------------------------------------------------------------

---�o�C�A�X�A�d�݃f�[�^�̓ǂݍ���-----------------------
encoderweightbram : encoder_weight_bram 
    port map(
        CLK => CLK,
        addr => bram_counter_w,
        weight_out  => multiplier_weight_temp
    ); 
--multiplier_weight_temp(15 downto 0) <= weight_test;

encoderbiasbram : encoder_bias_bram 
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
            delay_counter := 0;
        else
        --elsif(counter_state = CALCULATION)then
            if delay_counter < 0 then
                delay_counter := delay_counter + 1;
            else
                if counter2048 = 1045 then
                    bram_counter_b <= (others => '0');
                else
                    if bram_counter_b > 31 then
                        bram_counter_b <= bram_counter_b;
                    else
                        bram_counter_b <= bram_counter_b + 1;
                    end if;
--                bram_counter_b <= bram_counter_b + 1;
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
        --elsif(counter_state = CALCULATION)then
            if delay_counter < 2 then
                delay_counter := delay_counter + 1;
            else
                if counter2048 = 1045 then
                    bram_counter_w <= (others => '0');
                else
                    bram_counter_w <= bram_counter_w + 1;
                end if;
            end if;        
        end if;
    end if;
end process;
------------------------------------------------

---�o�C�A�X�f�[�^���i�[------------------------------------
process(CLK)
    variable delay_counter : integer := 0;
begin
    if(rising_edge(CLK))then
        if(RESET = '1')then
            bias_counter <= 1;
            delay_counter := 0;
        else
        --elsif(counter_state = CALCULATION)then
            if delay_counter < 1 then
                delay_counter := delay_counter + 1;
            else
                if counter2048 = 1045 then
                    bias_counter <= 1;
                else
                    if bias_counter > 31 then
                        bias_counter <= bias_counter;
                    else
                        bias_counter <= bias_counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;


process(CLK)
begin
    bias(bias_counter) <= bram_bias;
end process;
---------------------------------------------------------------



---���̓f�[�^�Əd�݃f�[�^�̊|�����킹-------------------------------------
Multiplier_32 : Multiplier
    port map (
        CLK => CLK,
        RESET => RESET, 
		Multinput => sinedinput_data_temp,
		Multweight => multiplier_weight_temp,
		Multout => in_wh_adder_temp
        );
        
process(CLK)
    variable delay_counter : integer := 0;
begin
    if(rising_edge(CLK))then
        if(RESET = '1')then
            sinedinput_data_counter <= 0;
            delay_counter := 0;
        else
        --elsif(counter_state = CALCULATION)then
            if delay_counter < 3 then
                delay_counter := delay_counter + 1;
            else
                if sinedinput_data_counter = 31 then
                    sinedinput_data_counter <= 0;
                else
                    sinedinput_data_counter <= sinedinput_data_counter + 1;
                end if;
            end if;
        end if;
    end if;
end process;

sinedinput_data_temp <= sinedinput_data(sinedinput_data_counter + 1);
-------------------------------------------------------------------------------------

---�|���Z�ŏo�Ă����f�[�^���܂Ƃ߂�------------------------------------------------

process(CLK)
    variable delay_counter : integer := 0;
begin
    if(rising_edge(CLK))then
        if(RESET = '1')then
            delay_counter := 0;
            in_wh_adder_counter <= 0;
        else
        --elsif(counter_state = CALCULATION)then
            if delay_counter < 6 then
                delay_counter := delay_counter + 1;
            else
                if in_wh_adder_counter = 31 then
                    in_wh_adder_counter <= 0;
                else
                    in_wh_adder_counter <= in_wh_adder_counter + 1;
                end if;
            end if;        
        end if;
    end if;
end process;

in_wh_adder((in_wh_adder_counter + 1) * 768 - 1 downto (in_wh_adder_counter + 1) * 768 - 768) <= in_wh_adder_temp;
-------------------------------------------------------------------------------------------

---���Z��ɓ���ĉB��w���v�Z------------------------------------
Adder1024to1 : Adder
    port map (
        RESET => RESET,
        CLK => CLK,
        addin => adder_temp,
        addout => hide_b_temp
        );

process(CLK)
    variable delay_counter : integer := 0;
begin
    if(rising_edge(CLK))then
        if(RESET = '1')then
            adder_temp <= (others => '0');
            delay_counter := 0;
        else
        --elsif(counter_state = CALCULATION)then
            if delay_counter < 1 then
                delay_counter := delay_counter + 1;
            else
                if sinedinput_data_counter = 2 then
                    adder_temp <= in_wh_adder;
                end if;
            end if;
        end if;
    end if;
end process;------------------------------------------------------------

---���Z�킩��̃f�[�^���i�[---------------------------------------------------------
process(CLK)
    variable delay_counter : integer := 0;
begin
    if(rising_edge(CLK))then
        if(RESET = '1')then
            hide_b_temp_counter <= 0;
            delay_counter := 0;
        else
        --elsif(counter_state = CALCULATION)then
            if delay_counter < 49 then
                delay_counter := delay_counter + 1;
            else
                if hide_b_temp_counter = 31 then
                    hide_b_temp_counter <= 0;
                else
                    hide_b_temp_counter <= hide_b_temp_counter + 1;
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
            hide_b_counter <= 0;
            delay_counter := 0;
        else
        --elsif(counter_state = CALCULATION)then
            if delay_counter < 11 then
                delay_counter := delay_counter + 1;
            else
                if hide_b_counter = 32 then
                    hide_b_counter <= 0;
                else
                    if hide_b_temp_counter = 1 then
                        hide_b_counter <= hide_b_counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

--�v����
process(CLK)
begin
    if(rising_edge(CLK))then
        if hide_b_counter > 32 then
        else
            if hide_b_temp_counter = 1 then
                hide_b(hide_b_counter+1) <= hide_b_temp;
            end if;
        end if;     
    end if;
end process;
------------------------------------------------------------------------------------------


---bias��16bit�ɂ���(16bit�̐��x�ő����Ă���������)---------------------
process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0')then
            for i in 1 to 32 loop
                if(bias(i)(15) = '0') then
                    tempbias(i) <= "00000" & bias(i) & "000"; --�����_�����킹�đ����K�v����
                else
                    tempbias(i) <= "11111" & bias(i) & "000"; --�����_�����킹�đ����K�v����
                end if;
		    end loop;   
        elsif (RESET = '1') then 
	       tempbias <=(others => (others => '0'));
	    end if;
    end if;
end process;
----------------------------------------------------------------------------

---bias�𑫂�---------------------------------------------
process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0')then
            for i in 1 to 32 loop
                hide(i) <= hide_b(i) + tempbias(i);
            end loop;
        elsif (RESET = '1') then 
	       hide <= (others => (others => '0'));
	    end if;
    end if;
end process;
-------------------------------------------------------------

---ReLU�֐���ʂ����̂�1�����ŏo��---------------------------
encoder_end <= enc_end;
output_data <= output_data_reg;
process(CLK)
begin   
    if (rising_edge(CLK)) then
        if(RESET = '0'and counter2048 = 1044 and counter_state = CALCULATION)then
            for i in 1 to 32 loop
                if(hide(i)(23) = '0') then
                    output_data_reg((i*24)-1 downto i*24-24) <= hide(i)(23 downto 0);
                else
                    output_data_reg((i*24)-1 downto i*24-24) <= "000000000000000000000000";
                end if;
		    end loop;
		    enc_end <= '1';   
        elsif (RESET = '1') then 
	     --  output_data <= (others => '0');
	       enc_end <= '0';
	    else
	       enc_end <= '0';
	    end if;
    end if;
end process;
----------------------------------------------------------------

end Behavioral;
