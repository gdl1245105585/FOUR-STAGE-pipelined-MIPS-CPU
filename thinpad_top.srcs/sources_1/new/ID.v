`include "defines.vh"
module ID(
    input wire clk,
    input wire rst,

    input wire [31:0] inst_ram_data1,
    
    inout wire [`ctrlBus-1:0] ctrlBus,

    input wire [`IF_ID_Bus-1:0] IF_ID_Bus,
    input wire [`EX_ID_Bus-1:0] EX_ID_Bus,
    input wire [`MEM_ID_Bus-1:0] MEM_ID_Bus,
 //   input wire [`WB_ID_Bus-1:0] WB_ID_Bus,

    output wire [`ID_EX_Bus-1:0] ID_EX_Bus,
    output wire [`ID_IF_Bus-1:0] ID_IF_Bus
);
reg [`ctrlBus-1:0] ctrl_flush;
wire [4:0] Inst_Src1_addr,Inst_Src2_addr,Inst_Des_addr;
//there use read data not the data selected because when you need to mem,not pause the ex stage
wire [31:0] Inst_Src1_Read,Inst_Src2_Read; 
wire [4:0] EX_addr,MEM_addr;
wire [31:0] EX_data,MEM_data;
wire MEM_we,EX_we;
reg [`EX_ID_Bus-1:0] EX_ID_Bus_reg;
reg [`MEM_ID_Bus-1:0] MEM_ID_Bus_reg;
reg [`WB_ID_Bus-1:0] WB_ID_Bus_reg;
assign {EX_we,EX_addr,EX_data} = EX_ID_Bus;
assign {MEM_we,MEM_addr,MEM_data} = MEM_ID_Bus;
//assign {WB_we,WB_addr,WB_data} = WB_ID_Bus;
reg flag;
reg  [`IF_ID_Bus-1:0] IF_ID_Bus_Reg;
always @(posedge clk) begin
    if(rst) begin
        IF_ID_Bus_Reg <= `IF_ID_Bus'd0;
         flag <=0;
    end
    else if(ctrlBus == `memstop)begin
        IF_ID_Bus_Reg <= `IF_ID_Bus'd0;
        ctrl_flush <= 3'd0;
        flag <= 1;
    end
    else begin
        IF_ID_Bus_Reg <= IF_ID_Bus;
        flag <= 0;
    end
end
//always @(posedge clk) begin
//    if(rst) begin
//        WB_ID_Bus_reg<= `WB_ID_Bus'd0;
//        MEM_ID_Bus_reg <= `MEM_ID_Bus'd0;
//        EX_ID_Bus_reg <= `EX_ID_Bus'd0;
//    end
//    else begin
//        WB_ID_Bus_reg <=WB_ID_Bus;
//        MEM_ID_Bus_reg<= MEM_ID_Bus;
//        EX_ID_Bus_reg <= EX_ID_Bus;
//    end
//end

reg [31:0] inst_addr;
reg inst_en_previous;
reg [31:0] inst_addr_next;
wire inst_en;
always @(*) begin
    inst_addr <= IF_ID_Bus_Reg[32:1];
    inst_en_previous <= IF_ID_Bus_Reg[0];
end 
wire [31:0] inst_ram_data;
assign inst_ram_data = inst_en_previous&&~flag ? inst_ram_data1:32'd0;
// inst decoder
wire Inst_ori,Inst_addu,Inst_sw,Inst_lw,Inst_bne,Inst_lui,Inst_bgez,Inst_bltz;
wire Inst_add,  Inst_addi,    Inst_addiu;
wire Inst_sub,  Inst_subu,  Inst_slt,   Inst_slti;
wire Inst_sltu, Inst_sltiu;
wire Inst_mul, Inst_and,   Inst_andi;
wire Inst_nor,   Inst_or;
wire Inst_xor,  Inst_xori,  Inst_sllv,  Inst_sll;
wire Inst_srav, Inst_sra,   Inst_srlv,  Inst_srl;
wire Inst_beq,    Inst_bgtz;
wire Inst_blez;
wire Inst_j,    Inst_jal,   Inst_jr,    Inst_jalr,Inst_lb,Inst_sb;
wire [15:0] imm;
wire [2:0] Inst_Src1_Select;
wire [3:0] Inst_Src2_Select;
wire [11:0] alu_opOneHot;
wire [3:0] mem_OneHot;
wire ID_we;
wire memop;
assign Inst_ori = inst_ram_data[31:26] == 6'b001101;
assign Inst_lui = inst_ram_data[31:26] == 6'b001111 && inst_ram_data[25:21] == 5'b00000;
assign Inst_addu = inst_ram_data[31:26] == 6'b000000 && inst_ram_data[10:6] == 5'b00000 &&inst_ram_data[5:0] == 6'b100001;
assign Inst_sw = inst_ram_data[31:26] ==6'b101011;
assign Inst_lw = inst_ram_data[31:26] == 6'b100011;
assign Inst_bgez = inst_ram_data[31:26] == 6'b000001 &&inst_ram_data[20:16] ==5'b00001;
assign Inst_bltz = inst_ram_data[31:26] == 6'b000001 &&inst_ram_data[20:16] ==5'b00000;

assign Inst_add     = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] == 5'b00000 & inst_ram_data[5:0] == 6'b100000;
assign Inst_addi    = inst_ram_data[31:26] == 6'b001000;
assign Inst_addu    = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b100001;
assign Inst_addiu   = inst_ram_data[31:26] == 6'b001001;
assign Inst_sub     = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b100010;
assign Inst_subu    = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b100011;
assign Inst_slt     = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b101010;
assign Inst_slti    = inst_ram_data[31:26] == 6'b001010;
assign Inst_sltu    = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b101011;
assign Inst_sltiu   = inst_ram_data[31:26] == 6'b001011;
assign Inst_mul    = inst_ram_data[31:26] == 6'b011100 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b000010;
assign Inst_and     = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b100100;
assign Inst_andi    = inst_ram_data[31:26] == 6'b001100;
assign Inst_nor     = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b100111;
assign Inst_or      = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b100101;
assign Inst_ori     = inst_ram_data[31:26] == 6'b001101;
assign Inst_xor     = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b100110;
assign Inst_xori    = inst_ram_data[31:26] == 6'b001110;
assign Inst_sllv    = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b000100;
assign Inst_sll     = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[25:21] == 5'b00000 & inst_ram_data[5:0] ==  6'b000000;
assign Inst_srav    = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b000111;
assign Inst_sra     = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[25:21] == 5'b00000 & inst_ram_data[5:0] ==  6'b000011;
assign Inst_srlv    = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b000110;
assign Inst_srl     = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[25:21] == 5'b00000 & inst_ram_data[5:0] ==  6'b000010;
assign Inst_beq     = inst_ram_data[31:26] == 6'b000100;
assign Inst_bne     = inst_ram_data[31:26] == 6'b000101;
assign Inst_bgez    = inst_ram_data[31:26] == 6'b000001 & inst_ram_data[20:16] == 5'b00001;
assign Inst_bgtz    = inst_ram_data[31:26] == 6'b000111 & inst_ram_data[20:16] == 5'b00000;
assign Inst_blez    = inst_ram_data[31:26] == 6'b000110 & inst_ram_data[20:16] == 5'b00000;
assign Inst_bltz    = inst_ram_data[31:26] == 6'b000001 & inst_ram_data[20:16] == 5'b00000;
assign Inst_j       = inst_ram_data[31:26] == 6'b000010;
assign Inst_jal     = inst_ram_data[31:26] == 6'b000011;
assign Inst_jr      = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[20:16] == 5'b00000 & inst_ram_data[16:11] == 5'b00000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b001000;
assign Inst_jalr    = inst_ram_data[31:26] == 6'b000000 & inst_ram_data[20:16] ==5'b00000 & inst_ram_data[10:6] ==  5'b00000 & inst_ram_data[5:0] ==  6'b001001;
assign Inst_lb      = inst_ram_data[31:26] == 6'b100000;
assign Inst_lw      = inst_ram_data[31:26] == 6'b100011;
assign Inst_sb      = inst_ram_data[31:26] == 6'b101000;
assign Inst_sw      = inst_ram_data[31:26] == 6'b101011;


assign Inst_Src1_addr = inst_ram_data[25:21];
assign Inst_Src2_addr = inst_ram_data[20:16];  
assign Inst_Des_addr = Inst_ori | Inst_lui | Inst_addiu | Inst_lw | Inst_slti | Inst_sltiu | Inst_addi | Inst_andi
                         | Inst_xori  | Inst_lb ?inst_ram_data[20:16]:
                        Inst_addu | Inst_subu | Inst_sll | Inst_or | Inst_xor | Inst_sltu | Inst_slt | Inst_add
                        | Inst_sub | Inst_and | Inst_nor | Inst_sllv | Inst_sra | Inst_srav | Inst_srl | Inst_mul|Inst_srlv|Inst_jalr
                        ?inst_ram_data[15:11]:Inst_jal?5'd31:5'd0;      

assign memop = Inst_sw|Inst_lw|Inst_lb|Inst_sb;
assign imm = inst_ram_data[15:0];
//
assign Inst_Src1_Select[0] =  Inst_add | Inst_addiu | Inst_addu  | Inst_ori | Inst_or | Inst_sw | Inst_lw | Inst_subu
                            | Inst_sltu | Inst_slt | Inst_slti | Inst_sltiu | Inst_addi | Inst_sub | Inst_xor
                           | Inst_and  | Inst_nor | Inst_xori | Inst_sllv | Inst_srav | Inst_srlv| Inst_andi
                           | Inst_lb | Inst_sb ;
assign Inst_Src1_Select[1] = Inst_jalr|Inst_jal;
assign Inst_Src1_Select[2] = Inst_sra | Inst_sll | Inst_srl;
assign Inst_Src2_Select[0] = Inst_add | Inst_addu | Inst_subu  | Inst_or | Inst_xor | Inst_sltu | Inst_slt| Inst_sll
                           | Inst_sub | Inst_and | Inst_nor | Inst_sllv | Inst_sra | Inst_srav | Inst_srlv| Inst_srl ;
assign Inst_Src2_Select[1] = Inst_lui | Inst_addiu | Inst_sw | Inst_lw | Inst_slti  | Inst_addi | Inst_lb| Inst_sltiu|  Inst_sb;
                           
assign Inst_Src2_Select[2] = Inst_jal | Inst_jalr;
assign Inst_Src2_Select[3] = Inst_ori  | Inst_xori| Inst_andi;

assign op_add = Inst_add | Inst_addi | Inst_addiu | Inst_jal | Inst_sw | Inst_lw  | Inst_addu
                | Inst_jalr  | Inst_sb | Inst_lb;
assign op_sub = Inst_subu | Inst_sub;
assign op_slt = Inst_slti|Inst_slt ;
assign op_sltu = Inst_sltiu|Inst_sltu  ;
assign op_and = Inst_andi|Inst_and  ;
assign op_nor = Inst_nor;
assign op_or =  Inst_or |Inst_ori;
assign op_xor = Inst_xori| Inst_xor;
assign op_sll = Inst_sllv| Inst_sll;
assign op_srl = Inst_srl | Inst_srlv;
assign op_sra = Inst_sra | Inst_srav;
assign op_lui = Inst_lui;

assign alu_opOneHot = {op_add, op_sub, op_slt, op_sltu, op_and, op_nor, op_or, op_xor,op_sll, op_srl, op_sra, op_lui};


assign mem_OneHot =  {Inst_lb,Inst_lw, Inst_sb, Inst_sw};

assign ID_we = Inst_ori | Inst_lui | Inst_addiu | Inst_subu | Inst_jal | Inst_addu | Inst_sll | Inst_or 
                 | Inst_lw | Inst_xor | Inst_sltu | Inst_slt | Inst_slti | Inst_sltiu | Inst_add | Inst_addi
                 | Inst_sub | Inst_and | Inst_andi | Inst_nor | Inst_xori | Inst_sllv | Inst_sra | Inst_srav
                 | Inst_srl | Inst_srlv | Inst_jalr |Inst_mul
                 | Inst_lb ;
// // rs to reg1
// assign sel_alu_src1[0] = inst_add | inst_addiu | inst_addu | inst_subu | inst_ori | inst_or | inst_sw | inst_lw 
//                        | inst_xor | inst_sltu | inst_slt | inst_slti | inst_sltiu | inst_addi | inst_sub 
//                        | inst_and | inst_andi | inst_nor | inst_xori | inst_sllv | inst_srav | inst_srlv
//                        | inst_lb | inst_lbu | inst_lh | inst_lhu | inst_sb | inst_sh;

// // pc to reg1
// assign sel_alu_src1[1] = inst_jal | inst_bltzal | inst_bgezal | inst_jalr;

// // sa_zero_extend to reg1
// assign sel_alu_src1[2] = inst_sll | inst_sra | inst_srl;


// // rt to reg2
// assign sel_alu_src2[0] = inst_add | inst_addu | inst_subu | inst_sll | inst_or | inst_xor | inst_sltu | inst_slt
//                        | inst_sub | inst_and | inst_nor | inst_sllv | inst_sra | inst_srav | inst_srl | inst_srlv;

// // imm_sign_extend to reg2
// assign sel_alu_src2[1] = inst_lui | inst_addiu | inst_sw | inst_lw | inst_slti | inst_sltiu | inst_addi | inst_lb
//                        | inst_lbu | inst_lh | inst_lhu | inst_sb | inst_sh;

// // 32'b8 to reg2
// assign sel_alu_src2[2] = inst_jal | inst_bltzal | inst_bgezal | inst_jalr;

// // imm_zero_extend to reg2
// assign sel_alu_src2[3] = inst_ori | inst_andi | inst_xori;


//regfile
regfile regesiterfile(
    .clk(clk),

    .dpra1(Inst_Src1_addr),
    .dpo1(Inst_Src1_Read),
    .dpra2(Inst_Src2_addr),
    .dpo2(Inst_Src2_Read),
    
    .we(MEM_we),
    .a(MEM_addr),
    .d(MEM_data)
);
//Data forwarding
wire [31:0] Inst_Src1_forwarding,Inst_Src2_forwarding;

assign Inst_Src1_forwarding = (EX_we & (EX_addr == Inst_Src1_addr)) ? EX_data :
                                 (MEM_we & (MEM_addr == Inst_Src1_addr)) ? MEM_data :
                      //           (WB_we & (WB_addr == Inst_Src1_addr)) ? WB_data :
                                                    Inst_Src1_Read;
assign Inst_Src2_forwarding = (EX_we & (EX_addr == Inst_Src2_addr)) ? EX_data :
                                 (MEM_we & (MEM_addr == Inst_Src2_addr)) ? MEM_data :
                          //       (WB_we & (WB_addr == Inst_Src2_addr)) ? WB_data :
                                                    Inst_Src2_Read;

wire [31:0] inst_addr_plus4;
assign inst_addr_plus4 = inst_addr +32'd4;
// jump management
always @(*) begin
    if(Inst_beq|Inst_bne|Inst_bgez|Inst_bgtz|Inst_blez|Inst_bltz)
    begin
        inst_addr_next <= inst_addr_plus4 + {{14{inst_ram_data[15]}},inst_ram_data[15:0],2'b0};
    end
    else if(Inst_j|Inst_jal)
    begin
        inst_addr_next <= {inst_addr[31:28],inst_ram_data[25:0],2'b0};
    end
    else if(Inst_jr|Inst_jalr)
    begin
        inst_addr_next <= Inst_Src1_forwarding;
    end
    else 
    begin
        inst_addr_next <= 32'd0;
    end
end

wire rs_eq_rt,rs_ge_z,rs_gt_z,rs_le_z,rs_lt_z;
    assign rs_eq_rt = (Inst_Src1_forwarding == Inst_Src2_forwarding);
    assign rs_ge_z  = ~Inst_Src1_forwarding[31];
    assign rs_gt_z  = ($signed(Inst_Src1_forwarding) > 0);
    assign rs_le_z  = (Inst_Src1_forwarding[31] == 1'b1 || Inst_Src1_forwarding == 32'b0);
    assign rs_lt_z  = (Inst_Src1_forwarding[31]);

    assign inst_en = Inst_beq & rs_eq_rt
                | Inst_bne & ~rs_eq_rt
                | Inst_bgez & rs_ge_z
                | Inst_bgtz & rs_gt_z
                | Inst_blez & rs_le_z
                | Inst_bltz & rs_lt_z
                | Inst_j
                | Inst_jr
                | Inst_jal
                | Inst_jalr;
assign ID_IF_Bus = {inst_addr_next,inst_en};
assign ID_EX_Bus = {Inst_mul,inst_addr,ID_we,Inst_Des_addr,Inst_Src1_Select,Inst_Src2_Select,mem_OneHot,alu_opOneHot,imm,Inst_Src2_forwarding,Inst_Src1_forwarding};
assign ctrlBus = memop==1'b1 ? 3'b`memstop:3'b0;
endmodule