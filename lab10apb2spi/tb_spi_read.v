//------------------------------------------------
//--SPI驱动仿真--读数据仿真
//------------------------------------------------
`timescale 1ns/1ns		//时间单位/精度

//------------<模块及端口声明>----------------------------------------
module tb_spi_read();

reg		sys_clk		;
reg		sys_rst_n	;
					
wire	spi_miso	;
wire	spi_sclk	;
wire	spi_cs    	;
wire	spi_mosi	;

parameter	BYTE_MAX 	= 8'd10	,		//一共读取多少个BYTE的数据
			SECTOR_ADDR = 8'h00	,		//扇区地址
			PAGE_ADDR   = 8'h00	,		//页地址
			BYTE_ADDR   = 8'h00	;		//字节地址
//------------<例化被测试模块>----------------------------------------
//读数据模块
spi_read	
#(
	.BYTE_MAX		(BYTE_MAX		),
	.SECTOR_ADDR	(SECTOR_ADDR	),
	.PAGE_ADDR		(PAGE_ADDR		),
	.BYTE_ADDR		(BYTE_ADDR		)
)
spi_read_inst(
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

//打印数据
always@(spi_read_inst.rec_done)begin
	if(spi_read_inst.rec_done && spi_read_inst.spi_read_ctrl_inst.flow_cnt == 'd7)
		$display("READ	:%h",spi_read_inst.data_rec);		//打印读取的数据
end
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
//重定义初始化数值
defparam memory.mem_access.initfile = "initM25P16_test.txt";	//其中的每页数据是从00累加到FF	

//------------<设置时钟>----------------------------------------------
always #10 sys_clk = ~sys_clk;		//系统时钟周期20ns

endmodule