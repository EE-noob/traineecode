`timescale 1ns/1ns		//时间单位/精度
//扇区擦除
module spi_sector_erase(
// 系统接口
	input	sys_clk		,						//全局时钟50MHz
	input	sys_rst_n	,   					//复位信号，低电平有效
// SPI物理接口											
	input	spi_miso	,   					//SPI串行输入，用来接收从机的数据
	output	spi_sclk	,   					//SPI时钟
	output	spi_cs    	,   					//SPI片选信号,低电平有效
	output	spi_mosi	    					//SPI输出，用来给从机发送数据   
);
parameter 	SECTOR_ADDR = 8'b0000_0000; 		//扇区地址
parameter	PAGE_ADDR   = 8'b0000_0000;			//页地址
parameter	BYTE_ADDR   = 8'b0000_1000;			//字节地址

wire			spi_start	;					//发送传输开始信号，一个高电平
wire			spi_end		;   				//发送传输结束信号，一个高电平
wire	[7:0]  	data_send   ;   				//要发送的数据
wire	[7:0]  	data_rec   	;   				//接收到的数据
wire         	send_done	;   				//主机发送一个字节完毕标志
wire         	rec_done	;   				//主机接收一个字节完毕标志

//------------<例化模块>----------------------------------------------------------------
//扇区擦除模块
spi_sector_erase_ctrl
#(
	.SECTOR_ADDR 	(SECTOR_ADDR),
	.PAGE_ADDR   	(PAGE_ADDR  ),
    .BYTE_ADDR   	(BYTE_ADDR  )
)	
spi_sector_erase_ctrl_inst
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
	.data_rec  		(data_rec	), 			
	.send_done		(send_done	), 			
	.rec_done		(rec_done	), 			
				
	.spi_miso		(spi_miso	), 			
	.spi_sclk		(spi_sclk	), 			
	.spi_cs    		(spi_cs		), 			
	.spi_mosi		(spi_mosi	)			
);

endmodule