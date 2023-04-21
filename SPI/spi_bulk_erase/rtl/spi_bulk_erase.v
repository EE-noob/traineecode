//全擦除指令模块
module spi_bulk_erase(
// 系统接口
	input	sys_clk		,		//全局时钟50MHz
	input	sys_rst_n	,   	//复位信号，低电平有效
// SPI物理接口							
	input	spi_miso	,   	//SPI串行输入，用来接收从机的数据
	output	spi_sclk	,   	//SPI时钟
	output	spi_cs    	,   	//SPI片选信号,低电平有效
	output	spi_mosi	    	//SPI输出，用来给从机发送数据   
);

wire			spi_start	;	//发送传输开始信号，一个高电平
wire			spi_end		;   //发送传输结束信号，一个高电平
wire	[7:0]  	data_send   ;   //要发送的数据
wire         	send_done	;   //主机发送一个字节完毕标志

//------------<例化模块>----------------------------------------------------------------
//全擦除控制模块
spi_bulk_erase_ctrl	spi_bulk_erase_ctrl_inst
(
    .sys_clk		(sys_clk	), 			
    .sys_rst_n		(sys_rst_n	), 			

	.send_done		(send_done	), 			
    .spi_start		(spi_start	),			
    .spi_end		(spi_end	),			
    .data_send    	(data_send	)			
);
//SPI驱动
spi_drive	spi_drive_inst(
	.sys_clk		(sys_clk	), 			
	.sys_rst_n		(sys_rst_n	), 			
		
	.spi_start		(spi_start	), 			
	.spi_end		(spi_end	), 			
	.data_send		(data_send	), 			
	.data_rec  		(			), 			
	.send_done		(send_done	), 			
	.rec_done		(			), 			
				
	.spi_miso		(spi_miso	), 			
	.spi_sclk		(spi_sclk	), 			
	.spi_cs    		(spi_cs		), 			
	.spi_mosi		(spi_mosi	)			
);

endmodule