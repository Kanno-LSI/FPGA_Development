----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/11/08 19:25:40
-- Design Name: 
-- Module Name: OUTPUT - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.all;
--use IEEE.NUMERIC_STD.ALL;
--use work.typedef.all;

entity OUTPUT is

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
        
        y_count_max : integer := 32*32*8/64-1 --�P���̉摜�̕�����(�o�͑w���~�r�b�g��/AXI�̃r�b�g��)
    );

    Port (CLK    : in std_logic;
          Y           : in std_logic_vector(data_dim * data_bit -1 downto 0);
          Y_ENABLE    : in std_logic;
      --    slave2_in : in std_logic_vector(31 downto 0);

          
          Dout        : out std_logic_vector(axi_bit-1 downto 0);
          fifob_wren  : out std_logic
     --     slave3_out : out std_logic_vector(31 downto 0)
          );
end OUTPUT;

architecture Behavioral of OUTPUT is    
    
    signal  y_out   : std_logic_vector(data_dim * data_bit -1 downto 0):=CONV_STD_LOGIC_VECTOR(0,data_dim * data_bit);
    signal  divived_en     : std_logic:='0';
    signal  y_count : integer range 0 to y_count_max := 0;

signal addr : std_logic_vector(10 -1 downto 0);
signal weight_out : std_logic_vector(32*8 - 1 downto 0);
signal y_out_reg   : std_logic_vector(axi_bit -1 downto 0) :=(others => '0');

begin

Dout <= y_out_reg(64-1 downto 0);
    
    
    process(CLK)begin
        if(rising_edge(CLK))then
            if(Y_ENABLE = '1')then
                y_out <= Y;
                divived_en <= '1';

            end if;
            
            if(divived_en = '1')then
                --Dout <= y_out(y_count * axi_bit + axi_bit -1 downto y_count * axi_bit +0);
                y_out_reg <= y_out(y_count * axi_bit + axi_bit -1 downto y_count * axi_bit +0);
                fifob_wren <= '1';
                if(y_count = y_count_max)then
                    y_count <= 0; 
                    divived_en <= '0';
                else
                    y_count <= y_count + 1;                            
                end if;
            else 
                fifob_wren <= '0';
            end if;
            
            
        end if;
        
    end process;
end Behavioral;