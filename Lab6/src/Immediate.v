`include "opcodes.v"
module ImmediateGenerator (input [31 : 0] inst, output reg [31 : 0] immediate);
    always @(*) begin
        case(inst[6:0])
            `ARITHMETIC_IMM: immediate = {{20{inst[31]}},inst[31:20]};
            `LOAD: immediate = {{20{inst[31]}},inst[31:20]};
            `STORE: immediate = {{20{inst[31]}},inst[31:25],inst[11:7]};
            `BRANCH: immediate = {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
            `JAL: immediate = {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
            `JALR: immediate = {{20{inst[31]}},inst[31:20]};
        endcase

    end
endmodule