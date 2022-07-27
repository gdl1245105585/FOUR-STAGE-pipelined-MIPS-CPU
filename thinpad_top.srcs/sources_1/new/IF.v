`include "defines.vh"
module IF(
    input clk,
    input rst,

    input [`ID_IF_Bus-1:0] ID_IF_Bus,
    input [`ctrlBus-1:0] ctrlBus,
    output [`IF_ID_Bus-1:0] IF_ID_Bus,
    output reg [31:0] inst_ram_addr,
    output reg inst_ram_en
);
wire [31:0] inst_ram_addr_next;
wire inst_ram_addr_jump_en;
wire [31:0] inst_ram_addr_jump;
reg flag;
reg en_flag;
assign {inst_ram_addr_jump,inst_ram_addr_jump_en} = ID_IF_Bus;
assign inst_ram_addr_next = flag==1?inst_ram_addr :inst_ram_addr_jump_en?inst_ram_addr_jump:inst_ram_addr+32'd4;
    always @(posedge clk) begin 
        if(rst) begin
            inst_ram_addr <= 32'h7ffffffc;
            inst_ram_en <= 1'b0;
            flag <= 0;
        end
        else if (ctrlBus ==  `memstop ) 
        begin
  //          inst_ram_en <= 0;
            inst_ram_en <= 1'b0;
            flag <= 1;
        end
        else if(flag == 1) begin
            flag <= 0;
            inst_ram_en <= 1'b1;
        end
        else if (ctrlBus == 3'b000 &&flag == 0)
        begin
            inst_ram_addr <= inst_ram_addr_next;
            inst_ram_en <= 1'b1;
        end

        else begin     
      //      inst_ram_en <= 1;
        end       
    end 
    assign IF_ID_Bus = {inst_ram_addr,inst_ram_en};
endmodule



// 不接受指令时，ce=0 inst = 0�?  �?以需要有效扣 这里的控制�?�辑