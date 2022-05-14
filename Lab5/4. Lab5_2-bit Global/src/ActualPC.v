`include "opcodes.v"

module ActualPC(input correct, input correct2,input isJAL, input isBranch, input isJALR, input [31:0] PC, input[31:0] immediate, 
input [31:0] alu_result, input alu_bcond, output reg[31:0] actualPC);
    always @(*) begin
    if(!correct) begin
        if(isJAL || isJALR)
            actualPC = alu_result;
        else if(isBranch) begin
            if(alu_bcond)
                actualPC = PC + immediate;
            else
                actualPC = PC + 4;
        end
end
    if(!correct2) begin
        if(isJAL || isJALR)
            actualPC = alu_result;
        else if(isBranch) begin
            if(alu_bcond)
                actualPC = PC + immediate;
            else
                actualPC = PC + 4;
        end
    end
    end
endmodule
