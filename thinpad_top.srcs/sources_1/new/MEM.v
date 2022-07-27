`include "defines.vh"
module MEM(
    input wire clk,
    input wire rst,

    input wire [31:0] ext_ram_read_data,
    input wire [`EX_MEM_Bus-1:0] EX_MEM_Bus,
    output wire [`MEM_ID_Bus-1:0] MEM_ID_Bus,

    output wire [`MEM_WB_Bus-1:0] MEM_WB_Bus
);
reg [`EX_MEM_Bus-1:0] EX_MEM_Bus_Reg;
always @(posedge clk) begin
    if(rst) begin
        EX_MEM_Bus_Reg <= `EX_MEM_Bus'd0;
    end
    else begin
        EX_MEM_Bus_Reg <=EX_MEM_Bus;
    end
end
wire [3:0] sb_lb_decoder;
wire inst_lb,inst_lw, inst_sb, inst_sw;
wire [3:0] mem_OneHot;
wire [31:0] alu_result,wb_result;
wire [4:0] Inst_Des_addr;
wire ex_we;
wire [7:0] lb_low_data;

assign {sb_lb_decoder,mem_OneHot,ex_we,Inst_Des_addr,alu_result} = EX_MEM_Bus_Reg;
assign {inst_lb,inst_lw, inst_sb, inst_sw} = mem_OneHot;
assign lb_low_data = sb_lb_decoder[3]?ext_ram_read_data[31:24]:
                     sb_lb_decoder[2]?ext_ram_read_data[23:16]:
                     sb_lb_decoder[1]?ext_ram_read_data[15:8]:
                     sb_lb_decoder[0]?ext_ram_read_data[7:0]:8'd1;  
//assign wb_result = inst_lb?{{24{lb_low_data[7]}},lb_low_data}:inst_lw?ext_ram_read_data:alu_result;
assign wb_result = inst_lb?{{24{lb_low_data[7]}},lb_low_data}:inst_lw?ext_ram_read_data:alu_result;
assign MEM_WB_Bus={ex_we,Inst_Des_addr,wb_result};
assign MEM_ID_Bus = MEM_WB_Bus;
endmodule