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

module spi_master_clkgen
(
    input  logic                        clk,
    input  logic                        rstn,
    input  logic                        en,
    input  logic          [7:0]         clk_div,
    input  logic                        clk_div_valid,
    output logic                        spi_clk,
    output logic                        spi_fall,
    output logic                        spi_rise
);

    logic [7:0] counter_trgt;
    logic [7:0] counter_trgt_next;
    logic [7:0] counter;
    logic [7:0] counter_next;

    logic       spi_clk_next;
    logic       running;

    //always_comb
    always @(*) 
    begin
            spi_rise = 1'b0;
            spi_fall = 1'b0;
            if (clk_div_valid)
                counter_trgt_next = clk_div;
            else
                counter_trgt_next = counter_trgt;

            if (counter == counter_trgt)
            begin
                counter_next = 0;
                spi_clk_next = ~spi_clk;
                if(spi_clk == 1'b0)
                    spi_rise = running;
                else
                    spi_fall = running;
            end
            else
            begin
                counter_next = counter + 1;
                spi_clk_next = spi_clk;
            end
    end

    //always_ff 
    always @(posedge clk, negedge rstn)
    begin
        if (rstn == 1'b0)
        begin
            counter_trgt <= 'h0;
            counter      <= 'h0;
            spi_clk      <= 1'b0;
            running      <= 1'b0;
        end
        else
        begin//1 clk... 
            //en or spi_clk: cnt,cnt_tgt,spiclk ->next.
            //!en&&!spi_clk:running=0.
            counter_trgt <= counter_trgt_next;
            //en==0:running=spi_clk_lastclk
            //en==1:running=1.
            if (spi_clk||en) 
            begin
                running <= 1'b1;
                spi_clk <= spi_clk_next;
                counter <= counter_next;
            end
            else
                running <= 1'b0;
        end
    end

endmodule
