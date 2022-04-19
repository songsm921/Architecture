`include "opcodes.v"
module PC(input reset, input clk, input pc_write, input pc_writenotcond, input alu_bcond, input [`word_size-1:0] next_pc, output reg [`word_size - 1: 0] current_pc);
    always @(posedge clk) begin
        if(reset)
            current_pc <= `word_size'd0;
        else begin
            if((!alu_bcond && pc_writenotcond) || pc_write) 
                current_pc <= next_pc;   
        end
    end 
endmodule