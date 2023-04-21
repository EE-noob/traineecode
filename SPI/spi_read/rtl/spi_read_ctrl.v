//FLASH读数据控制模块：合适的调用SPI驱动模块
module spi_read_ctrl
#(
	parameter	BYTE_MAX 	= 8'd10			,		//一共读取多少个BYTE的数据
				SECTOR_ADDR = 8'b0000_0000	,		//扇区地址
				PAGE_ADDR   = 8'b0000_0000	,		//页地址
				BYTE_ADDR   = 8'b0000_0000			//字节地址
)
(
    input               sys_clk		, 				// 全局时钟50MHz
    input               sys_rst_n	, 				// 复位信号，低电平有效
	
    input		[7:0]	data_rec  	, 				// 接收到的数据
    input				rec_done	, 				// 主机接收一个字节完毕标志位	
    input  		        send_done	, 				// 主机发送一个字节完毕标志位
    output  reg         spi_start	,				// 发送传输开始信号，一个高电平
    output  reg        	spi_end		,				// 发送传输结束信号，一个高电平
    output  reg  [7:0]  data_send    				// 要发送的数据         
);	
	
//指令定义	
localparam	READ	 	= 8'h03; 					//读数据指令
			
//reg define		
reg	[7:0]	flow_cnt;								//状态跳转计数器
reg	[7:0]	data_cnt;								//数据接收计数器
reg	[7:0]	cnt_wait;								//上电等待计数器

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin	                            //复位状态
		data_send <= 8'd0;
		spi_start <= 1'b0;	
		spi_end <= 1'b0;	
		flow_cnt <= 1'd0;
		cnt_wait <= 8'd0;
		data_cnt <= 8'd0;
	end
	else begin
		spi_start <= 1'b0;							//便于生成脉冲信号
		spi_end <= 1'b0;                            //便于生成脉冲信号
		case(flow_cnt)
			'd0:begin
				if(cnt_wait == 100)begin			//上电后等待稳定
					cnt_wait <= 8'd0;
					flow_cnt <= flow_cnt + 1'd1;
				end
				else begin
					cnt_wait <= cnt_wait + 1'd1;
					flow_cnt <= flow_cnt;								
				end
			end
			'd1:begin								//发送读数据指令	
				data_send <= READ;					//读数据指令
				spi_start <= 1'b1;					//拉高spi开始通讯信号
				flow_cnt <= flow_cnt + 1'd1;
			end	
			'd2:begin								//发送扇区地址
				if(send_done)begin					//指令被发送完成
					flow_cnt <= flow_cnt + 1'd1;
					data_send <= SECTOR_ADDR;		//数据为扇区地址
				end
				else begin
					flow_cnt <= flow_cnt;
					data_send <= data_send;							
				end
			end	
			'd3:begin								//发送页地址
				if(send_done)begin					//发送完成
					flow_cnt <= flow_cnt + 1'd1;
					data_send <= PAGE_ADDR;			//数据为页地址
				end
				else begin
					flow_cnt <= flow_cnt;
					data_send <= data_send;							
				end
			end	
			'd4:begin								//发送字节地址
				if(send_done)begin					//指令被发送完成
					flow_cnt <= flow_cnt + 1'd1;
					data_send <= BYTE_ADDR;			//数据为字节地址
				end
				else begin
					flow_cnt <= flow_cnt;
					data_send <= data_send;							
				end
			end				
			'd5:begin
				if(send_done)begin					//字节地址被发送完成
					flow_cnt <= flow_cnt + 1'd1;
					data_send <= 8'd0;				//清空发送数据
				end
				else
					flow_cnt <= flow_cnt;
			end	
			'd6:begin
				if(rec_done)						//这个发送最后一个字节的接收完成标志
					flow_cnt <= flow_cnt + 1'd1;				
				else
					flow_cnt <= flow_cnt;
			end				
			'd7:begin								//读取数据阶段
				if(rec_done)begin					//接收到了一个BYTE数据
					if(data_cnt == BYTE_MAX - 1'd1)begin	//接收到了指定长度个数据
						data_cnt <= 8'd0;			//计数器清零
						spi_end <= 1'b1;			//结束SPI传输
						flow_cnt <= flow_cnt + 1'd1;
					end
					else begin						//没有接收到指定长度的数据则继续接收
						data_cnt <= data_cnt + 1'd1;
						flow_cnt <= flow_cnt;								
					end				
				end
				else begin							//一个BYTE数据接收未完成
						data_cnt <= data_cnt;
						flow_cnt <= flow_cnt;								
				end				
			end
			'd8:begin								//停留在这个状态
					flow_cnt <= flow_cnt;
			end				
			default:;
		endcase
	end
end

endmodule