library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity M_AXIS_source_v1_0_M00_AXIS is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		C_M_AXIS_TDATA_WIDTH	: integer	:= 64;
		-- Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
		C_M_OUTPUT_DATA	: integer	:= 128
	);
	port (
		-- Users to add ports here
        wren_b : in std_logic;--fifo_bの書き込み許可signal. 自分の回路から書き込みたいタイミングでアサート。
        din_b : in std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);----fifo_bの書き込みデータ。自作回路からの出力。自分の回路に接続。
        slv_reg1_in : in std_logic_vector(32-1 downto 0);
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global ports
		M_AXIS_ACLK	: in std_logic;
		-- 
		M_AXIS_ARESETN	: in std_logic;
		-- Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		M_AXIS_TVALID	: out std_logic;
		-- TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		-- TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- TLAST indicates the boundary of a packet.
		M_AXIS_TLAST	: out std_logic;
		-- TREADY indicates that the slave can accept a transfer in the current cycle.
		M_AXIS_TREADY	: in std_logic
	);
end M_AXIS_source_v1_0_M00_AXIS;

architecture implementation of M_AXIS_source_v1_0_M00_AXIS is
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
    signal full_b : std_logic;--fifo_bのfull signal
    signal empty_b : std_logic;--fifo_bのempty signal
    signal wr_rst_busy : std_logic;
    signal rd_rst_busy : std_logic;
    
	-- Total number of output data                                              
--	constant NUMBER_OF_OUTPUT_WORDS : integer := 16384;                                   

--	 -- function called clogb2 that returns an integer which has the   
--	 -- value of the ceiling of the log base 2.                              
--	function clogb2 (bit_depth : integer) return integer is                  
--	 	variable depth  : integer := bit_depth;                               
--	 	variable count  : integer := 1;                                       
--	 begin                                                                   
--	 	 for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
--	      if (bit_depth <= 2) then                                           
--	        count := 1;                                                      
--	      else                                                               
--	        if(depth <= 1) then                                              
--	 	       count := count;                                                
--	 	     else                                                             
--	 	       depth := depth / 2;                                            
--	          count := count + 1;                                            
--	 	     end if;                                                          
--	 	   end if;                                                            
--	   end loop;                                                             
--	   return(count);        	                                              
--	 end;                                                                    

	 -- WAIT_COUNT_BITS is the width of the wait counter.                       
	 --constant  WAIT_COUNT_BITS  : integer := clogb2(C_M_START_COUNT-1);               
	                                                                                  
--	-- In this example, Depth of FIFO is determined by the greater of                 
--	-- the number of input words and output words.                                    
--	constant depth : integer := NUMBER_OF_OUTPUT_WORDS;                               
	                                                                                  
	-- bit_num gives the minimum number of bits needed to address 'depth' size of FIFO
	--constant bit_num : integer := clogb2(depth);                                      
	                                                                                  
--	-- Define the states of state machine                                             
--	-- The control state machine oversees the writing of input streaming data to the FIFO,
--	-- and outputs the streaming data from the FIFO                                   
--	type state is ( IDLE,        -- This is the initial/idle state                    
--	                INIT_COUNTER,  -- This state initializes the counter, once        
--	                                -- the counter reaches C_M_START_COUNT count,     
--	                                -- the state machine changes state to SEND_STREAM  
--	                SEND_STREAM);  -- In this state the                               
--	                             -- stream data is output through M_AXIS_TDATA        
--	-- State variable                                                                 
--	signal  mst_exec_state : state;                                                   
--	-- Example design FIFO read pointer                                               
--	signal read_pointer : integer range 0 to depth-1;                               

	-- AXI Stream internal signals
	--wait counter. The master waits for the user defined number of clock cycles before initiating a transfer.
	--signal count	: std_logic_vector(WAIT_COUNT_BITS-1 downto 0);
	--streaming data valid
	signal axis_tvalid	: std_logic;
	signal axis_tvalid_1	: std_logic;
	signal axis_tvalid_2	: std_logic;
	signal axis_tvalid_3	: std_logic;
	signal axis_tvalid_4	: std_logic;
	--streaming data valid delayed by one clock cycle
	signal axis_tvalid_delay	: std_logic;
	--Last of the streaming data 
	signal axis_tlast	: std_logic;
	--Last of the streaming data delayed by one clock cycle
	signal axis_tlast_delay	: std_logic;
	--FIFO implementation signals
	signal stream_data_out	: std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
	signal tx_en	: std_logic;
	--The master has issued all the streaming data stored in FIFO
	signal tx_done	: std_logic;

    --tlast
    signal tlast_counter : integer range 0 to C_M_OUTPUT_DATA*64-1 := 0;
    signal tlast_counter_start	: std_logic:='0';
    --debag
    signal debag_counter: integer range 0 to 10 := 0;
    signal slave1 : std_logic_vector(32-1 downto 0):= (others => '0');
    signal DATA_COUNT_MAX : integer ;--counterの最大値（slave1で制御）

