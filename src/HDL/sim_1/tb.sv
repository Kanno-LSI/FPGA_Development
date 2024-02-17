`timescale 1ns / 1ps

import axi_vip_pkg::*;
import test_bench_axi_vip_0_0_pkg::*;


module tb();

    // 適当な値を設定
    parameter STEP = 5;


    bit iclk, irstn;
    test_bench_wrapper dut(.iclk(iclk),.irstn(irstn));
    bit[8*4096-1:0] data_block_for_read;
    

    // クロック生成
    task clk_gen();
        iclk = 0;
        forever #(STEP/2) iclk = ~iclk;
    endtask
    
    default clocking cb@(posedge iclk);
    endclocking

    // リセット信号生成   
    task rst_gen();
        irstn = 0;
        ##(5);
        irstn = 1;
    endtask
    
       

    // agentとtransactionを宣言
    test_bench_axi_vip_0_0_mst_t vip_agent;   
    axi_transaction wr_transaction, rd_transaction;


    initial begin
        fork
            clk_gen();
            rst_gen();
        join_none

        ##(50);

        // Init AXI agent
        vip_agent = new("my vip agent", tb.dut.test_bench_i.axi_vip_0.inst.IF);
        vip_agent.start_master();

        //---------------
        // Write Transactions
        //---------------
       
         //if addr = 0 then slv_reg0_in
         //if addr = 4 then slv_reg1_in
         //if addr = 8 then slv_reg2_out
         //if addr = 12 then slv_reg3_out
         
         single_write_transaction_api(.addr(0),.data(0));//idle
         single_write_transaction_api(.addr(4),.data(0));//count_max
         ##(10);
         single_write_transaction_api(.addr(0),.data(1));//write
         ##(1000);
         set_read_transaction (rd_transaction,.addr(8));//set_count
         get_rd_data_block_back(rd_transaction,data_block_for_read);
         
         single_write_transaction_api(.addr(0),.data(2));//read
         ##(10);
         set_read_transaction (rd_transaction,.addr(12));//clk_counter
         get_rd_data_block_back(rd_transaction,data_block_for_read);
         
         
//         //addr = 0 write 
//        for (int i = 0; i < 128; i++) begin
//            single_write_transaction_api(.addr(0),.data(i));
//        end;
         
//         //addr = 4 write
//        single_write_transaction_api(.addr(0),.data('b11111111111111111111111111111111));
         
//        ##(200);
         
//         //addr = 8 read
//        for (int i = 0; i < 10; i++) begin
//            set_read_transaction (rd_transaction,.addr(8));
//            get_rd_data_block_back(rd_transaction,data_block_for_read);
//        end;
        
//        //addr = 12 read
//        set_read_transaction (rd_transaction,.addr(12));
//        get_rd_data_block_back(rd_transaction,data_block_for_read);

        
         
        ##(5000);
        

        $finish;
    end
    
      task send_wait_wr(inout axi_transaction wr_trans);
        wr_trans.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
        vip_agent.wr_driver.send(wr_trans);
        vip_agent.wr_driver.wait_rsp(wr_trans);
      endtask
    task automatic single_write_transaction_api ( 
                                input string                     name ="single_write",
                                input xil_axi_uint               id =0, 
                                input xil_axi_ulong              addr =0,
                                input xil_axi_len_t              len =0, 
                                input xil_axi_size_t             size =xil_axi_size_t'(xil_clog2((32)/8)),
                                input xil_axi_burst_t            burst =XIL_AXI_BURST_TYPE_INCR,
                                input xil_axi_lock_t             lock = XIL_AXI_ALOCK_NOLOCK,
                                input xil_axi_cache_t            cache =3,
                                input xil_axi_prot_t             prot =0,
                                input xil_axi_region_t           region =0,
                                input xil_axi_qos_t              qos =0,
                                input xil_axi_data_beat [255:0]  wuser =0, 
                                input xil_axi_data_beat          awuser =0,
                                input bit [32767:0]              data =0
                                                );
    axi_transaction                               wr_trans;
    wr_trans =vip_agent.wr_driver.create_transaction(name);
    wr_trans.set_write_cmd(addr,burst,id,len,size);
    wr_trans.set_prot(prot);
    wr_trans.set_lock(lock);
    wr_trans.set_cache(cache);
    wr_trans.set_region(region);
    wr_trans.set_qos(qos);
    wr_trans.set_data_block(data);
    send_wait_wr(wr_trans);
//    vip_agent.wr_driver.send(wr_trans);   
//     vip_agent.wr_driver.wait_rsp(wr_trans);
  endtask  : single_write_transaction_api


  task automatic single_read_transaction_api ( 
                                    input string                     name ="single_read",
                                    input xil_axi_uint               id =0, 
                                    input xil_axi_ulong              addr =0,
                                    input xil_axi_len_t              len =0, 
                                    input xil_axi_size_t             size =xil_axi_size_t'(xil_clog2((32)/8)),
                                    input xil_axi_burst_t            burst =XIL_AXI_BURST_TYPE_INCR,
                                    input xil_axi_lock_t             lock =XIL_AXI_ALOCK_NOLOCK ,
                                    input xil_axi_cache_t            cache =3,
                                    input xil_axi_prot_t             prot =0,
                                    input xil_axi_region_t           region =0,
                                    input xil_axi_qos_t              qos =0,
                                    input xil_axi_data_beat          aruser =0
                                                );
    axi_transaction                               rd_trans;
    rd_trans = vip_agent.rd_driver.create_transaction(name);
    rd_trans.set_read_cmd(addr,burst,id,len,size);
    rd_trans.set_prot(prot);
    rd_trans.set_lock(lock);
    rd_trans.set_cache(cache);
    rd_trans.set_region(region);
    rd_trans.set_qos(qos);
    vip_agent.rd_driver.send(rd_trans);   
  endtask  : single_read_transaction_api
 


  task automatic set_read_transaction ( inout axi_transaction rd_trans ,
                                    input string                     name ="single_read",
                                    input xil_axi_uint               id =0, 
                                    input xil_axi_ulong              addr =0,
                                    input xil_axi_len_t              len =0, 
                                    input xil_axi_size_t             size =xil_axi_size_t'(xil_clog2((32)/8)),
                                    input xil_axi_burst_t            burst =XIL_AXI_BURST_TYPE_INCR,
                                    input xil_axi_lock_t             lock =XIL_AXI_ALOCK_NOLOCK ,
                                    input xil_axi_cache_t            cache =3,
                                    input xil_axi_prot_t             prot =0,
                                    input xil_axi_region_t           region =0,
                                    input xil_axi_qos_t              qos =0,
                                    input xil_axi_data_beat          aruser =0
                                                );
    rd_trans = vip_agent.rd_driver.create_transaction(name);
    rd_trans.set_read_cmd(addr,burst,id,len,size);
    rd_trans.set_prot(prot);
    rd_trans.set_lock(lock);
    rd_trans.set_cache(cache);
    rd_trans.set_region(region);
    rd_trans.set_qos(qos);
  endtask
  
  task send_wait_rd(inout axi_transaction rd_trans);
    rd_trans.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
    vip_agent.rd_driver.send(rd_trans);
    vip_agent.rd_driver.wait_rsp(rd_trans);
  endtask
  
    task get_rd_data_block_back(inout axi_transaction rd_trans, 
                                 output bit[8*4096-1:0] Rdatablock
                            );  
    send_wait_rd(rd_trans);
    Rdatablock = rd_trans.get_data_block();
    // $display("Read data from Driver: Block Data %h ", Rdatablock);
  endtask
endmodule