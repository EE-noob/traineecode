/* //------------------------------------------------
//--SPI驱动仿真（模式0，1个BYTE）
//------------------------------------------------
`timescale 1ns/1ns		//时间单位/精度

//------------<模块及端口声明>----------------------------------------
module tb_spi_drive();
//系统接口
reg				sys_clk		;			// 全局时钟50MHz
reg				sys_rst_n	;   		// 复位信号，低电平有效
//用户接口                      		
reg				spi_start 	;   		// 发送传输开始信号，一个高电平
reg				spi_end   	;   		// 发送传输结束信号，一个高电平
reg		[7:0]  	data_send   ;   		// 要发送的数据
wire  	[7:0]  	data_rec  	;   		// 接收到的数据
wire         	send_done	;   		// 主机发送一个字节完毕标志位    
wire         	rec_done	;   		// 主机接收一个字节完毕标志位    
//SPI物理接口                   		
reg				spi_miso	;   		// SPI串行输入，用来接收从机的数据
wire         	spi_sclk	;   		// SPI时钟
wire			spi_cs    	;   		// SPI片选信号
wire         	spi_mosi	;   		// SPI输出，用来给从机发送数据
//仿真用
reg		[3:0]  	cnt_send 	;			//发送数据计数器，0-15      

//------------<例化SPI驱动模块（模式0）>----------------------------------------
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

//------------<设置初始测试条件>----------------------------------------
initial begin
	sys_clk = 1'b0;						//初始时钟为0
	sys_rst_n <= 1'b0;					//初始复位
	spi_start <= 1'b0;	
	data_send <= 8'd0;	
	spi_miso <= 1'bz;	
	spi_end <= 1'b0;	
	#80									//80个时钟周期后
	sys_rst_n <= 1'b1;					//拉高复位，系统进入工作状态
	#30									//30个时钟周期后拉高SPI开始信号，开始SPI传输
	spi_start <= 1'b1;data_send <= 8'b01010101;
	#20	
	spi_start <= 1'b0;
	@(posedge send_done)				//一个BYTE发送完成
	spi_end <= 1'b1;	#20	spi_end <= 1'b0;	//拉高一个周期结束信号	
	
end
	
//------------<设置时钟>----------------------------------------------
always #10 sys_clk = ~sys_clk;					//系统时钟周期20ns

endmodule */

/* //------------------------------------------------
//--SPI驱动仿真（模式0，多个BYTE）
//------------------------------------------------
`timescale 1ns/1ns		//时间单位/精度

//------------<模块及端口声明>----------------------------------------
module tb_spi_drive();
//系统接口
reg				sys_clk		;			// 全局时钟50MHz
reg				sys_rst_n	;   		// 复位信号，低电平有效
//用户接口                      		
reg				spi_start 	;   		// 发送传输开始信号，一个高电平
reg				spi_end   	;   		// 发送传输结束信号，一个高电平
reg		[7:0]  	data_send   ;   		// 要发送的数据
wire  	[7:0]  	data_rec  	;   		// 接收到的数据
wire         	send_done	;   		// 主机发送一个字节完毕标志位    
wire         	rec_done	;   		// 主机接收一个字节完毕标志位    
//SPI物理接口                   		
reg				spi_miso	;   		// SPI串行输入，用来接收从机的数据
wire         	spi_sclk	;   		// SPI时钟
wire			spi_cs    	;   		// SPI片选信号
wire         	spi_mosi	;   		// SPI输出，用来给从机发送数据
//仿真用
reg		[3:0]  	cnt_send 	;			//发送数据计数器，0-15      

//------------<例化SPI驱动模块（模式0）>----------------------------------------
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

//------------<设置初始测试条件>----------------------------------------
initial begin
	sys_clk = 1'b0;						//初始时钟为0
	sys_rst_n <= 1'b0;					//初始复位
	spi_start <= 1'b0;	
	data_send <= 8'd0;	
	spi_miso <= 1'bz;	
	spi_end <= 1'b0;	
	#80									//80个时钟周期后
	sys_rst_n <= 1'b1;					//拉高复位，系统进入工作状态
	#30									//30个时钟周期后拉高SPI开始信号，开始SPI传输
	spi_start <= 1'b1;	#20	spi_start <= 1'b0;
end

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		data_send <= 8'd0;			
		spi_end <= 1'b0;			
		cnt_send <= 4'd0; 		
	end
	else if(send_done)begin						//数据发送完成		
		if(cnt_send == 4'd10)begin		
			cnt_send <= 4'd0; 
			spi_end <= 1'b1;					//拉高结束标志，结束SPI传输过程	
			data_send <= 8'd0;
		end
		else begin
			cnt_send <= cnt_send + 4'd1; 
			spi_end <= 1'b0;					
			data_send <= data_send + 4'd1;		//发送数据累加	
		end
	end
	else begin
		data_send <= data_send;
		spi_end <= 1'b0;						//其他时候保持SPI传输（不结束）	
	end
end
	
//------------<设置时钟>----------------------------------------------
always #10 sys_clk = ~sys_clk;					//系统时钟周期20ns

endmodule */

 
 
 //------------------------------------------------