begin
	-- I/O Connections assignments

	--M_AXIS_TVALID	<= axis_tvalid_delay;
	M_AXIS_TVALID	<= '1';
	M_AXIS_TDATA	<= stream_data_out;
	--M_AXIS_TLAST	<= axis_tlast_delay;
	M_AXIS_TSTRB	<= (others => '1');


--	-- Control state machine implementation                                               
--	process(M_AXIS_ACLK)                                                                        
--	begin                                                                                       
--	  if (rising_edge (M_AXIS_ACLK)) then                                                       
--	    if(M_AXIS_ARESETN = '0') then                                                           
--	      -- Synchronous reset (active low)                                                     
--	      mst_exec_state      <= IDLE;                                                          
--	      count <= (others => '0');                                                             
--	    else                                                                                    
--	      case (mst_exec_state) is                                                              
--	        when IDLE     =>                                                                    
--	          -- The slave starts accepting tdata when                                          
--	          -- there tvalid is asserted to mark the                                           
--	          -- presence of valid streaming data                                               
--	          --if (count = "0")then                                                            
--	            mst_exec_state <= INIT_COUNTER;                                                 
--	          --else                                                                              
--	          --  mst_exec_state <= IDLE;                                                         
--	          --end if;                                                                           
	                                                                                            
--	          when INIT_COUNTER =>                                                              
--	            -- This state is responsible to wait for user defined C_M_START_COUNT           
--	            -- number of clock cycles.                                                      
--	            if ( count = std_logic_vector(to_unsigned((C_M_START_COUNT - 1), WAIT_COUNT_BITS))) then
--	              mst_exec_state  <= SEND_STREAM;                                               
--	            else                                                                            
--	              count <= std_logic_vector (unsigned(count) + 1);                              
--	              mst_exec_state  <= INIT_COUNTER;                                              
--	            end if;                                                                         
	                                                                                            
--	        when SEND_STREAM  =>                                                                
--	          -- The example design streaming master functionality starts                       
--	          -- when the master drives output tdata from the FIFO and the slave                
--	          -- has finished storing the S_AXIS_TDATA                                          
--	          if (tx_done = '1') then                                                           
--	            mst_exec_state <= IDLE;                                                         
--	          else                                                                              
--	            mst_exec_state <= SEND_STREAM;                                                  
--	          end if;                                                                           
	                                                                                            
--	        when others    =>                                                                   
--	          mst_exec_state <= IDLE;                                                           
	                                                                                            
--	      end case;                                                                             
--	    end if;                                                                                 
--	  end if;                                                                                   
--	end process;                                                                                


	--tvalid generation
	--axis_tvalid is asserted when the control state machine's state is SEND_STREAM and
	--number of output streaming data is less than the NUMBER_OF_OUTPUT_WORDS.
	--axis_tvalid <= '1' when ((mst_exec_state = SEND_STREAM) and (read_pointer < NUMBER_OF_OUTPUT_WORDS)) else '0';
	--axis_tvalid <= '1' when ((mst_exec_state = SEND_STREAM) and (read_pointer < NUMBER_OF_OUTPUT_WORDS) and (init_tready > 10)) else '0';

	
	process(M_AXIS_ACLK)begin
	   if(rising_edge(M_AXIS_ACLK))then
	       
