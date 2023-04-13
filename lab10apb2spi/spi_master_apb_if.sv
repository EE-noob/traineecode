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

`define REG_STATUS 4'b0000 // BASEREG + 0x00
`define REG_CLKDIV 4'b0001 // BASEREG + 0x04
`define REG_SPICMD 4'b0010 // BASEREG + 0x08
`define REG_SPIADR 4'b0011 // BASEREG + 0x0C
`define REG_SPILEN 4'b0100 // BASEREG + 0x10
`define REG_SPIDUM 4'b0101 // BASEREG + 0x14
`define REG_TXFIFO 4'b0110 // BASEREG + 0x18
`define REG_RXFIFO 4'b1000 // BASEREG + 0x20
`define REG_INTCFG 4'b1001 // BASEREG + 0x24
`define REG_INTSTA 4'b1010 // BASEREG + 0x28

module spi_master_apb_if
#(
    parameter BUFFER_DEPTH   = 32,
    parameter APB_ADDR_WIDTH = 32,  //APB slaves are 4KB by default
    parameter BIGLOG_BUFFER_DEPTH = `BigLog2(BUFFER_DEPTH)
)
(//apb port   
    //clk and reset
    input  wire                      HCLK,
    input  wire                      HRESETn,
    //input port of apb bus
    input  wire [APB_ADDR_WIDTH-1:0] PADDR,
    input  wire               [31:0] PWDATA,
    input  wire                      PSEL,
    input  wire                      PENABLE,
    input  wire                      PWRITE,//1 write 0 read
    //output of apb
    output reg               [31:0] PRDATA,
    output wire                      PREADY,
    output wire                      PSLVERR,

/*
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
    input wire                       spi_sdi0,
    input wire                       spi_sdi1,
    input wire                       spi_sdi2,
    input wire                       spi_sdi3,
*/

//APB regs
    //REG_STATUS  0x00;  [5:2] 0000;
    output reg                      spi_rd,//mono read
    output reg                      spi_wr,//mono write
    output reg                      spi_qrd,//quadri read
    output reg                      spi_qwr,//quadri write
    output reg                      spi_swrst,//software reset
    output reg                [3:0] spi_csreg,//spi slave cs
    //other bits reserve
    //REG_CLKDIV  0x04;  [5:2] 0001;
    output reg                [7:0] spi_clk_div,//0x00:div2,0x01:div4,etc
    //REG_SPICMD  0x08;  [5:2] 0010;
    output reg               [31:0] spi_cmd,
    //REG_SPIADR  0x0c;  [5:2] 0011;
    output reg               [31:0] spi_addr,
    //REG_SPILEN  0x10;  [5:2] 0100;
    output reg                [5:0] spi_cmd_len,
    output reg                [5:0] spi_addr_len,//13:8
    output reg               [15:0] spi_data_len,//31:16
    //REG_SPIDUM  0x14;  [5:2] 0101;
    output reg               [15:0] spi_dummy_rd,
    output reg               [15:0] spi_dummy_wr,
    //REG_TXFIFO  0x18;  [5:2] 0110;
    output wire               [31:0] spi_data_tx,
    input  wire               [31:0] spi_status,
    //REG_RXFIFO  0x20;  [5:2] 1000;
    input  wire               [31:0] spi_data_rx,
    //REG_INTCFG  0x24;  [5:2] 0110; interrupt configuration
    output reg [BIGLOG_BUFFER_DEPTH:0] spi_int_th_tx,//spi interrupt threshold of transmit
    output reg [BIGLOG_BUFFER_DEPTH:0] spi_int_th_rx,//spi interrupt threshold of receive 
    output reg [BIGLOG_BUFFER_DEPTH:0] spi_int_cnt_tx,//spi interrupt max brust data count of transmit
    output reg [BIGLOG_BUFFER_DEPTH:0] spi_int_cnt_rx,//spi interrupt max brust data count of receive
    output reg                      spi_int_cnt_en,//spi interrupt counter enable
    output reg                      spi_int_en,//spi interrupt enable
    //REG_INTSTA
    output wire                      spi_int_rd_sta,//spi read status,0 idle,1 busy

    //ready and valid
    output reg                      spi_clk_div_valid,
    output wire                      spi_data_tx_valid,
    input  wire                      spi_data_tx_ready,
    input  wire                      spi_data_rx_valid,
    output wire                      spi_data_rx_ready
);

    wire [3:0] write_address;
    wire [3:0] read_address;

    assign write_address = PADDR[5:2];
    assign read_address  = PADDR[5:2];

    assign PSLVERR = 1'b0;
    assign PREADY  = 1'b1;

    assign spi_int_rd_sta = PSEL & PENABLE & ~PWRITE & (read_address  == `REG_INTSTA);
    //1:read ing ...  REG_INTSTA

    always @( posedge HCLK or negedge HRESETn )
    begin
        //rest
        if ( HRESETn == 1'b0 )
        begin
            spi_swrst         <= 1'b0;
            spi_rd            <= 1'b0;
            spi_wr            <= 1'b0;
            spi_qrd           <= 1'b0;
            spi_qwr           <= 1'b0;
            spi_clk_div_valid <= 1'b0; 
            spi_clk_div       <= 8'b0;
            spi_cmd           <= 32'b0;
            spi_addr          <= 32'b0;
            spi_cmd_len       <=  6'b0;
            spi_addr_len      <=  6'b0;
            spi_data_len      <=  16'b0;
            spi_dummy_rd      <=  16'b0;
            spi_dummy_wr      <=  16'b0;
            spi_csreg         <=  4'b0;
            spi_int_th_tx     <=  {(BIGLOG_BUFFER_DEPTH+1){1'b0}};
            spi_int_th_rx     <=  {(BIGLOG_BUFFER_DEPTH+1){1'b0}};
            spi_int_cnt_tx    <=  {(BIGLOG_BUFFER_DEPTH+1){1'b0}};
            spi_int_cnt_rx    <=  {(BIGLOG_BUFFER_DEPTH+1){1'b0}};
            spi_int_cnt_en    <= 1'b0; 
            spi_int_en        <= 1'b0; 
        end
        //apb write
        else  if (PSEL && PENABLE && PWRITE)
              begin
                  spi_swrst         <= 1'b0;
                  spi_rd            <= 1'b0;
                  spi_wr            <= 1'b0;
                  spi_qrd           <= 1'b0;
                  spi_qwr           <= 1'b0;
                  spi_clk_div_valid <= 1'b0;

                  case(write_address)

                  `REG_STATUS:
                  begin
                      spi_rd    <= PWDATA[0];
                      spi_wr    <= PWDATA[1];
                      spi_qrd   <= PWDATA[2];
                      spi_qwr   <= PWDATA[3];
                      spi_swrst <= PWDATA[4];
                      spi_csreg <= PWDATA[11:8];
                  end

                  `REG_CLKDIV:
                  begin
                      spi_clk_div       <= PWDATA[7:0];
                      spi_clk_div_valid <= 1'b1;
                  end

                  `REG_SPICMD:
                      spi_cmd <= PWDATA;

                  `REG_SPIADR:
                      spi_addr <= PWDATA;

                  `REG_SPILEN:
                  begin
                      spi_cmd_len        <= PWDATA[5:0];
                      spi_addr_len       <= PWDATA[13:8];
                      spi_data_len[7:0]  <= PWDATA[23:16];
                      spi_data_len[15:8] <= PWDATA[31:24];
                  end

                  `REG_SPIDUM:
                  begin
                      spi_dummy_rd[7:0]  <= PWDATA[7:0];
                      spi_dummy_rd[15:8] <= PWDATA[15:8];
                      spi_dummy_wr[7:0]  <= PWDATA[23:16];
                      spi_dummy_wr[15:8] <= PWDATA[31:24];
                  end
                //tx/rx fifo?
                  `REG_INTCFG:
                  begin
                      spi_int_th_tx  <= PWDATA[     BIGLOG_BUFFER_DEPTH: 0];
                      spi_int_th_rx  <= PWDATA[ 8 + BIGLOG_BUFFER_DEPTH: 8];
                      spi_int_cnt_tx <= PWDATA[16 + BIGLOG_BUFFER_DEPTH:16];
                      spi_int_cnt_rx <= PWDATA[24 + BIGLOG_BUFFER_DEPTH:24];
                      spi_int_cnt_en <= PWDATA[30];
                      spi_int_en     <= PWDATA[31];
                  end
                  endcase
              end
              else
              begin
                  spi_swrst         <= 1'b0;
                  spi_rd            <= 1'b0;
                  spi_wr            <= 1'b0;
                  spi_qrd           <= 1'b0;
                  spi_qwr           <= 1'b0;
                  spi_clk_div_valid <= 1'b0;
              end
    end // SLAVE_REG_WRITE_PROC


  // implement slave model register read mux
  //always_comb
    always @(*) 
    begin
      case(read_address)
        `REG_STATUS:
            PRDATA = spi_status;
        `REG_CLKDIV:
            PRDATA = {24'h00_0000,spi_clk_div};
        `REG_SPICMD:
            PRDATA = spi_cmd;
        `REG_SPIADR:
            PRDATA = spi_addr;
        `REG_SPILEN:
            PRDATA = {spi_data_len,2'b00,spi_addr_len,2'b00,spi_cmd_len};
        `REG_SPIDUM:
            PRDATA = {spi_dummy_wr,spi_dummy_rd};
        `REG_RXFIFO:
            PRDATA = spi_data_rx;
        `REG_INTCFG:
        begin
            PRDATA                           = 32'b0;
            PRDATA[     BIGLOG_BUFFER_DEPTH: 0] = spi_int_th_tx;
            PRDATA[ 8 + BIGLOG_BUFFER_DEPTH: 8] = spi_int_th_rx;
            PRDATA[16 + BIGLOG_BUFFER_DEPTH:16] = spi_int_cnt_tx;
            PRDATA[24 + BIGLOG_BUFFER_DEPTH:24] = spi_int_cnt_rx;
            PRDATA[30]                       = spi_int_cnt_en;
            PRDATA[31]                       = spi_int_en;
        end
        default:
            PRDATA = 32'b0;
      endcase
    end // SLAVE_REG_READ_PROC

    assign spi_data_tx       = PWDATA;
    assign spi_data_tx_valid = PSEL & PENABLE &  PWRITE & (write_address == `REG_TXFIFO);
    assign spi_data_rx_ready = PSEL & PENABLE & ~PWRITE & (read_address  == `REG_RXFIFO);

endmodule
