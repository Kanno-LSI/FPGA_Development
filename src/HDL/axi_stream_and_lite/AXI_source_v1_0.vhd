library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AXI_source_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXIS
		C_S00_AXIS_TDATA_WIDTH	: integer	:= 64;

		-- Parameters of Axi Master Bus Interface M00_AXIS
		C_M00_AXIS_TDATA_WIDTH	: integer	:= 64;
		C_M00_OUTPUT_DATA	: integer	:= 128;
		
		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXIS
		s00_axis_aclk	: in std_logic;
		s00_axis_aresetn	: in std_logic;
		s00_axis_tready	: out std_logic;
		s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
		s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast	: in std_logic;
		s00_axis_tvalid	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXIS
		m00_axis_aclk	: in std_logic;
		m00_axis_aresetn	: in std_logic;
		m00_axis_tvalid	: out std_logic;
		m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		m00_axis_tstrb	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast	: out std_logic;
		m00_axis_tready	: in std_logic;
		
		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic		
	);
end AXI_source_v1_0;

architecture arch_imp of AXI_source_v1_0 is

	-- component declaration
	component S_AXIS_source_v1_0_S00_AXIS is
		generic (
		C_S_AXIS_TDATA_WIDTH	: integer	:= 64
		);
		port (
		--fifo_a用
	    rden_a   : in std_logic;--fifo_aの読みだし許可signal. 自分の回路から読み出したいタイミングでアサート。
	    full_a   : out std_logic;--fifo_aのfull signal
	    empty_a  : out std_logic;--fifo_aのempty signal
	    dout_a   : out std_logic_vector(C_S_AXIS_TDATA_WIDTH - 1 downto 0);--fifo_aの読み出しデータ。自作回路への入力。自分の回路に接続。 
		
		S_AXIS_ACLK	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TLAST	: in std_logic;
		S_AXIS_TVALID	: in std_logic
		);
	end component S_AXIS_source_v1_0_S00_AXIS;

	component M_AXIS_source_v1_0_M00_AXIS is
		generic (
		C_M_AXIS_TDATA_WIDTH	: integer	:= 64;
		C_M_OUTPUT_DATA	: integer	:= 128
		);
		port (
		--fifo用
        wren_b : in std_logic;--fifo_bの書き込み許可signal. 自分の回路から書き込みたいタイミングでアサート。
        din_b : in std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);----fifo_bの書き込みデータ。自作回路からの出力。自分の回路に接続。
        slv_reg1_in : in std_logic_vector(32-1 downto 0);
		
		M_AXIS_ACLK	: in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_TVALID	: out std_logic;
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TLAST	: out std_logic;
		M_AXIS_TREADY	: in std_logic
		);
	end component M_AXIS_source_v1_0_M00_AXIS;
	
	-- component declaration
	component AXI_LITE_source_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		-- Users to add ports here
        slv_reg0_in  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        slv_reg1_in  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        slv_reg2_out : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        slv_reg3_out : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component AXI_LITE_source_v1_0_S00_AXI;

    --------------------------------------------------------------------------------
    ----自作回路に関連する記述はどこでもいいけど、このあたりにかくとおさまりがよい。
    --------------------------------------------------------------------------------
    component main is
	   Port(CLK  : in std_logic;
	        RSTN : in std_logic;
            Din  : in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
            empty: in std_logic;
            slv_reg0_in : in std_logic_vector(32-1 downto 0);
            --slv_reg1_in : in std_logic_vector(32-1 downto 0);
        
            fifoa_rden : out std_logic;
            Dout       : out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
            fifob_wren : out std_logic;
            --slv_reg1_out : out std_logic_vector(32-1 downto 0);
            slv_reg2_out : out std_logic_vector(32-1 downto 0);
            slv_reg3_out : out std_logic_vector(32-1 downto 0)
            );
	end component;
    
    --fifo用
	signal full_a   : std_logic;--fifo_aのfull signal
	signal empty_a  : std_logic;--fifo_aのempty signal
	signal dout_a   : std_logic_vector(C_S00_AXIS_TDATA_WIDTH - 1 downto 0);--fifo_aの読み出しデータ。自作回路への入力。自分の回路に接続。 
	signal rden_a   : std_logic;--fifo_aの読みだし許可signal. 自分の回路から読み出したいタイミングでアサート。

    signal wren_b : std_logic;--fifo_bの書き込み許可signal. 自分の回路から書き込みたいタイミングでアサート。
    signal din_b : std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);----fifo_bの書き込みデータ。自作回路からの出力。自分の回路に接続。
    
    signal slv_reg0_in  :  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg1_in  :  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg2_out :  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg3_out :  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    
begin

-- Instantiation of Axi Bus Interface S00_AXIS
S_AXIS_source_v1_0_S00_AXIS_inst : S_AXIS_source_v1_0_S00_AXIS
	generic map (
		C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_TDATA_WIDTH
	)
	port map (
        rden_a  => rden_a,
	    full_a  => full_a,
	    empty_a  => empty_a,
	    dout_a   => dout_a,
	
		S_AXIS_ACLK	=> s00_axis_aclk,
		S_AXIS_ARESETN	=> s00_axis_aresetn,
		S_AXIS_TREADY	=> s00_axis_tready,
		S_AXIS_TDATA	=> s00_axis_tdata,
		S_AXIS_TSTRB	=> s00_axis_tstrb,
		S_AXIS_TLAST	=> s00_axis_tlast,
		S_AXIS_TVALID	=> s00_axis_tvalid
	);

-- Instantiation of Axi Bus Interface M00_AXIS
M_AXIS_source_v1_0_M00_AXIS_inst : M_AXIS_source_v1_0_M00_AXIS
	generic map (
		C_M_AXIS_TDATA_WIDTH	=> C_M00_AXIS_TDATA_WIDTH,
		C_M_OUTPUT_DATA	=> C_M00_OUTPUT_DATA
	)
	port map (
        wren_b  => wren_b,
        din_b   => din_b,
        slv_reg1_in => slv_reg1_in,
	
		M_AXIS_ACLK	=> m00_axis_aclk,
		M_AXIS_ARESETN	=> m00_axis_aresetn,
		M_AXIS_TVALID	=> m00_axis_tvalid,
		M_AXIS_TDATA	=> m00_axis_tdata,
		M_AXIS_TSTRB	=> m00_axis_tstrb,
		M_AXIS_TLAST	=> m00_axis_tlast,
		M_AXIS_TREADY	=> m00_axis_tready
	);
	
-- Instantiation of Axi Bus Interface S00_AXI
AXI_LITE_source_v1_0_S00_AXI_inst : AXI_LITE_source_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	    slv_reg0_in => slv_reg0_in,
	    slv_reg1_in => slv_reg1_in,
	    slv_reg2_out => slv_reg2_out,
	    slv_reg3_out => slv_reg3_out,
	    	
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);	

	-- Add user logic here
	--------------------------------------------------
	--自作回路に必要な記述はこのあたりにまとめるとよい
	--------------------------------------------------
	MF_main:main
	port map(
	         CLK => s00_axis_aclk,
	         RSTN => s00_axis_aresetn,
             Din  => dout_a,
             empty => empty_a,
             slv_reg0_in => slv_reg0_in,
        
             fifoa_rden => rden_a,
             Dout => din_b,
             fifob_wren => wren_b,
             --slv_reg1_out => slv_reg1_out,
             slv_reg2_out => slv_reg2_out,
	         slv_reg3_out => slv_reg3_out
	         );
	-- User logic ends

end arch_imp;