--	       axis_tvalid_1 <= M_AXIS_TREADY;
--	       axis_tvalid_2 <= axis_tvalid_1;
--	       axis_tvalid_3 <= axis_tvalid_2;
--	       axis_tvalid_4 <= axis_tvalid_3;
--	       axis_tvalid  <= axis_tvalid_4;
	       
	       --axis_tvalid<=M_AXIS_TREADY;
	       
	       --debag
--	       slv_reg1_out <= slave1;
--	       if(M_AXIS_TREADY='1')then
--	           if(stream_data_out = std_logic_vector(to_unsigned(1, 64)))then
--	               slave1 <= std_logic_vector(to_unsigned(debag_counter, 32));
--	           else
--	               if(debag_counter=10)then
--	                   debag_counter <= 0;
--	               else
--	                   debag_counter <= debag_counter+1;
--	               end if;
	               
--	           end if;
	           
--	       end if;
           if(slv_reg1_in = std_logic_vector(to_unsigned(0, 32)))then
                DATA_COUNT_MAX <= C_M_OUTPUT_DATA;
           elsif(slv_reg1_in = std_logic_vector(to_unsigned(1, 32)))then
                DATA_COUNT_MAX <= C_M_OUTPUT_DATA-4;
           elsif(slv_reg1_in = std_logic_vector(to_unsigned(2, 32)))then
                DATA_COUNT_MAX <= C_M_OUTPUT_DATA * 4;
           elsif(slv_reg1_in = std_logic_vector(to_unsigned(3, 32)))then
                DATA_COUNT_MAX <= C_M_OUTPUT_DATA * 4 -4;
           elsif(slv_reg1_in = std_logic_vector(to_unsigned(4, 32)))then
                DATA_COUNT_MAX <= C_M_OUTPUT_DATA * 16;
           elsif(slv_reg1_in = std_logic_vector(to_unsigned(5, 32)))then
                DATA_COUNT_MAX <= C_M_OUTPUT_DATA * 16 -4;
           elsif(slv_reg1_in = std_logic_vector(to_unsigned(6, 32)))then
                DATA_COUNT_MAX <= C_M_OUTPUT_DATA * 64;               
           else
                DATA_COUNT_MAX <= C_M_OUTPUT_DATA;
           end if;
	       
	       if(M_AXIS_ARESETN = '0') then
	           M_AXIS_TLAST <= '0';
	       end if;
	       
	       if(M_AXIS_TREADY='1')then
	           tlast_counter_start <= '1';
	           tlast_counter <= 1;
	       end if;    
	       
	       if(tlast_counter_start = '1')then
	       	   if(tlast_counter = DATA_COUNT_MAX-2)then --data数-2	               
	               M_AXIS_TLAST <= '1';
	               tlast_counter <= tlast_counter + 1;
	           elsif(tlast_counter = DATA_COUNT_MAX-1)then  --data数-1
	               tlast_counter <= 0;
	               tlast_counter_start <= '0';
	               M_AXIS_TLAST <= '0';
	           else
	               tlast_counter <= tlast_counter + 1;
	           end if;
	       end if;
	       
	       
	       
	   end if;
	end process;
	
--	--axis_tvalid <= '0' when (stream_data_out =std_logic_vector(to_unsigned(0, 32))) else '1';
	axis_tvalid <= '1';
	                                                                                               
--	-- AXI tlast generation                                                                        
--	-- axis_tlast is asserted number of output streaming data is NUMBER_OF_OUTPUT_WORDS-1          
--	-- (0 to NUMBER_OF_OUTPUT_WORDS-1)                                                             
--	axis_tlast <= '1' when (read_pointer = NUMBER_OF_OUTPUT_WORDS-1) else '0';                     
	                                                                                               
