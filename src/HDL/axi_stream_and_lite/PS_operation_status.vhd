library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.all;
--use IEEE.NUMERIC_STD.ALL;

entity PS_operation_status is
    Generic(
        RAMaddressbit : integer := 13;
        RAMaddressnum : integer := 8192;
        axi_bit : integer :=64;--PC通信時の入出力データのbit数。32bit固定。
        data_dim : integer := 1024 ; --入力・出力層の大きさ(32×32=1024)
        hide_dim : integer := 32 ; --隠れ層の大きさ
        data_bit : integer := 8 ; --入出力データのbit数
        weight_bit : integer := 8 ; --重みデータのbit数
        bias_bit : integer := 8 ;  --バイアスデータのbit数
        hide_bit : integer := 16 --隠れ層データのbit数
    );

    Port (CLK   : in std_logic;
          --slave使用しない場合も残しておく
          slv_reg0_in : in std_logic_vector(32-1 downto 0);


          fifob_wren : in std_logic;
          
          --slave使用しない場合も残しておく
         -- slv_reg1_out : out std_logic_vector(32-1 downto 0);
          slv_reg2_out : out std_logic_vector(32-1 downto 0)
          slv_reg3_out : out std_logic_vector(32-1 downto 0)
          
          );
end PS_operation_status;

architecture Behavioral of PS_operation_status is

    signal fifob_wren_reg : std_logic:='0';
    signal wren_on : std_logic:='0';
    signal read_on : std_logic:='0';
    signal write_on : std_logic:='0';
    
    signal PL_counter : std_logic_vector(32-1 downto 0):=CONV_STD_LOGIC_VECTOR(0,32);
    signal slv2_reg : std_logic_vector(32-1 downto 0):=CONV_STD_LOGIC_VECTOR(0,32);
    signal slv3_reg : std_logic_vector(32-1 downto 0):=CONV_STD_LOGIC_VECTOR(0,32);

begin

 fifob_wren_reg <= fifob_wren;

--slv_reg0_in:PS側状態信号 0:idle 1:wtite 2:read
--slv_reg1_in
--slv_reg2_out:read_enable
--slv_reg3_calc_counter 
slv_reg2_out <= slv2_reg;
slv_reg3_out <= slv3_reg;
process(CLK)begin
    if(rising_edge(CLK))then
        if(slv_reg0_in =CONV_STD_LOGIC_VECTOR(0,32))then--idle
                  
            if(PL_counter = "11111111111111111111111111111111")then
                PL_counter <= PL_counter;
            elsif(PL_counter >= CONV_STD_LOGIC_VECTOR(1,32))then
                PL_counter <= PL_counter +1;
            end if;
            
        elsif(slv_reg0_in =CONV_STD_LOGIC_VECTOR(1,32))then--write
            
            --PL_counter_start(一度のみ)
            if(write_on='0')then
                write_on <= '1';
                read_on <= '0';
                PL_counter <= CONV_STD_LOGIC_VECTOR(0,32);
            elsif(PL_counter = "11111111111111111111111111111111")then
                PL_counter <= PL_counter;
            else    
                PL_counter <= PL_counter +1;
            end if;
            
        elsif(slv_reg0_in =CONV_STD_LOGIC_VECTOR(2,32))then--read
            
            --CLK_counter_stop(１度のみ)
            if(read_on='0')then
                read_on <= '1';
                write_on <= '0';
                slv3_reg <= PL_counter;
            end if;
        end if;
        
        --計算完了set数
        if(fifob_wren_reg = '1')then
            if(wren_on = '0')then
                slv2_reg <= slv2_reg + 1;
                wren_on <= '1';
            end if;
        else
            wren_on <= '0';
        end if;
              
    end if;

end process;

end Behavioral;