//--SPI驱动仿真--全擦除仿真
//------------------------------------------------
`timescale 1ns/1ns		//时间单位/精度

//------------<模块及端口声明>----------------------------------------
module tb_spi_drive();
//系统接口
reg				sys_clk		;
reg				sys_rst_n	;
//用户接口
reg				spi_start	;
reg				spi_end	;
reg		[7:0]  	data_send   ;
wire  	[7:0]  	data_rec  	;
wire         	send_done	;
wire         	rec_done	;
//SPI物理接口
wire			spi_miso	;
wire         	spi_sclk	;
wire			spi_cs    	;
wire         	spi_mosi	;

parameter 	WR_EN_INST = 8'b0000_0110, 	//写使能指令
			BE_INST = 8'b1100_0111; 	//全擦除指令
	
//
reg	[3:0]	flow_cnt;		//状态跳转计数器
reg	[7:0]	cnt_wait;		//等待计数器

//------------<例化被测试模块>----------------------------------------
spi_drive	spi_drive_inst(
	.sys_clk	(sys_clk	), 			// 全局时钟50MHz
	.sys_rst_n	(sys_rst_n	), 			// 复位信号，低电平有效
	
	.spi_start	(spi_start	), 			
	.spi_end	(spi_end	), 			
	.data_send	(data_send	), 			// 要发送的数据
	.data_rec  	(data_rec	), 			// 接收到的数据
	.send_done	(send_done	), 			// 
	.rec_done	(rec_done	), 			// 
			   
	.spi_miso	(spi_miso	), 			// SPI串行输入，用来接收从机的数据
	.spi_sclk	(spi_sclk	), 			// SPI时钟
	.spi_cs    	(spi_cs		), 			// SPI片选信号
	.spi_mosi	(spi_mosi	)			// SPI输出，用来给从机发送数据
);

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
	#20								//5个时钟周期后
	sys_rst_n <= 1'b1;				//拉高复位，系统进入工作状态	
end

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		data_send <= 8'd0;
		spi_start <= 1'b0;	
		flow_cnt <= 1'd0;
		cnt_wait <= 8'd0;
	end
	else begin
		spi_start <= 1'b0;	
		spi_end <= 1'b0;
		case(flow_cnt)
			'd0:begin
				if(cnt_wait == 100)begin			//上电后等待期间稳定
					cnt_wait <= 8'd0;
					flow_cnt <= flow_cnt + 1;
				end
				else begin
					cnt_wait <= cnt_wait + 1'd1;
					flow_cnt <= flow_cnt;								
				end
			end
			'd1:begin									
				data_send <= WR_EN_INST;			//数据为写使能指令
				spi_start <= 1'b1;					//拉高spi开始通讯信号
				flow_cnt <= flow_cnt + 1;
			end	
			'd2:begin
				if(send_done)begin					//主机一个字节数据被发送完成
					flow_cnt <= flow_cnt + 1;
					// flow_cnt <= 'd4;
					spi_end <= 1'b1;
				end
				else
					flow_cnt <= flow_cnt;
			end	
			'd3:begin
				if(cnt_wait == 10)begin				//等待200ns
					cnt_wait <= 8'd0;				//等待计数器清零
					flow_cnt <= flow_cnt + 1;
				end
				else begin
					cnt_wait <= cnt_wait + 1'd1;
					flow_cnt <= flow_cnt;								
				end
			end
			'd4:begin									
				data_send <= BE_INST;               //数据为写使能指令
				spi_start <= 1'b1;					//拉高spi开始通讯信号
				flow_cnt <= flow_cnt + 1;
			end	
			'd5:begin
				if(send_done)begin					//发送完成
					flow_cnt <= flow_cnt + 1;
					spi_end <= 1'b1;				//拉高结束信号，在发送完8bit数据后结束SPI本次通讯
				end
				else
					flow_cnt <= flow_cnt;
			end	
			'd6:begin								//停留在这个状态
					flow_cnt <= flow_cnt;
			end				
			default:;
		endcase
	end
end

//写入 Flash 仿真模型初始值(全 F)
defparam memory.mem_access.initfile = "initmemory.txt";
	
//------------<设置时钟>----------------------------------------------
always #10 sys_clk = ~sys_clk;		//系统时钟周期20ns

endmodule
