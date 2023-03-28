module    mult_cell
    #(parameter A_width=4,
      parameter B_width=4)
    (
      input                           clk,
      input                           rstn,
      input                           en,
      input [B_width+A_width-1:0]     i_A,      
      input [B_width-1:0]             i_B,      
      input [B_width+A_width-1:0]     i_A_acci, //上次累加结果

      output reg [B_width+A_width-1:0]i_A_o,     //被乘数移位后保存值
      output reg [B_width-1:0]        i_B_shift, //乘数移位后保存值
      output reg [A_width+B_width-1:0]i_A_acco,  //当前累加结果
      output reg                rdy );

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rdy          <= 'b0 ;
            i_A_o        <= 'b0 ;
            i_A_acco     <= 'b0 ;
            i_B_shift    <= 'b0 ;
        end
        else if (en) begin
            rdy            <= 1'b1 ;
            i_B_shift    <= i_B >> 1 ;
            i_A_o        <= i_A << 1 ;
            if (i_B[0]) begin
                //乘数对应位为1则累加
                i_A_acco  <= i_A_acci + i_A ;  
            end
            else begin
                i_A_acco  <= i_A_acci ; //乘数对应位为1则保持
            end
        end
        else begin
            rdy            <= 'b0 ;
            i_A_o        <= 'b0 ;
            i_A_acco     <= 'b0 ;
            i_B_shift    <= 'b0 ;
        end
    end

endmodule

module    mult_man
    #(parameter A_width=4,
      parameter B_width=4)
    (
      input                     clk,
      input                     rstn,
      input                     data_rdy ,
      input [A_width-1:0]             i_A,
      input [B_width-1:0]             i_B,

      output                    res_rdy ,
      output [A_width+B_width-1:0]          res );

    wire [A_width+B_width-1:0]       i_A_t [B_width-1:0] ;
    wire [B_width-1:0]         i_B_t [B_width-1:0] ;
    wire [A_width+B_width-1:0]       i_A_acc_t [B_width-1:0] ;
    wire [B_width-1:0]         rdy_t ;

    //第一次例化相当于初始化，不能用 generate 语句
    mult_cell      #(.A_width(A_width), .B_width(B_width))
    u_mult_step0
    (
      .clk              (clk),
      .rstn             (rstn),
      .en               (data_rdy),
      .i_A            ({{(B_width){1'b0}}, i_A}),
      .i_B            (i_B),
      .i_A_acci       ({(A_width+B_width){1'b0}}),
      //output
      .i_A_acco       (i_A_acc_t[0]),
      .i_B_shift      (i_B_t[0]),
      .i_A_o          (i_A_t[0]),
      .rdy              (rdy_t[0]) );

    //多次模块例化，用 generate 语句
    genvar               i ;
    generate
        for(i=1; i<=B_width-1; i=i+1) begin: mult_stepx
            mult_cell      #(.A_width(A_width), .B_width(B_width))
            u_mult_step
            (
              .clk              (clk),
              .rstn             (rstn),
              .en               (rdy_t[i-1]),
              .i_A            (i_A_t[i-1]),
              .i_B            (i_B_t[i-1]),
              //上一次累加结果作为下一次累加输入
              .i_A_acci       (i_A_acc_t[i-1]),
              //output
              .i_A_acco       (i_A_acc_t[i]),                                      
              .i_A_o          (i_A_t[i]),  //被乘数移位状态传递
              .i_B_shift      (i_B_t[i]),  //乘数移位状态传递
              .rdy              (rdy_t[i]) );
        end
    endgenerate

    assign res_rdy       = rdy_t[B_width-1];
    assign res           = i_A_acc_t[B_width-1];

endmodule