`timescale 1ns / 1ps
`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/30 21:35:17
// Design Name: 
// Module Name: my_cpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module my_cpu(
    input wire clk,  
    input wire rst,

    input wire [31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共�?
    output wire[31:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持�?0
    output wire base_ram_en,

    //ExtRAM信号
    input wire[31:0] ext_ram_read_data,  //ExtRAM数据
    output wire[31:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持�?0
    output wire ext_ram_en,       //ExtRAM片�?�，低有�?
    output wire [31:0] ext_ram_write_data

    );

assign base_ram_be_n = 4'b0; // to be check 
wire [`ID_IF_Bus-1:0] ID_IF_Bus;
wire [`ctrlBus-1:0] ctrlBus;
wire [`IF_ID_Bus-1:0] IF_ID_Bus;
wire [`EX_ID_Bus-1:0] EX_ID_Bus;
wire [`MEM_ID_Bus-1:0] MEM_ID_Bus;
wire [`WB_ID_Bus-1:0] WB_ID_Bus;
wire [`ID_EX_Bus-1:0] ID_EX_Bus;
wire [`EX_MEM_Bus-1:0] EX_MEM_Bus;
wire [`MEM_WB_Bus-1:0] MEM_WB_Bus;
wire [31:0] ext_ram_addr1;
wire [31:0] inst_ram_addr1;
IF IF(
    .clk(clk),
    .rst(rst),

    .ID_IF_Bus(ID_IF_Bus),
    .ctrlBus(ctrlBus),
    .IF_ID_Bus(IF_ID_Bus),
    .inst_ram_addr(base_ram_addr),
    .inst_ram_en(base_ram_en)
);

ID ID(
    .clk(clk),
    .rst(rst),

    .inst_ram_data1(base_ram_data),
    
    .ctrlBus(ctrlBus),

    .IF_ID_Bus(IF_ID_Bus),
    .EX_ID_Bus(EX_ID_Bus),
    .MEM_ID_Bus(MEM_ID_Bus),
  //  .WB_ID_Bus(WB_ID_Bus),

    .ID_EX_Bus(ID_EX_Bus),
    .ID_IF_Bus(ID_IF_Bus)
);

EX EX(
    .clk(clk),
    .rst(rst),
    
    .ID_EX_Bus(ID_EX_Bus),

    .EX_MEM_Bus(EX_MEM_Bus),
    .EX_ID_Bus(EX_ID_Bus),

    .ext_ram_addr(ext_ram_addr), //ExtRAM地址
    .ext_ram_be_n(ext_ram_be_n),  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持�?0
    .ext_ram_en(ext_ram_en),       //ExtRAM片�?�，低有�?
    .ext_ram_write_data(ext_ram_write_data)
);
//FlaseStage FlaseStage(
//    .clk(clk),
//    .rst(rst),
    
//    .EX_FLASE_Bus(EX_FLASE_Bus),
//    .EX_ID_Bus(EX_ID_Bus),
    
//    . 
    
//);
MEM MEM(
    .clk(clk),
    .rst(rst),

    .ext_ram_read_data(ext_ram_read_data),
    .EX_MEM_Bus(EX_MEM_Bus),
    .MEM_ID_Bus(MEM_ID_Bus),

    .MEM_WB_Bus(MEM_WB_Bus)
);

//WB WB(
//    .clk(clk),
//    .rst(rst),
    
//    .MEM_WB_Bus(MEM_WB_Bus),

//    .WB_ID_Bus(WB_ID_Bus)
//);


//mmuInst mmuInst(
//    .addr_i(inst_ram_addr1),
//    .addr_o(base_ram_addr)
//);


//mmuData mmuData(
//    .addr_i(ext_ram_addr1),
//    .addr_o(ext_ram_addr)
//);
endmodule
