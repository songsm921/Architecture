`include "opcodes.v"

module ActualPC(input isTaken, input isJAL, input isBranch, input isJALR, input [31:0] PC, input[31:0] immediate, 
input [31:0] alu_result, output reg[31:0] actualPC);
    always @(*) begin
        if(isTaken) begin
            if(isJAL || isJALR) begin
                actualPC = alu_result;
            end
            else if(isBranch)
                actualPC = PC+immediate;
        end
    end

endmodule