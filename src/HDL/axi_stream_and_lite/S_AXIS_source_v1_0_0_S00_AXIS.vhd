library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity S_AXIS_source_v1_0_S00_AXIS is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- AXI4Stream sink: Data Width
		C_S_AXIS_TDATA_WIDTH	: integer	:= 64
	);
	port (
		-- Users to add ports here
	    rden_a   : in std_logic;--fifo_aの読みだし許可signal. 自分の回路から読み出したいタイミングでアサート。
	    full_a   : out std_logic;--fifo_aのfull signal
	    empty_a  : out std_logic;--fifo_aのempty signal
	    dout_a   : out std_logic_vector(C_S_AXIS_TDATA_WIDTH - 1 downto 0);--fifo_aの読み出しデータ。自作回路への入力。自分の回路に接続。   
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- AXI4Stream sink: Clock
		S_AXIS_ACLK	: in std_logic;
		-- AXI4Stream sink: Reset
		S_AXIS_ARESETN	: in std_logic;
		-- Ready to accept data in
		S_AXIS_TREADY	: out std_logic;
		-- Data in
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		-- Byte qualifier
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- Indicates boundary of last packet
		S_AXIS_TLAST	: in std_logic;
		-- Data is in valid
		S_AXIS_TVALID	: in std_logic
	);
end S_AXIS_source_v1_0_S00_AXIS;

architecture arch_imp of S_AXIS_source_v1_0_S00_AXIS is
    --------------------------------------------------
	----fifo記述部分
	--------------------------------------------------
	component fifo is
	   generic(
	       WIDTH : integer := 64;
	       DEPTH : integer := 8192);
	       
	   port(
	       clk : in std_logic;
	       srst : in std_logic;
	       wr_en : in std_logic;
	       rd_en : in std_logic;
	       din : in std_logic_vector(WIDTH - 1 downto 0);
	       
	       full : out std_logic;
	       empty : out std_logic;
	       dout : out std_logic_vector(WIDTH - 1 downto 0)
       
	       );
    end component;
    
    component fifo_generator_0 IS
    PORT (
        clk : IN STD_LOGIC;
        srst : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        wr_rst_busy : OUT STD_LOGIC;
        rd_rst_busy : OUT STD_LOGIC
    );
    END component;
 
	--fifo用
    signal srst : std_logic;
    
    constant FIFO_DEPTH : integer := 8192;--fifoの深さ。	
	
	-- function called clogb2 that returns an integer which has the 
	-- value of the ceiling of the log base 2.
	function clogb2 (bit_depth : integer) return integer is 
	variable depth  : integer := bit_depth;
	  begin
	    if (depth = 0) then
	      return(0);
	    else
	      for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
	        if(depth <= 1) then 
	          return(clogb2);      
	        else
	          depth := depth / 2;
	        end if;
	      end loop;
	    end if;
	end;    

	-- Total number of input data.
	constant NUMBER_OF_INPUT_WORDS  : integer := 8192;
	-- bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
	constant bit_num  : integer := clogb2(NUMBER_OF_INPUT_WORDS-1);
	-- Define the states of state machine
	-- The control state machine oversees the writing of input streaming data to the FIFO,
	-- and outputs the streaming data from the FIFO
	type state is ( IDLE,        -- This is the initial/idle state 
	                WRITE_FIFO); -- In this state FIFO is written with the
	                             -- input stream data S_AXIS_TDATA 
	signal axis_tready	: std_logic;
	-- State variable
	signal  mst_exec_state : state;  
	-- FIFO implementation signals
	signal  byte_index : integer;    
	-- FIFO write enable
	signal fifo_wren : std_logic;
	-- FIFO full flag
	signal fifo_full_flag : std_logic;
	-- FIFO write pointer
	signal write_pointer : integer range 0 to bit_num-1 ;
	-- sink has accepted all the streaming data and stored in FIFO
	signal writes_done : std_logic;

	type BYTE_FIFO_TYPE is array (0 to (NUMBER_OF_INPUT_WORDS-1)) of std_logic_vector(((C_S_AXIS_TDATA_WIDTH/4)-1)downto 0);