--	-- Delay the axis_tvalid and axis_tlast signal by one clock cycle                              
--	-- to match the latency of M_AXIS_TDATA                                                        
--	process(M_AXIS_ACLK)                                                                           
--	begin                                                                                          
--	  if (rising_edge (M_AXIS_ACLK)) then                                                          
--	    if(M_AXIS_ARESETN = '0') then                                                              
--	      axis_tvalid_delay <= '0';                                                                
--	      axis_tlast_delay <= '0';                                                                 
--	    else                                                                                       
--	      axis_tvalid_delay <= axis_tvalid;                                                        
--	      axis_tlast_delay <= axis_tlast;                                                          
--	    end if;                                                                                    
--	  end if;                                                                                      
--	end process;                                                                                   


--	--read_pointer pointer

--	process(M_AXIS_ACLK)                                                       
--	begin                                                                            
--	  if (rising_edge (M_AXIS_ACLK)) then                                            
--	    if(M_AXIS_ARESETN = '0') then                                                
--	      read_pointer <= 0;                                                         
--	      tx_done  <= '0';                                                           
--	    else                                                                         
--	      if (read_pointer <= NUMBER_OF_OUTPUT_WORDS-1) then                         
--	        if (tx_en = '1') then                                                    
--	          -- read pointer is incremented after every read from the FIFO          
--	          -- when FIFO read signal is enabled.                                   
--	          read_pointer <= read_pointer + 1;                                      
--	          tx_done <= '0';                                                        
--	        end if;                                                                  
--	      elsif (read_pointer = NUMBER_OF_OUTPUT_WORDS) then                         
--	        -- tx_done is asserted when NUMBER_OF_OUTPUT_WORDS numbers of streaming data
--	        -- has been out.                                                         
--	        tx_done <= '1';                                                          
--	      end  if;                                                                   
--	    end  if;                                                                     
--	  end  if;                                                                       
--	end process;                                                                     


--	--FIFO read enable generation 

--	tx_en <= M_AXIS_TREADY and axis_tvalid;                                   
                                                                             
	-- FIFO Implementation                                                          
	                                                                                
	-- Streaming output data is read from FIFO                                      
--	  process(M_AXIS_ACLK)                                                          
--	  variable  sig_one : integer := 1;                                             
--	  begin                                                                         
--	    if (rising_edge (M_AXIS_ACLK)) then                                         
--	      if(M_AXIS_ARESETN = '0') then                                             
--	    	stream_data_out <= std_logic_vector(to_unsigned(sig_one,C_M_AXIS_TDATA_WIDTH));  
--	      elsif (tx_en = '1') then -- && M_AXIS_TSTRB(byte_index)                   
--	        stream_data_out <= std_logic_vector( to_unsigned(read_pointer,C_M_AXIS_TDATA_WIDTH) + to_unsigned(sig_one,C_M_AXIS_TDATA_WIDTH));
--	      end if;                                                                   
--	     end if;                                                                    
--	   end process;                                                                 

	-- Add user logic here
	--いじるのはここから下にしておいた方が楽。別に他の部分変えてみてもいいよ。
    srst <= not M_AXIS_ARESETN;
    ------------------------------
    --CPUへの出力を保存するfifo
    ------------------------------       
--	fifo_b : fifo
--	generic map(
--	       WIDTH => C_M_AXIS_TDATA_WIDTH,
--	       DEPTH => FIFO_DEPTH)
	       
--	port map (
--	       clk => M_AXIS_ACLK,
--	       srst => srst,
--	       wr_en => wren_b,
--	       rd_en => M_AXIS_TREADY,
--	      -- rd_en => tx_en,
--	       din => din_b,
	       	       
--	       full => full_b,
--	       empty => empty_b,
--	       dout => M_AXIS_TDATA

--	       );
	       
	fifo_b : fifo_generator_0       
	port map (
	       clk => M_AXIS_ACLK,
	       srst => srst,
	       wr_en => wren_b,
	       rd_en => M_AXIS_TREADY,
	      -- rd_en => tx_en,
	       din => din_b,
	       	       
	       full => full_b,
	       empty => empty_b,
	       --dout => M_AXIS_TDATA
	       dout => stream_data_out
	    --   wr_rst_busy => wr_rst_busy,
	    --   rd_rst_busy => rd_rst_busy

	       );   

	-- User logic ends

end implementation;
