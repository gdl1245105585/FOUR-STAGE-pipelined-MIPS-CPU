`default_nettype none


module thinpad_top(
    (*mark_debug = "true"*)input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ�����루���ã��ɲ��ã�

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�������ON��ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
   (*mark_debug = "true"*) output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����
    output wire video_de           //��������Ч�źţ���������������
);

/* =========== Demo code begin =========== */

// PLL��Ƶʾ��
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // �ⲿʱ������
  // Clock out ports
  .clk_out1(clk_10M), // ʱ�����1��Ƶ����IP���ý��������� // �Ѹĳ�50
  .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP���ý���������
  // Status and control signals
  .reset(reset_btn), // PLL��λ����
  .locked(locked)    // PLL����ָʾ�����"1"��ʾʱ���ȶ���
                     // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
 );

reg reset_of_clk10M;
// �첽��λ��ͬ���ͷţ���locked�ź�תΪ�󼶵�·�ĸ�λreset_of_clk10M
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
       base_ram_data_reg <= 32'h0;  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
        base_ram_addr_reg <= 19'h0; //BaseRAM��ַ
        base_ram_be_n_reg <= 4'b0;  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        base_ram_ce_n_reg <= 1'b1;       //BaseRAMƬѡ������Ч
        base_ram_oe_n_reg <= 1'b1;       //BaseRAM��ʹ�ܣ�����Ч
        base_ram_we_n_reg <= 1'b1;       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
        ext_ram_data_reg <= 32'h0;  //ExtRAM����
        ext_ram_addr_reg <= 19'h0; //ExtRAM��ַ
        ext_ram_be_n_reg <= 4'b0;  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        ext_ram_ce_n_reg <= 1'b1;       //ExtRAMƬѡ������Ч
        ext_ram_oe_n_reg <= 1'b1;       //ExtRAM��ʹ�ܣ�����Ч
        ext_ram_we_n_reg <= 1'b1;      //ExtRAMдʹ�ܣ�����Ч

        data_from_base <= 1'b0;
        from_uart <= 1'b0;
        uart_situation <= 1'b0;
        uart_write_data <= 32'b0;
        write_enable <= 1'b0;
    end
    else if (data_ram_addr >=32'h80000000 && data_ram_addr <= 32'h803fffff && data_ram_en) begin

        base_ram_data_reg <= data_ram_write_data;

        base_ram_addr_reg <= data_ram_addr[21:2]; //BaseRAM��ַ
        base_ram_be_n_reg <= (|data_ram_be_n) ? ~data_ram_be_n : 4'b0;  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        base_ram_ce_n_reg <= ~data_ram_en;       //BaseRAMƬѡ������Ч      
        base_ram_oe_n_reg <= ~(data_ram_en & ~(|data_ram_be_n));
        base_ram_we_n_reg <= ~(data_ram_en & (|data_ram_be_n));

    //ExtRAM�ź�
        ext_ram_data_reg <= 32'h0;  //ExtRAM����
        ext_ram_addr_reg <= 19'h0; //ExtRAM��ַ
        ext_ram_be_n_reg <= 4'b0;  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        ext_ram_ce_n_reg <= 1'b1;       //ExtRAMƬѡ������Ч
        ext_ram_oe_n_reg <= 1'b1;       //ExtRAM��ʹ�ܣ�����Ч
        ext_ram_we_n_reg <= 1'b1;      //ExtRAMдʹ�ܣ�����Ч


        data_from_base <= 1'b0;
        from_uart <= 1'b0;
        uart_situation <= 1'b0;
        uart_write_data <= 32'b0;
        write_enable <= 1'b0;
    end
    else if (data_ram_addr >= 32'h80400000 && data_ram_addr <= 32'h807fffff && data_ram_en) begin       
 //       base_ram_data <= 32'h0;  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
        data_from_base <= 1'b1;
        from_uart <= 1'b0;
        uart_situation <= 1'b0;
        uart_write_data <= 32'b0;
        write_enable <= 1'b0;
        
        base_ram_addr_reg <= inst_ram_addr[21:2]; //BaseRAM��ַ
        base_ram_be_n_reg <= inst_ram_be_n;  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        base_ram_ce_n_reg <= ~inst_ram_en;       //BaseRAMƬѡ������Ч
        base_ram_oe_n_reg <= ~inst_ram_en;       //BaseRAM��ʹ�ܣ�����Ч
        base_ram_we_n_reg <= 1'b1;       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
        ext_ram_addr_reg <= data_ram_addr[21:2];  //ExtRAM����
        ext_ram_data_reg <= data_ram_write_data; //ExtRAM��ַ
        ext_ram_be_n_reg <= (|data_ram_be_n) ? ~data_ram_be_n : 4'b0;  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        ext_ram_ce_n_reg <= ~data_ram_en;       //ExtRAMƬѡ������Ч
        ext_ram_oe_n_reg <= ~(data_ram_en & ~(|data_ram_be_n));       //ExtRAM��ʹ�ܣ�����Ч
        ext_ram_we_n_reg <= ~(data_ram_en & (|data_ram_be_n)); 


    end
    else if (data_ram_addr == 32'hbfd003fc) begin
        data_from_base <= 1'b1;
        from_uart <= 1'b1;
        uart_situation <= 1'b1;
        uart_write_data <= 32'b0;
        write_enable <= 1'b0;    
    
        base_ram_addr_reg <= inst_ram_addr[21:2]; //BaseRAM��ַ
        base_ram_be_n_reg <= inst_ram_be_n;  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        base_ram_ce_n_reg <= ~inst_ram_en;       //BaseRAMƬѡ������Ч
        base_ram_oe_n_reg <= ~inst_ram_en;       //BaseRAM��ʹ�ܣ�����Ч
        base_ram_we_n_reg <= 1'b1;       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
        ext_ram_data_reg <= 32'h0;  //ExtRAM����
        ext_ram_addr_reg <= 19'h0; //ExtRAM��ַ
        ext_ram_be_n_reg <= 4'b0;  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        ext_ram_ce_n_reg <= 1'b1;       //ExtRAMƬѡ������Ч
        ext_ram_oe_n_reg <= 1'b1;       //ExtRAM��ʹ�ܣ�����Ч
        ext_ram_we_n_reg <= 1'b1;      //ExtRAMдʹ�ܣ�����Ч


    end
    else if (data_ram_addr == 32'hbfd003f8 && data_ram_en) begin   
        data_from_base <= 1'b1;
        from_uart <= 1'b1;
        uart_situation <= 1'b0;
        uart_write_data <= data_ram_write_data;
        write_enable <= (|data_ram_be_n) ? 1'b1 : 1'b0;
         
        base_ram_addr_reg <= inst_ram_addr[21:2]; //BaseRAM��ַ
        base_ram_be_n_reg <= inst_ram_be_n;  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        base_ram_ce_n_reg <= ~inst_ram_en;       //BaseRAMƬѡ������Ч
        base_ram_oe_n_reg <= ~inst_ram_en;       //BaseRAM��ʹ�ܣ�����Ч
        base_ram_we_n_reg <= 1'b1;       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
        ext_ram_data_reg <= 32'h0;  //ExtRAM����
        ext_ram_addr_reg <= 19'h0; //ExtRAM��ַ
        ext_ram_be_n_reg <= 4'b0;  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        ext_ram_ce_n_reg <= 1'b1;       //ExtRAMƬѡ������Ч
        ext_ram_oe_n_reg <= 1'b1;       //ExtRAM��ʹ�ܣ�����Ч
        ext_ram_we_n_reg <= 1'b1;      //ExtRAMдʹ�ܣ�����Ч


    end
    else begin       
        data_from_base <= 1'b1;
        from_uart <= 1'b0;
        uart_situation <= 1'b0;
        uart_write_data <= 32'b0;
        write_enable <= 1'b0;
         
        base_ram_addr_reg <= inst_ram_addr[21:2]; //BaseRAM��ַ
        base_ram_be_n_reg <= inst_ram_be_n;  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        base_ram_ce_n_reg <= ~inst_ram_en;       //BaseRAMƬѡ������Ч
        base_ram_oe_n_reg <= ~inst_ram_en;       //BaseRAM��ʹ�ܣ�����Ч
        base_ram_we_n_reg <= 1'b1;       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
        ext_ram_data_reg <= 32'h0;  //ExtRAM����
        ext_ram_addr_reg <= 19'h0; //ExtRAM��ַ
        ext_ram_be_n_reg <= 4'b0;  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        ext_ram_ce_n_reg <= 1'b1;       //ExtRAMƬѡ������Ч
        ext_ram_oe_n_reg <= 1'b1;       //ExtRAM��ʹ�ܣ�����Ч
        ext_ram_we_n_reg <= 1'b1;      //ExtRAMдʹ�ܣ�����Ч


    end
end


// uart
async_receiver #(.ClkFrequency(48000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_r(
        .clk(clk_20M),                       //�ⲿʱ���ź�
        .RxD(rxd),                           //�ⲿ�����ź�����
        .RxD_data_ready(ext_uart_ready),  //���ݽ��յ���־
        .RxD_clear(ext_uart_clear),       //������ձ�־
        .RxD_data(ext_uart_rx)             //���յ���һ�ֽ�����
    );

assign ext_uart_clear = ext_uart_ready; //�յ����ݵ�ͬʱ�������־����Ϊ������ȡ��ext_uart_buffer��
always @(posedge clk_20M) begin //���յ�������ext_uart_buffer
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

always @(posedge clk_20M) begin //��������ext_uart_buffer���ͳ�ȥ
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

async_transmitter #(.ClkFrequency(48000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_t(
        .clk(clk_20M),                  //�ⲿʱ���ź�
        .TxD(txd),                      //�����ź����
        .TxD_busy(ext_uart_busy),       //������æ״ָ̬ʾ
        .TxD_start(ext_uart_start),    //��ʼ�����ź�
        .TxD_data(ext_uart_tx)        //�����͵�����
    );

endmodule
