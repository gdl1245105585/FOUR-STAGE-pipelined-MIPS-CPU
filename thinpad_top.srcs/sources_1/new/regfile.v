`include "defines.vh"
module regfile(
    input [4:0] a,
    input [31:0] d,
    input [4:0] dpra1,
    input [4:0] dpra2,
    input clk,
    input we,
    output [31:0] dpo1,
    output [31:0] dpo2,
    output reg [32*32-1:0]data,
    output reg wrReady
    );
 //   reg [32*32-1:0] data;
    initial begin data[32*32-1:0]  = 1024'b0;
    end
    assign  dpo1 = data[(dpra1+1)*32-1-:32];
    assign  dpo2 = data[(dpra2+1)*32-1-:32];
    always @(posedge clk) begin
        if (we == 1 )begin
            data[(a+1)*32 -1-:32] <= d;
            wrReady <= 1;
        end
        else wrReady <=0;
    end
endmodule