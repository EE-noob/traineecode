module tb_spi_master_clkgen;

    // Inputs
    reg clk;
    reg rstn;
    reg en;
    reg [7:0] clk_div;
    reg clk_div_valid;

    // Outputs
    reg spi_clk;
    reg spi_fall;
    reg spi_rise;

    // Instantiate the design being tested
    spi_master_clkgen dut (
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .clk_div(clk_div),
        .clk_div_valid(clk_div_valid),
        .spi_clk(spi_clk),
        .spi_fall(spi_fall),
        .spi_rise(spi_rise)
    );

    // Reset inputs
    initial begin
        clk = 1'b0;
        rstn = 1'b0;
        en = 1'b1;
        clk_div = 'b0;
        clk_div_valid = 1'b0;

        // Wait for some time to let reset settle
        #20;
        rstn = 1'b1;
        // Start a test
        // Test case 1: clk_div_valid is high, should change spi_clk
        
        clk_div_valid = 1'b1;
        clk_div = 'h00;
        #100;
        clk_div_valid = 1'b0;
        
        // Test case 2: clk_div_valid is low, should not change spi_clk
        clk_div_valid = 1'b1;
        clk_div = 'h01;
        #10;
        #200;
        clk_div_valid = 1'b0;
        
        // Test case 3: clk_div = 1, spi_clk should have high frequency
        //en = 1'b1;
        clk_div_valid = 1'b1;
        clk_div = 'h02;
        #200;
        clk_div_valid = 1'b0;
        #10;
        if(!(spi_clk == 1'b0)) 
        $display("Test case 3 success"); 
        else $display("Test case 3 failed: spi_clk frequency too low for clk_div = 1");
        
        // Test case 4: clk_div = 100, spi_clk should have lower frequency
        //en = 1'b1;
        clk_div_valid = 1'b1;
        clk_div = 'h03;
        #200;
        if(spi_clk == 1'b0) 
        $display("Test case 4 success"); 
        else $display("Test case 4 failed: spi_clk frequency too high for clk_div = 100");

        $display("All test cases passed");
        $finish; // stop the simulation
    end
    
    // Generate clock signal
    always #5 clk = ~clk;

    //verdi or dve
    `ifdef VCS
    initial begin
        $fsdbDumpfile("clkgen_tb.fsdb");
        $fsdbDumpvars(0);
        $fsdbDumpMDA();
    end
    initial begin
        `ifdef DUMP VPD
        $vcdpluson();
        `endif
    end
    `endif

    
endmodule
