# 基于APB的SPI接口驱动m25p16 flash

## 一、设计要求
基于APB的SPI接口驱动
要求:
A、
设计一个基于APB总线的SPI master驱动控制器，Controller 端为APB总线,
APB总线时钟频率为100M
B、
SPI接口支持1pcs slave和4pcs slave SPI，SPI 时运行时钟为25M
C、
Controller能通过APB总线完成SPI外设的各种操作，比如块擦除、数据写入、
数据读取、状态读取等操作。设计的目标模块主要功能是完成了接口的通信转换，主
控端采用AMBA的APB总线，设备端采用SPI master core。
D、
以M25P16 SPI Flash为原型对设计模块进行验证，搭建tb测试环境并验证
（野火的视频是W25Q16,16表示16Mbit也就是2MByte）
E、模块名称: apb_ spi master.v
F、模块顶层端口如下:
![在这里插入图片描述](https://img-blog.csdnimg.cn/dd749cf759054ab487834588ef7484ae.png)
![在这里插入图片描述](https://img-blog.csdnimg.cn/8c37310f765648f5ad0b17c466a541d6.png)
G 模块内APB操作的寄存器定义如下
![在这里插入图片描述](https://img-blog.csdnimg.cn/ceb8a3b09f754422b8f2b22f70d5c6ea.png)
![在这里插入图片描述](https://img-blog.csdnimg.cn/f1c94ebdf2c74c62b8cf34b7fe2aa05b.png)
![在这里插入图片描述](https://img-blog.csdnimg.cn/babd68433e454c0a855123e31d333437.png)
![在这里插入图片描述](https://img-blog.csdnimg.cn/5ec2a45777074b2d97090c1166e71e1e.png)
### 图示
![在这里插入图片描述](https://img-blog.csdnimg.cn/93bd3b7df7a6444d84ff4ed69078278d.png)




## 二、设计思路
### apb3.0 原理
PENABLE：这表明访问阶段正在发生。在整个访问阶段，地址、数据和控制信号都保持有效。在这个周期结束时，传输就完成了。

![在这里插入图片描述](https://img-blog.csdnimg.cn/1a3f828aa4b9440ea3df9df3d33a9712.png)

![在这里插入图片描述](https://img-blog.csdnimg.cn/d50a1768a3b44e8eb88286e59c5f62cf.png)


### spi 原理

#### 简介
SPI ( Serial Peripheral Interface，串行外设接口）是一种串行、高速的，全双工，同步的通信总线。分为主（master）、从（slave）两种模式，一个SPI通讯系统需要包含一个（且只能是一个）maser（主设备），一个或多个slave（从设备），常用于短距离通讯。
SPI接口的读写操作，都是由master发起。当存在多个从设备时，通过各自的片选（slave select）信号进行管理。
优点：快，简单
缺点：没有信号确认数据是否接收
硬件开发人员设计、提供的SPI接口，其实只是一个数据读写通道 ，具体读写数据所代表的意义需要在应用中定义。不像SD接口那样，对于命令有着明确详细的定义。
#### interface
除了供电、接地两个模拟连接以外，SPI总线定义四组数字信号：

    - 接口时钟SCLK（Serial Clock，也叫SCK、CLK），master输出至slave的通讯时钟。
    - MOSI（ Master Output Slave Input，也叫SIMO、MTSR、DI、DIN、SI）自master输出至slave的数据线。
    - MISO （Master Input Slave Output，也叫SOMI、MRST、DO、DOUT、SO）自slave输出至master的数据线。
    - SS（Slave select，也叫nSS、CS、CSB、CSN、EN、nSS、STE、SYNC）master对slave的片选信号，自master输出至slave，低有效。

![在这里插入图片描述](https://img-blog.csdnimg.cn/da3acb0d2aba4ad884f9666b7eec697d.png)
某些芯片产品上，对SPI两条数据线的命名为SDO/SDI。此时需要将master的SDO连接到slave的SDI，将master的SDI连接到slave的SDO。

![在这里插入图片描述](https://img-blog.csdnimg.cn/1c4502c51ec44ba78efa7f997a8bfb2c.png)

#### mode
The SPI functions in three modes, run, wait, and stop.
•
Run Mode
This is the basic mode of operation.
•
Wait Mode
SPI operation in wait mode is a configurable low power mode, controlled by the SPISWAI bit
located in the SPICR2 register. In wait mode, if the SPISWAI bit is clear, the SPI operates like in
Run Mode. If the SPISWAI bit is set, the SPI goes into a power conservative state, with the SPI
clock generation turned off. If the SPI is configured as a master, any transmission in progress stops,
but is resumed after CPU goes into Run Mode. If the SPI is configured as a slave, reception and
transmission of a byte continues, so that the slave stays synchronized to the master.
•
Stop Mode
The SPI is inactive in stop mode for reduced power consumption. If the SPI is configured as a
master, any transmission in progress stops, but is resumed after CPU goes into Run Mode. If the
SPI is configured as a slave, reception and transmission of a byte continues, so that the slave stays
synchronized to the master.

#### register
![在这里插入图片描述](https://img-blog.csdnimg.cn/de3d062adc4b46908a3ab1e96707ea88.png)
![在这里插入图片描述](https://img-blog.csdnimg.cn/da06a56a9622403bb9589dfcea4bf033.png)


![在这里插入图片描述](https://img-blog.csdnimg.cn/3fd9d4f26f09452bb086058cc71270c6.png)

#### 时序

SPI的接口时序配置由两个参数决定：
1、 CPOL，clock polarity，译作时钟极性。
2、 CPHA，clock phase，译作时钟相位。
CPOL具体说明：
CPOL用于定义时钟信号在空闲状态下处于高电平还是低电平，为1代表高电平，0为低电平。
知道这些就好，很简单的一个概念 。如果存在疑问，结合下面的时序图理解就好。
CPHA具体说明：
首先，在同步接口中，肯定存在一个接口时钟，用来同步采样接口上数据的。
CPHA就是用来定义数据采样在第几个边沿的。为1代表第二个边沿采样，为0代表第一个边沿采样。
以上两个参数，总共有四种组合：
MODE 0: CPOL=0, CPHA=0 ，CLK限制状态为低电平，第一个边沿采样，所以是上升沿采样。
MODE 1: CPOL=0, CPHA=1，CLK限制状态为低电平，第二个边沿采样，所以是下降沿采样。
MODE 2: CPOL=1, CPHA=0 ，CLK限制状态为高电平，第一个边沿采样，所以是下降沿采样。
MODE 3: CPOL=1, CPHA=1 ，CLK限制状态为高电平，第二个边沿采样，所以是上升沿采样。


#### 数据有效性
MOSI和MISO线在SCK的每个时钟周期传输一位数据，开发者可以自行设置MSB或LSB先行，不过需要保证两个通讯设备都使用同样的协定。
SPI 使用 MOSI 及 MISO 信号线来传输数据，使用 SCK 信号线进行数据同步。MOSI 及 MISO 数据线在 SCK 的每个时钟周期传输一位数据，且数据输入输出是同时进行的。数据传输时，MSB 先行或 LSB 先行并没有作硬性规定，但要保证两个 SPI 通讯设备之间使用同样的协定，一般都会采用MSB 先行模式。

### M25P16 SPI Flash 原理
##### ac characteristics
![在这里插入图片描述](https://img-blog.csdnimg.cn/ef42a6795cae477d929ece90c68aa303.png)
![在这里插入图片描述](https://img-blog.csdnimg.cn/2f8b7e27f1e24b0d90a888058a610de8.png)




### 图示
![在这里插入图片描述](https://img-blog.csdnimg.cn/93bd3b7df7a6444d84ff4ed69078278d.png)

### state machine
controller_state
![在这里插入图片描述](https://img-blog.csdnimg.cn/18d4dc4138b14ad8a3052695f62ece23.png)

### 说明
spi最大突发传输计数器和阈值寄存器的位宽


## 三、设计实现

### rtl_code
### tb

###  terminal_output
### waveform
##### clk_gen
	POSTSIM
![!\[在这里插入图片描述\](https://img-blog.csdnimg.cn/1e365ad52d6a4b0eb440b31bc8073070.png](https://img-blog.csdnimg.cn/7beceb79ddc04f579b0a7c6a873feae7.png)
	GATESIM
![在这里插入图片描述](https://img-blog.csdnimg.cn/54b15bf56d9748a6b71b9f7eb75a67a9.png)



### spyglass
### dc
#### clkgen area report
![在这里插入图片描述](https://img-blog.csdnimg.cn/c07b30f6ae2542149dca4f0967c7b831.png)
