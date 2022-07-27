`include "defines.vh"
module EX(
    input clk,
    input rst,
    
    input wire [`ID_EX_Bus-1:0] ID_EX_Bus,

    output wire [`EX_MEM_Bus-1:0] EX_MEM_Bus,
    output wire [`EX_ID_Bus-1:0] EX_ID_Bus,

    output wire[31:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持�??0
    output wire ext_ram_en,       //ExtRAM片�?�，低有�??
    output wire [31:0] ext_ram_write_data
);
reg [`ID_EX_Bus-1:0] ID_EX_Bus_Reg;
always @(posedge clk) begin
    if(rst) begin
        ID_EX_Bus_Reg <= `ID_EX_Bus'd0;
    end
    else begin
        ID_EX_Bus_Reg <= ID_EX_Bus;
    end
end
wire inst_mul;
wire [15:0] imm;
wire [2:0] Inst_Src1_Select;
wire [3:0] Inst_Src2_Select;
wire [11:0] alu_opOneHot;
wire [3:0] mem_OneHot;
wire [31:0] Inst_Src2_forwarding,Inst_Src1_forwarding;
wire [4:0] Inst_Des_addr;
wire ex_we;
wire [31:0] inst_addr;
assign {inst_mul,inst_addr,ex_we,Inst_Des_addr,Inst_Src1_Select,Inst_Src2_Select,mem_OneHot,alu_opOneHot,imm,Inst_Src2_forwarding,Inst_Src1_forwarding}=ID_EX_Bus_Reg;

wire [31:0] alu_result;
wire [31:0] alu_src1,alu_src2;

assign alu_src1 = Inst_Src1_Select[1] ? inst_addr :
                      Inst_Src1_Select[2] ? {27'b0,imm[10:6]} : Inst_Src1_forwarding;
assign alu_src2 =     Inst_Src2_Select[1] ? {{16{imm[15]}},imm[15:0]} :
                      Inst_Src2_Select[2] ? 32'd8:
                      Inst_Src2_Select[3] ? {16'b0, imm} : Inst_Src2_forwarding;

alu u_alu(
    .alu_control (alu_opOneHot ),
    .alu_src1    (alu_src1    ),
    .alu_src2    (alu_src2    ),
    .alu_result  (alu_result  )
);
wire [63:0] mul_result;
dadda_32 u_mul(
    .A(Inst_Src1_forwarding),
    .B(Inst_Src2_forwarding),
    .Y(mul_result)
    );
wire [31:0] final_result;
assign final_result = inst_mul?mul_result[31:0]:alu_result;
wire [3:0] sb_lb_decoder;
assign sb_lb_decoder = alu_result[1:0] == 2'b00 ?4'b0001:
                       alu_result[1:0] == 2'b01 ?4'b0010:
                       alu_result[1:0] == 2'b10 ?4'b0100:
                       alu_result[1:0] == 2'b11 ?4'b1000:4'b0000;                                    
wire inst_sw,inst_lw,inst_sb,insy_lb;
assign {inst_lb,inst_lw, inst_sb, inst_sw} = mem_OneHot;
assign ext_ram_be_n = inst_sb?sb_lb_decoder:inst_sw?4'b1111:4'b0;
assign ext_ram_en = inst_sw|inst_lw|inst_sb|inst_lb;
assign ext_ram_addr = alu_result;
assign ext_ram_write_data = inst_sb?{4{Inst_Src2_forwarding[7:0]}}:Inst_Src2_forwarding;

assign  EX_ID_Bus= {ex_we,Inst_Des_addr,final_result};
assign  EX_MEM_Bus = {sb_lb_decoder,mem_OneHot,ex_we,Inst_Des_addr,final_result};
endmodule