library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.all;
--use IEEE.NUMERIC_STD.ALL;

entity main is
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
          RSTN  : in std_logic;
          Din   : in std_logic_vector(axi_bit-1 downto 0);
          empty : in std_logic;
          --slave使用しない場合も残しておく
          slv_reg0_in : in std_logic_vector(32-1 downto 0);
          
          fifoa_rden : out std_logic;
          Dout       : out std_logic_vector(axi_bit-1 downto 0);
          fifob_wren : out std_logic;
          --slave使用しない場合も残しておく
         -- slv_reg1_out : out std_logic_vector(32-1 downto 0);
          slv_reg2_out : out std_logic_vector(32-1 downto 0);
          slv_reg3_out : out std_logic_vector(32-1 downto 0)
          
          );
end main;

architecture Behavioral of main is
    
 --========================================
--=component                             =
--========================================


component INPUT
    Port (CLK            : in std_logic;
          RSTN           : in std_logic;
          Din            : in std_logic_vector(axi_bit-1 downto 0);
          empty          : in std_logic;
          ENCODE_ENABLE  : in std_logic;

          fifoa_rden     : out std_logic;
          X              : out std_logic_vector(data_dim * data_bit -1 downto 0);
          ENCODE_START   : out std_logic      
          );
end component;   

--component Middle
--    Port (CLK    : in std_logic;
--          X           : in std_logic_vector(data_dim * data_bit -1 downto 0);
--          ENCODE_START   : in std_logic;
          
--          ENCODE_ENABLE  : out std_logic;
--          Y           : out std_logic_vector(data_dim * data_bit -1 downto 0);
--          Y_ENABLE    : out std_logic
--          );
--end component;

component AUTOENCODER
    Port(
        CLK : in std_logic;
        X : in std_logic_vector(data_dim * data_bit -1 downto 0);
        ENCODE_START : in std_logic;
        
        ENCODE_ENABLE  : out std_logic;
        Y : out std_logic_vector(data_dim * data_bit -1 downto 0);
        Y_ENABLE : out std_logic;
        slv_reg3_out : out std_logic_vector(31 downto 0)
    );
end component;

component OUTPUT
    Port (CLK    : in std_logic;
          Y           : in std_logic_vector(data_dim * data_bit -1 downto 0);
          Y_ENABLE    : in std_logic;
         -- slave2_in : in std_logic_vector(31 downto 0);

          Dout        : out std_logic_vector(axi_bit-1 downto 0);
          fifob_wren  : out std_logic
       --   slave3_out : out std_logic_vector(31 downto 0)
          );
end component;

component PS_operation_status    
    Port (CLK   : in std_logic;
          --slave使用しない場合も残しておく
          slv_reg0_in : in std_logic_vector(32-1 downto 0);


          fifob_wren : in std_logic;
          
          --slave使用しない場合も残しておく
         -- slv_reg1_out : out std_logic_vector(32-1 downto 0);
          slv_reg2_out : out std_logic_vector(32-1 downto 0)
         -- slv_reg3_out : out std_logic_vector(32-1 downto 0)
          
          );
end component;
--========================================


--========================================
--=signal                                =
--========================================       

    signal encode_start  : std_logic;
    signal encode_en : std_logic;
    signal x   : std_logic_vector(data_dim * data_bit -1 downto 0);
    
    signal y   : std_logic_vector(data_dim * data_bit -1 downto 0);
    signal y_en   : std_logic;
    
    signal fifob_wren_reg : std_logic:='0';

--========================================


begin
--========================================
--=Port map                              =
--========================================
         
INPUT_DATA:INPUT
port map(CLK => CLK,
         RSTN => RSTN,
         Din => Din,
         empty => empty,
         ENCODE_ENABLE => encode_en,
         
         fifoa_rden => fifoa_rden,
         X => x,    
         ENCODE_START => encode_start
         );

--CALCLATION_EMPTY:Middle
--port map(CLK => CLK,
--         X   => x,
--         ENCODE_START => encode_start,
         
--         ENCODE_ENABLE => encode_en,
--         Y   => y,
--         Y_ENABLE => y_en
--         );

CALCLATION:AUTOENCODER
port map(CLK => CLK,
         X   => x,
         ENCODE_START => encode_start,
         
         ENCODE_ENABLE => encode_en,
         Y   => y,
         Y_ENABLE => y_en,
         
         slv_reg3_out => slv_reg3_out
         );

fifob_wren <= fifob_wren_reg;
OUTPUT_DATA:OUTPUT
port map(CLK => CLK,
         Y   => y,
         Y_ENABLE => y_en,
        -- slave2_in => slave2_in,
         
         Dout => Dout,
         fifob_wren => fifob_wren_reg
     --    slave3_out => slave3_out
         );
         
PS_operation_status_inst:PS_operation_status
port map(CLK => CLK,
         slv_reg0_in => slv_reg0_in,
         fifob_wren => fifob_wren_reg,
         
         slv_reg2_out => slv_reg2_out
      --   slv_reg3_out => slv_reg3_out
        );


--========================================


--========================================
--=process                               =
--========================================


----========================================    
end Behavioral;