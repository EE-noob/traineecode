// ----------------------------------------------------
//COPYRIGHT(c)2012，Macrosilico Technologies Co， Ltd+
// All rights reserved
// Module name : module. name .
// function description :
//
// Author: sysu/MST202302018
// Date:2023/4/14
// history :none
// ----------------------------------------------------

`define BigLog2(VALUE) ((VALUE) < ( 1 ) ? 0 : (VALUE) < ( 2 ) ? 1 : (VALUE) < ( 4 ) ? 2 : (VALUE) < ( 8 ) ? 3 : (VALUE) < ( 16 )  ? 4 : (VALUE) < ( 32 )  ? 5 : (VALUE) < ( 64 )  ? 6 : (VALUE) < ( 128 ) ? 7 : (VALUE) < ( 256 ) ? 8 : (VALUE) < ( 512 ) ? 9 : (VALUE) < ( 1024 ) ? 10 : (VALUE) < ( 2048 ) ? 11 : (VALUE) < ( 4096 ) ? 12 : (VALUE) < ( 8192 ) ? 13 : (VALUE) < ( 16384 ) ? 14 : (VALUE) < ( 32768 ) ? 15 : (VALUE) < ( 65536 ) ? 16 : (VALUE) < ( 131072 ) ? 17 : (VALUE) < ( 262144 ) ? 18 : (VALUE) < ( 524288 ) ? 19 : (VALUE) < ( 1048576 ) ? 20 : (VALUE) < ( 1048576 * 2 ) ? 21 : (VALUE) < ( 1048576 * 4 ) ? 22 : (VALUE) < ( 1048576 * 8 ) ? 23 : (VALUE) < ( 1048576 * 16 ) ? 24 : 25)

module apb_spi_master
#(
    parameter BUFFER_DEPTH   = 10,
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(//apb port   
    //clk and reset
    input  logic                      HCLK,
    input  logic                      HRESETn,
    //input port of apb bus
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    input  logic                      PWRITE,//1 write 0 read
    //output of apb
    output reg               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,

//interupt
    output reg               [2:0]  events_o,//[0] read ,[1] instructions over,[2] write
    
//spi physical port
//output
    output reg                      spi_clk,
    output reg               [1:0]  spi_mode,//standard,dual,quad
    //cs_n
    output reg                      spi_csn0,
    output reg                      spi_csn1,
    output reg                      spi_csn2,
    output reg                      spi_csn3,
    //MOSI for SPI slave
    output reg                      spi_sdo0,
    output reg                      spi_sdo1,
    output reg                      spi_sdo2,
    output reg                      spi_sdo3,              
//input
    //MISO for SPI slave
    input logic                       spi_sdi0,
    input logic                       spi_sdi1,
    input logic                       spi_sdi2,
    input logic                       spi_sdi3
);


    localparam BIGLOG_BUFFER_DEPTH = `BigLog2(BUFFER_DEPTH);

    logic    [7:0] spi_clk_div;
    logic          spi_clk_div_valid;
    logic   [31:0] spi_status;
    logic   [31:0] spi_addr;
    logic    [5:0] spi_addr_len;
    logic   [31:0] spi_cmd;
    logic    [5:0] spi_cmd_len;
    logic   [15:0] spi_data_len;
    logic   [15:0] spi_dummy_rd;
    logic   [15:0] spi_dummy_wr;
    logic          spi_swrst;
    logic          spi_rd;
    logic          spi_wr;
    logic          spi_qrd;
    logic          spi_qwr;
    logic    [3:0] spi_csreg;
    logic   [31:0] spi_data_tx;
    logic          spi_data_tx_valid;
    logic          spi_data_tx_ready;
    logic   [31:0] spi_data_rx;
    logic          spi_data_rx_valid;
    logic          spi_data_rx_ready;
    logic    [6:0] spi_ctrl_status;
    logic   [31:0] spi_ctrl_data_tx;
    logic          spi_ctrl_data_tx_valid;
    logic          spi_ctrl_data_tx_ready;
    logic   [31:0] spi_ctrl_data_rx;
    logic          spi_ctrl_data_rx_valid;
    logic          spi_ctrl_data_rx_ready;

    logic          s_eot;

    logic  [BIGLOG_BUFFER_DEPTH:0] elements_tx;
    logic  [BIGLOG_BUFFER_DEPTH:0] elements_rx;

    logic  [BIGLOG_BUFFER_DEPTH:0] r_counter_tx;
    logic  [BIGLOG_BUFFER_DEPTH:0] r_counter_rx;

    logic  [BIGLOG_BUFFER_DEPTH:0] s_th_tx;
    logic  [BIGLOG_BUFFER_DEPTH:0] s_th_rx;

    logic  [BIGLOG_BUFFER_DEPTH:0] s_cnt_tx;
    logic  [BIGLOG_BUFFER_DEPTH:0] s_cnt_rx;

    logic                       s_rise_int_tx;
    logic                       s_rise_int_rx;

    logic                       s_int_tx;
    logic                       s_int_rx;

    logic                       s_int_en;
    logic                       s_int_cnt_en;

    logic                       s_int_rd_intsta;

    enum logic  [1:0] { INT_RX_ACTIVE, GEN_INT_RX, INT_RX_INACTIVE } r_state_rx,s_state_rx_next;
    enum logic  [1:0] { INT_TX_ACTIVE, GEN_INT_TX, INT_TX_INACTIVE } r_state_tx,s_state_tx_next;

    localparam FILL_BITS = 7-BIGLOG_BUFFER_DEPTH;

    assign s_rise_int_tx = (elements_tx <= s_th_tx);
    assign s_rise_int_rx = (elements_rx >= s_th_rx);

    assign spi_status = {{FILL_BITS{1'b0}},elements_tx,{FILL_BITS{1'b0}},elements_rx,9'h0,spi_ctrl_status};

    assign events_o[0] = s_int_tx | s_int_rx;
    assign events_o[1] = s_eot;

    //always_ff: 
    always @(posedge HCLK, negedge HRESETn)
    begin
        if(~HRESETn)
        begin
            r_state_tx <= INT_TX_ACTIVE;
            r_state_rx <= INT_RX_ACTIVE;
        end
        else
        begin
            r_state_tx <= s_state_tx_next;
            r_state_rx <= s_state_rx_next;
        end
    end

    //always_ff 
    always @(posedge HCLK, negedge HRESETn)
    begin
        if(~HRESETn)
        begin
            r_counter_tx <= 'h0;
            r_counter_rx <= 'h0;
        end
        else
        begin
            if (s_int_cnt_en)
            begin
                if (spi_ctrl_data_tx_valid && spi_ctrl_data_tx_ready)
                begin
                    if (r_counter_tx == s_cnt_tx-1)
                        r_counter_tx <= 'h0;
                    else
                        r_counter_tx <= r_counter_tx + 1;
                end
                if (spi_ctrl_data_rx_valid && spi_ctrl_data_rx_ready)
                begin
                    if (r_counter_rx == s_cnt_rx-1)
                        r_counter_rx <= 'h0;
                    else
                        r_counter_rx <= r_counter_rx + 1;
                end
            end
            else
            begin
                r_counter_tx <= 'h0;
                r_counter_rx <= 'h0;
            end
        end
    end

    //always_comb
    always @(*) 
    begin
        s_state_tx_next = r_state_tx;
        s_int_tx        = 1'b0;

        case(r_state_tx)
        INT_TX_ACTIVE:
        begin
            if (s_rise_int_tx && s_int_en)
                s_state_tx_next = GEN_INT_TX;
        end

        GEN_INT_TX:
        begin
            s_int_tx = 1'b1;
            s_state_tx_next = INT_TX_INACTIVE;
        end

        INT_TX_INACTIVE:
        begin
            if (s_int_cnt_en)
            begin
                if ((spi_ctrl_data_tx_valid && spi_ctrl_data_tx_ready) && (r_counter_tx == s_cnt_tx-1))
                    s_state_tx_next = INT_TX_ACTIVE;
            end
            else
            begin
                if (s_int_rd_intsta)
                    s_state_tx_next = INT_TX_ACTIVE;
            end
        end

        default :
        begin
            s_state_tx_next = r_state_tx;
            s_int_tx        = 1'b0;
        end
        endcase
    end


    //always_comb
    always @(*)
    begin
        s_state_rx_next = r_state_rx;
        s_int_rx        = 1'b0;

        case(r_state_rx)
        INT_RX_ACTIVE:
        begin
            if (s_rise_int_rx && s_int_en)
                s_state_rx_next = GEN_INT_RX;
        end

        GEN_INT_RX:
        begin
            s_int_rx = 1'b1;
            s_state_rx_next = INT_RX_INACTIVE;
        end

        INT_RX_INACTIVE:
        begin
            if (s_int_cnt_en)
            begin
                if ((spi_ctrl_data_rx_valid && spi_ctrl_data_rx_ready) && (r_counter_rx == s_cnt_rx-1))
                    s_state_rx_next = INT_RX_ACTIVE;
            end
            else
            begin
              if (s_int_rd_intsta)
                  s_state_rx_next = INT_RX_ACTIVE;
            end
        end
        endcase
    end

    spi_master_apb_if
    #(
        .BUFFER_DEPTH   ( BUFFER_DEPTH   ),
        .APB_ADDR_WIDTH ( APB_ADDR_WIDTH )
    )
    u_axiregs
    (
        .HCLK              ( HCLK              ),
        .HRESETn           ( HRESETn           ),
        .PADDR             ( PADDR             ),
        .PWDATA            ( PWDATA            ),
        .PWRITE            ( PWRITE            ),
        .PSEL              ( PSEL              ),
        .PENABLE           ( PENABLE           ),
        .PRDATA            ( PRDATA            ),
        .PREADY            ( PREADY            ),
        .PSLVERR           ( PSLVERR           ),

        .spi_clk_div       ( spi_clk_div       ),
        .spi_clk_div_valid ( spi_clk_div_valid ),
        .spi_status        ( spi_status        ),
        .spi_addr          ( spi_addr          ),
        .spi_addr_len      ( spi_addr_len      ),
        .spi_cmd           ( spi_cmd           ),
        .spi_cmd_len       ( spi_cmd_len       ),
        .spi_data_len      ( spi_data_len      ),
        .spi_dummy_rd      ( spi_dummy_rd      ),
        .spi_dummy_wr      ( spi_dummy_wr      ),
        .spi_swrst         ( spi_swrst         ),
        .spi_rd            ( spi_rd            ),
        .spi_wr            ( spi_wr            ),
        .spi_qrd           ( spi_qrd           ),
        .spi_qwr           ( spi_qwr           ),
        .spi_csreg         ( spi_csreg         ),
        .spi_int_th_rx     ( s_th_rx           ),
        .spi_int_th_tx     ( s_th_tx           ),
        .spi_int_cnt_rx    ( s_cnt_rx          ),
        .spi_int_cnt_tx    ( s_cnt_tx          ),
        .spi_int_en        ( s_int_en          ),
        .spi_int_cnt_en    ( s_int_cnt_en      ),
        .spi_int_rd_sta    ( s_int_rd_intsta   ),
        .spi_data_tx       ( spi_data_tx       ),
        .spi_data_tx_valid ( spi_data_tx_valid ),
        .spi_data_tx_ready ( spi_data_tx_ready ), //FIXME not used inside thhis module
        .spi_data_rx       ( spi_data_rx       ),
        .spi_data_rx_valid ( spi_data_rx_valid ),
        .spi_data_rx_ready ( spi_data_rx_ready )
    );

    spi_master_fifo
    #(
        .DATA_WIDTH   ( 32           ),
        .BUFFER_DEPTH ( BUFFER_DEPTH )
    )
    u_txfifo
    (
        .clk_i      ( HCLK                   ),
        .rst_ni     ( HRESETn                ),
        .clr_i      ( spi_swrst              ),

        .elements_o ( elements_tx            ),

        .data_o     ( spi_ctrl_data_tx       ),
        .NotEmpty    ( spi_ctrl_data_tx_valid ),
        .PutOutWill    ( spi_ctrl_data_tx_ready ),

        .PutInWill    ( spi_data_tx_valid      ),
        .data_i     ( spi_data_tx            ),
        .NotFull    ( spi_data_tx_ready      )
    );

    spi_master_fifo
    #(
        .DATA_WIDTH   ( 32           ),
        .BUFFER_DEPTH ( BUFFER_DEPTH )
    )
    u_rxfifo
    (
        .clk_i      ( HCLK                   ),
        .rst_ni     ( HRESETn                ),
        .clr_i      ( spi_swrst              ),

        .elements_o ( elements_rx            ),

        .data_o     ( spi_data_rx            ),
        .NotEmpty    ( spi_data_rx_valid      ),
        .PutOutWill    ( spi_data_rx_ready      ),

        .PutInWill    ( spi_ctrl_data_rx_valid ),
        .data_i     ( spi_ctrl_data_rx       ),
        .NotFull    ( spi_ctrl_data_rx_ready )
    );

    spi_master_controller u_spictrl
    (   //clk and reset
        .clk                    ( HCLK                   ),
        .rstn                   ( HRESETn                ),
        //apb regs
        .eot                    ( s_eot                  ),
        .spi_clk_div            ( spi_clk_div            ),
        .spi_clk_div_valid      ( spi_clk_div_valid      ),
        .spi_status             ( spi_ctrl_status        ),
        .spi_addr               ( spi_addr               ),
        .spi_addr_len           ( spi_addr_len           ),
        .spi_cmd                ( spi_cmd                ),
        .spi_cmd_len            ( spi_cmd_len            ),
        .spi_data_len           ( spi_data_len           ),
        .spi_dummy_rd           ( spi_dummy_rd           ),
        .spi_dummy_wr           ( spi_dummy_wr           ),
        .spi_swrst              ( spi_swrst              ),
        .spi_rd                 ( spi_rd                 ),
        .spi_wr                 ( spi_wr                 ),
        .spi_qrd                ( spi_qrd                ),
        .spi_qwr                ( spi_qwr                ),
        .spi_csreg              ( spi_csreg              ),
        //fifo I/F
        .spi_ctrl_data_tx       ( spi_ctrl_data_tx       ),
        .spi_ctrl_data_tx_valid ( spi_ctrl_data_tx_valid ),
        .spi_ctrl_data_tx_ready ( spi_ctrl_data_tx_ready ),
        .spi_ctrl_data_rx       ( spi_ctrl_data_rx       ),
        .spi_ctrl_data_rx_valid ( spi_ctrl_data_rx_valid ),
        .spi_ctrl_data_rx_ready ( spi_ctrl_data_rx_ready ),
        //top_out
        .spi_clk                ( spi_clk                ),
        .spi_csn0               ( spi_csn0               ),
        .spi_csn1               ( spi_csn1               ),
        .spi_csn2               ( spi_csn2               ),
        .spi_csn3               ( spi_csn3               ),
        .spi_mode               ( spi_mode               ),
        .spi_sdo0               ( spi_sdo0               ),
        .spi_sdo1               ( spi_sdo1               ),
        .spi_sdo2               ( spi_sdo2               ),
        .spi_sdo3               ( spi_sdo3               ),
        .spi_sdi0               ( spi_sdi0               ),
        .spi_sdi1               ( spi_sdi1               ),
        .spi_sdi2               ( spi_sdi2               ),
        .spi_sdi3               ( spi_sdi3               )
    );

endmodule
