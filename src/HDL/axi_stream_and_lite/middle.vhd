----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/11/07 19:09:11
-- Design Name: 
-- Module Name: middle - Behavioral
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

entity Middle is

    Generic(
       -- RAMaddressbit : integer := 13;
       -- RAMaddressnum : integer := 8192;
        data_bit : integer := 64;--PC’ÊM‚Ì“üo—Íƒf[ƒ^‚Ìbit”B32bitŒÅ’èB
        M : integer := 32;--‰B‚ê‘w‚Ìƒ†ƒjƒbƒg”
        N : integer := 32*32;--
        x_bit : integer := 8;--“ü—Í‘wbit
        W1_bit : integer := 8;--“ü—Í‘w¨‰B‚ê‘wd‚İbit
        b1_bit : integer := 8;--“ü—Í‘w¨‰B‚ê‘wƒoƒCƒAƒXbit
        a_bit : integer := 8;--‰B‚ê‘wbit
        W2_bit : integer := 8;--‰B‚ê‘w¨o—Í‘wd‚İbit
        b2_bit : integer := 8;--‰B‚ê‘w¨o—Í‘wƒoƒCƒAƒXbit
        y_bit : integer := 8--o—Í‘wbit
    );

    Port (CLK    : in std_logic;
          X           : in std_logic_vector(N*x_bit-1 downto 0);
--          W1          : in std_logic_vector(M*N*W1_bit-1 downto 0);
--          B1          : in std_logic_vector(M*b1_bit-1 downto 0);
--          W2          : in std_logic_vector(M*N*W2_bit-1 downto 0);
--          B2          : in std_logic_vector(M*b2_bit-1 downto 0);
          ENCODE_START   : in std_logic;
          
          ENCODE_ENABLE  : out std_logic;
          Y           : out std_logic_vector(N*y_bit-1 downto 0);
          Y_ENABLE    : out std_logic
          );
end Middle;

architecture Behavioral of Middle is


    signal  y_out   : std_logic_vector(N*x_bit-1 downto 0);
    signal  y_en    : std_logic:='0';
    signal  encode_en : std_logic:='1';
    signal  delay_counter    : std_logic_vector(31 downto 0):=CONV_STD_LOGIC_VECTOR(0,32);
    signal  count_start    : std_logic:='0';
    signal  count_enable    : std_logic:='0';

begin

    Y <= y_out;
    Y_ENABLE <= y_en;
    ENCODE_ENABLE <= encode_en;

--    process(CLK)begin
--        if(rising_edge(CLK))then
--            if(ENCODE_START = '1')then
--                count_start <= '1';
--            end if;
            
--            if(count_start = '1')then
--                --if(delay_counter = "00000000"&"11111111"&"11111111"&"11111111")then
--                if(delay_counter = "00000000"&"00000000"&"00000000"&"11111111")then
--                    delay_counter <= (others => '0');
--                    count_start <= '0';
--                    count_enable <= '1';
--                else
--                    delay_counter <= delay_counter + 1;
--                end if;            
--            else
--                count_enable <= '0';
--            end if;
--        end if;
--    end process;

    process(CLK)begin
        if(rising_edge(CLK))then
            if(ENCODE_START = '1')then
            --if(count_enable = '1')then
                y_out <= X;
                y_en <= '1';
            else
                y_en <= '0';
            end if;
            
            if(y_en = '1')then
                encode_en <= '0';
            else
                encode_en <= '1';
            end if;
                       
        end if;       
    end process;
end Behavioral;