begin
	-- I/O Connections assignments

	S_AXIS_TREADY	<= axis_tready;
	-- Control state machine implementation
	process(S_AXIS_ACLK)
	begin
	  if (rising_edge (S_AXIS_ACLK)) then
	    if(S_AXIS_ARESETN = '0') then
	      -- Synchronous reset (active low)
	      mst_exec_state      <= IDLE;
	    else
	      case (mst_exec_state) is
	        when IDLE     => 
	          -- The sink starts accepting tdata when 
	          -- there tvalid is asserted to mark the
	          -- presence of valid streaming data 
	          if (S_AXIS_TVALID = '1')then
	            mst_exec_state <= WRITE_FIFO;
	          else
	            mst_exec_state <= IDLE;
	          end if;
	      
	        when WRITE_FIFO => 
	          -- When the sink has accepted all the streaming input data,
	          -- the interface swiches functionality to a streaming master
	          if (writes_done = '1') then
	            mst_exec_state <= IDLE;
	          else
	            -- The sink accepts and stores tdata 
	            -- into FIFO
	            mst_exec_state <= WRITE_FIFO;
	          end if;
	        
	        when others    => 
	          mst_exec_state <= IDLE;
	        
	      end case;
	    end if;  
	  end if;
	end process;
	-- AXI Streaming Sink 
	-- 
	-- The example design sink is always ready to accept the S_AXIS_TDATA  until
	-- the FIFO is not filled with NUMBER_OF_INPUT_WORDS number of input words.
	--axis_tready <= '1' when ((mst_exec_state = WRITE_FIFO) and (write_pointer <= NUMBER_OF_INPUT_WORDS-1)) else '0';
    axis_tready <= '1';
    
	process(S_AXIS_ACLK)
	begin
	  if (rising_edge (S_AXIS_ACLK)) then
	    if(S_AXIS_ARESETN = '0') then
	      write_pointer <= 0;
	      writes_done <= '0';
	    else
	      if (write_pointer <= NUMBER_OF_INPUT_WORDS-1) then
	        if (fifo_wren = '1') then
	          -- write pointer is incremented after every write to the FIFO
	          -- when FIFO write signal is enabled.
	          write_pointer <= write_pointer + 1;
	          writes_done <= '0';
	        end if;
	        if ((write_pointer = NUMBER_OF_INPUT_WORDS-1) or S_AXIS_TLAST = '1') then
	          -- reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
	          -- has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
	          writes_done <= '1';
	        end if;
	      end  if;
	    end if;
	  end if;
	end process;
    
	-- FIFO write enable generation
	fifo_wren <= S_AXIS_TVALID and axis_tready;

	-- FIFO Implementation
--	 FIFO_GEN: for byte_index in 0 to (C_S_AXIS_TDATA_WIDTH/8-1) generate

--	 signal stream_data_fifo : BYTE_FIFO_TYPE;
--	 begin   
--	  -- Streaming input data is stored in FIFO
--	  process(S_AXIS_ACLK)
--	  begin
--	    if (rising_edge (S_AXIS_ACLK)) then
--	      if (fifo_wren = '1') then
--	        stream_data_fifo(write_pointer) <= S_AXIS_TDATA((byte_index*8+7) downto (byte_index*8));
--	      end if;  
--	    end  if;
--	  end process;

--	end generate FIFO_GEN;

	-- Add user logic here
	--いじるのはここから下にしておいた方が楽。別に他の部分変えてみてもいいよ。
    srst <= not S_AXIS_ARESETN;
    ------------------------------
    --CPUからの入力を保存するfifo
    ------------------------------
--    fifo_a : fifo
--	generic map(
--	       WIDTH => C_S_AXIS_TDATA_WIDTH,
--	       DEPTH => FIFO_DEPTH)
	       
--	port map (
--	       clk => S_AXIS_ACLK,
--	       srst => srst,

--	       wr_en => fifo_wren,
--	       rd_en => rden_a,	       
--	       din => S_AXIS_TDATA,

--	       full => full_a,
--	       empty => empty_a,
--	       dout => dout_a
--	       );
	         
	fifo_a : fifo_generator_0       
	port map (
	       clk => S_AXIS_ACLK,
	       srst => srst,
	       wr_en => fifo_wren,
	       rd_en => rden_a,
	       din => S_AXIS_TDATA,
	       	       
	       full => full_a,
	       empty => empty_a,
	       dout => dout_a
	    --   wr_rst_busy => wr_rst_busy,
	    --   rd_rst_busy => rd_rst_busy

	       ); 

	-- User logic ends
end arch_imp;
