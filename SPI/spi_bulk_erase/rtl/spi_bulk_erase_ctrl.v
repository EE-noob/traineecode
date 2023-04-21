//全擦除指令控制模块
module spi_bulk_erase_ctrl
(
    input               sys_clk		, 			// 全局时钟50MHz
    input               sys_rst_n	, 			// 复位信号，低电平有效
	
	input         		send_done	, 			// 主机发送一个字节完毕标志位      
    output  reg         spi_start	,			// 发送传输开始信号，一个高电平
    output  reg        	spi_end		,			// 发送传输结束信号，一个高电平
    output  reg  [7:0]  data_send    			// 要发送的数据         
);

//指令定义
parameter 	WR_EN 		= 8'b0000_0110, 			//写使能指令
			BULK_ERASE 	= 8'b1100_0111, 			//全擦除指令
			READ 		= 8'h0000_0011;				//读数据指令
			
//reg define	
reg	[7:0]	flow_cnt;							//状态跳转计数器
reg	[31:0]	cnt_wait;							//等待计数器

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		data_send <= 8'd0;
		spi_start <= 1'b0;	
		flow_cnt <= 1'd0;
		cnt_wait <= 'd0;
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
				data_send <= BULK_ERASE;            //全擦除指令
				spi_start <= 1'b1;					//拉高spi开始通讯信号
				flow_cnt <= flow_cnt + 1'd1;
			end	
			'd5:begin
				if(send_done)begin					//主机一个字节数据被发送完成
					flow_cnt <= flow_cnt + 1'd1;
					spi_end <= 1'b1;				//结束第2次SPI通信
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

endmodule