`include "opcodes.v"
module PC(input reset, input clk, input pc_write, input [`word_size-1:0] next_pc, output reg [`word_size - 1: 0] current_pc);
    always @(posedge clk) begin
        if(reset)
            current_pc <= `word_size'd0;
        else begin
            if(pc_write) 
                current_pc <= next_pc;   
        end
    end 
endmodule