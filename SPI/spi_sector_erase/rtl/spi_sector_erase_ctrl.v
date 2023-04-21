//SPI扇区擦除控制模块
`timescale 1ns/1ns		//时间单位/精度
module spi_sector_erase_ctrl
#(
	parameter 	SECTOR_ADDR = 8'b0000_0000, 		//扇区地址
	parameter	PAGE_ADDR   = 8'b0000_0000,			//页地址
	parameter	BYTE_ADDR   = 8'b0000_0000			//字节地址
)
(
    input               sys_clk		, 				// 全局时钟50MHz
    input               sys_rst_n	, 				// 复位信号，低电平有效
		
    input  		        send_done	, 				// 主机发送一个字节完毕标志位
    output  reg         spi_start	,				// 发送传输开始信号，一个高电平
    output  reg        	spi_end		,				// 发送传输结束信号，一个高电平
    output  reg  [7:0]  data_send    				// 要发送的数据         
);

//指令定义
localparam 	WR_EN 		 = 8'b0000_0110, 			//写使能指令	
			SECTOR_ERASE = 8'b1101_1000;			//扇区擦除指令
				
//reg define		
reg	[7:0]	flow_cnt;								//状态跳转计数器
reg	[7:0]	cnt_wait;								//上电等待计数器

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		data_send <= 8'd0;
		spi_start <= 1'b0;	
		spi_end <= 1'b0;	
		flow_cnt <= 1'd0;
		cnt_wait <= 8'd0;
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
			'd1:begin									
				data_send <= WR_EN;					//数据为写使能指令
				spi_start <= 1'b1;					//拉高spi开始通讯信号
				flow_cnt <= flow_cnt + 1'd1;
			end
			'd2:begin
				if(send_done)begin					//主机一个字节数据被发送完成
					flow_cnt <= flow_cnt + 1'd1;
					spi_end <= 1'b1;				//结束第1次SPI通信
				end
				else
					flow_cnt <= flow_cnt;
			end	
			'd3:begin
				if(cnt_wait == 10)begin				//等待200ns，两次命令的间隔时间
					cnt_wait <= 8'd0;				//等待计数器清零
					flow_cnt <= flow_cnt + 1'd1;
				end
				else begin
					cnt_wait <= cnt_wait + 1'd1;
					flow_cnt <= flow_cnt;								
				end
			end
			'd4:begin									
				data_send <= SECTOR_ERASE;          //扇区擦除指令
				spi_start <= 1'b1;					//拉高spi开始通讯信号
				flow_cnt <= flow_cnt + 1'd1;
			end				
			'd5:begin								//发送扇区地址
				if(send_done)begin					//指令被发送完成
					flow_cnt <= flow_cnt + 1'd1;
					data_send <= SECTOR_ADDR;		//数据为扇区地址
				end
				else begin
					flow_cnt <= flow_cnt;
					data_send <= data_send;							
				end
			end	
			'd6:begin								//发送页地址
				if(send_done)begin					//发送完成
					flow_cnt <= flow_cnt + 1'd1;
					data_send <= PAGE_ADDR;			//数据为页地址地址
				end
				else begin
					flow_cnt <= flow_cnt;
					data_send <= data_send;							
				end
			end	
			'd7:begin								//发送字节地址
				if(send_done)begin					//指令被发送完成
					flow_cnt <= flow_cnt + 1'd1;
					data_send <= BYTE_ADDR;			//数据为字节地址
				end
				else begin
					flow_cnt <= flow_cnt;
					data_send <= data_send;							
				end
			end				
			'd8:begin
				if(send_done)begin					//主机一个字节数据被发送完成
					flow_cnt <= flow_cnt + 1'd1;
					spi_end <= 1'b1;				//结束第1次SPI通信
				end
				else
					flow_cnt <= flow_cnt;
			end					
			'd9:begin								//停留在这个状态
					flow_cnt <= flow_cnt;
			end				
			default:;
		endcase
	end
end

endmodule