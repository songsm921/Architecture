`include "opcodes.v"

module ActualPC(input notMatch,input notMatch2, input isJAL, input isBranch, input isJALR, input [31:0] PC, input[31:0] immediate, 
input [31:0] alu_result, output reg[31:0] actualPC);
    always @(*) begin
        if(notMatch || notMatch2) begin
            if(isJAL || isJALR) begin
                actualPC = alu_result;
            end
            else if(isBranch) begin
                if(notMatch2)
                    actualPC = PC + immediate;
                else
                    actualPC = PC+4;
            end
        end
    end

endmodule