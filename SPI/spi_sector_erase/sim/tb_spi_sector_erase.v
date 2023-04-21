//------------------------------------------------
//--SPI驱动仿真--扇区擦除仿真
//------------------------------------------------
`timescale 1ns/1ns		//时间单位/精度

//------------<模块及端口声明>----------------------------------------
module tb_spi_sector_erase();

reg		sys_clk		;
reg		sys_rst_n	;
					
wire	spi_miso	;
wire	spi_sclk	;
wire	spi_cs    	;
wire	spi_mosi	;

//------------<例化被测试模块>----------------------------------------
//扇区擦除模块
spi_sector_erase	spi_sector_erase_inst(
	.sys_clk	(sys_clk	),
	.sys_rst_n	(sys_rst_n	),

	.spi_miso	(spi_miso	),
	.spi_sclk	(spi_sclk	),
	.spi_cs    	(spi_cs		),
	.spi_mosi	(spi_mosi	)
);
//m25p16仿真模型
m25p16  memory (
    .c          (spi_sclk	), 
    .data_in    (spi_mosi   ), 
    .s          (spi_cs   	), 
    .w          (1'b1		), 
    .hold       (1'b1   	), 
    .data_out   (spi_miso   )
);	

//------------<设置初始测试条件>----------------------------------------
initial begin
	sys_clk = 1'b0;					//初始时钟为0
	sys_rst_n <= 1'b0;				//初始复位
	#20								//20个时钟周期后
	sys_rst_n <= 1'b1;				//拉高复位，系统进入工作状态	
end

//重定义初始化数值
defparam memory.mem_access.initfile = "initM25P16_test.txt";	//其中的数据是从0累加	
//------------<设置时钟>----------------------------------------------
always #10 sys_clk = ~sys_clk;		//系统时钟周期20ns

endmodule