`default_nettype none


module thinpad_top(
    (*mark_debug = "true"*)input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
   (*mark_debug = "true"*) output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);

/* =========== Demo code begin =========== */

// PLL分频示例
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // 外部时钟输入
  // Clock out ports
  .clk_out1(clk_10M), // 时钟输出1，频率在IP配置界面中设置 // 已改成50
  .clk_out2(clk_20M), // 时钟输出2，频率在IP配置界面中设置
  // Status and control signals
  .reset(reset_btn), // PLL复位输入
  .locked(locked)    // PLL锁定指示输出，"1"表示时钟稳定，
                     // 后级电路复位信号应当由它生成（见下）
 );

reg reset_of_clk10M;
// 异步复位，同步释放，将locked信号转为后级电路的复位reset_of_clk10M
always@(posedge clk_20M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end


//cpu inst sram
wire        inst_ram_en;
wire [3 :0] inst_ram_be_n;
wire [31:0] inst_ram_addr;
wire [31:0] inst_ram_read_data;
wire        data_ram_en;
wire [3 :0] data_ram_be_n;
wire [31:0] data_ram_addr;
wire [31:0] data_ram_write_data;
wire [31:0] data_ram_read_data;


my_cpu u_mycpu(              
    .clk              (clk_20M),
    .rst           (reset_of_clk10M),
    .base_ram_addr   (inst_ram_addr ),
    .base_ram_be_n  (inst_ram_be_n),
    .base_ram_data  (inst_ram_read_data),
    .base_ram_en(inst_ram_en),

    .ext_ram_en     (data_ram_en   ),//1
    .ext_ram_be_n    (data_ram_be_n  ),//sel
    .ext_ram_addr   (data_ram_addr ),
  //  .ext_ram_we     (ext_ram_we),
    .ext_ram_write_data  (data_ram_write_data),
    .ext_ram_read_data  (data_ram_read_data)
);




reg [31:0] base_ram_data_reg;
reg [19:0] base_ram_addr_reg;
reg [3:0] base_ram_be_n_reg;
reg base_ram_ce_n_reg;
reg base_ram_oe_n_reg;
reg base_ram_we_n_reg;

reg [31:0] ext_ram_data_reg;
reg [19:0] ext_ram_addr_reg;
reg [3:0] ext_ram_be_n_reg;
reg ext_ram_ce_n_reg;
reg ext_ram_oe_n_reg;
reg ext_ram_we_n_reg;

reg data_from_base; // 1-inst 0-data for base_ram
reg from_uart;
reg uart_situation; // 1-flag 0-data

(*mark_debug = "true"*)wire [31:0] uart_rdata;
(*mark_debug = "true"*)reg [31:0] uart_write_data;

wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer;
(*mark_debug = "true"*) reg  [7:0] ext_uart_tx;
(*mark_debug = "true"*)wire ext_uart_ready;
wire  ext_uart_clear, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;

reg write_enable;

reg uart_read_flag;
reg uart_write_flag;

assign base_ram_data = ~base_ram_we_n_reg ? base_ram_data_reg : 32'bz;
assign ext_ram_data = ~ext_ram_we_n_reg ? ext_ram_data_reg : 32'bz;

assign base_ram_addr = base_ram_addr_reg;
assign base_ram_be_n = base_ram_be_n_reg;
assign base_ram_ce_n = base_ram_ce_n_reg;
assign base_ram_oe_n = base_ram_oe_n_reg;
assign base_ram_we_n = base_ram_we_n_reg;

assign ext_ram_addr = ext_ram_addr_reg;
assign ext_ram_be_n = ext_ram_be_n_reg;
assign ext_ram_ce_n = ext_ram_ce_n_reg;
assign ext_ram_oe_n = ext_ram_oe_n_reg;
assign ext_ram_we_n = ext_ram_we_n_reg;


assign inst_ram_read_data = ~data_from_base ? 32'b0 
                            : ~base_ram_oe_n_reg ? base_ram_data 
                            : 32'b0;
assign data_ram_read_data = from_uart ? uart_situation ? {30'b0,ext_uart_avai,~ext_uart_busy} : {24'b0,ext_uart_buffer} : data_from_base ? (~ext_ram_oe_n_reg ? ext_ram_data : 32'b0) : (~base_ram_oe_n_reg ? base_ram_data : 32'b0);
 
// out 
always @ (posedge clk_20M) begin
    if (reset_of_clk10M) begin
       base_ram_data_reg <= 32'h0;  //BaseRAM数据，低8位与CPLD串口控制器共享
        base_ram_addr_reg <= 19'h0; //BaseRAM地址
        base_ram_be_n_reg <= 4'b0;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
        base_ram_ce_n_reg <= 1'b1;       //BaseRAM片选，低有效
        base_ram_oe_n_reg <= 1'b1;       //BaseRAM读使能，低有效
        base_ram_we_n_reg <= 1'b1;       //BaseRAM写使能，低有效

    //ExtRAM信号
        ext_ram_data_reg <= 32'h0;  //ExtRAM数据
        ext_ram_addr_reg <= 19'h0; //ExtRAM地址
        ext_ram_be_n_reg <= 4'b0;  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
        ext_ram_ce_n_reg <= 1'b1;       //ExtRAM片选，低有效
        ext_ram_oe_n_reg <= 1'b1;       //ExtRAM读使能，低有效
        ext_ram_we_n_reg <= 1'b1;      //ExtRAM写使能，低有效

        data_from_base <= 1'b0;
        from_uart <= 1'b0;
        uart_situation <= 1'b0;
        uart_write_data <= 32'b0;
        write_enable <= 1'b0;
    end
    else if (data_ram_addr >=32'h80000000 && data_ram_addr <= 32'h803fffff && data_ram_en) begin

        base_ram_data_reg <= data_ram_write_data;

        base_ram_addr_reg <= data_ram_addr[21:2]; //BaseRAM地址
        base_ram_be_n_reg <= (|data_ram_be_n) ? ~data_ram_be_n : 4'b0;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
        base_ram_ce_n_reg <= ~data_ram_en;       //BaseRAM片选，低有效      
        base_ram_oe_n_reg <= ~(data_ram_en & ~(|data_ram_be_n));
        base_ram_we_n_reg <= ~(data_ram_en & (|data_ram_be_n));

    //ExtRAM信号
        ext_ram_data_reg <= 32'h0;  //ExtRAM数据
        ext_ram_addr_reg <= 19'h0; //ExtRAM地址
        ext_ram_be_n_reg <= 4'b0;  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
        ext_ram_ce_n_reg <= 1'b1;       //ExtRAM片选，低有效
        ext_ram_oe_n_reg <= 1'b1;       //ExtRAM读使能，低有效
        ext_ram_we_n_reg <= 1'b1;      //ExtRAM写使能，低有效


        data_from_base <= 1'b0;
        from_uart <= 1'b0;
        uart_situation <= 1'b0;
        uart_write_data <= 32'b0;
        write_enable <= 1'b0;
    end
    else if (data_ram_addr >= 32'h80400000 && data_ram_addr <= 32'h807fffff && data_ram_en) begin       
 //       base_ram_data <= 32'h0;  //BaseRAM数据，低8位与CPLD串口控制器共享
        data_from_base <= 1'b1;
        from_uart <= 1'b0;
        uart_situation <= 1'b0;
        uart_write_data <= 32'b0;
        write_enable <= 1'b0;
        
        base_ram_addr_reg <= inst_ram_addr[21:2]; //BaseRAM地址
        base_ram_be_n_reg <= inst_ram_be_n;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
        base_ram_ce_n_reg <= ~inst_ram_en;       //BaseRAM片选，低有效
        base_ram_oe_n_reg <= ~inst_ram_en;       //BaseRAM读使能，低有效
        base_ram_we_n_reg <= 1'b1;       //BaseRAM写使能，低有效

    //ExtRAM信号
        ext_ram_addr_reg <= data_ram_addr[21:2];  //ExtRAM数据
        ext_ram_data_reg <= data_ram_write_data; //ExtRAM地址
        ext_ram_be_n_reg <= (|data_ram_be_n) ? ~data_ram_be_n : 4'b0;  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
        ext_ram_ce_n_reg <= ~data_ram_en;       //ExtRAM片选，低有效
        ext_ram_oe_n_reg <= ~(data_ram_en & ~(|data_ram_be_n));       //ExtRAM读使能，低有效
        ext_ram_we_n_reg <= ~(data_ram_en & (|data_ram_be_n)); 


    end
    else if (data_ram_addr == 32'hbfd003fc) begin
        data_from_base <= 1'b1;
        from_uart <= 1'b1;
        uart_situation <= 1'b1;
        uart_write_data <= 32'b0;
        write_enable <= 1'b0;    
    
        base_ram_addr_reg <= inst_ram_addr[21:2]; //BaseRAM地址
        base_ram_be_n_reg <= inst_ram_be_n;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
        base_ram_ce_n_reg <= ~inst_ram_en;       //BaseRAM片选，低有效
        base_ram_oe_n_reg <= ~inst_ram_en;       //BaseRAM读使能，低有效
        base_ram_we_n_reg <= 1'b1;       //BaseRAM写使能，低有效

    //ExtRAM信号
        ext_ram_data_reg <= 32'h0;  //ExtRAM数据
        ext_ram_addr_reg <= 19'h0; //ExtRAM地址
        ext_ram_be_n_reg <= 4'b0;  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
        ext_ram_ce_n_reg <= 1'b1;       //ExtRAM片选，低有效
        ext_ram_oe_n_reg <= 1'b1;       //ExtRAM读使能，低有效
        ext_ram_we_n_reg <= 1'b1;      //ExtRAM写使能，低有效


    end
    else if (data_ram_addr == 32'hbfd003f8 && data_ram_en) begin   
        data_from_base <= 1'b1;
        from_uart <= 1'b1;
        uart_situation <= 1'b0;
        uart_write_data <= data_ram_write_data;
        write_enable <= (|data_ram_be_n) ? 1'b1 : 1'b0;
         
        base_ram_addr_reg <= inst_ram_addr[21:2]; //BaseRAM地址
        base_ram_be_n_reg <= inst_ram_be_n;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
        base_ram_ce_n_reg <= ~inst_ram_en;       //BaseRAM片选，低有效
        base_ram_oe_n_reg <= ~inst_ram_en;       //BaseRAM读使能，低有效
        base_ram_we_n_reg <= 1'b1;       //BaseRAM写使能，低有效

    //ExtRAM信号
        ext_ram_data_reg <= 32'h0;  //ExtRAM数据
        ext_ram_addr_reg <= 19'h0; //ExtRAM地址
        ext_ram_be_n_reg <= 4'b0;  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
        ext_ram_ce_n_reg <= 1'b1;       //ExtRAM片选，低有效
        ext_ram_oe_n_reg <= 1'b1;       //ExtRAM读使能，低有效
        ext_ram_we_n_reg <= 1'b1;      //ExtRAM写使能，低有效


    end
    else begin       
        data_from_base <= 1'b1;
        from_uart <= 1'b0;
        uart_situation <= 1'b0;
        uart_write_data <= 32'b0;
        write_enable <= 1'b0;
         
        base_ram_addr_reg <= inst_ram_addr[21:2]; //BaseRAM地址
        base_ram_be_n_reg <= inst_ram_be_n;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
        base_ram_ce_n_reg <= ~inst_ram_en;       //BaseRAM片选，低有效
        base_ram_oe_n_reg <= ~inst_ram_en;       //BaseRAM读使能，低有效
        base_ram_we_n_reg <= 1'b1;       //BaseRAM写使能，低有效

    //ExtRAM信号
        ext_ram_data_reg <= 32'h0;  //ExtRAM数据
        ext_ram_addr_reg <= 19'h0; //ExtRAM地址
        ext_ram_be_n_reg <= 4'b0;  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
        ext_ram_ce_n_reg <= 1'b1;       //ExtRAM片选，低有效
        ext_ram_oe_n_reg <= 1'b1;       //ExtRAM读使能，低有效
        ext_ram_we_n_reg <= 1'b1;      //ExtRAM写使能，低有效


    end
end


// uart
async_receiver #(.ClkFrequency(48000000),.Baud(9600)) //接收模块，9600无检验位
    ext_uart_r(
        .clk(clk_20M),                       //外部时钟信号
        .RxD(rxd),                           //外部串行信号输入
        .RxD_data_ready(ext_uart_ready),  //数据接收到标志
        .RxD_clear(ext_uart_clear),       //清除接收标志
        .RxD_data(ext_uart_rx)             //接收到的一字节数据
    );

assign ext_uart_clear = ext_uart_ready; //收到数据的同时，清除标志，因为数据已取到ext_uart_buffer中
always @(posedge clk_20M) begin //接收到缓冲区ext_uart_buffer
    if (reset_of_clk10M) 
    begin
        ext_uart_buffer <= 8'b0;
        ext_uart_avai <= 1'b0;
    end
    else if(ext_uart_ready)
    begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1'b1;
    end 
    else if(from_uart&&~write_enable)
    begin 
        ext_uart_avai <= 1'b0;
    end
end

always @(posedge clk_20M) begin //将缓冲区ext_uart_buffer发送出去
    if(reset_of_clk10M) begin
        ext_uart_tx <= 8'b0;
        ext_uart_start <= 1'b0;
    end
    else if(!ext_uart_busy && write_enable)
    begin 
        ext_uart_tx <= uart_write_data[7:0];
        ext_uart_start <= 1;
    end 
    else  
    begin
        ext_uart_start <= 0;
    end
end

async_transmitter #(.ClkFrequency(48000000),.Baud(9600)) //发送模块，9600无检验位
    ext_uart_t(
        .clk(clk_20M),                  //外部时钟信号
        .TxD(txd),                      //串行信号输出
        .TxD_busy(ext_uart_busy),       //发送器忙状态指示
        .TxD_start(ext_uart_start),    //开始发送信号
        .TxD_data(ext_uart_tx)        //待发送的数据
    );

endmodule
