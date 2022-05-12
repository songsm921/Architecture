`include "opcodes.v"
module HazardDetection(input [6:0]opcode, input [31:0]inst, input [31:0]clk, input [4:0]ID_EX_rd, input ID_EX_mem_read, input isTaken,
output reg isStall, output reg IF_ID_write, output reg pc_write);
    reg use_rs1; 
    reg use_rs2; // caution!
    reg [1:0]clk_start;
    always @(*) begin
        if(opcode !=`JAL && inst[19:15]!=0)
            use_rs1 = 1;
        else
            use_rs1 = 0;
        if(opcode != `JAL && opcode != `ARITHMETIC_IMM && opcode != `JALR && opcode != `LOAD && inst[24:20]!=0)
            use_rs2 = 1;
        else
            use_rs2 = 0;
        if((((inst[19:15] == ID_EX_rd) && use_rs1) || ((inst[24:20] == ID_EX_rd) && use_rs2)) && ID_EX_mem_read) begin
            isStall = 1;
            IF_ID_write = 0; 
            pc_write = 0;
            //clk_start = clk;
        end
        else begin
            isStall = 0;
            IF_ID_write = 1; 
            pc_write = 1;
        end
    end
endmodule
// 