module DATA_REORG(
//clk and reset, from external
    input           exclk,
    input           rst_n,
//HPS I/F   
    input           as_rd, //as数据读取控制信号
    input           as_wr, // as数据写入控制信号
    input [7:0]     as_addr, // as数据的地址信号
    output [31:0]   as_rd_data, //输出as读取数据的端口信号
    input [31:0]    as_wr_data, //输入as写入数据的端口信号
    output          as_data_waitquest, // as数据等待状态的输出端口信号
//DDR I/F
    input           r_avm_waitrequest, //是否需要等待r_avm完成请求数据的控制信号
    output          r_avm_read, //控制r_avm数据读取的输出端口信号
    output [31:0]   r_avm_address, //r_avm地址信息输出端口信号
    input [63:0]    r_avm_readdata, // input port for reading data from r_avm
    input           r_avm_readdatavalid, // input port for indicating valid read data from r_avm
    output [7:0]    r_avm_byteenable, // output port for indicating byte enable to write data to r_avm
    output [4:0]    r_avm_burstcount, // output port for indicating the number of data in a continuous data transfer operation inside r_avm
//DDR I/F   
    input           w_avm_waitrequest, // 是否需要等待w_avm完成请求的控制信号
    output          w_avm_write, // whether or not to write data to w_avm
    output [31:0]   w_avm_address, // output port for w_avm address information
    input [31:0]    w_avm_writedata, // w_avm写入数据的输入端口信号  
    output [7:0]    w_avm_byteenable, // output port for indicating byte enable to write data to w_avm
    output [4:0]    w_avm_burstcount // output port for indicating the number of data in a continuous data transfer operation inside w_avm
);





endmodule